//
//  PEXLoginTask.m
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXLoginTask.h"
#import "PEXTask_Protected.h"

#import "PEXCredentials.h"
#import "PEXDatabase.h"
#import "PEXUser.h"
#import "PEXLoginTaskResult.h"
#import "PEXAuthCheckTask.h"
#import "PEXTaskEventWrapper.h"
#import "PEXCertGenTask.h"
#import "PEXCListFetchTask.h"
#import "NSString+DDXML.h"
#import "PEXRegex.h"
#import "PEXDBUserProfile.h"
#import "PEXGuiSetNewPasswordExecutor.h"
#import "PEXGuiController.h"
#import "PEXChangePasswordParams.h"
#import "PEXChangePasswordTask.h"
#import "PEXTaskContainerEvents.h"
#import "PEXUtils.h"
#import "PEXTaskContainerEventSerializer.h"
#import "PEXXmppCenter.h"
#import "PEXXmppManager.h"
#import "PEXPjManager.h"
#import "PEXMessageManager.h"
#import "PEXService.h"
#import "PEXMessageDigest.h"
#import "PEXCryptoUtils.h"
#import "PEXTaskBlock.h"
#import "PEXSoapAdditions.h"
#import "PEXLicenceInfo.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXLoginHelper.h"
#import "PEXChatAccountingManager.h"
#import "PEXLicenceManager.h"
#import "PEXTimeUtils.h"
#import "PEXReferenceTimeManager.h"
#import "PEXReport.h"
#import "PEXAccountingHelper.h"

/**
* List of main tasks in this login task.
* Used for progress monitoring.
*/
typedef enum PEX_LOGIN_MAIN_TASK {
    PEX_TASK_LOGIN_MAIN_CHECK_TASK=0,
    PEX_TASK_LOGIN_MAIN_AUTH_CHECK_TASK,
    PEX_TASK_LOGIN_MAIN_CHANGE_PASSWORD_TASK,
    PEX_TASK_LOGIN_MAIN_CERT_GEN_TASK,
    PEX_TASK_LOGIN_MAIN_CLIST_FETCH_TASK
}PEX_LOGIN_MAIN_TASK;

const NSInteger PEX_AUTH_CHECK_CODE_OLD_VERSION=-11;
const NSInteger PEX_AUTH_CHECK_CODE_INCOMPATIBLE_VERSION=-12;
const NSInteger PEX_AUTH_CHECK_CODE_GENERIC_FAIL=-1;

@interface PEXLoginTask ()
{
    @private volatile bool _passwordSet;

    // Semaphore for monitoring login process for perform to wait for finish.
    @private dispatch_semaphore_t _performSemaphore;
}

@property (nonatomic) PEXGuiController * controller;
@property (nonatomic) PEXLoginTaskResult * result;
@property (nonatomic) const PEXCredentials * credentials;

/**
* Internal property, says whether a new certificate has to be generated for the user
* or there is already some.
*/
@property (nonatomic) BOOL certificateExistsForUser;

/**
* If true, cancellation signal was received.
*/
@property (nonatomic) BOOL alreadyCancelled;

/**
* Internal property, user displayname, derived from the login name.
*/
@property (nonatomic) NSString * displayName;

/**
* Internal property, user domain, derived from the login name.
*/
@property (nonatomic) NSString * userDomain;

/**
* Internal property, private data structure. Contains user identity.
* Generated during the login process, used for SOAP calls.
*/
@property (nonatomic) PEXUserPrivate * privData;

/**
* Account profile loaded from database / generated for currently
* logged user. Initialized
*/
@property (nonatomic) PEXDbUserProfile * account;

/**
* New password set by the new password.
*/
@property (nonatomic) NSString * nwPass;

@property (nonatomic) NSProgress * progress;
@property (nonatomic, weak) PEXTask * currentTask;

@property (nonatomic) PEXTaskBlock * conditionCheckTask;
@property (nonatomic) PEXAuthCheckTask * authCheckTask;
@property (nonatomic) PEXCertGenTask * certGenTask;
@property (nonatomic) PEXCListFetchTask * clistFetchTask;
@property (nonatomic) PEXChangePasswordTask * changePassTask;

@property (nonatomic) PEXTaskContainerEventSerializer * eventProcessor;

@property (nonatomic) PEXLicenceInfo * licenceInfo;
@property (nonatomic) NSDictionary * auxJson;
@property (nonatomic) NSString * turnPassword;

@property (nonatomic, assign) bool licenceWasUpdated;

- (void) endedInternal: (const PEXTaskEvent * const) ev;
- (void) progressedInternal: (int) source event: (const PEXTaskEvent * const) ev;

@end

@implementation PEXLoginTask
static void *ProgressObserverContext = &ProgressObserverContext;

- (id) initWithCredentials: (PEXCredentials * const) credentials
                controller: (PEXGuiController *) controller;
{
    self = [super init];
    __weak PEXLoginTask * weakSelf = self;

    _performSemaphore = nil;
    self.controller = controller;
    self.credentials = credentials;
    self.progress = self.progress = [NSProgress progressWithTotalUnitCount: 1+4+1+1+1];
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
            PEXLoginTaskEventProgress * ev = [[PEXLoginTaskEventProgress alloc] init];
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
    PEXLoginStage stage = PEX_LOGIN_STAGE_1;
    switch(source){
        default: return;
        case PEX_TASK_LOGIN_MAIN_CHECK_TASK:

            break;

        case PEX_TASK_LOGIN_MAIN_AUTH_CHECK_TASK:
            switch(tev.subTaskId){
                default: break;
                case PACT_KEYGEN: stage = PEX_LOGIN_STAGE_AUTH_KEYGEN; break;
                case PACT_SOAP:   stage = PEX_LOGIN_STAGE_AUTH_SOAP; break;
            }
            break;

        case PEX_TASK_LOGIN_MAIN_CHANGE_PASSWORD_TASK:
            switch(tev.subTaskId){
                default: break;
                case PEX_CHANGEPASS_OTT:     stage = PEX_LOGIN_STAGE_CHANGEPASS_OTT; break;
                case PEX_CHANGEPASS_SOAP:    stage = PEX_LOGIN_STAGE_CHANGEPASS_SOAP; break;
                case PEX_CHANGEPASS_KEYGEN:  stage = PEX_LOGIN_STAGE_CHANGEPASS_KEYGEN; break;
                case PEX_CHANGEPASS_REKEY:   stage = PEX_LOGIN_STAGE_CHANGEPASS_REKEY; break;
            }
            break;

        case PEX_TASK_LOGIN_MAIN_CERT_GEN_TASK:
            switch(tev.subTaskId){
                default: break;
                case PCGT_KEYGEN:   stage = PEX_LOGIN_STAGE_PCGT_KEYGEN; break;
                case PCGT_OTT:      stage = PEX_LOGIN_STAGE_PCGT_OTT; break;
                case PCGT_SOAPSIGN: stage = PEX_LOGIN_STAGE_PCGT_SOAP; break;
                case PCGT_VERIFY:   stage = PEX_LOGIN_STAGE_PCGT_VERIFY; break;
                case PCGT_STORE:    stage = PEX_LOGIN_STAGE_PCGT_STORE; break;
            }
            break;

        case PEX_TASK_LOGIN_MAIN_CLIST_FETCH_TASK:
            switch(tev.subTaskId){
                default: break;
                case PCLT_FETCH_CL:     stage = PEX_LOGIN_STAGE_PCLT_FETCH_CL; break;
                case PCLT_PROCESS_CL:   stage = PEX_LOGIN_STAGE_PCLT_PROCESS_CL; break;
                case PCLT_CERT_REFRESH: stage = PEX_LOGIN_STAGE_PCLT_CERT_REFRESH; break;
                case PCLT_CERT_PROCESS: stage = PEX_LOGIN_STAGE_PCLT_CERT_PROCESS; break;
                case PCLT_STORE:        stage = PEX_LOGIN_STAGE_PCLT_STORE; break;
            }
            break;
    }

    // No useful update happened. Exit.
    if (stage==PEX_LOGIN_STAGE_1){
        return;
    }

    // Notify about this update.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        PEXLoginTaskEventProgress * evv = [[PEXLoginTaskEventProgress alloc] initWithStage:stage];
        [self progressed:evv];
    }];
}

- (void)cancel {
    [super cancel];

    // Propagate cancellation via NSProgress.
    [self.progress cancel];
    DDLogVerbose(@"Cancel called at PEXLoginTask.");

    // Mark as cancelled so no further progress updates are not reflected
    // from normal tasks.
    self.alreadyCancelled = self.result.resultDescription == PEX_LOGIN_TASK_CANCELLED;

    // Notify about this update.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        PEXLoginTaskEventProgress * evv = [[PEXLoginTaskEventProgress alloc] initWithStage:PEX_LOGIN_STAGE_CANCELLING];
        [self progressed:evv];
    }];
}

// Internal termination event.
- (void) endedInternal: (const PEXTaskEvent * const) ev{
    const PEXLoginTaskEventEnd * const tev = (const PEXLoginTaskEventEnd * const) ev;

    // Set event to the main result - will be returned afterwards.
    self.result = tev.getResult;
    BOOL endedWithFault = self.result.resultDescription != PEX_LOGIN_TASK_RESULT_LOGGED_IN;
    if (endedWithFault) {
        DDLogWarn(@"Login process ended wiht fault [%ld]", (long)self.result.resultDescription);
        [PEXReport logEvent:PEX_EVENT_LOGIN_TASK_FINISHED_FAIL code:@(self.result.resultDescription)];

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
    if (_performSemaphore!=nil){
        dispatch_semaphore_signal(_performSemaphore);
    }

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
    // If database was opened, close it.
    @try {
        if (self.result.dbLoadResult != PEX_DB_LOAD_FATAL_ERROR) {
            DDLogVerbose(@"Closing database");
            [PEXDatabase unloadDatabase];
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in closing database, exception=%@", e);
    }

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
    // Normal login process.
    // This should follow procedure described @ https://iwiki.phone-x.net/index.php/Login_process
    //
    // Input sanitizing.
    // Auth check task.
    // Encrypted database open.
    // OPT: Certificate generation.
    // Contact list fetch + certificate refresh.
    // Redirect to main application screen.
    //

    // KVO on the progress.
    __weak __typeof__(self) weakSelf = self;
    [self.progress addObserver:weakSelf
                    forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                       options:NSKeyValueObservingOptionInitial
                       context:ProgressObserverContext];

    // Reset event queue.
    [self.eventProcessor clear];

    // Initialize semaphore.
    _performSemaphore = dispatch_semaphore_create(0);
    self.alreadyCancelled = NO;

    // Input sanitizing.
    [self sanitizeInput];
}

-(void) sanitizeInput {
    // 1. Trim, lowercase on username.
    self.credentials.username = [[self.credentials.username stringByTrimming] lowercaseString];
    self.credentials.password = [self.credentials.password stringByTrimming];

    // 2. Regex check for name.
    NSRegularExpression * regex = [PEXRegex regularExpressionWithString:@"^([^@:]+)(:?@([^@:]+\\.[^@]+))?$" isCaseSensitive:NO error:nil];
    NSRange range = NSMakeRange(0, self.credentials.username.length);
    NSArray * m = [regex matchesInString:self.credentials.username options:0 range:range];
    if (m==nil || [m count]==0){
        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_ILLEGAL_LOGIN_NAME];
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
        return;
    }

    // 3. Add default server part if is missing.
    if ([self.credentials.username rangeOfString:@"@"].location == NSNotFound){
        self.credentials.username = [NSString stringWithFormat:@"%@@phone-x.net", self.credentials.username];
    }

    // Display name extract.
    NSArray * nameParts = [self.credentials.username componentsSeparatedByString:@"@"];
    self.displayName = nameParts[0];
    self.userDomain = nameParts[1];

    // Check if previous shutdown has completed.
    [self checkConditionsTask];
}

- (void) checkConditionsTask {
    // Create block task.
    PEXTaskBlock * task = [[PEXTaskBlock alloc] initWithName:@"preAuthCheck" block:nil];

    // Conditions to check body, specific for logging in.
    __weak __typeof(self) weakSelf = self;
    task.block = ^(PEXBlockSubtask *subtask) {
        // Check service state, wait for finished / initialized state for 5 seconds.
        PEXService * svc = [PEXService instance];
        NSDate * date = [NSDate date];

        DDLogVerbose(@"Starting wait loop for service to become ready.");
        while (YES) {
            if (svc.initState == PEX_SERVICE_FINISHED || svc.initState == PEX_SERVICE_INITIALIZED) {
                DDLogDebug(@"Service is ready for a new login process.");
                break;
            }

            if ([date timeIntervalSinceNow] < -10) {
                DDLogInfo(@"Waiting for service to become ready for login timed out.");
                break;
            }

            // adapt this value in microseconds.
            usleep(10000);
        }
    };

    // Task management - add observers and start.
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onCheckConditionsCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:PEX_TASK_LOGIN_MAIN_CHECK_TASK event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"conditioncheck task: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:0];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.conditionCheckTask = task;
    self.currentTask = task;

    // Run task in async thread.
    [task startOnBackgroundThread];
}

-(void) onCheckConditionsCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (![self onTaskFinishedCheck:ev]){
        return;
    }

    DDLogVerbose(@"Conditions check completed; %@", ev);

    // Check last username that attempted to login to the application. Due to IPH-10 and iOS bug
    // TLS credentials are cached and for a new user they cannot be used for login.
    PEXService * svc = [PEXService instance];
    if (svc.lastLoginUserName != nil && ![self.credentials.username isEqualToString:svc.lastLoginUserName]){
        // Display warning that login cannot continue and quit.
        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_TLS_CACHE_BUG];
        PEXLoginTaskEventEnd * endEvt = [[PEXLoginTaskEventEnd alloc] initWithResult:res];
        [self endedInternal: endEvt];
        return;
    }

    svc.lastLoginUserName = self.credentials.username;

    // Start auth check task.
    [self startAuthCheckTask];
}

-(void) startAuthCheckTask {
// Auth check task.
    PEXAuthCheckTask * task = [[PEXAuthCheckTask alloc] init];
    PEXCertGenParams * param = [[PEXCertGenParams alloc] init];
    param.userName = self.credentials.username;
    param.password = self.credentials.password;
    self.privData = [[PEXUserPrivate alloc] initWithUsername:param.userName pass:param.password];
    task.params = param;
    task.privData = self.privData;

    __weak PEXLoginTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onAuthCheckCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:PEX_TASK_LOGIN_MAIN_AUTH_CHECK_TASK event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"authchecktask: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:4];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.authCheckTask = task;
    self.currentTask = task;

    // Run task in async thread.
    [PEXReport logEvent:PEX_EVENT_LOGIN_TASK_STARTED];
    [task startOnBackgroundThread];
}

-(BOOL) onTaskFinishedCheck: (PEXTaskFinishedEvent const * const) ev {
    if (ev.didFinishCancelled){
        DDLogError(@"Task cancelled: %@", ev);

        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_CANCELLED];
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
        return NO;

    } else if (ev.didFinishWithError){
        DDLogError(@"Task failed: %@", ev);

        // Check connection error.
        if ([PEXUtils doErrorMatch:ev.finishError domain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet]){
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_NO_NETWORK];
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return NO;
        }

        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_SERVERSIDE_PROBLEM];
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
        return NO;
    }

    return YES;
}

-(void) onAuthCheckCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (![self onTaskFinishedCheck:ev]){
        return;
    }

    DDLogVerbose(@"Auth check completed; %@", ev);
    DDLogVerbose(@"AuthCheckResponse: %@", [PEXSoapAdditions authCheckToString:self.authCheckTask.response]);

    // Check auth check response.
    __weak hr_authCheckV3Response * response = self.authCheckTask.response;
    NSDate * serverTime = response.serverTime;

    PEXAppState * appState = [PEXAppState instance];
    if (!appState.referenceTimeManager)
        appState.referenceTimeManager = [[PEXReferenceTimeManager alloc] init];

    // TODO referenceTimeManager not destroyed after login failure
    [appState.referenceTimeManager setReferenceServerTime:serverTime];


    NSDate * curDate = [NSDate date];
    double timeDriftDouble = ([serverTime timeIntervalSince1970] - [curDate timeIntervalSince1970]) * 1000.0;
    long timeDrift = ABS((long) ceil(timeDriftDouble));
    DDLogVerbose(@"Time drift in milliseconds: %ld, serverTime: %@, localTime: %@", timeDrift, serverTime, curDate);

    if (response.authHashValid == hr_trueFalse_false){
        // Check clock problem which causes login problem.
        if (timeDrift > (1000 * 60 * 3)){
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_CLOCK_PROBLEM];
            res.serverTime = response.serverTime;
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return;
        }

        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_INCORRECT_CREDENTIALS];
        res.serverTime = response.serverTime;
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];

        DDLogWarn(@"Auth hash verification failed!");
        return;
    }

    // Check if account is disabled on the server
    if (response.accountDisabled != nil && [response.accountDisabled boolValue]){
        // One reason for disabled account can be trial version expiration, verify it.
        // If expiration date is in the past, report expired trial problem.
        NSDate * expDate = response.accountExpires;
        if (expDate != nil){
            if ([expDate compare:[NSDate date]] == NSOrderedAscending){
                PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_TRIAL_EXPIRED];
                [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
                return;
            }
        }

        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_ACCOUNT_DISABLED];
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
        return;
    }

    // Check error code, login may have failed for some reason.
    if (response.errCode != nil){
        NSInteger errorCode = [response.errCode integerValue];
        NSDictionary * const auxJsonDictionary = [PEXLoginTask parseAuxJson:response.auxJSON pError:nil];
        if (errorCode == PEX_AUTH_CHECK_CODE_OLD_VERSION){
            DDLogVerbose(@"Error code: old version");
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_OLD_VERSION];
            [PEXLoginTask findServerFailMessage:res auxData:auxJsonDictionary];
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return;

        } else if (errorCode == PEX_AUTH_CHECK_CODE_INCOMPATIBLE_VERSION) {
            DDLogVerbose(@"Error code: incompatible version");
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_INCOMPATIBLE_VERSION];
            [PEXLoginTask findServerFailMessage:res auxData:auxJsonDictionary];
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return;

        } else if (errorCode == PEX_AUTH_CHECK_CODE_GENERIC_FAIL) {
            DDLogVerbose(@"Error code: generic fail with potential message");
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_GENERIC_SERVER_FAIL];
            [PEXLoginTask findServerFailMessage:res auxData:auxJsonDictionary];
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return;

        } else if (errorCode < 0) {
            DDLogVerbose(@"Error code: unrecognized fail with potential message");
            PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_UNSPECIFIED_SERVER_FAIL];
            [PEXLoginTask findServerFailMessage:res auxData:auxJsonDictionary];
            [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
            return;
        }
    }

    // Reset password retry attempt counter
    [self.privData resetInvalidPasswordEntryCounter];

    // Check our certificate validity
    hr_trueFalseNA certValid = response.certValid;
    if(certValid==hr_trueFalseNA_na){
        DDLogDebug(@"Certificate valid N/A. Probably certificate was not provided.");
    } else if(certValid==hr_trueFalseNA_true){
        self.certificateExistsForUser=true;
        DDLogDebug(@"Certificate valid OK.");
    } else {
        // Certificate is not valid (invalidated, may be revoked), thus ignore it as I would not have it
        DDLogInfo(@"Certificate not valid. CertificateStatus: %d", response.certStatus);
//        params.setPrivateCredentials(null);
//        params.setServiceURL(ServiceConstants.getServiceURL(params.getUserDomain(), false));
        self.certificateExistsForUser=false;
    }

    // Force password change (usually on first login).
    if(response.forcePasswordChange == hr_trueFalse_true){
        DDLogError(@"Password change forced by the server.");
        [self startShowPassChange];
        return;
    }

    // Retrieve license information
    self.licenceInfo = [[PEXLicenceInfo alloc] initWithV3Response: response];
    DDLogVerbose(@"%@", self.licenceInfo.description);

    // Parse trial event data, turn password.
    [self parseAuxJson:response];

    // Extract TURN password.
    self.turnPassword = self.auxJson[@"turnPwd"];

    // Do we have a valid certificate?
    if (!self.certificateExistsForUser){
        DDLogVerbose(@"Going to generate a certificate");
        [self startCertGenTask];
        return;

    } else {
        DDLogVerbose(@"Certificate gen step skipped");

        // TODO: handle this case when certificate is already generated from previous run.
        [self onCertGenCompleted: nil];
        return;
    }
}

+ (void) findServerFailMessage: (PEXLoginTaskResult *) result auxData: (NSDictionary *) auxData {
    if (auxData == nil){
        return;
    }

    @try {
        NSString * title = auxData[@"loginFailTitleMsg"];
        NSString * desc = auxData[@"loginFailDescMsg"];

        if (![PEXUtils isEmpty:title]){
            result.serverFailTitle = title;
        }

        if (![PEXUtils isEmpty:desc]){
            result.serverFailDesc = desc;
        }
    }@catch(NSException * e){
        DDLogError(@"Exception when parsing login fail message");
    }
}

+ (NSDictionary *) parseAuxJson: (NSString *) auxJson pError: (NSError **) pError {
    NSError * jsonError;
    NSDictionary * auxJsonDictionary;
    @try {
        auxJsonDictionary = [NSJSONSerialization JSONObjectWithData:[auxJson dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:NSJSONReadingMutableContainers
                                                              error:&jsonError];

        if (auxJsonDictionary == nil){
            DDLogError(@"Error parsing JSON data: %@", jsonError);
        }
    } @catch (NSException * e){
        DDLogError(@"JSON deserialization failed with exception %@", e);
    }

    if (pError != NULL){
        *pError = jsonError;
    }

    return auxJsonDictionary;
}

- (void) parseAuxJson: (const hr_authCheckV3Response * const) response
{
    // Parse JSON data
    NSDictionary * const auxJsonDictionary = [PEXLoginTask parseAuxJson:response.auxJSON pError:nil];
    if (auxJsonDictionary) {
        self.auxJson = auxJsonDictionary;
    }
}

- (void) startShowPassChange {
    [self showSetNewPasswordDialogModal];
}

- (void) startChangePassword {
    PEXChangePasswordParams * params = [[PEXChangePasswordParams alloc] init];
    params.userSIP = self.privData.username;
    params.targetUserSIP = self.privData.username;
    params.rekeyDB = YES;
    params.rekeyKeyStore = YES;
    params.derivePasswords = YES;
    params.userNewPass = self.nwPass;
    params.userOldPass = self.privData.pass;

    // Reset new password from property, not needed anymore.
    self.nwPass = nil;
    // Configure task.
    self.changePassTask = [[PEXChangePasswordTask alloc] init];
    self.changePassTask.privData = self.privData;
    self.changePassTask.nwPrivData = [self.privData initCopy];
    self.changePassTask.params = params;

    __weak PEXLoginTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onPasswordChangeCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:PEX_TASK_LOGIN_MAIN_CHANGE_PASSWORD_TASK event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"changePasswordTask: Cancel ended block %@", ev);
    };

    [self.changePassTask addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [self.changePassTask prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.currentTask = self.changePassTask;
    __weak PEXTaskContainer * task = self.changePassTask;

    // Run task in async thread.
    [task startOnBackgroundThread];
}

- (void) onPasswordChangeCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (![self onTaskFinishedCheck:ev]){
        return;
    }
    DDLogVerbose(@"Password changed task completed; %@", ev);

    // Copy new identity data, mainly new password.
    self.privData = self.changePassTask.nwPrivData;
    self.credentials.password = self.changePassTask.nwPrivData.pass;

    // Start auth check task again.
    [self startAuthCheckTask];
}

- (void) tryOpenDatabase {
    @try {

        [self openDatabase];

    } @catch(NSException * e){
        DDLogWarn(@"Exception in setting DB key and user save task, exception=%@", e);

        // TODO: Trigger error to the server, this is a bug.
        // ...
        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] init];
        res.resultDescription = PEX_LOGIN_TASK_DATABASE_ERROR;
        res.dbLoadResult = PEX_DB_LOAD_FATAL_ERROR;
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
    }
}

- (void) openDatabase
{
    DDLogVerbose(@"Going to open a database for user %@", self.credentials.username);
    PEXUser * const user = [[PEXUser alloc] init];
    user.email = self.credentials.username;

    // not the best but it works :)
    bool repeat = false;
    do
    {
        const PEXDbLoadResult dbLoadResult = [PEXDatabase openOrCreateDatabase:user
                                                         encryptionKey:self.privData.pkcsPass];

        switch (dbLoadResult)
        {
            case PEX_DB_LOAD_FATAL_ERROR:
            {
                [PEXDatabase unloadDatabase];
                [self databaseError:dbLoadResult
                   errorDescription:@"Error: Database cannot be opened..."
                          repeatOut: &repeat];
                repeat = false;
                return;
            }
            case PEX_DB_LOAD_KEY_PROBLEM:
                if (!repeat)
                {
                    // Destroy the database and create it again with open
                    [PEXDatabase unloadDatabase];
                    [PEXDatabase removeDatabase:user];
                    repeat = true;
                    continue;
                }
                else
                {
                    [PEXDatabase unloadDatabase];
                    [self databaseError:dbLoadResult
                       errorDescription:@"Error: Database cannot be opened with the specified key..."
                              repeatOut: &repeat];
                    repeat = false;
                    return;
                }
                break;

            case PEX_DB_LOAD_RECCREATED:
            case PEX_DB_LOAD_OK:
                DDLogVerbose(@"Database opened successfully");
                repeat = false;
                break;
        }

    } while (repeat);

    // Save user to the database.
    [self saveUser];

    // Save certificate info to the database - presence will publish current certificate hash.
    [self saveCertInfo];

    [self saveExpiredInfoLogsData];

    // Cert gen OK, now fetch contactlist.
    [self startContactlistFetchTask];
}

- (void) databaseError: (const PEXDbLoadResult) dbLoadResult
      errorDescription: (NSString * const) description
             repeatOut: (bool *) repeat
{
    DDLogError(@"%@", description);
    PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] init];
    res.resultDescription = PEX_LOGIN_TASK_DATABASE_ERROR;
    res.dbLoadResult = dbLoadResult;
    [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
    *repeat = false;
    return;
}

- (void) saveUser {
    // Now useless, it always returns 1
    NSNumber * accountId = nil;

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    NSArray * profiles = [PEXDbUserProfile loadFromDatabase:cr selection:nil selectionArgs:nil
                                                 projection:@[PEX_DBUSR_FIELD_ID, PEX_DBUSR_FIELD_ACC_ID, PEX_DBUSR_FIELD_DISPLAY_NAME]
                                                  sortOrder:nil];

    // Load all profiles stored for distribution accountManager
    DDLogVerbose(@"Number of saved accounts=%ld", (unsigned long) profiles.count);
    if (profiles != nil && profiles.count > 0){
        accountId = ((PEXDbUserProfile * )profiles[0]).id;
        self.account = [PEXDbUserProfile getProfileFromDbId:cr id:accountId projection: [PEXDbUserProfile getFullProjection]];
    }

    // Nil check again, may be nil after load, if data is invalid or something.
    if (self.account == nil){
        self.account = [[PEXDbUserProfile alloc] init];
    }

    // Load account from database to private attribute (will be used later).
    self.account.accountManager = @"";
    self.account.username = self.credentials.username;
    self.account.display_name = self.displayName;
    self.account.datatype = @(PEX_DBUSR_CRED_DATA_PLAIN_PASSWD);
    self.account.data = self.credentials.password;
    self.account.xmpp_password = self.privData.xmppPass;
    self.account.xmpp_service = self.userDomain;
    self.account.xmpp_server = self.userDomain;
    self.account.xmpp_user = self.credentials.username;
    self.account.active = true;

    // TODO permission notifications
    // [self licenceWillBeUpdatedForUser];

    self.account.licenseType = self.licenceInfo.licenseType;
    self.account.licenseIssuedOn = self.licenceInfo.licenseIssuedOn;
    self.account.licenseExpiresOn = self.licenceInfo.licenseExpiresOn;
    self.account.licenseExpired = self.licenceInfo.licenseExpired;

    // Message Waiting Indicator events are disabled
    // if SIP presence is disabled (creates SUBSCRIBE/NOTIFY transactions).
    self.account.mwi_enabled = NO;

    // Enable TURN authentication, profile-specific.
    // TURN uses realm as domain. Patched version of restund
    // checks full user name.
    self.account.turn_cfg_user = self.account.username;
    self.account.turn_cfg_password = self.turnPassword;

    // First time user
    if (accountId == nil){
        @try {
            [PEXDbUserProfile setDefaultValues:self.account];
        } @catch(NSException * e){
            DDLogError(@"Exception during initial account setup, exception=%@", e);

            // TODO: Trigger error to the server, this is bug
            // ...
        }

        PEXDbUri const * const insUri = [cr insert:[PEXDbUserProfile getURI] contentValues:[self.account getDbContentValues]];
        if (insUri != nil && insUri.itemId != nil){
            accountId = insUri.itemId;
            self.account.id = insUri.itemId;
        } else {
            DDLogError(@"Error: cannot get inserted account ID");
        }

        DDLogVerbose(@"Inserted account [%@] id=[%@]", self.account.display_name, accountId);
    } else {
        // Profile ID convention.
        // TODO: do not do this in future. Long term todo...
        if(![accountId isEqualToNumber:@(1)]) {
            DDLogWarn(@"Account id != 1");
            self.account.id = @(1);
        }

        BOOL res = [cr update:[PEXDbUserProfile getURI]
                ContentValues:[self.account getDbContentValues]
                    selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBUSR_FIELD_ID]
                selectionArgs:@[[NSString stringWithFormat:@"%lld", [self.account.id longLongValue]]]];
        DDLogDebug(@"Updated account [%@] id=[%@] res=%d", self.account.display_name, accountId, res);
    }

    self.privData.accountId = self.account.id;
}

// TODO permission notifications
- (void)licenceWillBeUpdatedForUser
{
    /*
    PEXLicenceInfo * const oldInfo = [PEXLicenceManager getCurrentLicenceInternalNotSafeForUser:self.account.username];
    PEXLicenceInfo * const newInfo = self.licenceInfo;

    if (oldInfo && newInfo)
        self.licenceWasUpdated = ![oldInfo isEqual:newInfo];
        */
}

- (void)saveExpiredInfoLogsData
{
    PEXDbContentProvider * const cp = [PEXDbAppContentProvider instance];
    if (![cp delete:[PEXDbExpiredLicenceLog getURI]
          selection:nil
      selectionArgs:nil])
        DDLogVerbose(@"Problem deleting expired licence events from database");

    PEXChatAccountingManager * const manager = [[PEXChatAccountingManager alloc] init];
    [[PEXAppState instance] setChatAccountingManager:manager];

    if (!self.auxJson)
        return;

    NSDictionary * const evtLog = self.auxJson[@"evtlog"];
    if (!evtLog)
        return;

    NSDictionary * const events = evtLog[@"events"];
    if (!events || (events.count == 0))
    {
        DDLogVerbose(@"No expired licence events received from server");
        return;
    }

    NSMutableArray * const logs = [[NSMutableArray alloc] initWithCapacity:events.count];

    for (NSDictionary * const event in events)
    {
        PEXDbExpiredLicenceLog * const log = [[PEXDbExpiredLicenceLog alloc] init];
        // log.id = event[@"id"];
        log.type = event[@"type"];
        log.date = [NSDate dateWithTimeIntervalSince1970:[((NSNumber *) event[@"date"]) doubleValue] / 1000.0];

        [logs addObject:log];
    }

    [PEXLicenceManager addExpiredLicenceLogs:logs];
}

- (void)saveSupportContactToPreferences
{
    if (!self.auxJson)
        return;

    NSArray * const supportContacts = self.auxJson[@"support_contacts"];

    NSString * supportContactSip;

    if (supportContacts &&
            (supportContacts.count > 0) &&
            (supportContactSip = supportContacts[0]))
    {
        [[PEXUserAppPreferences instance] setStringPrefForKey:PEX_PREF_SUPPORT_CONTACT_SIP_KEY
                                                        value:supportContactSip];
    }
    else
    {
        // TODO clear support contact from preference?
    }
}

+ (void) processAccountServerSettings: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData {
    if (!auxJson) {
        return;
    }

    // Process testing settings.
    @try {
        DDLogVerbose(@"Going to update account settings.");

        NSDictionary * accountSettings = auxJson[@"accountSettings"];
        if (accountSettings == nil){
            DDLogVerbose(@"No account testing settings");
            return;
        }

        PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];

        // Mute push notifications until XX UTC milli timestamp setting.
        id muteUntilObj = accountSettings[@"mutePush"];
        if (muteUntilObj != nil){
            NSNumber * muteUntil = [PEXUtils getAsNumber:muteUntilObj];

            // Set to user preferences.
            [prefs setNumberPrefForKey:PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND value:muteUntil];
            DDLogVerbose(@"Mute push notification until: %@", muteUntil);
        }

        // Password reset email
        NSString * recoveryEmail = [PEXUtils getAsString:accountSettings[@"recoveryEmail"]];
        // Set to profile database, if nil, set recovery email to nil also.
        int affected = 0;
        if (privData.accountId == nil){
            DDLogError(@"Could not update recovery email setting, no account loaded");
        } else {
            PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
            PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
            [cv put:PEX_DBUSR_FIELD_RECOVERY_EMAIL string:recoveryEmail];

            affected = [cr updateEx:[PEXDbUserProfile getURI]
                      ContentValues:cv
                          selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBUSR_FIELD_ID]
                      selectionArgs:@[privData.accountId]];

        }

        // Notification if not shown already.
        if ([PEXUtils isEmpty:recoveryEmail]){
            [[PEXGNFC instance] setRecoveryMailNotificationAsync];
        }
        DDLogVerbose(@"Recovery email: %@, affected: %d", recoveryEmail, affected);


    } @catch (NSException * e) {
        DDLogError(@"Exception in processing app settings %@", e);
    }
}

+ (void) processAppServerSettings: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData {
    if (!auxJson) {
        return;
    }

    // Process testing settings.
    @try {
        DDLogVerbose(@"Going to update app settings.");

        NSDictionary * testingSettings = auxJson[@"testingSettings"];
        if (testingSettings == nil){
            DDLogVerbose(@"No app testing settings");
            return;
        }

        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
        PEXAppPreferences * appPrefs = [PEXAppPreferences instance];

        // Explicit debugging view.
        {
            NSNumber *dbgView = [PEXUtils getAsNumber:testingSettings[@"debugView"]];
            if (dbgView != nil) {
                [prefs setIntPrefForKey:PEX_PREF_DEBUG_VIEW value:[dbgView integerValue]];
                DDLogVerbose(@"App prefs: debugging view: %@", dbgView);

            } else {
                [prefs removeKey:PEX_PREF_DEBUG_VIEW];
            }
        }

        // Explicit logging level.
        {
            NSString *logLevel = [PEXUtils getAsString:testingSettings[@"logLevel"]];
            if (logLevel != nil) {
                [prefs setStringPrefForKey:PEX_PREF_LOG_LEVEL value:logLevel];
                [defaults setObject:logLevel forKey:PEX_PREF_LOG_LEVEL];

                // Apply.
                [PEXBase setLogLevelFromString:logLevel];
                DDLogVerbose(@"App prefs: log level: %@", logLevel);

            } else {
                [prefs removeKey:PEX_PREF_LOG_LEVEL];
                [defaults removeObjectForKey:PEX_PREF_LOG_LEVEL];
            }
        }

        // Synchronous logging.
        {
            NSNumber *logSync = [PEXUtils getAsNumber:testingSettings[@"logSync"]];
            if (logSync != nil) {
                [prefs setIntPrefForKey:PEX_PREF_LOG_SYNC value:[logSync integerValue]];
                [PEXBase setLogSyncFromNumber:logSync];

                DDLogVerbose(@"App prefs: Sync logging: %@", logSync);

            } else {
                [prefs removeKey:PEX_PREF_LOG_SYNC];
            }
        }

        // Google analytics force on.
        {
            NSNumber *googleAnalyticsForceOn = [PEXUtils getAsNumber:testingSettings[@"gaiForceOn"]];
            if (googleAnalyticsForceOn != nil) {
                [appPrefs setBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON value:[googleAnalyticsForceOn boolValue]];
                DDLogVerbose(@"App prefs: Google analytics force on: %@", googleAnalyticsForceOn);

            } else {
                [appPrefs removeKey:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON];
            }
        }

        // Google analytics default value.
        {
            NSNumber *googleAnalyticsDefaultOn = [PEXUtils getAsNumber:testingSettings[@"gaiDefaultOn"]];
            if (googleAnalyticsDefaultOn != nil) {
                [appPrefs setBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_DEFAULT_ON value:[googleAnalyticsDefaultOn boolValue]];
                DDLogVerbose(@"App prefs: Google analytics default on: %@", googleAnalyticsDefaultOn);

            } else {
                [appPrefs removeKey:PEX_PREF_GOOGLE_ANALYTICS_DEFAULT_ON];
            }
        }

        // Apply google analytics state change.
        [PEXReport checkGoogleAnalyticsEnabledStatus];

        [defaults synchronize];

    } @catch (NSException * e) {
        DDLogError(@"Exception in processing app settings %@", e);
    }

    // Pass control to other components that may find their settings.
    @try {
        [[PEXService instance] onSettingsUpdate:auxJson[@"testingSettings"] privData:privData];
    } @catch(NSException * e){
        DDLogError(@"Exception in processing app settings by service, %@", e);
    }
}

+ (void) processAppServerPolicy: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData {
    if (!auxJson) {
        return;
    }

    // Process testing settings.
    @try {
        NSDictionary * policySettings = auxJson[@"currentPolicy"];
        if (policySettings == nil){
            DDLogVerbose(@"No app policy settings");
            return;
        }

        DDLogVerbose(@"Going to update app policy settings.");
        [[PEXService instance].licenceManager updatePolicyFrom:policySettings];

    } @catch (NSException * e) {
        DDLogError(@"Exception in processing app policy %@", e);
    }
}

- (void) startCertGenTask {
    PEXCertGenTask * task = [[PEXCertGenTask alloc] init];
    PEXCertGenParams * param = [[PEXCertGenParams alloc] init];
    param.userName = self.credentials.username;
    param.password = self.credentials.password;
    task.params = param;
    task.privData = self.privData;

    __weak PEXLoginTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onCertGenCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:PEX_TASK_LOGIN_MAIN_CERT_GEN_TASK event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"certGenTask: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.certGenTask = task;
    self.currentTask = task;

    // Run task in async thread.
    [task startOnBackgroundThread];
}

/**
* Stores certificate information (freshness, will be published in presence text).
* Uses loaded {@link #account} attribute in {@link #saveAccount(CertGenParams)}.
*
* @param params
*/
-(void) saveCertInfo{
    if (self.privData == nil || self.privData.cert == nil || !self.privData.cert.isAllocated){
        DDLogError(@"Certificate is null, cannot set certHash.");
        return;
    }

    if (self.account.id == nil){
        DDLogError(@"Account has nil ID");
    }

    @try {
        X509 * crt = self.privData.cert.getRaw;
        self.account.cert_path = self.privData.pemCrtPath;
        self.account.cert_not_before = [PEXCryptoUtils getNotBefore:crt];
        self.account.cert_hash = [PEXMessageDigest getCertificateDigestWrap:self.privData.cert];
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

        BOOL success = [cr update:[PEXDbUserProfile getURI] ContentValues:[self.account getDbContentValues]
                        selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBUSR_FIELD_USERNAME]
                    selectionArgs:@[self.account.username]];

        if (success) {
            DDLogVerbose(@"User account updated, success=%d, user=%@, id=%lld, cert_hash=%@, notBefore=%@",
                    success, self.privData.username, [self.account.id longLongValue], self.account.cert_hash, self.account.cert_not_before
            );
        } else {
            DDLogError(@"User account updated, success=%d, user=%@, id=%lld, cert_hash=%@, notBefore=%@",
                    success, self.privData.username, [self.account.id longLongValue], self.account.cert_hash, self.account.cert_not_before
            );
        }
    } @catch (NSException * e) {
        DDLogError(@"Was not able to set certificate freshness data to profile. Exception=%@", e);
    }
}

- (void) onCertGenCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (![self onTaskFinishedCheck:ev]){
        return;
    }
    DDLogVerbose(@"CertGen completed; %@", ev);

    // Adopt initialized privData from the cert task.
    if (ev != nil && self.certGenTask.privData != nil){
        self.privData = self.certGenTask.privData;

        // Reset password retry attempt counter
        [self.privData resetInvalidPasswordEntryCounter];

        DDLogVerbose(@"Credentials reloaded, uname=%@", self.privData.username);

    } else if (ev != nil) {
        DDLogError(@"Private data from cert gen task is nil!");

        // TODO: better cancellation: new custom method, sets status, cancels waiting in perform.
        PEXLoginTaskResult * res = [[PEXLoginTaskResult alloc] initWithResultDescription:PEX_LOGIN_TASK_RESULT_SERVERSIDE_PROBLEM];
        [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:res]];
    }

    // Password is now valid, encrypted database can be opened or created.
    // Test database password is OK.
    [self tryOpenDatabase];
}

- (void) startContactlistFetchTask {
    PEXCListFetchTask * task = [[PEXCListFetchTask alloc] init];
    PEXCListFetchParams * param = [[PEXCListFetchParams alloc] init];
    param.sip = self.credentials.username;
    param.dbId = [self.account.id longLongValue];
    param.resetPresence = YES;
    param.updateClistTable = YES;
    param.cr = [PEXDbAppContentProvider instance];
    task.params = param;
    task.privData = self.privData;

    __weak PEXLoginTask * weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onClistFetchCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    ew.progressedBlock = ^(PEXTaskEvent const * const ev){
        [weakSelf progressedInternal:PEX_TASK_LOGIN_MAIN_CLIST_FETCH_TASK event:ev];
    };

    ew.cancelEndedBlock = ^(PEXTaskEvent const * const ev){
        DDLogDebug(@"clistFetch: Cancel ended block %@", ev);
    };

    [task addListener:ew];

    // Progress & task init.
    [self.progress becomeCurrentWithPendingUnitCount:1];
    [task prepareForPerform];
    [self.progress resignCurrent];

    // Set to internal state.
    self.clistFetchTask = task;
    self.currentTask = task;

    // Run task in async thread.
    DDLogVerbose(@"Starting contact list fetch task");
    [task startOnBackgroundThread];
}

- (void) onClistFetchCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (![self onTaskFinishedCheck:ev]){
        return;
    }
    DDLogVerbose(@"CListFetchTask completed; %@", ev);

    // Update privdata state to the app state.
    PEXAppState * appState = [PEXAppState instance];
    [appState setPrivData: self.privData];

    // TODO permission notifications
    /*
    if (self.licenceWasUpdated)
    {
        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                                                      value:false];
    }
    */

    [self saveSupportContactToPreferences];

    // Application settings processing.
    [PEXLoginTask processAppServerSettings:self.auxJson privData:self.privData];

    // Account settings processing.
    [PEXLoginTask processAccountServerSettings:self.auxJson privData:self.privData];

    // Policy settings.
    [PEXLoginTask processAppServerPolicy:self.auxJson privData:self.privData];

    // Password save to keychain for automatic login.
    [PEXLoginHelper storeCredentialsToKeychain:self.privData];

    // Start service.
    PEXService * svc = [PEXService instance];
    [svc updatePrivData:self.privData];
    [svc onLoginCompleted];

    // Login is finished here.
    [PEXReport logEvent:PEX_EVENT_LOGIN_TASK_FINISHED_SUCC];
    self.result.resultDescription = PEX_LOGIN_TASK_RESULT_LOGGED_IN;
    [self endedInternal: [[PEXLoginTaskEventEnd alloc] initWithResult:self.result]];
}

- (void) startedProtected
{
    [super startedProtected];
}

- (void) endedProtected
{
    [self ended:[[PEXLoginTaskEventEnd alloc] initWithResult:_result]];
}

- (void) performCancel
{
    //TODO add closing opened database
    DDLogInfo(@"performCancel!!!!");
    self.result.resultDescription = PEX_LOGIN_TASK_CANCELLED;

    [self cancelStarted:nil];
    [NSThread sleepForTimeInterval:1.0];

    [self cancelProgressed:nil];

    [NSThread sleepForTimeInterval:1.0];
    _unsuccessful = true;
    [self cancelEnded:nil];
}

- (PEXLoginTaskResult *) getResult { return self.result; }

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskEnded:(const PEXTaskEvent *const)event {

}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}

- (void) showSetNewPasswordDialogModal
{
    _passwordSet = false;
    // show the dialog
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        PEXGuiSetNewPasswordExecutor *executor = [[PEXGuiSetNewPasswordExecutor alloc]
                initWithParentController:self.controller
                                listener:self];

        [executor showGetChangePassword];
    });

    // see callBack passwordSet
    while (!_passwordSet) {
        // tweak as you will
        [NSThread sleepForTimeInterval:.05];
    }
}

- (void)passwordSet:(NSString *const)newPassword {
    //do nothing ( the method with loop will continue)
    // or do something (thi is called from other thread)

    self.nwPass = newPassword;
    _passwordSet = true;

#ifndef MOCK_LOGIN_TASK
    [self startChangePassword];
#endif
}

@end
