//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHCalls.h"
#import "PEXFtResult.h"
#import "PEXCanceller.h"
#import "PEXSipUri.h"
#import "hr.h"
#import "PEXSOAPTask.h"
#import "PEXDHKeyGeneratorParams.h"
#import "PEXDHKeyHolder.h"

@interface PEXDHCalls() {}
@property(nonatomic) NSError * error;
@property(nonatomic) BOOL wasCancelled;
@property(nonatomic) PEXSOAPTask * curTask;
@end

@implementation PEXDHCalls {

}
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [super init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData canceller:(id <PEXCanceller>)canceller {
    self = [super init];
    if (self) {
        self.privData = privData;
        self.canceller = canceller;
    }

    return self;
}

+ (instancetype)callsWithPrivData:(PEXUserPrivate *)privData canceller:(id <PEXCanceller>)canceller {
    return [[self alloc] initWithPrivData:privData canceller:canceller];
}


+ (instancetype)callsWithPrivData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithPrivData:privData];
}

-(void) checkCallPreconditions {
    // Check validity of input parameter.
    if (self.privData == nil){
        @throw [NSException exceptionWithName:PEXRuntimeException reason:@"nil privdata" userInfo:nil];
    }
}

- (void)doCancel {
    _wasCancelled = YES;
    if (_curTask != nil){
        [_curTask cancel];
    }
}

- (BOOL)shouldCancel {
    return _wasCancelled || (self.canceller != nil && [self.canceller isCancelled]);
}

-(void) subCancel {
    _wasCancelled = YES;
    // TODO: notify about cancellation?
}

-(void) subError: (NSError *) error {
    self.error = error;
}

/**
* Performs SOAP ftRemoveDHKeys call with given request.
*/
-(PEXFtResult *) deleteKeysRequest: (hr_ftRemoveDHKeysRequest *) removeReq result: (PEXFtResult *) mres {
    // Create SOAP envelope
    // Fail safe init of the soap task.
    PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.deleteKeys"];
    _curTask = task;

    task.logXML = YES;
    [task prepareSOAP:self.privData];

    // Prepare SOAP operation.
    __weak __typeof(self) weakSelf = self;
    task.desiredBody = [hr_ftRemoveDHKeysResponse class];
    task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
    task.srcOperation = [[PhoenixPortSoap11Binding_ftRemoveDHKeys alloc]
            initWithBinding:task.getBinding delegate:task ftRemoveDHKeysRequest:removeReq];

    // Start task, sync blocking here, on purpose.
    [task start];

    // Check basic sanity
    if (![self soapTaskFinished:task mres:mres]){
        return mres;
    }

    // Extract answer
    hr_ftRemoveDHKeysResponse * body = (hr_ftRemoveDHKeysResponse *) task.responseBody;
    if (body != nil && body.errCode != nil) {
        mres.code = [body.errCode integerValue];
    }

    mres.soapTaskError = task.taskError;
    DDLogDebug(@"Result code=%ld", (long)mres.code);
    return mres;
}

/**
* Deletes DH keys from the server based on a given mapping UserSip -> Date.
*
* Each entry in the map is inspected, if date for a given user is nil,
* all DH keys for particular user will be removed, otherwise only
* keys older (created) than specified date will be removed.
*
* @param mpar
* @param deleteOlderForUser    // Map<String, Date> deleteOlderForUser
* @param rand
* @return
*/
-(PEXFtResult *) deleteKeys: (NSDictionary *) deleteOlderForUser {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    // If map is empty, do nothing.
    if (deleteOlderForUser == nil || [deleteOlderForUser count] == 0){
        return mres;
    }

    // HTTP transport - declare before TRY block to be able to
    // extract response in catch block for debugging.
    @try {
        [self checkCallPreconditions];

        // Get my domain
        NSString * domain = [PEXSipUri getDomainFromSip:self.privData.username parsed:NULL];

        hr_ftRemoveDHKeysRequest * removeReq = [[hr_ftRemoveDHKeysRequest alloc] init];
        removeReq.version = @(1);
        removeReq.deleteAll = [[USBoolean alloc] initWithBool:NO];

        // Fill delete conditions w.r.t. map.
        // If date is nil, delete all DH keys for a given user
        // otherwise delete only keys older than specified date.
        hr_sipList * sipList = [[hr_sipList alloc] init];
        hr_sipDatePairList * sipdate = [[hr_sipDatePairList alloc] init];

        for(NSString * usr in deleteOlderForUser){
            id obj = deleteOlderForUser[usr];
            if ([obj isKindOfClass:[NSNull class]]){
                [sipList addUser:usr];
                continue;
            }

            // Date not nil, remove only older than for a given user
            hr_sipDatePair * p = [[hr_sipDatePair alloc] init];
            p.sip = usr;
            p.dt = (NSDate *) obj;
            [sipdate addSipdate:p];
        }

        // At least one delete condition has to be non-empty.
        if ([sipList.user count] == 0 && [sipdate.sipdate count] == 0){
            return mres;
        }

        if ([sipList.user count] > 0){
            [removeReq setUsers:sipList];
        }

        if ([sipdate.sipdate count] > 0){
            [removeReq setUserDateList:sipdate];
        }

        // Perform the request itself.
        return [self deleteKeysRequest:removeReq result:mres];

    } @catch (NSException * e) {
        DDLogError(@"Exception in deleteKeys time map, exception=%@", e);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = e;
        return mres;
    }

    return mres;
}

/**
* Deletes DH keys from server for particular user.
* Fields needed to be initialized in mpar:
* 	- my sip.
*  - destination sip to delete keys - in user list (OPTIONAL).
*  - storage password for SSL.
*
*  If destination SIP is empty and nonce2 list is empty, all keys are removed.
*
* @param mpar
* @param rand
* @return
*/
-(PEXFtResult *) deleteKeysWithParams: (PEXDHKeyGeneratorParams *) mpar{
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;
    if (mpar.privKey != nil){
        self.privData = mpar.privKey;
    }

    // HTTP transport - declare before TRY block to be able to
    // extract response in catch block for debugging.
    @try {
        // Check validity of input parameter.
        [self checkCallPreconditions];

        // Get my domain, build request.
        NSString * domain = [PEXSipUri getDomainFromSip:self.privData.username parsed:NULL];
        hr_ftGetStoredDHKeysInfoRequest * getReq = [[hr_ftGetStoredDHKeysInfoRequest alloc] init];
        getReq.version = @(1);
        getReq.detailed = [[USBoolean alloc] initWithBool:YES];
        getReq.users = [[hr_sipList alloc] init];

        // Fill in the request structure
        hr_ftRemoveDHKeysRequest * dhReq = [[hr_ftRemoveDHKeysRequest alloc] init];
        dhReq.version = @(1);
        dhReq.deleteAll = [[USBoolean alloc] initWithBool:NO];

        NSArray * uList = mpar.userList;         // GenKeyForUser;
        NSArray * nList = mpar.deleteNonce2List; // NSString;

        if ((uList == nil || [uList count] == 0) && (nList == nil || [nList count] == 0)){
            DDLogVerbose(@"Going to delete all DH keys");
            dhReq.deleteAll = [[USBoolean alloc] initWithBool:YES];

        } else {
            // User list is not empty?
            if (uList != nil && [uList count] > 0){
                hr_sipList * uList2 = [[hr_sipList alloc] init];

                for(PEXDHKeyGenForUser * kUser in uList){
                    DDLogVerbose(@"Going to delete all DH keys for user: %@", kUser.userSip);
                    [uList2 addUser:kUser.userSip];
                }

                [dhReq setUsers: uList2];
            }

            // Nonce list is not empty?
            if (nList != nil && [nList count] > 0){
                hr_ftNonceList * regNList = [[hr_ftNonceList alloc] init];
                for(NSString * cn in nList){
                    DDLogVerbose(@"Going to delete nonce2: %@", cn);
                    [regNList addNonce:cn];
                }

                [dhReq setNonceList: regNList];
            }
        }

        // Perform the request itself.
        return [self deleteKeysRequest:dhReq result:mres];

    } @catch (NSException * e) {
        DDLogError(@"Exception in deleteKeys, exception=%@", e);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = e;
        return mres;
    }

    return mres;
}

/**
* Performs query for all DH keys.
*/
-(PEXFtResult *) getDhKeys: (hr_ftGetStoredDHKeysInfoResponse **) body {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    // HTTP transport - declare before TRY block to be able to
    // extract response in catch block for debugging.
    @try {
        [self checkCallPreconditions];

        // Get my domain, build request.
        NSString * domain = [PEXSipUri getDomainFromSip:self.privData.username parsed:NULL];
        hr_ftGetStoredDHKeysInfoRequest * getReq = [[hr_ftGetStoredDHKeysInfoRequest alloc] init];
        getReq.version = @(1);
        getReq.detailed = [[USBoolean alloc] initWithBool:YES];
        getReq.users = [[hr_sipList alloc] init];

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.getKeys"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftGetStoredDHKeysInfoResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo alloc]
                initWithBinding:task.getBinding delegate:task ftGetStoredDHKeysInfoRequest:getReq];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
            return mres;
        }

        // Extract answer
        if (body != nil){
            *body = (hr_ftGetStoredDHKeysInfoResponse *) task.responseBody;
        }

        mres.soapTaskError = task.taskError;
        return mres;

    } @catch (NSException * e) {
        DDLogError(@"Exception in deleteKeys time map, exception=%@", e);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = e;
        return mres;
    }

    return mres;
}

- (PEXFtResult *)uploadKeys:(NSArray *)keys response: (hr_ftAddDHKeysResponse **) response {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    @try {
        [self checkCallPreconditions];

        // Get my domain, build request.
        NSString * domain = [PEXSipUri getDomainFromSip:self.privData.username parsed:NULL];
        hr_ftAddDHKeysRequest * uploadReq = [[hr_ftAddDHKeysRequest alloc] init];
        for(PEXDHKeyHolder * holder in keys){
            if (holder == nil || holder.serverKey == nil || holder.serverKey.user == nil){
                DDLogError(@"Holder is illegal! holder=%@", holder);
                continue;
            }

            [uploadReq addDhkeys:holder.serverKey];
        }

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.uploadKeys"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftAddDHKeysResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftAddDHKeys alloc]
                initWithBinding:task.getBinding delegate:task ftAddDHKeysRequest:uploadReq];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
            return mres;
        }

        hr_ftAddDHKeysResponse * resp = (hr_ftAddDHKeysResponse *) task.responseBody;
        if (response != NULL){
            *response = resp;
        }

        if (resp.errCode != nil){
            NSInteger errCode = [resp.errCode integerValue];
            mres.responseCode = errCode;
            mres.soapTaskError = task.taskError;

            if (errCode < 0) {
                mres.code = PEX_DH_CALL_RES_SOAP_ERROR;
                return mres;
            }
        }

        return mres;

    } @catch (NSException * e) {
        DDLogError(@"Exception in uploadKeys, exception=%@", e);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = e;
        return mres;
    }

    return mres;
}

-(PEXFtResult *) deleteFileFromServer: (NSArray *) nonces2 domain: (NSString *) domain response: (hr_ftDeleteFilesResponse **) response {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    @try {
        [self checkCallPreconditions];

        // Do SOAP call
        hr_ftNonceList *nonceList = [[hr_ftNonceList alloc] init];
        for (NSString * nonce2 in nonces2) {
            [nonceList addNonce:nonce2];
        }

        hr_ftDeleteFilesRequest *req = [[hr_ftDeleteFilesRequest alloc] init];
        req.deleteAll = [[USBoolean alloc] initWithBool:NO];
        req.nonceList = nonceList;

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.deleteFiles"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftDeleteFilesResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftDeleteFiles alloc]
                initWithBinding:task.getBinding delegate:task ftDeleteFilesRequest:req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
            return mres;
        }

        hr_ftDeleteFilesResponse * resp = (hr_ftDeleteFilesResponse *) task.responseBody;
        if (response != NULL){
            *response = resp;
        }

        if (resp.errCode != nil){
            NSInteger errCode = [resp.errCode integerValue];
            mres.responseCode = errCode;
            mres.soapTaskError = task.taskError;

            if (errCode < 0) {
                mres.code = PEX_DH_CALL_RES_SOAP_ERROR;
                return mres;
            }
        }

    } @catch(NSException *ex){
        DDLogError(@"Exception in deleteFiles, exception=%@", ex);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = ex;
        return mres;
    }

    return mres;
}

-(PEXFtResult *) getStoredFiles: (NSArray *) nonces2 domain: (NSString *) domain response: (hr_ftGetStoredFilesResponse **) response {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    @try {
        [self checkCallPreconditions];

        // Do SOAP call
        hr_ftNonceList *nonceList = [[hr_ftNonceList alloc] init];
        for (NSString * nonce2 in nonces2) {
            [nonceList addNonce:nonce2];
        }

        hr_ftGetStoredFilesRequest *req = [[hr_ftGetStoredFilesRequest alloc] init];
        req.getAll = [[USBoolean alloc] initWithBool:NO];
        req.nonceList = nonceList;

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.getFiles"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftGetStoredFilesResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftGetStoredFiles alloc]
                initWithBinding:task.getBinding delegate:task ftGetStoredFilesRequest:req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
            return mres;
        }

        hr_ftGetStoredFilesResponse * resp = (hr_ftGetStoredFilesResponse *) task.responseBody;
        if (response != NULL){
            *response = resp;
        }

        if (resp.errCode != nil){
            NSInteger errCode = [resp.errCode integerValue];
            mres.responseCode = errCode;
            mres.soapTaskError = task.taskError;

            if (errCode < 0) {
                mres.code = PEX_DH_CALL_RES_SOAP_ERROR;
                return mres;
            }
        }

    } @catch(NSException *ex){
        DDLogError(@"Exception in getStoredFile, exception=%@", ex);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = ex;
        return mres;
    }

    return mres;
}

- (PEXFtResult *)getDHKeysPart1:(NSString *)user domain:(NSString *)domain response:(hr_ftGetDHKeyResponse **)response {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    @try {
        [self checkCallPreconditions];

        // Do SOAP call
        hr_ftGetDHKeyRequest *req = [[hr_ftGetDHKeyRequest alloc] init];
        req.user = user;

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.getKey"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftGetDHKeyResponse class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftGetDHKey alloc]
                initWithBinding:task.getBinding delegate:task ftGetDHKeyRequest: req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
             return mres;
        }

        hr_ftGetDHKeyResponse * resp = (hr_ftGetDHKeyResponse *) task.responseBody;
        if (response != NULL){
            *response = resp;
        }

        if (resp.errCode != nil){
            NSInteger errCode = [resp.errCode integerValue];
            mres.responseCode = errCode;
            mres.soapTaskError = task.taskError;
        }

    } @catch(NSException *ex){
        DDLogError(@"Exception in getDHKey, exception=%@", ex);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = ex;
        return mres;
    }

    return mres;
}

- (PEXFtResult *)getDHKeysPart2:(NSString *)user nonce1:(NSString *)nonce1 domain:(NSString *)domain response:(hr_ftGetDHKeyPart2Response **)response {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    _wasCancelled = NO;

    @try {
        [self checkCallPreconditions];

        // Do SOAP call
        hr_ftGetDHKeyPart2Request *req = [[hr_ftGetDHKeyPart2Request alloc] init];
        req.user = user;
        req.nonce1 = nonce1;

        // Create SOAP envelope
        // Fail safe init of the soap task.
        PEXSOAPTask * task = [[PEXSOAPTask alloc] initWith:self andName:@"net.phonex.getKey2"];
        _curTask = task;

        task.logXML = YES;
        [task prepareSOAP:self.privData];

        // Prepare SOAP operation.
        __weak __typeof(self) weakSelf = self;
        task.desiredBody = [hr_ftGetDHKeyPart2Response class];
        task.shouldCancelBlock = ^BOOL(PEXSubTask const *const soapTask) { return [weakSelf shouldCancel]; };
        task.srcOperation = [[PhoenixPortSoap11Binding_ftGetDHKeyPart2 alloc]
                initWithBinding:task.getBinding delegate:task ftGetDHKeyPart2Request: req];

        // Start task, sync blocking here, on purpose.
        [task start];

        // Check basic sanity
        if (![self soapTaskFinished:task mres:mres]){
            return mres;
        }

        hr_ftGetDHKeyPart2Response * resp = (hr_ftGetDHKeyPart2Response *) task.responseBody;
        if (response != NULL){
            *response = resp;
        }

        if (resp.errCode != nil){
            NSInteger errCode = [resp.errCode integerValue];
            mres.responseCode = errCode;
            mres.soapTaskError = task.taskError;
        }

    } @catch(NSException *ex){
        DDLogError(@"Exception in getKey2, exception=%@", ex);

        if (mres.code == 0){
            mres.code = PEX_DH_CALL_RES_EXCEPTION;
        }

        mres.ex = ex;
        return mres;
    }

    return mres;
}

/**
* Checks result of the SOAP task and sets PEXFtResult with correct data.
* Calls subCancel or subError if given action occurred.
* Returns YES if task finished fine.
*/
- (BOOL) soapTaskFinished: (PEXSOAPTask *) task mres: (PEXFtResult *) mres {
    mres.cancelDetected = task.cancelDetected;
    mres.timeoutDetected = task.timeoutDetected;

    // Cancelled check block.
    if ([task cancelDetected] || [self shouldCancel]) {
        [self subCancel];
        mres.code = PEX_DH_CALL_RES_CANCELLED;
        mres.soapTaskError = task.taskError;
        return NO;
    }

    // Error check block.
    if ([task finishedWithError] || task.responseBody == nil) {
        [self subError:task.error];
        mres.code = PEX_DH_CALL_RES_ERROR;
        mres.soapTaskError = task.taskError;
        mres.err = task.error;
        return NO;
    }

    return YES;
}

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

@end