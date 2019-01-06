//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactRenameTask.h"
#import "PEXTask_Protected.h"
#import "PEXAuthCheckTask.h"
#import "PEXTaskEventWrapper.h"
#import "PEXCListFetchTask.h"
#import "NSString+DDXML.h"
#import "PEXRegex.h"
#import "PEXDBUserProfile.h"
#import "PEXUtils.h"
#import "PEXCListAddTask.h"
#import "PEXCListRenameTask.h"
#import "PEXReport.h"

@interface PEXContactRenameTask () { }
@property (nonatomic) PEXContactRenameResult * result;

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
@property (nonatomic) PEXCListRenameTask * clistRenameTask;

- (void) endedInternal: (const PEXTaskEvent * const) ev;
@end

@implementation PEXContactRenameTask
static void *ProgressObserverContext = &ProgressObserverContext;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.contactAddress = nil;
        self.progress = [NSProgress progressWithTotalUnitCount: 1];
        self.alreadyCancelled = NO;
    }

    return self;
}

- (instancetype)initWithContactAddress:(NSString *)contactAddress {
    self = [self init];
    if (self) {
        self.contactAddress = contactAddress;
    }

    return self;
}

+ (instancetype)taskWithContactAddress:(NSString *)contactAddress {
    return [[self alloc] initWithContactAddress:contactAddress];
}

- (void)cancel {
    [super cancel];

    // Propagate cancellation via NSProgress.
    [self.progress cancel];
    DDLogVerbose(@"Cancel called at PEXLoginTask.");

    // Mark as cancelled so no further progress updates are not reflected
    // from normal tasks.
    self.alreadyCancelled = self.result.resultDescription == PEX_CONTACT_RENAME_CANCELLED;
}

// Internal termination event.
- (void) endedInternal: (const PEXTaskEvent * const) ev{
    const PEXContactRenameTaskEventEnd * const tev = (const PEXContactRenameTaskEventEnd * const) ev;

    // Set event to the main result - will be returned afterwards.
    self.result = tev.getResult;
    BOOL endedWithFault = self.result.resultDescription != PEX_CONTACT_RENAME_RESULT_RENAMED;
    if (endedWithFault) {
        DDLogDebug(@"Contact rename process ended wiht fault[%ld]", (long)self.result.resultDescription);

        // Try to cancel current operation
        [self.progress cancel];

        // State rollback here.
        [self onCancelledStateRollback];
    } else {
        // Normal end, no state rollback. Signalize end of waiting right now.
        // Signalize end to the waiting loop.
        [self finishWaiting];
    }
}

- (void) finishWaiting {
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
    // Initialize semaphore.
    self.alreadyCancelled = NO;

    // Input sanitizing.
    [self sanitizeInput];
}

-(void) sanitizeInput {
    // 1. Trim, lowercase on username.
    self.contactAddress = [[self.contactAddress stringByTrimming] lowercaseString];
    self.contactAlias = [self.contactAlias stringByTrimming];

    // 2. Regex check for name.
    NSRegularExpression * regex = [PEXRegex regularExpressionWithString:@"^([^@:]+)(:?@([^@:]+\\.[^@]+))?$" isCaseSensitive:NO error:nil];
    NSRange range = NSMakeRange(0, self.contactAddress.length);
    NSArray * m = [regex matchesInString:self.contactAddress options:0 range:range];
    if (m==nil || [m count]==0){
        PEXContactRenameResult * res = [[PEXContactRenameResult alloc] initWithResultDescription:PEX_CONTACT_RENAME_RESULT_ILLEGAL_LOGIN_NAME];
        [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:res]];
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
    [self startContactlistRenameTask];
}

-(void) startContactlistRenameTask {
    PEXAppState * appState = [PEXAppState instance];
    PEXCListRenameTask * task = [[PEXCListRenameTask alloc] init];
    PEXCListChangeParams * param = [[PEXCListChangeParams alloc] init];
    param.userName = self.contactAddress;
    param.diplayName = self.contactAlias;
    param.inWhitelist = YES;
    param.cr = [PEXDbAppContentProvider instance];
    task.params = param;
    task.privData = [appState getPrivateData];

    __weak PEXContactRenameTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onContactlistRenameTaskCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        DDLogVerbose(@"contact_rename progress: %@", ev);
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"contact_rename task: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.clistRenameTask = task;

    // Run task in async thread.
    [task startOnBackgroundThread];
}

-(void) onContactlistRenameTaskCompleted : (PEXTaskFinishedEvent const * const) ev{
    if (ev.didFinishCancelled){
        DDLogError(@"Task cancelled: %@", ev);

        PEXContactRenameResult * res = [[PEXContactRenameResult alloc] initWithResultDescription:PEX_CONTACT_RENAME_CANCELLED];
        [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:res]];
        return;

    } else if (ev.didFinishWithError){
        DDLogError(@"Task failed: %@", ev);

        // Check connection error.
        if ([PEXUtils doErrorMatch:ev.finishError domain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet]){
            PEXContactRenameResult * res = [[PEXContactRenameResult alloc] initWithResultDescription:PEX_CONTACT_RENAME_RESULT_NO_NETWORK];
            [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:res]];
            return;
        }

        // User already added.
        if ([PEXUtils doErrorMatch:ev.finishError domain:PEXCListAddErrorDomain code:PEXClistAddErrorUserAlreadyAdded]){
            PEXContactRenameResult * res = [[PEXContactRenameResult alloc] initWithResultDescription:PEX_CONTACT_RENAME_RESULT_UNKNOWN_USER];
            [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:res]];
            return;
        }

        PEXContactRenameResult * res = [[PEXContactRenameResult alloc] initWithResultDescription:PEX_CONTACT_RENAME_RESULT_SERVERSIDE_PROBLEM];
        [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:res]];
        return;
    }

        // Check result of contact add task.
    DDLogVerbose(@"Contact list add task completed; %@", ev);

    // Task done.
    [PEXReport logUsrEvent:PEX_EVENT_USER_RENAMED];
    self.result.resultDescription = PEX_CONTACT_RENAME_RESULT_RENAMED;
    [self endedInternal: [[PEXContactRenameTaskEventEnd alloc] initWithResult:self.result]];
}

- (void) endedProtected
{
    [self ended:[[PEXContactRenameTaskEventEnd alloc] initWithResult:_result]];
}

- (void) performCancel
{
    DDLogInfo(@"performCancel!!!!");
    self.result.resultDescription = PEX_CONTACT_RENAME_CANCELLED;

    [self cancelStarted:nil];
    [NSThread sleepForTimeInterval:1.0];

    [self cancelProgressed:nil];

    [NSThread sleepForTimeInterval:1.0];
    _unsuccessful = true;
    [self cancelEnded:nil];
}

- (PEXContactRenameResult *) getResult { return self.result; }

@end
