//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactAddTask.h"
#import "PEXTask_Protected.h"
#import "PEXAuthCheckTask.h"
#import "PEXTaskEventWrapper.h"
#import "PEXCListFetchTask.h"
#import "NSString+DDXML.h"
#import "PEXRegex.h"
#import "PEXDBUserProfile.h"
#import "PEXGuiController.h"
#import "PEXContactAddEvents.h"
#import "PEXTaskContainerEvents.h"
#import "PEXUtils.h"
#import "PEXTaskContainerEventSerializer.h"
#import "PEXCListAddTask.h"
#import "PEXService.h"
#import "PEXReport.h"

NSString * PEX_ACTION_CONTACT_ADDED = @"net.phonex.contacts.action.added";
NSString * PEX_EXTRA_CONTACT_ADDED = @"PEX_EXTRA_CONTACT_ADDED";

@interface PEXContactAddTask () { }
@property (nonatomic) PEXGuiController * controller;
@property (nonatomic) PEXContactAddResult * result;

/**
* If true, cancellation signal was received.
*/
@property (nonatomic) BOOL alreadyCancelled;

/**
* Account profile loaded from database / generated for currently
* logged user. Initialized
*/
@property (nonatomic) PEXDbUserProfile * account;

@property (nonatomic) NSProgress * progress;
@property (nonatomic) PEXCListAddTask * clistAddTask;
@property (nonatomic) PEXTaskContainerEventSerializer * eventProcessor;

- (void) endedInternal: (const PEXTaskEvent * const) ev;
- (void) progressedInternal: (int) source event: (const PEXTaskEvent * const) ev;
@end

@implementation PEXContactAddTask
static void *ProgressObserverContext = &ProgressObserverContext;

- (id) initWithController: (PEXGuiController *) controller;
{
    self = [super init];
    __weak __typeof__(self) weakSelf = self;

    self.controller = controller;
    self.progress = [NSProgress progressWithTotalUnitCount: 1];
    self.alreadyCancelled = NO;
    self.eventProcessor = [[PEXTaskContainerEventSerializer alloc] init];
    self.eventProcessor.eventCallbackBlock = ^(int source, const PEXTaskProgressedEvent *const tev){
        [weakSelf processProgressedInternal:source event:tev];
    };

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == ProgressObserverContext) {
        NSProgress *progress2 = object;
        DDLogVerbose(@"Progressed; fractionCompleted: %1.3f", progress2.fractionCompleted);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSProgress *progress = object;
            PEXContactAddTaskEventProgress * ev = [[PEXContactAddTaskEventProgress alloc] init];
            ev.progress = progress;
            ev.ignoreStage = YES;
            [self progressed:ev];
        }];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)progressedInternal:(int)source event:(const PEXTaskEvent *const)ev {
    if (ev==nil){ // || ![ev isKindOfClass:[PEXTaskProgressedEvent class]]){
        DDLogError(@"Invalid progress received");
        return;
    }

    const PEXTaskProgressedEvent * const tev = (const PEXTaskProgressedEvent * const) ev;
    DDLogVerbose(@"progressedInternal[%d] %@", source, tev);

    // If progress is cancelled, do not accept more notifications in this way
    // i.e., by normal sub-tasks.
    if (self.alreadyCancelled){
        DDLogVerbose(@"progressedInternal, no more progress updates - it was cancelled.");
        return;
    }

    // Hand-over to our progress processing engine.
    // Use async call on serial synchronization queue so thread safety is guaranteed.
    [self.eventProcessor addEvent:source event:tev];
}

- (void)processProgressedInternal:(int)source event:(const PEXTaskProgressedEvent *const)tev {
    // Some events are interesting and worth a notification.
    PEXContactAddStage stage = PEX_CONTACT_ADD_STAGE_1;
    switch(tev.subTaskId){
        default: break;
        case PCLAT_PREPARE:                 stage = PEX_CONTACT_ADD_STAGE_PREPARE; break;
        case PCLAT_CERT_FETCH:              stage = PEX_CONTACT_ADD_STAGE_CERT_FETCH; break;
        case PCLAT_CERT_PROCESS:            stage = PEX_CONTACT_ADD_STAGE_CERT_PROCESS; break;
        case PCLAT_CONTACT_STORE_SOAP:      stage = PEX_CONTACT_ADD_STAGE_CONTACT_STORE_SOAP; break;
        case PCLAT_CONTACT_STORE_LOCALLY:   stage = PEX_CONTACT_ADD_STAGE_CONTACT_STORE_LOCALLY; break;
        case PCLAT_ROLLBACK:                stage = PEX_CONTACT_ADD_STAGE_ROLLBACK; break;
    }

    // No useful update happened. Exit.
    if (stage==PEX_CONTACT_ADD_STAGE_1){
        return;
    }

    // Notify about this update.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        PEXContactAddTaskEventProgress * evv = [[PEXContactAddTaskEventProgress alloc] initWithStage:stage];
        [self progressed:evv];
    }];
}

- (void)cancel {
    [super cancel];

    // Propagate cancellation via NSProgress.
    [self.progress cancel];
    DDLogVerbose(@"Cancel called at PEXContactAddTask.");

    // Mark as cancelled so no further progress updates are not reflected
    // from normal tasks.
    self.alreadyCancelled = self.result.resultDescription == PEX_CONTACT_ADD_CANCELLED;

    // Notify about this update.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        PEXContactAddTaskEventProgress * evv = [[PEXContactAddTaskEventProgress alloc] initWithStage:PEX_CONTACT_ADD_STAGE_ROLLBACK];
        [self progressed:evv];
    }];
}

// Internal termination event.
- (void) endedInternal: (const PEXTaskEvent * const) ev{
    const PEXContactAddTaskEventEnd * const tev = (const PEXContactAddTaskEventEnd * const) ev;

    // Set event to the main result - will be returned afterwards.
    self.result = tev.getResult;
    BOOL endedWithFault = self.result.resultDescription != PEX_CONTACT_ADD_RESULT_ADDED;
    if (endedWithFault) {
        DDLogDebug(@"Contact add process ended wiht fault[%ld]", (long)self.result.resultDescription);

        // Try to cancel current operation
        [self.progress cancel];

        // State rollback here.
        [self onCancelledStateRollback];
    } else {
        // Signalize successful user add.
        [PEXReport logUsrEvent:PEX_EVENT_USER_ADDED];
        [PEXService executeWithName:@"bcast_user_added" async:YES block:^{
            NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

            // Post notification to the notification center.
            [center postNotificationName:PEX_ACTION_CONTACT_ADDED object:nil userInfo:@{
                    PEX_EXTRA_CONTACT_ADDED : self.contactAddress
            }];
        }];

        // Normal end, no state rollback. Signalize end of waiting right now.
        // Signalize end to the waiting loop.
        [self finishWaiting];
    }
}

- (void) finishWaiting {
    // Unregister KVO.
    NSProgress * myProgress = self.progress;
    @try {
        if (myProgress != nil){
            [myProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:ProgressObserverContext];
        }
    } @catch (NSException * __unused exception) {}

    [self endedProtected];
}

- (void) onCancelledStateRollback {
    // Call finish waiting eventually.
    [self finishWaiting];
}

/**
* Has to be overriden, if perform is called using GCD,
* NSOperationQueue refuses to start a new thread if
* perform is waiting, on some devices.
*/
- (void) start
{
    [self startedProtected];
    [self perform];
}

- (void) perform
{
    // KVO on the progress.
    __weak __typeof__(self) weakSelf = self;
    [self.progress addObserver:weakSelf
                    forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                       options:NSKeyValueObservingOptionInitial
                       context:ProgressObserverContext];

    // Reset event queue.
    [self.eventProcessor clear];

    // Initialize semaphore.
    self.alreadyCancelled = NO;

    // Input sanitizing.
    [self sanitizeInput];
}

-(void) sanitizeInput {
    // 1. Trim, lowercase on username.
    self.contactAddress = [[self.contactAddress stringByTrimming] lowercaseString];
    self.contactAlias   = [self.contactAlias stringByTrimming];

    // 2. Regex check for name.
    NSRegularExpression * regex = [PEXRegex regularExpressionWithString:@"^([^@:]+)(:?@([^@:]+\\.[^@]+))?$" isCaseSensitive:NO error:nil];
    NSRange range = NSMakeRange(0, self.contactAddress.length);
    NSArray * m = [regex matchesInString:self.contactAddress options:0 range:range];
    if (m==nil || [m count]==0){
        PEXContactAddResult * res = [[PEXContactAddResult alloc] initWithResultDescription:PEX_CONTACT_ADD_RESULT_ILLEGAL_LOGIN_NAME];
        [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:res]];
        return;
    }

    // 3. Add default server part if is missing.
    if ([self.contactAddress rangeOfString:@"@"].location == NSNotFound){
        self.contactAddress = [NSString stringWithFormat:@"%@@phone-x.net", self.contactAddress];
    }

    // Display name extract.
    NSArray * nameParts = [self.contactAddress componentsSeparatedByString:@"@"];

    // Empty display name?
    if ([PEXUtils isEmpty:self.contactAlias]){
        self.contactAlias = nameParts[0];
    }

    // Start task.
    [self startContactlistAddTask];
}

-(void) startContactlistAddTask {
    PEXAppState * appState = [PEXAppState instance];
    PEXCListAddTask * task = [[PEXCListAddTask alloc] init];
    PEXCListChangeParams * param = [[PEXCListChangeParams alloc] init];
    param.userName = self.contactAddress;
    param.diplayName = self.contactAlias;
    param.inWhitelist = YES;
    param.cr = [PEXDbAppContentProvider instance];
    task.params = param;
    task.privData = [appState getPrivateData];

    __weak PEXContactAddTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onContactlistAddTaskCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:0 event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"contactadd task: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.clistAddTask = task;

    // Run task in async thread.
    [task startOnBackgroundThread];
}

-(void) onContactlistAddTaskCompleted : (PEXTaskFinishedEvent const * const) ev{
    if (ev.didFinishCancelled){
        DDLogError(@"Task cancelled: %@", ev);

        PEXContactAddResult * res = [[PEXContactAddResult alloc] initWithResultDescription:PEX_CONTACT_ADD_CANCELLED];
        [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:res]];
        return;

    } else if (ev.didFinishWithError){
        DDLogError(@"Task failed: %@", ev);

        // Check connection error.
        if ([PEXUtils doErrorMatch:ev.finishError domain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet]){
            PEXContactAddResult * res = [[PEXContactAddResult alloc] initWithResultDescription:PEX_CONTACT_ADD_RESULT_NO_NETWORK];
            [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:res]];
            return;
        }

        // User already added.
        if ([PEXUtils doErrorMatch:ev.finishError domain:PEXCListAddErrorDomain code:PEXClistAddErrorUserAlreadyAdded]){
            PEXContactAddResult * res = [[PEXContactAddResult alloc] initWithResultDescription:PEX_CONTACT_ADD_RESULT_ALREADY_ADDED];
            [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:res]];
            return;
        }

        PEXContactAddResult * res = [[PEXContactAddResult alloc] initWithResultDescription:PEX_CONTACT_ADD_RESULT_SERVERSIDE_PROBLEM];
        [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:res]];
        return;
    }

    // Check result of contact add task.
    DDLogVerbose(@"Contact list add task completed; %@", ev);

    // Task done.
    self.result.resultDescription = PEX_CONTACT_ADD_RESULT_ADDED;
    [self endedInternal: [[PEXContactAddTaskEventEnd alloc] initWithResult:self.result]];
}

- (void) endedProtected
{
    [self ended:[[PEXContactAddTaskEventEnd alloc] initWithResult:_result]];
}

- (void) performCancel
{
    DDLogInfo(@"performCancel!!!!");
    self.result.resultDescription = PEX_CONTACT_ADD_CANCELLED;

    [self cancelStarted:nil];
    [NSThread sleepForTimeInterval:1.0];

    [self cancelProgressed:nil];

    [NSThread sleepForTimeInterval:1.0];
    _unsuccessful = true;
    [self cancelEnded:nil];
}

- (PEXContactAddResult *) getResult { return self.result; }

@end
