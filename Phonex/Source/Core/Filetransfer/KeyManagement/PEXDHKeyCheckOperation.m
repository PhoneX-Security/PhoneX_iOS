//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHKeyCheckOperation.h"
#import "PEXDhKeyGenManager.h"
#import "PEXCanceller.h"
#import "PEXCancelledException.h"
#import "PEXSipUri.h"
#import "PEXDbContact.h"
#import "PEXUtils.h"
#import "PEXDbUserCertificate.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"
#import "PEXDhKeyHelper.h"
#import "PEXDbDhKey.h"
#import "PEXFtResult.h"
#import "PEXDHCalls.h"
#import "hr.h"
#import "PEXDHKeyGeneratorParams.h"
#import "PEXUserKeyRefreshRecord.h"
#import "PEXDBMessage.h"
#import "PEXUserKeyRefreshQueue.h"
#import "NSError+PEX.h"
#import "PEXService.h"
#import "PEXFileTransferException.h"

#define PEX_MESSAGE_STATISTIC_SAMPLE_SIZE 100
const NSInteger PEXFtErrorGetKeyFailed = 4001;
const NSInteger PEXFtErrorGetKeyNotConnected = 4002;
const NSInteger PEXFtErrorGetKeyFailedException = 4003;

/**
* Class for storage in deleteInvalidKeys.
* @author ph4r05
*
*/
@interface PEXUserCert : NSObject <NSCoding, NSCopying> {}
@property(nonatomic) NSString * certHash;
@property(nonatomic) NSDate * notBefore;
@property(nonatomic) BOOL inWhitelist;
@property(nonatomic) PEXX509 * cert;
@end


@interface PEXDHKeyCheckOperation() {
    BOOL _wasCancelled;
    NSString * _domain;
    NSMutableDictionary * _userCerts; //private Map<String, UserCert> userCerts = new HashMap<String, UserCert>();
    PEXDhKeyHelper * _dhelper;

    // Number of ready DH keys for each user
    NSMutableDictionary * _readyKeys;

    // Recent messages / files statistics for cost computation.
    // Approximative. NSString * -> NSNumber *; username -> float.
    NSMutableDictionary * _recentMessages;
    NSMutableDictionary * _recentFiles;
    PEXService          * _svc;
}

@property(nonatomic) NSError * opError;
@property(nonatomic) NSInteger numOfUsersUpdated;
@property(nonatomic) BOOL interruptedDueToConnectionError;
@end

@implementation PEXDHKeyCheckOperation {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _wasCancelled = NO;
        _userCerts = [[NSMutableDictionary alloc] init];
        _shouldExpireKeys = YES;
        _shouldPerformCleaning = YES;
        _triggerKeyUpdate = YES;
        _interruptedDueToConnectionError = NO;
    }

    return self;
}

- (instancetype)initWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.mgr = mgr;
        self.privData = privData;
    }

    return self;
}

+ (instancetype)operationWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithMgr:mgr privData:privData];
}

/**
* Main entry point for this task.
*/
-(void) main {
    @try {
        [self runInternal];
    } @catch(NSException * e){
        DDLogError(@"Exception in certificate refresh. Exception=%@", e);
        if (_opError == nil){
            _opError = [NSError errorWithDomain:PEXFtErrorDomain code:PEXFtErrorGetKeyFailedException userInfo:@{PEXExtraException : e}];
        }
    }

    // Finished, finalize all internal statuses.
    [self.mgr resetState];
    [self.mgr bcastState];
}

- (void)runInternal {
    _wasCancelled = NO;

    PEXUserPrivate * privData = self.privData;
    if (privData == nil){
        DDLogError(@"Priv data is nil!");
        return;
    }

    _interruptedDueToConnectionError = NO;
    _svc = [PEXService instance];
    _domain = [PEXSipUri getDomainFromSip:privData.username parsed:nil];
    _dhelper = [[PEXDhKeyHelper alloc] init];
    _dhelper.privData = privData;
    _dhelper.mySip = privData.username;
    _opError = nil;

    [self checkIfConnected];
    [self checkIfCancelled];


    //
    // Phase 1 - Load stored users, certificates. Delete old keys based on certificate details for a user.
    //
    DDLogDebug(@"Phase 1 - delete invalid keys; domain=%@", _domain);
    [self deleteInvalidKeys];
    [self checkIfCancelled];
    [self checkIfConnected];

    //
    // Phase 2 - get all DH keys from the server, remove those not in local
    // 			 database, generate new keys and upload them to the server.
    //
    DDLogDebug(@"Phase 2 - sync & generate keys");
    PEXDHCalls * getKeysCall = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];

    hr_ftGetStoredDHKeysInfoResponse * resp = nil;
    PEXFtResult * res = [getKeysCall getDhKeys:&resp];
    if (res.code != 0 || resp == nil){
        DDLogWarn(@"Get DH keys response is invalid");
        NSDictionary * userInfo = getKeysCall.error != nil ? @{PEXExtraMessage : getKeysCall.error} : nil;
        _opError = [NSError errorWithDomain:PEXFtErrorDomain code:PEXFtErrorGetKeyFailed userInfo:userInfo];
        return;
    }

    [self checkIfCancelled];
    [self checkIfConnected];

    // This step is needed since we get actual number of usable keys per user.
    // If cleaning is enabled, it also synchronizes local-remote DH key storage so
    // both contain intersection of these two sets.
    [self localRemoteSync:resp];

    // Get last 100 messages, compute statistics - group by username, for priority computation.
    [self getRecentMessagesStatistics];
    NSInteger numOfUsersUpdated = 0;

    // Update user queue with user records. URecord contains information how many keys to generate.
    // Only for users having valid certificate and in whitelist (can contact me).
    for(NSString * sip in _userCerts){
        PEXUserCert * uc = _userCerts[sip];
        NSInteger numKeys = _readyKeys[sip] != nil ? [((NSNumber *) _readyKeys[sip]) integerValue] : 0;

        DDLogDebug(@"Phase 2, usr[%@] keys2gen[%ld]", sip, (long)(self.maxDhKeys - numKeys));

        // If not in white-list or has invalid certificate - no DHkeys.
        // Also checks for certificate validity. Without certificate no DH keys are possible.
        if (!uc.inWhitelist || uc.certHash == nil || uc.notBefore == nil){
            DDLogVerbose(@"Skipping, whitelist=%d; cert probably not valid", uc.inWhitelist);
            continue;
        }

        // If some keys are missing, generate new ones.
        if (numKeys >= self.maxDhKeys){
            DDLogVerbose(@"Skipping, enough keys, numKeys=%ld", (long)numKeys);
            continue;
        }

        PEXUserKeyRefreshRecord * uRec = [[PEXUserKeyRefreshRecord alloc] init];
        uRec.user = sip;
        uRec.maximalKeys = self.maxDhKeys;
        uRec.availableKeys = numKeys;

        // Messages / files statistics.
        NSNumber * recentMsg = _recentMessages[sip];
        NSNumber * recentFile = _recentFiles[sip];
        uRec.ratioOfMessagesInLastWindow = recentMsg == nil  ? 0.0 : ((double)[recentMsg  integerValue] / (double) PEX_MESSAGE_STATISTIC_SAMPLE_SIZE);
        uRec.ratioOfFilesInLastWindow    = recentFile == nil ? 0.0 : ((double)[recentFile integerValue] / (double) PEX_MESSAGE_STATISTIC_SAMPLE_SIZE);

        [self.mgr updateUserRecord:uRec];
        numOfUsersUpdated += 1;
    }

    self.numOfUsersUpdated = numOfUsersUpdated;
    if (self.triggerKeyUpdate && numOfUsersUpdated > 0){
        DDLogVerbose(@"Triggering key update, num of users updated: %ld", (long)numOfUsersUpdated);
        [self.mgr triggerKeyGen];
    }

    // Task may got canceled.
    [self checkIfCancelled];
    DDLogInfo(@"Finished properly");
}

/**
* Put this error on the top of the error stack, leaving tail of the error chain in the EXTRA.
*/
-(void) chainErrorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict {
    _opError = [NSError errorWithDomain:domain code:code userInfo:dict subError:_opError];
}

-(void) chainError: (NSError *) error {
    _opError = [NSError errorWithError:error subError:_opError];
}

/**
* Computes statistics of the recent messages for calculation of a priority for DH key gen.
*/
- (void) getRecentMessagesStatistics {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * c = [cr query:[PEXDbMessage getURI] projection:[PEXDbMessage getLightProjection]
                      selection:[NSString stringWithFormat:@" WHERE (%@=? AND %@=1) OR (%@=? AND %@=0)",
                                      PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_IS_OUTGOING,
                                      PEXDBMessage_FIELD_TO,   PEXDBMessage_FIELD_IS_OUTGOING ]
                  selectionArgs:@[self.privData.username, self.privData.username]
                      sortOrder:[NSString stringWithFormat:@" ORDER BY %@ DESC LIMIT %d", PEXDBMessage_FIELD_ID, PEX_MESSAGE_STATISTIC_SAMPLE_SIZE]];

    _recentMessages = [[NSMutableDictionary alloc] init];
    _recentFiles    = [[NSMutableDictionary alloc] init];

    if (c == nil){
        return;
    }

    for (NSInteger i = 0; [c moveToNext] && i < PEX_MESSAGE_STATISTIC_SAMPLE_SIZE; i++) {
        PEXDbMessage *msg = [PEXDbMessage messageFromCursor:c];
        NSString *remoteParty = [msg getRemoteParty];
        if (remoteParty == nil) {
            continue;
        }

        // Existence.
        if (_recentMessages[remoteParty] == nil) {
            _recentMessages[remoteParty] = @(0);
        }

        if (_recentFiles[remoteParty] == nil) {
            _recentFiles[remoteParty] = @(0);
        }

        // Incrementation.
        _recentMessages[remoteParty] = @([((NSNumber *) _recentMessages[remoteParty]) integerValue] + 1);
        if ([PEXDBMessage_MIME_FILE isEqualToString:msg.mimeType]) {
            _recentFiles[remoteParty] = @([((NSNumber *) _recentFiles[remoteParty]) integerValue] + 1);
        }
    }
}

/**
* Deletes server-only and local-only DH keys.
* Basically performs intersection and synchronizes this state.
*/
- (PEXFtResult *)localRemoteSync: (hr_ftGetStoredDHKeysInfoResponse *) resp {
    // Construct data structures for local-remote key synchronization.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    // Get set of all Nonce2 in database (function returns list, make a set).
    NSSet * nonceSet = [NSSet setWithArray:[PEXDbDhKey getReadyDHKeysNonce2:nil cr:cr]];
    // Set of nonce2 that are on server but not in local database.
    NSMutableSet * deleteServerNonce = [[NSMutableSet alloc] init];
    // Set of nonce2 that are not on server but in local database.
    NSMutableSet * deleteLocalNonce = [[NSMutableSet alloc] init];
    // Number of ready DH keys for each user
    _readyKeys = [[NSMutableDictionary alloc] init];
    // Set of nonces present on server.
    NSMutableSet * serverNonceSet = [[NSMutableSet alloc] init];

    // Count READY DH keys for a given user. If less than given threshold, generate new ones & upload them.
    hr_ftDHKeyUserInfoArr * keyInfo = resp.info;
    if (keyInfo != nil && keyInfo.keyinfo != nil && [keyInfo.keyinfo count] > 0){
        for(hr_ftDHKeyUserInfo * info in keyInfo.keyinfo){
            NSString * cnonce2 = info.nonce2;
            hr_ftDHkeyState cstate = info.status;
            NSString * csip = info.user;

            // If this nonce2 is not in local database, mark for deletion.
            if (![nonceSet containsObject:cnonce2]){
                [deleteServerNonce addObject:cnonce2];
                continue;
            }

            if (_readyKeys[csip] == nil){
                _readyKeys[csip] = @(0);
            }

            // Increment number of ready keys for a given user.
            if (cstate == hr_ftDHkeyState_ready){
                _readyKeys[csip] = @([((NSNumber *) _readyKeys[csip]) integerValue] + 1);
            }

            [serverNonceSet addObject:cnonce2];
        }

        // If there are some keys that are on the server but not locally, delete
        // them since there is no usage for them. This may be an artifact after
        // removing an user from database.
        if ([deleteServerNonce count] > 0 && self.shouldPerformCleaning){
            DDLogVerbose(@"Removing server-only keys: %lu", (unsigned long)[deleteServerNonce count]);

            // Initialize task an invoke main work method.
            PEXDHKeyGeneratorParams * gkp2 = [[PEXDHKeyGeneratorParams alloc] init];
            gkp2.deleteNonce2List = [[deleteServerNonce allObjects] mutableCopy];

            // Initialize task an invoke main work method.
            PEXDHCalls * call = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];
            [call deleteKeysWithParams:gkp2];
            if (call.error != nil && self.opError == nil){
                _opError = call.error;
            }

            DDLogVerbose(@"Server-only keys removed.");
        }
    } else {
        DDLogVerbose(@"We have no keys on the server side.");
    }

    // Task may got canceled.
    [self checkIfCancelled];

    // Scan for nonce2 that are stored locally but not on the server.
    for(NSString * dbNonce in nonceSet){
        // Nonce is in local database but is not on the server, mark for deletion.
        if (![serverNonceSet containsObject:dbNonce]){
            [deleteLocalNonce addObject:dbNonce];
        }
    }

    // Delete local-only nonce2 right now.
    if ([deleteLocalNonce count] > 0 && self.shouldPerformCleaning){
        DDLogVerbose(@"Deleting local-only keys: %lu", (unsigned long)[deleteLocalNonce count]);
        [PEXDbDhKey removeDHKeys:[deleteLocalNonce allObjects] cr:cr];
    }

    return [[PEXFtResult alloc] init];
}

/**
* Delete old keys based on certificate details for an user.
* Stores information about certificate for each user to userCerts.
*
* SOAP, rand, tv, dhelper has to be initialized prior this call.
*
* @param par
*/
- (PEXFtResult *)deleteInvalidKeys {
    PEXFtResult * mres = [[PEXFtResult alloc] init];
    mres.code = 0;
    mres.ex = nil;

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * c = [cr query:[PEXDbContact getURI]
                     projection:[PEXDbContact getFullProjection]
                      selection:@"WHERE 1"
                  selectionArgs:@[] sortOrder:nil];

    if (c == nil){
        DDLogWarn(@"Cursor is nil for clist fetch");
        mres.code = 3;
        return mres;
    }

    // Store sip -> date, delete keys older than date for a given user.
    [_userCerts removeAllObjects];
    NSMutableDictionary * deleteOlderForUser = [[NSMutableDictionary alloc] init]; // new HashMap<String, Date>();

    // Iterate over each contact, remove invalid DH keys
    // from local database and mark for deletion from server.
    @try {
        while([c moveToNext]){
            [self checkIfCancelled];
            PEXDbContact * clist = [PEXDbContact contactFromCursor:c];

            // Load certificate for remote contact to determine current certificate hash & validity date (from).
            NSDate * notBefore = nil;
            NSString * certHash = nil;

            PEXUserCert * uc = [[PEXUserCert alloc] init];

            // TODO: fix this in near future. Contacts have false in whitelist...
            uc.inWhitelist = YES; //clist.isInWhitelist();

            @try {
                PEXDbUserCertificate * sipcert = [PEXDbUserCertificate newCertificateForUser:clist.sip cr:cr projection:[PEXDbUserCertificate getFullProjection]];

                BOOL baseCrtInsane = sipcert == nil || sipcert.certificateStatus == nil || [sipcert.certificateStatus integerValue] != CERTIFICATE_STATUS_OK;
                PEXX509 * curCert  = baseCrtInsane ? nil : [sipcert getCertificateObj];
                if (curCert != nil){
                    notBefore = [PEXCryptoUtils getNotBefore: curCert.getRaw];
                    certHash = [PEXMessageDigest getCertificateDigestWrap: curCert];

                    uc.notBefore = notBefore;
                    uc.certHash = certHash;
                    uc.cert = curCert;
                }
            } @catch(NSException * e){
                DDLogWarn(@"Problem with user certificate for user %@, exception=%@", clist.sip, e);
            }

            // Store loaded information about user certificate for later use.
            _userCerts[clist.sip] = uc;

            // Delete all invalid DH keys (w.r.t. current certificate).
            // If some were deleted, mark time notBefore and delete it from the server as well.
            if (self.shouldPerformCleaning) {
                @try {
                    // Remove only some, based on certificate data.
                    // If both parameters (notBefore, certHash) happen to be nil, all
                    // DHkeys for particular user will be removed.
                    int removedNum = [PEXDbDhKey removeDHKeys:clist.sip olderThan:notBefore certHash:certHash
                                              expirationLimit:self.shouldExpireKeys ? [NSDate date] : nil cr:cr];

                    if (removedNum > 0) {
                        // There were some stored keys, remove them also from the server.
                        // notBefore can be nil if cert is not valid, in that case all keys will be
                        // removed.
                        deleteOlderForUser[clist.sip] = notBefore != nil ? notBefore : [NSNull null];
                    }

                    DDLogVerbose(@"Phase 1, usr[%@] notBefore[%@] removed[%d]", clist.sip, uc.notBefore, removedNum);
                } @catch (NSException *e) {
                    DDLogError(@"Exception during removing invalid DHKeys, exception=%@", e);
                }
            }
        }
    } @catch (NSException * e) {
        DDLogError(@"Error while getting SipClist from DB: exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    // If task was canceled, do no SOAP communication.
    if ([self wasCancelled]){
        mres.code=2;
        return mres;
    }

    if ([deleteOlderForUser count] == 0){
        return mres;
    }

    // If delete map is not empty, make a SOAP call to delete some entries.
    // This call deletes all keys older than defined deadline for particular user.
    // Use-case: user has new certificate what expires keys generated for old certificate.
    if (self.shouldPerformCleaning) {
        @try {
            DDLogInfo(@"Removing DHkeys from server");

            // Initialize task an invoke main work method.
            PEXDHCalls *call = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];
            [call deleteKeys:deleteOlderForUser];
            if (call.error != nil && self.opError == nil) {
                self.opError = call.error;
            }

        } @catch (NSException *e) {
            DDLogError(@"Exception in removing DH keys from the server, exception=%@", e);
        }
    }

    return mres;
}

/**
* Returns true if the local canceller signalizes a canceled state.
* @return
*/
-(BOOL) wasCancelled{
    return _wasCancelled || [self isCancelled] || (self.canceller != nil && [self.canceller isCancelled]);
}

/**
* Throws exception if operation was cancelled.
* @return
*/
-(void) checkIfCancelled {
    if ([self wasCancelled]){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];
    }
}

/**
* Check if connectivity is OK.
* if not, exception is thrown.
*/
-(void) checkIfConnected {
    _interruptedDueToConnectionError |= ![_svc isConnectivityWorking];
    if (_interruptedDueToConnectionError){
        [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorGetKeyNotConnected userInfo:nil];
        [PEXFileTransferException raise:PEXFileTransferNotConnectedException format:@"Not connected"];
    }
}

- (void)doCancel {
    _wasCancelled = YES;
    [self cancel];

    // TODO: implement.
}


@end

@implementation PEXUserCert
- (instancetype)init {
    self = [super init];
    if (self) {
        self.cert = nil;
        self.certHash = nil;
        self.notBefore = nil;
        self.inWhitelist = YES;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.cert = [coder decodeObjectForKey:@"self.cert"];
        self.certHash = [coder decodeObjectForKey:@"self.certHash"];
        self.notBefore = [coder decodeObjectForKey:@"self.notBefore"];
        self.inWhitelist = [coder decodeBoolForKey:@"self.inWhitelist"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.cert forKey:@"self.cert"];
    [coder encodeObject:self.certHash forKey:@"self.certHash"];
    [coder encodeObject:self.notBefore forKey:@"self.notBefore"];
    [coder encodeBool:self.inWhitelist forKey:@"self.inWhitelist"];
}


- (id)copyWithZone:(NSZone *)zone {
    PEXUserCert *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.certHash = self.certHash;
        copy.notBefore = self.notBefore;
        copy.inWhitelist = self.inWhitelist;
        copy.cert = self.cert;
    }

    return copy;
}

@end