//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertGenTask.h"
#import "PEXTask_Protected.h"
#import "PEXCryptoUtils.h"
#import "PEXGenerator.h"
#import "PEXPasswdGenerator.h"
#import "PEXAESCipher.h"
#import "PhoenixPortServiceSvc.h"
#import "PEXMessageDigest.h"
#import "PEXCertGenTaskEvent.h"
#import "PEXSecurityCenter.h"
#import "PEXPKCS12Passwd.h"
#import "PEXPEMPasswd.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXSOAPTask.h"
#import "PEXSOAPManager.h"
#import "PEXCertGenKeyGenTaskThread.h"
#import "PEXCertKeyGeneratorManager.h"

#define NUM_TASKS PCGT_MAX

@class PEXCertGenSubtask;

// Private part of the PEXCertGenTask
@interface PEXCertGenTask ()  { }
@end

// Subtask parent - has internal state.
@interface PEXCertGenSubtask : PEXSubTask { }
@property (nonatomic, weak) PEXCertGenTaskState * state;
@property (nonatomic, weak) PEXCertGenParams * params;
@property (nonatomic, weak) PEXCertGenTask * ownDelegate;
- (id) initWithDel:(PEXCertGenTask *) delegate andName: (NSString *) taskName;
@end

@implementation PEXCertGenSubtask {}
- (id) initWithDel:(PEXCertGenTask *)delegate andName: (NSString *) taskName {
    self = [super initWith:delegate andName:taskName];
    self.delegate = delegate;
    self.ownDelegate = delegate;
    self.state = [delegate state];
    self.params = [delegate params];
    return self;
}

-(void) subCancel {
    [super subCancel];
    self.state.cancelDetected=YES;
}

- (void)subError:(NSError *)error {
    [super subError:error];
    self.state.errorOccurred=YES;
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
@interface PEXCertGenKeyGenTask : PEXCertGenSubtask { }
@end

// Generate CSR from request.
@interface PEXCertGenCSRGenTask : PEXCertGenSubtask { }
@end

// One time token.
@interface PEXCertGenOTTTask : PEXCertGenSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Generate auth hash.
@interface PEXCertGenAuthHashTask : PEXCertGenSubtask { }
@end

// Encrypt CSR.
@interface PEXCertGenEncCSRTask : PEXCertGenSubtask { }
@end

// SOAP request, sending CSR for signing.
@interface PEXCertGenSoapSignTask : PEXCertGenSubtask { }
@property (nonatomic) PEXSOAPTask * soapTask;
@end

// Derive encryption passwords.
@interface PEXCertGenStoragePasswordsTask : PEXCertGenSubtask { }
@end

// Verify returned certificate.
@interface PEXCertGenVerifyTask : PEXCertGenSubtask { }
@end

// Store certificate, private credentials.
@interface PEXCertGenStoreTask : PEXCertGenSubtask { }
@end

//
// Implementation part
//
@implementation PEXCertGenKeyGenTask { }
- (void)subMain {
    self.state.keyPair = nil;

    // Generate RSA key-pair with 2048 bit size, store it to the state.
    // Find a way for cancelling this long running task.
    //  a) change source code for OpenSSL RSA key gen, add cancellation check.
    //  b) SELECTED. Run it in another thread, let it finish in background, abandon it.
    //     Make this code more async with spawning thread manually with NSThread
    //     and waiting for completion here. If cancel is received, abandon running thread.
    __weak __typeof(self) weakSelf = self;
    DDLogVerbose(@"Going to obtain RSA keygen thread from pool.");
    PEXCertKeyGeneratorManager * keyGenManager = [PEXCertKeyGeneratorManager instance];

    // Obtain generator thread from pool.
    // Old generators might be created from past invocations so wait until there
    // is some an available in pool.
    PEXCertGenKeyGenTaskThread * thread = nil;
    dispatch_time_t poolWaitTime = dispatch_time(DISPATCH_TIME_NOW, 25ull * 1000000ull);
    int waitRes = [keyGenManager getNewGeneratorWithWait:poolWaitTime
                                                 timeout:120.0
                                               doRunLoop:YES
                                                  result:&thread
                                             cancelBlock: ^BOOL() { return [weakSelf shouldCancel]; }];

    // Wait finished, check the result.
    if (waitRes != kWAIT_RESULT_FINISHED) {
        // Timeout or cancel, anyway, error.
        DDLogWarn(@"RSA keygen waiting thread exit with fail [%d]", waitRes);
        self.state.keyPair=NULL;
        self.state.errorOccurred=YES;
        return;
    }

    DDLogVerbose(@"RSA keygen thread obtained from pool. Starting keygen.");
    // Start generation in the background thread, in order to enable cancellation.
    [thread start];
    // Wait for thread to get started.
    [NSThread sleepForTimeInterval:0.25];

    // Construct service binding.
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 25ull * 1000000ull);
    waitRes = [PEXSOAPManager waitThreadWithCancellation:thread doneSemaphore:thread.doneSemaphore
                                             semWaitTime:tdeadline timeout:90.0 doRunLoop:YES
                                             cancelBlock:^BOOL() { return [weakSelf shouldCancel]; }];
    // Wait finished, check the result.
    if (waitRes == kWAIT_RESULT_FINISHED) {
        if (!thread.result){
            DDLogError(@"RSA generation failed. code=%d", thread.result);
            self.state.keyPair=NULL;
            self.state.errorOccurred=YES;
            return;
        }

        self.state.keyPair = thread.keyPair;
        DDLogVerbose(@"Key generated. p=%p", self.state.keyPair);
    } else {
        // Timeout or cancel, anyway, error.
        DDLogWarn(@"RSA keygen thread exit with fail [%d]", waitRes);
        self.state.keyPair=NULL;
        self.state.errorOccurred=YES;
        return;
    }
}
@end

@implementation PEXCertGenCSRGenTask { }
- (void)subMain {
    // Generate a new wrapper.
    self.state.csr = [[PEXX509Req alloc] init];
    RSA * rsa = self.state.keyPair.getRaw;

    X509_REQ * csrReq = [PEXGenerator generateCSRWith:self.params.userName andPubKey:rsa];
    if (csrReq==NULL){
        DDLogError(@"CSR generation failed");
        self.state.errorOccurred=YES;
        return;
    }
    [self.state.csr setRaw:csrReq];

    // Convert it to PEM.
    self.state.csrPem = [PEXCryptoUtils exportCSRToPEM:csrReq];
    if (self.state.csrPem==nil){
        DDLogError(@"CSR PEM generation failed");
        self.state.errorOccurred=YES;
        return;
    }

    DDLogVerbose(@"CSR pem generated. p=%@", self.state.csrPem);
}
@end

@implementation PEXCertGenOTTTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.crtgen.ott"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Generate user token at random.
    NSString * utokenBase = [NSString stringWithFormat:@"certgen_[%lld][%@]",
                    [@([[NSDate date] timeIntervalSince1970] * 1000ll) longLongValue], self.params.userName];

    NSString * utoken = [PEXMessageDigest bytes2base64: [PEXMessageDigest md5Message:utokenBase]];
    self.state.userToken = utoken;

    // Construct service binding.
    __weak id weakSelf = self;
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:nil];

    // Construct request.
    hr_getOneTimeTokenRequest *request = [hr_getOneTimeTokenRequest new];
    request.type = @1;
    request.user = self.params.userName;
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
    if (![self.state.userToken isEqualToString:body.userToken] || ![self.params.userName isEqualToString:body.user]) {
        DDLogError(@"OTT Body is invalid");
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }

    self.state.serverToken = body.serverToken;
    DDLogVerbose(@"OTT finished. ServerToken=%@", self.state.serverToken);
}
@end

@implementation PEXCertGenAuthHashTask { }
- (void)subMain {
    // Generate HA1b password.
    self.state.ha1 = [PEXPasswdGenerator getHA1:self.params.userName password:self.params.password];
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Generate auth token.
    self.state.authToken =
            [PEXPasswdGenerator generateUserAuthToken:self.params.userName
                                                  ha1:self.state.ha1
                                             usrToken:self.state.userToken
                                          serverToken:self.state.serverToken
                                          milliWindow:1000ll * 60ll * 10ll
                                               offset:0];
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Generate encryption token.
    self.state.encToken =
            [PEXPasswdGenerator generateUserEncToken:self.params.userName
                                                 ha1:self.state.ha1
                                            usrToken:self.state.userToken
                                         serverToken:self.state.serverToken
                                         milliWindow:1000ll * 60ll * 10ll
                                              offset:0];

    DDLogVerbose(@"Auth tokens generated");
}
@end

@implementation PEXCertGenEncCSRTask { }
- (void)subMain {
    // Convert PEM csr to NSData.
    NSString * csr = self.state.csrPem;
    NSData * csrCiph = [PEXAESCipher encrypt:[csr dataUsingEncoding:NSUTF8StringEncoding]
                                    password:[self.state.encToken dataUsingEncoding:NSUTF8StringEncoding]];

    if (csrCiph==nil){
        DDLogError(@"CSR encryption failed");
        self.state.errorOccurred=YES;
        return;
    }

    self.state.csrEncrypted = csrCiph;
}
@end

@implementation PEXCertGenSoapSignTask { }
- (void)prepareProgress {
    [super prepareProgress];
    [self.progress becomeCurrentWithPendingUnitCount:1];

    self.soapTask = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.crtgen.sign"];
    [self.soapTask prepareProgress];

    [self.progress resignCurrent];
}

- (void)subMain {
    // Construct service binding.
    self.soapTask.logXML = YES;
    [self.soapTask prepareSOAP:nil];

    // Construct request.
    hr_signCertificateV2Request *request = [hr_signCertificateV2Request new];
    request.user = self.params.userName;
    request.authHash = self.state.authToken;
    request.CSR = self.state.csrEncrypted;
    request.serverToken = self.state.serverToken;
    request.usrToken = self.state.userToken;
    DDLogVerbose(@"Request connstructed %@", request);

    // Cancel test.
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Prepare SOAP operation.
    __weak id weakSelf = self;
    self.soapTask.desiredBody = [hr_signCertificateV2Response class];
    self.soapTask.shouldCancelBlock = ^BOOL(PEXSubTask const *const task) { return [weakSelf shouldCancel]; };
    self.soapTask.srcOperation = [[PhoenixPortSoap11Binding_signCertificateV2 alloc]
            initWithBinding:self.soapTask.getBinding delegate:self.soapTask signCertificateV2Request:request];

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

    // Some basic check on data correctness.
    hr_signCertificateV2Response * body = (hr_signCertificateV2Response *) self.soapTask.responseBody;
    if (body.certificate==nil
            || body.certificate.certificate==nil
            || body.certificate.status != hr_certificateStatus_ok
            || ![self.params.userName isEqualToString:body.certificate.user])
    {
        DDLogError(@"Certificate invalid");
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }

    // Try to decode certificate, it is in DER form.
    PEXX509 * pcert = [[PEXX509 alloc] initWith:[PEXCryptoUtils importCertificateFromDER:body.certificate.certificate]];
    if (pcert==nil || pcert.getRaw == nil){
        DDLogError(@"Certificate cannot be decoded.");
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }

    self.state.certificate = pcert;
    DDLogVerbose(@"Sign finished. Certificate=%@", self.state.certificate);
}
@end

@implementation PEXCertGenVerifyTask { }
- (void)subMain {
    // Verify certificate vs. CSR.
    DDLogVerbose(@"Verify certificate");

    // Get pointers for better access.
    X509 * cert = self.state.certificate.getRaw;
    X509_REQ * req = self.state.csr.getRaw;

    // Check if public key matches.
    if (![PEXCryptoUtils isPubKeyEqual:cert csr:req]){
        DDLogError(@"Public key differs between Cert & CSR");
        self.state.errorOccurred=YES;
        return;
    }

    // Check if CNAME matches
    if (![PEXCryptoUtils isCNameEqual:cert csr:req]){
        DDLogError(@"CNAME differs between Cert & CSR");
        self.state.errorOccurred=YES;
        return;
    }

    DDLogVerbose(@"Certificate verification successful");
}
@end

@implementation PEXCertGenStoragePasswordsTask
- (void)subMain {
    // Generate PKCS password part.
    // 1.1. Generate new storage salt for the password generator.
    [PEXPKCS12Passwd generateNewSalt:self.params.userName];
    // 1.2. Generate new storage password, usign salt.
    self.state.pkcsPassword = [PEXPKCS12Passwd getStoragePass:self.params.userName key:self.params.password];

    // Cancel test.
    if ([self shouldCancel]){
        [self subCancel];
        return;
    }

    // Generate PEM password part.
    // 2.1. Generate new storage salt for the password generator.
    [PEXPEMPasswd generateNewSalt:self.params.userName];
    // 2.2. Generate new storage password, usign salt.
    self.state.pemPassword = [PEXPEMPasswd getStoragePass:self.params.userName key:self.params.password];
}
@end

@implementation PEXCertGenStoreTask { }
- (void)subMain {
    // Store state.
    DDLogVerbose(@"StoreState");

    // Obtain file manager instance for file manipulation.
    NSFileManager * fmgr = [NSFileManager defaultManager];

    // Create a private directory if it does not exist.
    [PEXSecurityCenter getDefaultPrivateDirectory:YES];

    // Obtain paths for certificate and private key.
    NSString * certPath = [PEXSecurityCenter getCertificateFile:self.params.userName];
    NSString * privKeyPath = [PEXSecurityCenter getPrivkeyFile:self.params.userName];
    NSString * pkcs12Path = [PEXSecurityCenter getPKCS12File:self.params.userName];
    const BOOL identityBackupFlag = [[PEXUserAppPreferences instance] getDefaultBackupFlagForIdentity];

    // Export received certificate to PEM and write it to a file.
    // Default encryption mode - until first auth.
    NSString * certPem = [PEXCryptoUtils exportCertificateToPEM: self.state.certificate.getRaw];
    [fmgr removeItemAtPath:certPath error:nil];
    [fmgr createFileAtPath:certPath contents:[certPem dataUsingEncoding:NSUTF8StringEncoding]
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    [PEXSecurityCenter trySetBackupFlagFile:certPem backupFlag:identityBackupFlag];
    DDLogVerbose(@"CertificateFile: %@", certPath);

    // Export private key to a file, ahs to generate encryption password at first.
    NSString * privPem = [PEXCryptoUtils exportPrivKeyToPEM:self.state.keyPair.getRaw password:self.state.pemPassword];
    [fmgr removeItemAtPath:privKeyPath error:nil];
    [fmgr createFileAtPath:privKeyPath contents:[privPem dataUsingEncoding:NSUTF8StringEncoding]
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    [PEXSecurityCenter trySetBackupFlagFile:certPem backupFlag:identityBackupFlag];
    DDLogVerbose(@"PrivkeyFile: %@", certPem);

    // Export PKCS12 file - main identity file for SOAP & XMPP calls.
    PKCS12 * p12 = [PEXCryptoUtils createDefaultKeystore:self.params.userName pkcsPasswd:self.state.pkcsPassword
                                     cert:self.state.certificate.getRaw certChain:NULL privKey:self.state.keyPair.getRaw];
    NSData * p12Bin = [PEXCryptoUtils exportPKCS12:p12];
    PKCS12_free(p12);
    [fmgr removeItemAtPath:pkcs12Path error:nil];
    [fmgr createFileAtPath:pkcs12Path contents:p12Bin
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    [PEXSecurityCenter trySetBackupFlagFile:pkcs12Path backupFlag:identityBackupFlag];
    DDLogVerbose(@"PKCS12File: %@, forUser=%@", pkcs12Path, self.params.userName);

    // Store interesting information to privData for next tasks.
    if (self.ownDelegate!=nil && self.ownDelegate.privData!=nil){
        PEXUserPrivate * pData = self.ownDelegate.privData;
        pData.username = self.params.userName;
        pData.pass = self.params.password;
        pData.pemPass = self.state.pemPassword;
        pData.pkcsPass = self.state.pkcsPassword;

        // Read back identity for next operations.
        int identityLoadRes = [PEXSecurityCenter loadIdentity:pData];
        if (identityLoadRes != kIDENTITY_EXISTS){
            DDLogError(@"Cannot load previously generated identity, res=%d", identityLoadRes);
        }

        DDLogVerbose(@"Priv data refreshed for user=%@, res=%d", pData.username, identityLoadRes);
    }

    DDLogVerbose(@"Certificate pem=[%@]", certPem);
    DDLogVerbose(@"PrivKey pem=[%@]", privPem);

    // Cookies for SOAP call has to be cleared here, user may have generated a new certificate.
    [PEXSOAPManager clearPhonexCookies];
    [PEXSOAPManager eraseCredentials];
}
@end

// Public implementation.
@implementation PEXCertGenTask { }

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskName = @"CertGen";

        // Initialize empty state
        [self setState:[[PEXCertGenTaskState alloc] init]];
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
    [self setSubTask:[[PEXCertGenKeyGenTask           alloc] initWithDel:self andName:@"KeyGen"]   id:PCGT_KEYGEN];
    [self setSubTask:[[PEXCertGenCSRGenTask           alloc] initWithDel:self andName:@"CSRGen"]   id:PCGT_CSRGEN];
    [self setSubTask:[[PEXCertGenOTTTask              alloc] initWithDel:self andName:@"OTT"]      id:PCGT_OTT];
    [self setSubTask:[[PEXCertGenAuthHashTask         alloc] initWithDel:self andName:@"AuthHash"] id:PCGT_AuthHash];
    [self setSubTask:[[PEXCertGenEncCSRTask           alloc] initWithDel:self andName:@"EncCSR"]   id:PCGT_EncCSR];
    [self setSubTask:[[PEXCertGenSoapSignTask         alloc] initWithDel:self andName:@"SOAPSign"] id:PCGT_SOAPSIGN];
    [self setSubTask:[[PEXCertGenVerifyTask           alloc] initWithDel:self andName:@"Verify"]   id:PCGT_VERIFY];
    [self setSubTask:[[PEXCertGenStoragePasswordsTask alloc] initWithDel:self andName:@"PassGen"]  id:PCGT_PEMPASSGEN];
    [self setSubTask:[[PEXCertGenStoreTask            alloc] initWithDel:self andName:@"Store"]    id:PCGT_STORE];

    // Add dependencies to the tasks.
    // KeyGen + CSR are independent on OTT. Can be processed individually.
    // Can help since OTT is a network task - interleave with keygen.
    [self.tasks[PCGT_CSRGEN]     addDependency:self.tasks[PCGT_KEYGEN]];
    [self.tasks[PCGT_AuthHash]   addDependency:self.tasks[PCGT_OTT]];
    [self.tasks[PCGT_EncCSR]     addDependency:self.tasks[PCGT_CSRGEN]];
    [self.tasks[PCGT_EncCSR]     addDependency:self.tasks[PCGT_AuthHash]];
    [self.tasks[PCGT_SOAPSIGN]   addDependency:self.tasks[PCGT_EncCSR]];
    [self.tasks[PCGT_VERIFY]     addDependency:self.tasks[PCGT_SOAPSIGN]];
    [self.tasks[PCGT_PEMPASSGEN] addDependency:self.tasks[PCGT_VERIFY]];
    [self.tasks[PCGT_STORE]      addDependency:self.tasks[PCGT_PEMPASSGEN]];

    // Mark last task so we know what to wait for.
    [self.tasks[PCGT_STORE] setIsLast:YES];
}

- (void)subTasksFinished:(int)waitResult {
    [super subTasksFinished:waitResult];

    PEXLoginTaskEventFinished * finResult;
    // If was cancelled - signalize cancel ended.
    if (waitResult==kWAIT_RESULT_CANCELLED){
        [self cancelEnded:NULL];
        finResult = [[PEXLoginTaskEventFinished alloc] initWithState: PEX_TASK_FINISHED_CANCELLED];
    } else if (self.state.errorOccurred || waitResult==kWAIT_RESULT_TIMEOUTED) {
        finResult = [[PEXLoginTaskEventFinished alloc] initWithState: PEX_TASK_FINISHED_ERROR];
        finResult.finishError = self.state.lastError;
    } else {
        finResult = [[PEXLoginTaskEventFinished alloc] initWithState: PEX_TASK_FINISHED_OK];
    }

    self.finishedEvent = finResult;
    DDLogVerbose(@"End of waiting loop");
}

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");
}

- (void)taskStarted:(const PEXTaskEvent *const)event {
    [super taskStarted:event];
}

- (void)taskEnded:(const PEXTaskEvent *const)event {
    [super taskEnded:event];
}

- (void)taskProgressed:(const PEXTaskEvent *const)event {
    [super taskProgressed:event];
}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {
    [super taskCancelStarted:event];
}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {
    [super taskCancelEnded:event];
}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {
    [super taskCancelProgressed:event];
}


@end