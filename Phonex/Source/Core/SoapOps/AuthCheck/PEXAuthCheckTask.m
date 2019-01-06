//
// Created by Dusan Klinec on 20.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAuthCheckTask.h"
#import "PEXSubTask.h"
#import "PEXSecurityCenter.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXPasswdGenerator.h"
#import "PEXPKCS12Passwd.h"
#import "PEXPEMPasswd.h"
#import "PEXSOAPManager.h"
#import "PEXTask_Protected.h"
#import "PEXTaskFinishedEvent.h"
#import "PEXSOAPTask.h"
#import "NSProgress+PEXAsyncUpdate.h"
#import "PEXUtils.h"

#define NUM_TASKS PACT_MAX
@class PEXAuthCheckTask;

@interface PEXAutchCheckTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSString * pkcsPassword;
@property(atomic) NSString * pemPassword;
@property(atomic) NSString * xmppPassword;
@property(atomic) NSString * authHash;
@property(atomic) NSError * lastError;
@property(atomic) hr_authCheckV3Response * authResponse;
@end

@implementation PEXAutchCheckTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.pkcsPassword = nil;
        self.pemPassword = nil;
        self.xmppPassword = nil;
        self.authHash = nil;
        self.lastError = nil;
        self.authResponse = nil;
    }

    return self;
}

@end

// Private part of the PEXAuthCheckTask
@interface PEXAuthCheckTask ()  { }
@property(atomic) PEXAutchCheckTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXAuthCheckSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXAutchCheckTaskState * state;
@property (nonatomic, weak) PEXCertGenParams * params;
@property (nonatomic, weak) PEXAuthCheckTask * ownDelegate;
@property (nonatomic, weak) PEXUserPrivate * privData;
- (id) initWithDel:(PEXAuthCheckTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXAuthCheckSubtask {}
- (id) initWithDel:(PEXAuthCheckTask *)delegate andName: (NSString *) taskName {
    self = [super initWith:delegate andName:taskName];
    self.delegate = delegate;
    self.ownDelegate = delegate;
    self.state = [delegate state];
    self.params = [delegate params];
    self.privData = [delegate privData];
    return self;
}

-(void) subCancel {
    [super subCancel];
    self.state.cancelDetected=YES;
}

- (void)subError:(NSError *)error {
    [super subError:error];
    self.state.errorOccurred = YES;
    self.state.lastError = error;
}

- (BOOL)shouldCancel {
    BOOL shouldCancel = [super shouldCancel];
    if (shouldCancel) return YES;

    return  self.state.errorOccurred || self.state.cancelDetected;
}

@end

//
// Subtasks
//
@interface PEXAuthCheckKeyGenTask : PEXAuthCheckSubtask { }
@end

@interface PEXAuthCheckSOAPTask : PEXAuthCheckSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXAuthCheckFinishTask : PEXAuthCheckSubtask { }
@end

//
// Implementation part
//
@implementation PEXAuthCheckKeyGenTask { }
- (void)subMain {
    // Derive encryption keys and load stored identity, if any.
    NSString * username = self.params.userName;
    int storedCredsCheck = [PEXSecurityCenter checkStoredUserLoginData:username];

        // Progress set - do not use default setting with 1 total unit count.
    if (storedCredsCheck == kLOGIN_DATA_OK) {
        [self setProgressOnMain:36 completedCount:0 async:NO];
        DDLogVerbose(@"Stored credentials found on the device");
    } else {
        [self setProgressOnMain:3 completedCount:0 async:NO];
    }

    // Generate creds & load identity.
    if (storedCredsCheck == kLOGIN_DATA_OK){
        // Generate PKCS password part.
        // 1.1. Generate new storage password, using salt.
        [self.progress becomeCurrentWithPendingUnitCountOnMain:30 async:NO];
        self.state.pkcsPassword = [PEXPKCS12Passwd getStoragePass:self.params.userName key:self.params.password progress:self.progress];
        self.privData.pkcsPass = self.state.pkcsPassword;
        [self.progress resignCurrentOnMainAsync: NO];

        // Cancel test.
        if ([self shouldCancel]){
            [self subCancel];
            return;
        }

        // Generate PEM password part.
        // 2.1. Generate new storage password, using salt.
        self.state.pemPassword = [PEXPEMPasswd getStoragePass:self.params.userName key:self.params.password];
        self.privData.pemPass = self.state.pemPassword;
        [self incProgressOnMain:1 async:NO];

        // Cancel test.
        if ([self shouldCancel]){
            [self subCancel];
            return;
        }

        // Load identity file, init privData.
        int identityLoadRes = [PEXSecurityCenter loadIdentity:self.privData];
        [self incProgressOnMain:1 async:NO];

        if (identityLoadRes!=kIDENTITY_EXISTS){
            DDLogVerbose(@"Identity load was not successful");
        }
    }

    // Cancel test.
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Generate XMPP password part.
    self.state.xmppPassword = [PEXPasswdGenerator generateXMPPPassword:self.params.userName passwd:self.params.password];
    self.privData.xmppPass = self.state.xmppPassword;
    [self incProgressOnMain:1 async:NO];

    // SIP password.
    // In current version it is login password.
    self.privData.sipPass = self.params.password;

    // Database password.
    // TODO: gen.

    // Generate auth hash - invariant on stored credentials.
    // Do as a last thing since auth token is time dependent.
    NSString * ha1 = [PEXPasswdGenerator getHA1:self.params.userName password:self.params.password];
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Generate auth token.
    self.state.authHash = [PEXPasswdGenerator generateUserAuthToken:self.params.userName
                            ha1:ha1 usrToken:@"" serverToken:@"" milliWindow:1000ll * 60ll * 10ll offset:0];
    [self incProgressOnMain:1 async:NO];
}
@end

@implementation PEXAuthCheckSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.authcheck.soap"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    // TODO: if previous login failed, try logging without this identity - may be invalid/not recognized.
    [self.soapTask prepareSOAP:self.privData];

    // Cookies for SOAP call has to be cleared here, user may have generated a new certificate.
    [PEXSOAPManager clearPhonexCookies];
    [PEXSOAPManager eraseCredentials];

    // Construct request.
    hr_authCheckV3Request *request = [[hr_authCheckV3Request alloc] init];
    request.targetUser = self.params.userName;
    request.authHash = self.state.authHash;
    request.appVersion = [PEXUtils getUniversalApplicationCode];
    request.unregisterIfOK = hr_trueFalse_true;
    DDLogVerbose(@"Request connstructed %@", request);

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.soapTask.desiredBody = [hr_authCheckV3Response class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) { return [weakSelf shouldCancel]; };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_authCheckV3 alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask authCheckV3Request:request];

    // Start task, sync blocking here, on purpose.
    [self.soapTask start];

    // Cancelled check block.
    if ([self.soapTask cancelDetected] || [self shouldCancel]){
        [self subCancel];
        return;
    }

    // Error check block.
    if ([self.soapTask finishedWithError]){
        [self subError: self.soapTask.error];
        return;
    }

    // Extract answer
    hr_authCheckV3Response * body = (hr_authCheckV3Response *) self.soapTask.responseBody;
    self.state.authResponse = body;
}

@end

@implementation PEXAuthCheckFinishTask { }
- (void)subMain {
    self.ownDelegate.response = self.state.authResponse;
}
@end


@implementation PEXAuthCheckTask {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"AuthCheck";

        // Initialize empty state
        [self setState: [[PEXAutchCheckTaskState alloc] init]];
    }

    return self;
}

- (int)getNumSubTasks {
    return NUM_TASKS;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXAuthCheckKeyGenTask         alloc] initWithDel:self andName:@"KeyGen"]   id:PACT_KEYGEN];
    [self setSubTask:[[PEXAuthCheckSOAPTask           alloc] initWithDel:self andName:@"SOAP"]     id:PACT_SOAP];
    [self setSubTask:[[PEXAuthCheckFinishTask         alloc] initWithDel:self andName:@"Finish"]   id:PACT_FINISH];

    // Add dependencies to the tasks.
    [self.tasks[PACT_SOAP]     addDependency:self.tasks[PACT_KEYGEN]];
    [self.tasks[PACT_FINISH]   addDependency:self.tasks[PACT_SOAP]];

    // Mark last task so we know what to wait for.
    [self.tasks[PACT_FINISH] setIsLast:YES];
}

- (void)subTasksFinished:(int)waitResult {
    [super subTasksFinished:waitResult];

    PEXTaskFinishedEvent * finResult;
    // If was cancelled - signalize cancel ended.
    if (waitResult==kWAIT_RESULT_CANCELLED){
        [self cancelEnded:NULL];
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_CANCELLED];
    } else if (self.state.errorOccurred || waitResult==kWAIT_RESULT_TIMEOUTED) {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_ERROR];
        finResult.finishError = self.state.lastError;
    } else {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_OK];
    }

    self.finishedEvent = finResult;
    DDLogVerbose(@"End of waiting loop, onAuthCheckCompleted.");
}

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");
}


@end