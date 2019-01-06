//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXChangePasswordTask.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXTask_Protected.h"
#import "PEXPasswdGenerator.h"
#import "PEXPEMPasswd.h"
#import "PEXPKCS12Passwd.h"
#import "PEXUserPrivate.h"
#import "PEXMessageDigest.h"
#import "PEXTaskFinishedEvent.h"
#import "PEXSipUri.h"
#import "PEXAESCipher.h"
#import "PEXCryptoUtils.h"
#import "PEXDatabase.h"
#import "PEXUtils.h"
#import "PEXStringUtils.h"
#import "PEXLoginHelper.h"
#import "PEXReport.h"
#import "PEXService.h"

#define NUM_TASKS PEX_CHANGEPASS_MAX
@class PEXChangePasswordTask;

NSString * const PEXPassChangeErrorDomain = @"net.phonex.changepass";
NSInteger const PEXPassChangeErrorNotAuthorized = -1;
NSInteger const PEXPassChangeErrorServerCall = -2;

// State.
@interface PEXChangePasswordTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSString * userToken;
@property(atomic) NSString * serverToken;
@property(atomic) NSString * authHash;
@property(atomic) NSData * xnewHA1;
@property(atomic) NSData * xnewHA1B;
@property(nonatomic) PEXUserPrivate * nwPrivData;
@property(atomic) NSError * lastError;
@end

// State implementation.
@implementation PEXChangePasswordTaskState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
        self.authHash = nil;
        self.lastError = nil;
        self.nwPrivData = nil;
    }

    return self;
}

@end

// Private part of the PEXChangePasswordTask
@interface PEXChangePasswordTask ()  { }
@property(atomic) PEXChangePasswordTaskState * state;
@end

// Subtask parent - has internal state.
@interface PEXChangePasswordSubTask : PEXSubTask { }
@property (nonatomic, weak) PEXChangePasswordTaskState * state;
@property (nonatomic, weak) PEXChangePasswordParams * params;
@property (nonatomic, weak) PEXUserPrivate * privData;
@property (nonatomic, weak) PEXChangePasswordTask * ownDelegate;
- (id) initWithDel:(PEXChangePasswordTask *) delegate andName: (NSString *) taskName;
@end

// Subtask base
@implementation PEXChangePasswordSubTask {}
- (id) initWithDel:(PEXChangePasswordTask *)delegate andName: (NSString *) taskName {
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
@interface PEXChangePasswordOTTTask : PEXChangePasswordSubTask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXChangePasswordGenSOAPTask : PEXChangePasswordSubTask { }
@end

@interface PEXChangePasswordSOAPTask : PEXChangePasswordSubTask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

@interface PEXChangePasswordKeyGenTask : PEXChangePasswordSubTask { }
@end

@interface PEXChangePasswordRekeyTask : PEXChangePasswordSubTask { }
@end

//
// Implementation part
//
@implementation PEXChangePasswordOTTTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.changepass.ott"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Generate user token at random.
    NSString * utokenBase = [NSString stringWithFormat:@"changepass_[%lld][%@]",
                                                       [@([[NSDate date] timeIntervalSince1970] * 1000ll) longLongValue], self.params.userSIP];

    NSString * utoken = [PEXMessageDigest bytes2base64: [PEXMessageDigest md5Message:utokenBase]];
    self.state.userToken = utoken;

    // Construct service binding.
    __weak id weakSelf = self;
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:nil];

    // Construct request.
    hr_getOneTimeTokenRequest *request = [hr_getOneTimeTokenRequest new];
    request.type = @1;
    request.user = self.params.userSIP;
    request.userToken = self.state.userToken;
    DDLogVerbose(@"Request connstructed %@", request);

    // Prepare SOAP operation.
    self.soapTask.desiredBody = [hr_getOneTimeTokenResponse class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) { return [weakSelf shouldCancel]; };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_getOneTimeToken alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask getOneTimeTokenRequest:request];

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

    hr_getOneTimeTokenResponse * body = (hr_getOneTimeTokenResponse *) self.soapTask.responseBody;

    // Some basic check on data correctness.
    if (![self.state.userToken isEqualToString:body.userToken] || ![self.params.userSIP isEqualToString:body.user]) {
        DDLogError(@"OTT Body is invalid");
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }

    self.state.serverToken = body.serverToken;
    DDLogVerbose(@"OTT finished. ServerToken=%@", self.state.serverToken);
}
@end

@implementation PEXChangePasswordGenSOAPTask { }
- (void)subMain {
    @try {
        // Request signing of certificate.
        NSString *domain = nil;
        @try {
            PEXSIPURIParsedSipContact *in = [PEXSipUri parseSipContact:self.params.userSIP];
            domain = in.domain;
        } @catch (NSException *e) {
            DDLogError(@"Exception: cannot parse domain from SIP name, exception=%@", e);
            [self subError:[NSError errorWithDomain:PEXInputUserDomain code:PEXInputInvalidUSername userInfo:nil]];
            return;
        }

        [self setProgressOnMain:3 completedCount:0 async:NO];

        // Generate HA1 password.
        NSString *ha1 = [PEXPasswdGenerator getHA1:self.params.userSIP password:self.params.userOldPass];
        [self checkCancelDoItAndThrow];
        [self incProgressOnMain:1 async:NO];

        // Generate auth token.
        self.state.authHash =
                [PEXPasswdGenerator generateUserAuthToken:self.params.userSIP ha1:ha1
                                                 usrToken:self.state.userToken
                                              serverToken:self.state.serverToken
                                              milliWindow:1000ll * 60ll * 10ll offset:0];
        [self checkCancelDoItAndThrow];

        // Generate encryption token.
        NSString *encToken =
                [PEXPasswdGenerator generateUserEncToken:self.params.userSIP ha1:ha1
                                                usrToken:self.state.userToken
                                             serverToken:self.state.serverToken
                                             milliWindow:1000ll * 60ll * 10ll offset:0];
        [self checkCancelDoItAndThrow];

        [self incProgressOnMain:1 async:NO];

        // New password.
        DDLogDebug(@"Generating new password for domain: [%@] for user: [%@] ", domain, self.params.userSIP);
        NSString *newHA1String = [PEXPasswdGenerator getHA1:self.params.userSIP password:self.params.userNewPass];
        NSString *newHA1BString = [PEXPasswdGenerator getHA1:self.params.userSIP domain:domain password:self.params.userNewPass];

        // Encrypt new ha1 and ha1b.
        self.state.xnewHA1 = [PEXAESCipher encrypt:[newHA1String dataUsingEncoding:NSUTF8StringEncoding]
                                          password:[encToken dataUsingEncoding:NSUTF8StringEncoding]];
        self.state.xnewHA1B = [PEXAESCipher encrypt:[newHA1BString dataUsingEncoding:NSUTF8StringEncoding]
                                           password:[encToken dataUsingEncoding:NSUTF8StringEncoding]];
        [self incProgressOnMain:1 async:NO];
    } @catch(PEXOperationCancelledException * cex){
        // Cancelled.
    }
}
@end

@implementation PEXChangePasswordSOAPTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.changepass.soap"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:self.privData];

    // Construct request.
    hr_passwordChangeV2Request *request = [[hr_passwordChangeV2Request alloc] init];
    request.targetUser = self.params.targetUserSIP;
    request.user = self.params.userSIP;
    request.serverToken = self.state.serverToken;
    request.usrToken = self.state.userToken;
    request.authHash = self.state.authHash;
    request.xnewHA1 = self.state.xnewHA1;
    request.xnewHA1B = self.state.xnewHA1B;
    DDLogVerbose(@"Request connstructed %@", request);

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.soapTask.desiredBody = [hr_passwordChangeV2Response class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) { return [weakSelf shouldCancel]; };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_passwordChangeV2 alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask passwordChangeV2Request:request];

    // Start task, sync blocking here, on purpose.
    [self.soapTask start];

    // Cancelled check block.
    if ([self.soapTask cancelDetected] || [self shouldCancel]){
        [self subCancel];
        return;
    }

    // Error check block.
    if ([self.soapTask finishedWithError]){
        // Check if it is not authorized / SOAPfault.
        NSError * errorToReturn = self.soapTask.error;
        if (self.soapTask.soapFault != nil){
            if ([PEXStringUtils containsIc:self.soapTask.soapFault.faultstring needle:@"not authorized"]){
                errorToReturn = [NSError errorWithDomain:PEXPassChangeErrorDomain code:PEXPassChangeErrorNotAuthorized
                                                userInfo:@{PEX_EXTRA_SOAP_FAULT : self.soapTask.soapFault}];
            } else {
                errorToReturn = [NSError errorWithDomain:PEXPassChangeErrorDomain code:PEXPassChangeErrorServerCall
                                                userInfo:@{PEX_EXTRA_SOAP_FAULT : self.soapTask.soapFault}];
            }
        }

        [self subError: errorToReturn];
        return;
    }

    // Extract answer
    hr_passwordChangeV2Response * body = (hr_passwordChangeV2Response *) self.soapTask.responseBody;
    if (body.result==nil || ![body.result isEqualToNumber:@(1)]){
        DDLogError(@"Change password request failed.");
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }
}
@end

@implementation PEXChangePasswordKeyGenTask { }
- (void)subMain {
    // Copy current private data to the new one.
    self.state.nwPrivData = [self.privData initCopy];
    self.state.nwPrivData.pass = self.params.userNewPass;

    // Generate passwords if desired.
    if (self.params.derivePasswords){
        [self setProgressOnMain:3 completedCount:0 async:NO];
        @try {
            // Generate PKCS password part.
            // 1.1. Generate new storage password, using salt.
            // If there is no salt, it needs to be generated.
            if (![PEXPKCS12Passwd saltExists:self.params.userSIP]){
                DDLogVerbose(@"Has to generate new PKCS12 salt.");
                [PEXPKCS12Passwd generateNewSalt:self.params.userSIP];
            }

            self.state.nwPrivData.pkcsPass = [PEXPKCS12Passwd getStoragePass:self.params.userSIP key:self.params.userNewPass];
            [self incProgressOnMain:1 async:NO];
            [self checkCancelDoItAndThrow];

            // Generate PEM password part.
            // 2.1. Generate new storage password, using salt.
            // If there is no salt, it needs to be generated.
            if (![PEXPEMPasswd saltExists:self.params.userSIP]){
                DDLogVerbose(@"Has to generate new PEM salt.");
                [PEXPEMPasswd generateNewSalt:self.params.userSIP];
            }

            self.state.nwPrivData.pemPass = [PEXPEMPasswd getStoragePass:self.params.userSIP key:self.params.userNewPass];
            [self incProgressOnMain:1 async:NO];
            [self checkCancelDoItAndThrow];

            // Generate XMPP password part.
            self.state.nwPrivData.xmppPass = [PEXPasswdGenerator generateXMPPPassword:self.params.userSIP passwd:self.params.userNewPass];
        } @catch(PEXOperationCancelledException * cex){
        } @catch(NSException * e){
            DDLogError(@"Cannot generate strong encryption keys. exception=%@", e);
            [self subError: [NSError errorWithDomain:PEXRuntimeDomain code:PEXRuntimeCryptoException userInfo:@{PEXExtraException : e}]];
            return;
        }
    }
}
@end

@implementation PEXChangePasswordRekeyTask { }
- (void)subMain {
    [self setProgressOnMain:3 completedCount:0 async:NO];

    // KeyStore re-keying.
    if (self.params.rekeyKeyStore)
    {
        // Open with old data/passwords.
        PEXUserPrivate * newIdentity = [self.privData initCopy];

        //PEXUserPrivate * newIdentity = self.state.nwPrivData;
        int identityLoadRes = [PEXSecurityCenter loadIdentity:newIdentity];
        if (identityLoadRes == kIDENTITY_EXISTS){

            // Copy new passwords to the newIdentity so files are exported with new passwords.
            [self.state.nwPrivData copyPasswordsTo:newIdentity];

            // Export loaded identity to a new PKCS.
            [PEXSecurityCenter exportKeyStore:newIdentity];

            // Export loaded identity to new PEM files.
            [PEXSecurityCenter exportPEMFiles:newIdentity];

            [newIdentity copyIdentityTo:self.state.nwPrivData];

        }
    }
    [self incProgressOnMain:1 async:NO];

    // Database re-keying.
    if (self.params.rekeyDB){

        NSString * const oldPass = self.privData.pkcsPass;
        NSString * const newPass = self.state.nwPrivData.pkcsPass;

        // the operation should not fail
        if (![PEXDatabase rekeyDatabase:oldPass withKey:newPass])
        {
            DDLogError(@"Database rekeying failed during password change");
        }
    }
    [self incProgressOnMain:1 async:NO];
}
@end

// Main executor task.
@implementation PEXChangePasswordTask {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"PassChange";

        // Initialize empty state
        [self setState: [[PEXChangePasswordTaskState alloc] init]];
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
    [self setSubTask:[[PEXChangePasswordOTTTask         alloc] initWithDel:self andName:@"KeyGen"]   id:PEX_CHANGEPASS_OTT];
    [self setSubTask:[[PEXChangePasswordGenSOAPTask     alloc] initWithDel:self andName:@"SOAPGen"]  id:PEX_CHANGEPASS_GENSOAP];
    [self setSubTask:[[PEXChangePasswordSOAPTask        alloc] initWithDel:self andName:@"SOAP"]     id:PEX_CHANGEPASS_SOAP];
    [self setSubTask:[[PEXChangePasswordKeyGenTask      alloc] initWithDel:self andName:@"Keygen"]   id:PEX_CHANGEPASS_KEYGEN];
    [self setSubTask:[[PEXChangePasswordRekeyTask       alloc] initWithDel:self andName:@"Rekey"]    id:PEX_CHANGEPASS_REKEY];

    // Add dependencies to the tasks.
    [self.tasks[PEX_CHANGEPASS_GENSOAP] addDependency:self.tasks[PEX_CHANGEPASS_OTT]];
    [self.tasks[PEX_CHANGEPASS_SOAP]    addDependency:self.tasks[PEX_CHANGEPASS_GENSOAP]];
    [self.tasks[PEX_CHANGEPASS_KEYGEN]  addDependency:self.tasks[PEX_CHANGEPASS_SOAP]];
    [self.tasks[PEX_CHANGEPASS_REKEY]   addDependency:self.tasks[PEX_CHANGEPASS_KEYGEN]];

    // Mark last task so we know what to wait for.
    [self.tasks[PEX_CHANGEPASS_REKEY] setIsLast:YES];
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

        self.nwPrivData = self.state.nwPrivData;
        [[PEXAppState instance] setPrivData:self.state.nwPrivData];
        [PEXReport logUsrEvent:PEX_EVENT_PASS_CHANGED];
        [[PEXService instance] updatePrivData:self.state.nwPrivData];

        // DEPRECATED See IPH-294
        // if ([[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY
        //                                            defaultValue:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT])
        [PEXLoginHelper storeCredentialsToKeychain:self.state.nwPrivData];
    }

    self.finishedEvent = finResult;
    DDLogVerbose(@"End of waiting loop, onPasswordChanged.");
}

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");
}

@end