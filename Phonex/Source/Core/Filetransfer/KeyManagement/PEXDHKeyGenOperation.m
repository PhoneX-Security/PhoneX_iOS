//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHKeyGenOperation.h"
#import "PEXCanceller.h"
#import "PEXDhKeyGenManager.h"
#import "PEXDhKeyHelper.h"
#import "PEXCancelledException.h"
#import "PEXSipUri.h"
#import "PEXUserKeyRefreshRecord.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "NSError+PEX.h"
#import "PEXDHKeyHolder.h"
#import "PEXDbDhKey.h"
#import "PEXDHCalls.h"
#import "PEXService.h"
#import "hr.h"
#import "PEXFtResult.h"
#import "PEXFileTransferException.h"

const NSInteger PEX_NUM_OF_UPLOAD_RETRIES           = 3;
const NSInteger PEX_NUM_OF_USERS_IN_BULK            = 3;
const NSInteger PEX_NUM_OF_KEYS_PER_USER_IN_BULK    = 2;
const NSInteger PEXFtErrorKeyUploadFailed               = 5001;
const NSInteger PEXFtErrorKeyUploadFailedNotConnected   = 5002;
const NSInteger PEXFtErrorKeyUploadFailedException      = 5003;

@interface PEXDHKeyGenOperation() {
    BOOL _wasCancelled;
    NSString * _domain;
    PEXDhKeyHelper * _dhelper;

    NSMutableArray * _currentUserRecords;
    NSMutableArray * _cachedKeys;
    NSMutableArray * _usersWithKeysGeneratedTmp;
    PEXService     * _svc;
}

@property(nonatomic) NSError * opError;
@property(nonatomic) BOOL interruptedDueToConnectionError;
@property(nonatomic) NSArray * usersWithKeysGenerated;
@end

@implementation PEXDHKeyGenOperation {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.numOfUsersInBulk = PEX_NUM_OF_USERS_IN_BULK;
        self.numOfKeysPerUserInBulk = PEX_NUM_OF_KEYS_PER_USER_IN_BULK;
        self.numOfUploadRetries = PEX_NUM_OF_UPLOAD_RETRIES;
        self.interruptedDueToConnectionError = NO;
        self.usersWithKeysGenerated = [[NSArray alloc] init];
        _wasCancelled = NO;
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
            _opError = [NSError errorWithDomain:PEXFtErrorDomain code:PEXFtErrorKeyUploadFailedException userInfo:@{PEXExtraException : e}];
        }
    }

    // Finished, finalize all internal statuses.
    [self.mgr resetState];
    [self.mgr bcastState];
}

- (void)runInternal {
    _wasCancelled = NO;
    _interruptedDueToConnectionError = NO;

    PEXUserPrivate * privData = self.privData;
    if (privData == nil){
        DDLogError(@"Priv data is nil!");
        return;
    }

    BOOL uploadError = NO;
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    _domain = [PEXSipUri getDomainFromSip:privData.username parsed:nil];
    _dhelper = [[PEXDhKeyHelper alloc] init];
    _dhelper.privData = privData;
    _dhelper.mySip = privData.username;
    _dhelper.myCert = privData.cert;
    _dhelper.privKey = privData.privKey;
    _svc = [PEXService instance];

    _opError = nil;
    _cachedKeys = [[NSMutableArray alloc] init];
    _currentUserRecords = [[NSMutableArray alloc] init];
    _usersWithKeysGeneratedTmp = [[NSMutableArray alloc] init];
    _usersWithKeysGenerated = [[NSArray alloc] init];
    NSInteger expectedNumOfKeys = _numOfUsersInBulk * _numOfKeysPerUserInBulk;
    NSInteger numOfKeysToGenerate = 0;

    // Poll user priority queue until we have enough keys to generate in one bulk.
    // This block construct list of users to generate.
    PEXUserKeyRefreshRecord * uRecord = nil;

    do {
        // If there are keys for upload, upload them. If error occurs, roll back them (delete from database) and quit
        // since there is probably some problem with connection or with the server.
        int uploadResult = [self uploadCachedKeys: NO];
        if (uploadResult < 0){
            uploadError = YES;
            DDLogWarn(@"Upload ended with error, quiting key gen task");

            [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorKeyUploadFailed userInfo:nil];
            break;
        } else if (uploadError > 0){
            DDLogVerbose(@"Keys were uploaded");
        }

        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            DDLogVerbose(@"Cancelled / connectivity down: %d", _interruptedDueToConnectionError);
            break;
        }

        // Poll one user record from priority queue.
        uRecord = [self.mgr pollUserRecord];
        if (uRecord == nil || ![uRecord shouldBeProcessed]){
            // Put record back to the queue.
            if (uRecord != nil){
                [self.mgr updateUserRecord:uRecord];
            }

            // queue is empty or current record is already saturated with keys.
            break;
        }

        NSInteger curKeysToGenerate = MAX(0, MIN(self.numOfKeysPerUserInBulk, uRecord.maximalKeys - uRecord.availableKeys));

        // Get certificate and verify its sanity.
        PEXDbUserCertificate * uCrt = [PEXDbUserCertificate newCertificateForUser:uRecord.user cr:cr projection:[PEXDbUserCertificate getFullProjection]];

        // Empty certificate -> cannot generate DH keys for him.
        BOOL baseCrtInsane = uCrt == nil || uCrt.certificateStatus == nil || [uCrt.certificateStatus integerValue] != CERTIFICATE_STATUS_OK;
        PEXX509 * xCrt = baseCrtInsane ? nil : [uCrt getCertificateObj];
        if (xCrt == nil){
            DDLogWarn(@"Empty/invalid certificate in genKeys");
            PEXDHKeyGeneratorProgress * prg = [PEXDHKeyGeneratorProgress progressWithUser:uRecord.user state:PEX_KEYGEN_STATE_DONE];
            [self publishProgress:prg];

            uRecord.certIsOK = NO;
            [self.mgr updateUserRecord:uRecord];
            continue;
        }

        // Store this user to processed so it can be later updated with number of generated keys.
        [_currentUserRecords addObject:uRecord];

        // Generate DH keys per user.
        for(NSInteger curKey = uRecord.availableKeys, keyCtr = 0;
            curKey < uRecord.maximalKeys && keyCtr < curKeysToGenerate && ![self wasCancelled];
            ++curKey, ++keyCtr)
        {
            [_dhelper setUserSip: uRecord.user];
            [_dhelper setSipCert: xCrt];

            // Progress
            PEXDHKeyGeneratorProgress * prg = [PEXDHKeyGeneratorProgress progressWithUser:uRecord.user state:PEX_KEYGEN_STATE_GENERATING_KEY];
            prg.alreadyGeneratedKeys = @(curKey);
            prg.maxKeysToGen = @(uRecord.maximalKeys);
            [self publishProgress:prg];

            // Generates DH key and stores it to the database.
            PEXDHKeyHolder * keyHolder = [_dhelper generateDHKey];
            [_cachedKeys addObject:keyHolder];

            // Last key was generated ? Move to generated state.
            if ((curKey+1) >= uRecord.maximalKeys){
                prg = [PEXDHKeyGeneratorProgress progressWithUser:uRecord.user state:PEX_KEYGEN_STATE_GENERATED];
                prg.alreadyGeneratedKeys = @(curKey);
                prg.maxKeysToGen = @(uRecord.maximalKeys);

                [self publishProgress:prg];
            }
        }

        numOfKeysToGenerate += curKeysToGenerate;
    } while(![self wasCancelled]);

    DDLogVerbose(@"Finished queue procesing, err=%@", self.opError);

    // Upload in bulks:
    [self uploadCachedKeys: YES];
    _usersWithKeysGenerated = [NSArray arrayWithArray:_usersWithKeysGeneratedTmp];

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

- (int) uploadCachedKeys: (BOOL) forceAll {
    // Check if was cancelled, if yes, abort transfer and delete keys.
    _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
    if ([self wasCancelled] || _interruptedDueToConnectionError){
        DDLogVerbose(@"Cancelled / connectivity down: %d", _interruptedDueToConnectionError);
        if (_interruptedDueToConnectionError){
            [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorKeyUploadFailedNotConnected userInfo:nil];
        }

        [self dbDeleteKeys];
        [self publishProgress:_currentUserRecords state: PEX_KEYGEN_STATE_DONE];
        [self returnToQueue];
        return 0;
    }

    // If not forced and not enough messages, do nothing.
    NSInteger keysToUpload = [_cachedKeys count];
    NSInteger expectedKeysToUpload = _numOfUsersInBulk * _numOfKeysPerUserInBulk;
    if (!forceAll && keysToUpload < expectedKeysToUpload){
        return 0;
    }

    if (keysToUpload == 0){
        [self publishProgress:_currentUserRecords state:PEX_KEYGEN_STATE_DONE];
        [self returnToQueue];
        return 0;
    }

    DDLogVerbose(@"Uploading keys to the server, keys=%d", (int) keysToUpload);

    hr_ftAddDHKeysResponse *resp = nil;
    PEXFtResult *mres = nil;
    BOOL uploadSuccessful = NO;
    NSMutableDictionary * uploadedUserKeysCounts = [[NSMutableDictionary alloc] initWithCapacity:[_currentUserRecords count]];
    [self publishProgress:_currentUserRecords state:PEX_KEYGEN_STATE_SERVER_CALL_SAVE];

    // Try to upload keys for several times until it succeeds.
    NSInteger curRetry = 0;
    for(; curRetry < _numOfUploadRetries; curRetry++) {
        // Cancellation & connectivity check.
        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            if (_interruptedDueToConnectionError){
                [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorKeyUploadFailedNotConnected userInfo:nil];
            }
            break;
        }

        PEXDHCalls *call = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];
        resp = nil;
        mres = [call uploadKeys:_cachedKeys response:&resp];
        if (mres.code < 0 || resp == nil){
            // Negative code means error so as empty response.
            DDLogWarn(@"Key upload did not go well. code=%ld, resp=%@", (long) mres.code, resp);
            continue;
        }

        // TODO: parse response code, some keys may be invalid. Use uploadedUserKeysCounts.
        uploadSuccessful = YES;
        break;
    }

    [self publishProgress:_currentUserRecords state:PEX_KEYGEN_STATE_POST_SERVER_CALL_SAVE];
    if(!uploadSuccessful){
        DDLogWarn(@"Key upload was not sucessful, deleting keys. Retries=%d", (int) curRetry);
        [self dbDeleteKeys];
        [self publishProgress:_currentUserRecords state:PEX_KEYGEN_STATE_DONE];
        [self returnToQueue];
        return -1;

    }

    DDLogVerbose(@"Keys upload successful, retries=%d", (int) curRetry);

    // Group number of uploaded keys by user name. Get counts.
    for(PEXDHKeyHolder * holder in _cachedKeys){
        NSString * uname = holder.dbKey.sip;
        if (uploadedUserKeysCounts[uname] == nil){
            uploadedUserKeysCounts[uname] = @(0);
        }

        uploadedUserKeysCounts[uname] = @([((NSNumber *) uploadedUserKeysCounts[uname]) integerValue] + 1);
    }

    // Update user records in the queue - update available key count so we have fresh priority queue.
    for(PEXUserKeyRefreshRecord * uRecord in _currentUserRecords){
        if (uploadedUserKeysCounts[uRecord.user] != nil){
            NSInteger cNewKeys = [uploadedUserKeysCounts[uRecord.user] integerValue];
            uRecord.availableKeys += cNewKeys;
            if (cNewKeys > 0) {
                [_usersWithKeysGeneratedTmp addObject:uRecord.user];
            }
        }

        [self.mgr updateUserRecord:uRecord];
    }

    [self publishProgress:_currentUserRecords state:PEX_KEYGEN_STATE_DONE];
    [_cachedKeys removeAllObjects];
    [_currentUserRecords removeAllObjects];

    return (int) keysToUpload;
}

-(void) publishProgress: (NSArray *) array state: (PEXKeyGenStateEnum) state {
    if (array == nil || [array count] == 0){
        return;
    }

    for(PEXUserKeyRefreshRecord * uRecord in array){
        PEXDHKeyGeneratorProgress * prg = [PEXDHKeyGeneratorProgress progressWithUser:uRecord.user state:PEX_KEYGEN_STATE_GENERATED];
        [self publishProgress:prg];
    }
}

-(void) publishProgress: (PEXDHKeyGeneratorProgress *) prg {
    // TODO: implement.
}

/**
* Deletes keys from database using DHkeyHolder list.
*
* @param keys
*/
-(void) dbDeleteKeys: (NSArray *) keys{ // PEXDHKeyHolder
    if (keys == nil || [keys count] == 0){
        return;
    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Delete
    for (PEXDHKeyHolder * h in keys){
        [PEXDbDhKey removeDHKey:h.dbKey.nonce2 cr:cr];
    }
}

/**
* Deletes all generated DH keys from the storage and removes them from the _cachedKeys.
* Called when upload was not successful.
*/
-(void) dbDeleteKeys {
    [self dbDeleteKeys:_cachedKeys];
    [_cachedKeys removeAllObjects];
}

/**
* Returns current user record to the queue without any change.
* Called on error.
*/
-(void) returnToQueue {
    if (_currentUserRecords == nil || [_currentUserRecords count] == 0){
        return;
    }

    for(PEXUserKeyRefreshRecord * uRecord in _currentUserRecords){
        [self.mgr updateUserRecord:uRecord];
    }

    [_currentUserRecords removeAllObjects];
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
        [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorKeyUploadFailedNotConnected userInfo:nil];
        [PEXFileTransferException raise:PEXFileTransferNotConnectedException format:@"Not connected"];
    }
}

- (void)doCancel {
    _wasCancelled = YES;
    [self cancel];

    // TODO: implement.
}


@end