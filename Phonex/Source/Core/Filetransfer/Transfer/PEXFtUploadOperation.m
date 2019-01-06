//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtUploadOperation.h"
#import "PEXFtTransferManager.h"
#import "PEXService.h"
#import "PEXCanceller.h"
#import "PEXDhKeyHelper.h"
#import "PEXSipUri.h"
#import "PEXDbContentProvider.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDBMessage.h"
#import "PEXCancelledException.h"
#import "PEXFileTransferException.h"
#import "PEXFtResult.h"
#import "PEXFtUploadException.h"
#import "PEXDbUserCertificate.h"
#import "PEXTransferProgressWithBlock.h"
#import "PEXDHCalls.h"
#import "NSError+PEX.h"
#import "PEXDhKeyGenManager.h"
#import "PEXFtUploadEntry.h"
#import "PEXFtUploadParams.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXMessageDigest.h"
#import "PEXAmpDispatcher.h"
#import "PEXFtHolder.h"
#import "PEXCryptoUtils.h"
#import "PEXFileToSendEntry.h"
#import "PEXDbFileTransfer.h"
#import "PEXDbReceivedFile.h"
#import "PEXMessageManager.h"
#import "PEXSystemUtils.h"
#import "PEXUtils.h"

const NSInteger PEXFtErrorUploadFailed              = 9001;
const NSInteger PEXFtErrorUploadFailedNotConnected  = 9002;
const NSInteger PEXFtErrorUploadFailedException     = 9003;

@interface PEXFtUploadState : NSObject {}
@property(nonatomic) int64_t                     msgId;
@property(nonatomic) int64_t                     queueMsgId;
@property(nonatomic) NSString                  * nonce2;
@property(nonatomic) NSData                    * nonce2b;
@property(nonatomic) NSString                  * destination;
@property(nonatomic) PEXDbMessage              * msg;

@property(nonatomic) PEXFtUploadParams         * params;
@property(nonatomic) PEXPbGetDHKeyResponseBodySCip * resp1;
@property(nonatomic) hr_ftGetDHKeyPart2Response    * getKeyResponse2;

@property(nonatomic) PEXDbUserCertificate      * senderCrt;
@property(nonatomic) PEXDhKeyHelper            * dhelper;
@property(nonatomic) PEXFtHolder               * ftHolder;
@property(nonatomic) PEXFtUploadResult         * updResult;
@property(nonatomic) PEXFtPreUploadFilesHolder * preUploadHolder;

@property(nonatomic) NSNumber                  * transferRecordId;
@property(nonatomic) PEXDbFileTransfer         * transferRecord;

@property(nonatomic) BOOL                      operationSuccessful;
@property(nonatomic) BOOL                      recoverableFault;
@property(nonatomic) PEXFtError                errCode;
@property(nonatomic, copy) dispatch_block_t    throwIfCancel;
@property(nonatomic, copy) cancel_block        cancelBlock;
@end

@interface PEXFtUploadOperation() {
    volatile BOOL _wasCancelled;
    NSString *_domain;
    PEXFtUploadState * _uState;
    PEXFtUploadEntry * _curEntry;
}

@property(nonatomic) NSError * opError;
@property(nonatomic) PEXService * svc;
@property(nonatomic) BOOL interruptedDueToConnectionError;
@end

@implementation PEXFtUploadOperation {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.showNotifications   = NO;
        self.writeErrorToMessage = YES;
        self.deleteFromServer    = YES;
        _wasCancelled = NO;
        _interruptedDueToConnectionError = NO;
    }

    return self;
}

- (instancetype)initWithMgr:(PEXFtTransferManager *)mgr privData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.mgr = mgr;
        self.privData = privData;
    }

    return self;
}

+ (instancetype)operationWithMgr:(PEXFtTransferManager *)mgr privData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithMgr:mgr privData:privData];
}

- (void)doCancel {
    _wasCancelled = YES;
    [self cancel];

    // TODO: implement.
}

/**
* Receive connectivity changes so we can react on this.
*/
- (void)onCancelEvent:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    NSNumber * cancelId = notification.userInfo[PEX_EXTRA_FTRANSFET_DO_CANCEL_TRANSFER_ID];
    if (cancelId == nil) {
        return;
    }

    if (_curEntry!=nil && [cancelId isEqualToNumber: _curEntry.params.msgId]) {
        _curEntry.cancelled = YES;
    }
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
            _opError = [NSError errorWithDomain:PEXFtErrorDomain code:PEXFtErrorUploadFailedException userInfo:@{PEXExtraException : e}];
        }
    }
}

- (void)runInternal {
    _wasCancelled = NO;
    _interruptedDueToConnectionError = NO;
    _svc = [PEXService instance];
    _domain = [PEXSipUri getDomainFromSip:_privData.username parsed:nil];

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXUserPrivate * privData = self.privData;
    if (privData == nil){
        DDLogWarn(@"Priv data is nil!");
        return;
    }

    // Register to message receiver, react on cancellation requests.
    NSNotificationCenter * notifCtr = [NSNotificationCenter defaultCenter];
    [notifCtr addObserver:self selector:@selector(onCancelEvent:) name:PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER object:nil];

    /**
    * While there are some files to download.
    */
    while (![self wasCancelled] && ![_mgr isUploadQueueEmpty]){
        @autoreleasepool {
            _curEntry = [_mgr pollUploadQueue];
            if (_curEntry == nil || _curEntry.params == nil) {
                continue;
            }

            if (_curEntry.cancelled) {
                [PEXDbMessage deleteById:cr messageId:(uint64_t) [_curEntry.params.msgId longLongValue]];
                continue;
            }

            // Process this single request.
            @try {
                [self processMessage:_curEntry];
            } @catch(NSException * e){
                DDLogError(@"Uncaught exception in process message");
            }

            PEXMessageManager * msgMgr = [PEXMessageManager instance];
            [msgMgr onTransferFinished:_uState.msgId queueMsgId:_uState.queueMsgId statusOk:_uState.operationSuccessful recoverable:_uState.recoverableFault];
        }
    }

    // Unregister mesage receiver (cancellation events).
    [notifCtr removeObserver:self];
    DDLogInfo(@"Finished properly");
}

-(void) loadCrt: (PEXDbContentProvider *) cr {
    // Loads remote party certificate.
    _uState.senderCrt = [PEXDbUserCertificate newCertificateForUser:_uState.params.destinationSip cr:cr projection:[PEXDbUserCertificate getFullProjection]];
    if(_uState.senderCrt == nil){
        DDLogError(@"Could not find certificate for %@", _uState.params.destinationSip);
        [self publishError:_uState.msgId error:PEX_FT_ERROR_CERTIFICATE_MISSING];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"No stored certificate for user=%@", _uState.params.destinationSip];
    }
}

-(void) prepareDhelper {
    // initialize DHKeyHelper for processing the protocol
    _uState.dhelper = [[PEXDhKeyHelper alloc] init];
    _uState.dhelper.privData    = _privData;
    _uState.dhelper.mySip       = _privData.username;
    _uState.dhelper.myCert      = _privData.cert;
    _uState.dhelper.privKey     = _privData.privKey;
    _uState.dhelper.connectionTimeoutMilli = 30000; // TODO: make timeouts to work.
    _uState.dhelper.readTimeoutMilli = 30000;       // TODO: make timeouts to work.
    _uState.dhelper.userSip     = _uState.params.destinationSip;
    _uState.dhelper.sipCert     = _uState.senderCrt.getCertificateObj;
    _uState.dhelper.canceller   = _canceller;
    _uState.dhelper.cancelBlock = _uState.cancelBlock;
}

-(void) getKeyPart1 {
    // Request DH pub key part, part 1
    [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_DOWNLOADING_KEYS progress:-1];
    hr_ftGetDHKeyResponse * getKey1Resp = nil;
    PEXFtResult * mres = [self getDHKeyPart1:_uState.params.destinationSip response:&getKey1Resp];
    _uState.throwIfCancel();

    if ([PEXFtResult wasError:mres] || getKey1Resp == nil){
        _uState.recoverableFault = YES;
        DDLogError(@"Could not get DH keys: %@", mres);

        [self publishError:_uState.msgId error: PEX_FT_ERROR_BAD_RESPONSE];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"Bad response, try again later"];
    }

    if ([getKey1Resp.errCode integerValue] < 0){
        DDLogWarn(@"Received negative error code (%@)", getKey1Resp.errCode);

        [self publishError:_uState.msgId error:PEX_FT_ERROR_UPD_NO_AVAILABLE_DHKEYS];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"Cannot get response keys"];
    }

    // get msg1(dh_group_id, g^x, nonce_1, sig_1)
    _uState.resp1 = [_uState.dhelper getDhKeyResponse:getKey1Resp.aEncBlock];

    // verify sig_1
    if (![_uState.dhelper verifySig1:_uState.resp1 nonce2:nil signature:_uState.resp1.sig1]){
        DDLogWarn(@"sig_1 verification failed");

        [self publishError:_uState.msgId error:PEX_FT_ERROR_SECURITY_ERROR];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"sig_1 is not correct"];
    }
}

-(void) getKeyPart2{
    hr_ftGetDHKeyPart2Response * getKeyResponse2 = nil;
    NSString * nonce1hashed = [[PEXMessageDigest sha256Message:_uState.resp1.nonce1] base64EncodedStringWithOptions:0];
    PEXFtResult * mres = [self getDHKeyPart2:_uState.params.destinationSip nonce1:nonce1hashed response:&getKeyResponse2];
    if ([PEXFtResult wasError:mres] || getKeyResponse2 == nil){
        _uState.recoverableFault = YES;
        DDLogError(@"Could not get DH keys: %@", mres);

        [self publishError:_uState.msgId error: PEX_FT_ERROR_BAD_RESPONSE];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"Bad response, try again later"];
    }

    _uState.getKeyResponse2 = getKeyResponse2;
    if ([_uState.getKeyResponse2.errCode integerValue] < 0){
        DDLogWarn(@"Received negative error code (%@)", _uState.getKeyResponse2.errCode);

        [self publishError:_uState.msgId error:PEX_FT_ERROR_GENERIC_ERROR];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"Cannot get response keys"];
    }
}

-(void) sigVerify {
    // Read nonce2 from last message of the GetKey protocol (will be file identifier).
    _uState.nonce2  = _uState.getKeyResponse2.nonce2;
    _uState.nonce2b = [[NSData alloc] initWithBase64EncodedData:[_uState.nonce2 dataUsingEncoding:NSASCIIStringEncoding] options:0];

    // Verification of the Signature2 (contains also nonce2).
    NSData * sig2 = [_uState.dhelper getDhPart2Response:_uState.getKeyResponse2.sig2];
    if (![_uState.dhelper verifySig1:_uState.resp1 nonce2:_uState.getKeyResponse2.nonce2 signature:sig2]){
        DDLogWarn(@"sig_2 verification failed");

        [self publishError:_uState.msgId error:PEX_FT_ERROR_SECURITY_ERROR];
        [PEXFtUploadException raise:PEXFileTransferGenericException format:@"sig_1 is not correct"];
    }
}

-(void) storeTransferRecord {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbFileTransfer    * tr = [[PEXDbFileTransfer alloc] init];

    tr.nonce2     = _uState.nonce2;
    tr.messageId  = @(_uState.msgId);
    tr.isOutgoing = @(YES);

    // No crypto material is needed since we do not support
    if (_uState.ftHolder != nil && _uState.ftHolder.c != nil) {
        tr.nonce1 = _uState.ftHolder.nonce1;
        tr.nonceb = [_uState.ftHolder.nonceb base64EncodedStringWithOptions:0];
        tr.salt1  = [_uState.ftHolder.salt1  base64EncodedStringWithOptions:0];
        tr.saltb  = [_uState.ftHolder.saltb  base64EncodedStringWithOptions:0];
        tr.c      = [_uState.ftHolder.c      base64EncodedStringWithOptions:0];
    }

    tr.numOfFiles   = _uState.preUploadHolder == nil ? nil : @([_uState.preUploadHolder.files2send count]);
    tr.title        = _uState.preUploadHolder == nil ? nil : _uState.preUploadHolder.mf.title;
    tr.descr        = _uState.preUploadHolder == nil ? nil : _uState.preUploadHolder.mf.xdescription;
    tr.thumb_dir    = [_uState.dhelper getThumbDirectory];
    tr.deletedFromServer = @(NO);
    tr.dateCreated  = [NSDate date];
    tr.dateFinished = nil;
    tr.statusCode   = @(0);

    // Fields for upload resumption.
    tr.uKeyData = _uState.ftHolder.ukeyData;
    tr.metaPrepRec = _uState.ftHolder.filePrepRec[PEX_FT_META_IDX];
    tr.packPrepRec = _uState.ftHolder.filePrepRec[PEX_FT_ARCH_IDX];

    tr.metaFile    = _uState.ftHolder.filePath[PEX_FT_META_IDX];
    tr.packFile    = _uState.ftHolder.filePath[PEX_FT_ARCH_IDX];

    tr.metaHash    = [_uState.ftHolder.fileHash[PEX_FT_META_IDX] base64EncodedStringWithOptions:0];
    tr.packHash    = [_uState.ftHolder.fileHash[PEX_FT_ARCH_IDX] base64EncodedStringWithOptions:0];

    tr.metaSize    = _uState.ftHolder.fileSize[PEX_FT_META_IDX];
    tr.packSize    = _uState.ftHolder.fileSize[PEX_FT_ARCH_IDX];

    tr.metaState = @(PEX_FT_FILEDOWN_TYPE_NONE);
    tr.packState = @(PEX_FT_FILEDOWN_TYPE_NONE);
    tr.shouldDeleteFromServer = @(NO);

    PEXDbUri const * const insUri = [cr insert:[PEXDbFileTransfer getURI] contentValues:[tr getDbContentValues]];
    _uState.transferRecord        = tr;
    _uState.transferRecordId      = insUri.itemId;
    DDLogVerbose(@"FileTransfer record stored. id=%@, obj=%@", insUri.itemId, tr);
}

-(void) recoverFromTransferRecord {
    PEXDbFileTransfer * tr = _uState.transferRecord;
    PEXFtHolder       * ft = [[PEXFtHolder alloc] init];
    _uState.nonce2         = tr.nonce2;
    ft.nonce2 = [NSData dataWithBase64EncodedString: _uState.nonce2];
    ft.c      = tr.c      == nil ? nil : [NSData dataWithBase64EncodedString: tr.c];
    ft.nonce1 = tr.nonce1 == nil ? nil : tr.nonce1;
    ft.nonceb = tr.nonceb == nil ? nil : [NSData dataWithBase64EncodedString: tr.nonceb];
    ft.salt1  = tr.salt1  == nil ? nil : [NSData dataWithBase64EncodedString: tr.salt1];
    ft.saltb  = tr.saltb  == nil ? nil : [NSData dataWithBase64EncodedString: tr.saltb];
    _uState.destination = [PEXSipUri getCanonicalSipContact:_uState.msg.to includeScheme:NO];

    // Fields for upload resumption.
    ft.ukeyData                     = tr.uKeyData;
    ft.filePrepRec[PEX_FT_META_IDX] = tr.metaPrepRec;
    ft.filePrepRec[PEX_FT_ARCH_IDX] = tr.packPrepRec;

    ft.filePath[PEX_FT_META_IDX]    = tr.metaFile;
    ft.filePath[PEX_FT_ARCH_IDX]    = tr.packFile;

    if (tr.metaHash != nil){
        ft.fileHash[PEX_FT_META_IDX]    = [NSData dataWithBase64EncodedString:tr.metaHash];
    }
    
    if (tr.packHash != nil){
        ft.fileHash[PEX_FT_ARCH_IDX]    = [NSData dataWithBase64EncodedString:tr.packHash];
    }

    ft.fileSize[PEX_FT_META_IDX]    = tr.metaSize;
    ft.fileSize[PEX_FT_ARCH_IDX]    = tr.packSize;

    [self loadCrt:[PEXDbAppContentProvider instance]];
    [self prepareDhelper];
    [_uState.dhelper computeCi:ft];
    _uState.ftHolder = ft;
}

-(void) storeTransferedFiles {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Now store new record for each sent file.
    for(PEXFtFileEntry * fe in _uState.preUploadHolder.files2send){
        PEXDbReceivedFile * dbrcv = [[PEXDbReceivedFile alloc] init];
        dbrcv.nonce2     = _uState.nonce2;
        dbrcv.msgId      = @(_uState.msgId);
        dbrcv.transferId = _uState.transferRecordId;
        dbrcv.fileName   = fe.fname;
        dbrcv.mimeType   = fe.metaMsg.mimeType;
        dbrcv.fileHash   = [fe.sha256 base64EncodedStringWithOptions:0];
        dbrcv.fileMetaHash = [fe.sha256 base64EncodedStringWithOptions:0];
        dbrcv.title      = fe.metaMsg.title;
        dbrcv.desc       = fe.metaMsg.desc;
        dbrcv.path       = [fe.file absoluteString];
        dbrcv.isAsset    = @(fe.isAsset);
        dbrcv.size       = @(fe.size);
        dbrcv.prefOrder  = @(fe.metaMsg.prefOrder);
        dbrcv.dateReceived  = [NSDate date];
        dbrcv.thumbFileName = nil;
        dbrcv.recordType    = @(PEX_RECV_FILE_FULL);
        PEXDbUri const * const fileUri = [cr insert:[PEXDbReceivedFile getURI] contentValues:[dbrcv getDbContentValues]];
        if (fileUri == nil || fileUri.itemId == nil){
            DDLogError(@"DbFileTransferFile insert failed, obj=%@", dbrcv);
        } else {
            DDLogVerbose(@"Uploaded file stored to DbFileTransferFile, id=%@, obj=%@", fileUri.itemId, dbrcv);
        }
    }
}

-(void) storeTransferSuccessful {
    if (_uState.transferRecordId == nil){
        DDLogError(@"Cannot store transfer successful record, transfer record ID is nil");
        return;
    }

    _uState.transferRecord.metaState = @(PEX_FT_FILEDOWN_TYPE_DONE);
    _uState.transferRecord.packState = @(PEX_FT_FILEDOWN_TYPE_DONE);
    _uState.transferRecord.packHash = @"";
    _uState.transferRecord.metaHash = @"";
    _uState.transferRecord.dateFinished = [NSDate date];

    // Clear crypto material, not needed in DB anymore.
    [_uState.transferRecord clearCryptoMaterial];
    [self updateFtRecord];
}

-(BOOL) updateFtRecord {
    if (_uState.transferRecord == nil || _uState.transferRecordId == nil){
        DDLogError(@"Cannot update file transfer progress, nil encountered");
        return NO;
    }

    return [[PEXDbAppContentProvider instance] update:[PEXDbFileTransfer getURI]
                                        ContentValues:[_uState.transferRecord getDbContentValues]
                                            selection:[NSString stringWithFormat: @"WHERE %@=?", PEX_DBFT_FIELD_ID]
                                        selectionArgs:@[[_uState.transferRecordId stringValue]]];
}

-(void) processMessage: (PEXFtUploadEntry *) e {
    _uState = [[PEXFtUploadState alloc] init];
    _uState.msgId = [e.params.msgId longLongValue];
    _uState.queueMsgId = [e.params.queueMsgId longLongValue];
    _uState.params = e.params;
    _uState.operationSuccessful = NO;
    e.processingStarted = YES;
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_INITIALIZATION progress:-1];

    // Simple cancelling detection.
    __weak __typeof(self) weakSelf = self;
    __weak __typeof(e)    weakE    = e;
    _uState.throwIfCancel = ^{
        [weakSelf checkIfCancelled];
        if (weakE.cancelled){
            [PEXCancelledException raise:PEXFileTransferGenericException format:@"Operation cancelled"];
        }
    };

    _uState.cancelBlock = ^BOOL {
        return [weakSelf wasCancelled] || weakE.cancelled;
    };

    PEXTransferProgressWithBlock *txProgress = [PEXTransferProgressWithBlock blockWithProgressBlock:^(NSNumber *partial, double total) {
        [weakSelf.mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_UPLOADING progress:MIN((int) (ceil(total * 100.0)), 100)];
    }];

    // Define input file processing progress monitor.
    PEXTransferProgressWithBlock *procProgress = [PEXTransferProgressWithBlock blockWithProgressBlock:^(NSNumber *partial, double total) {
        [weakSelf.mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_ENCRYPTING_FILES progress:MIN((int) (ceil(total * 100.0)), 100)];
    }];

    @try {
        // Fetch message from database.
        _uState.msg = [PEXDbMessage initById:cr messageId:_uState.msgId];

        // Try to recover file transfer state so we can support upload resumption.
        PEXDbFileTransfer * ftTmp = [[PEXDbFileTransfer alloc] initWithNonce2:_uState.nonce2 msgId:_uState.msgId cr:cr];
        if (ftTmp != nil){
            _uState.transferRecord   = ftTmp;
            _uState.transferRecordId = ftTmp.id;

            // Recover crypto state from file transfer record.
            _uState.throwIfCancel();
            [self recoverFromTransferRecord];
            DDLogVerbose(@"FT record restored from DB for %@, msgId: %lld", _uState.nonce2, _uState.msgId);
        }

        // Do key compute if necessary.
        if (_uState.transferRecord == nil || ![_uState.transferRecord isKeyComputingDone]) {
            DDLogVerbose(@"Upload key computation phase started");
            _uState.throwIfCancel();

            [self loadCrt:cr];
            [self prepareDhelper];

            // Get DH key part 1.
            [self getKeyPart1];

            // Was operation cancelled?
            _uState.throwIfCancel();

            // Get DH key part 2
            [self getKeyPart2];

            // Was operation cancelled?
            _uState.throwIfCancel();

            DDLogVerbose(@"Key verification started");
            [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_KEY_VERIFICATION progress:-1];

            // Verify key correctness.
            [self sigVerify];

            //
            // Key is loaded from the server, can continue with upload.
            //

            // AT first, initialize FTKey holder, it generates encryption keys
            // for the file transfer protocol.
            DDLogVerbose(@"Generating encryption keys");
            [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_COMPUTING_ENC_KEYS progress:-1];
            _uState.ftHolder = [_uState.dhelper createFTHolder:_uState.resp1 nonce2:_uState.nonce2b];

            // Was operation cancelled?
            _uState.throwIfCancel();

            // Process files to send (holder gets initialized by those).
            DDLogVerbose(@"Going to proces input files");
            [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_ENCRYPTING_FILES progress:-1];

            _uState.dhelper.txprogress = procProgress;
            _uState.preUploadHolder = [_uState.dhelper ftSetFilesToSend:_uState.ftHolder params:_uState.params];
            // Store transfer record after all key material was derived. Checkpoint for state recovery.
            [self storeTransferRecord];
            // Store all transfer files to database so they can be forwarded.
            // It has to be done with preUploadHandler, after recovery on backof this information is
            // not available anymore.
            [self storeTransferedFiles];
        }

        // If file was not uploaded successfully.
        _uState.throwIfCancel();
        if (_uState.transferRecord == nil || ![_uState.transferRecord isPackDone]) {
            [PEXDbMessage setMessageType:cr messageId:_uState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING_FILES];

            @try {
                // Upload files to the server.
                DDLogVerbose(@"Going to upload file");
                [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_UPLOADING progress:-1];

                // Was operation cancelled?
                _uState.throwIfCancel();

                // Set progress monitor to the DHKeyHelper.
                _uState.dhelper.txprogress = txProgress;
                _uState.dhelper.debug = NO;
                _uState.updResult = [_uState.dhelper uploadFile:_uState.ftHolder];

                BOOL uploadSuccess = [_uState.dhelper wasUploadSuccessful:_uState.updResult];
                if (!uploadSuccess) {
                    _uState.recoverableFault = YES;
                    DDLogInfo(@"Upload was not successful!");

                    // Cancelled?
                    if (_uState.updResult.uploaderFinishCode == kWAIT_RESULT_CANCELLED){
                        _uState.recoverableFault = NO;
                        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];

                    } else if (_uState.updResult.uploaderFinishCode == kWAIT_RESULT_TIMEOUTED || [PEXUtils isErrorWithConnectivity:_uState.updResult.error]){
                        [self publishError:_uState.msgId error:PEX_FT_ERROR_TIMEOUT];
                        DDLogVerbose(@"Operation timed out");
                        return;
                    }

                    // Handle particular error code.
                    [self uploadFailed];
                    return;
                }

                // Remove temporary files on success, they are not needed anymore.
                [_uState.dhelper cleanFiles:_uState.ftHolder];

                // store nonce2 in SipMessage (may be useful when resending)
                PEXDbContentValues *cv = [[PEXDbContentValues alloc] init];
                [cv put:PEXDBMessage_FIELD_FILE_NONCE string:_uState.nonce2];
                [cv put:PEXDBMessage_FIELD_RANDOM_NUM int64:[PEXCryptoUtils secureRandomUInt32:YES]];  // also set SipMessage nonce id (required for read-acknowledgment.
                [PEXDbMessage updateMessage:cr messageId:_uState.msgId contentValues:cv];

                // Store FileTransfer & ReceivedFiles records.
                [self storeTransferSuccessful];
                _uState.operationSuccessful = YES;
            } @catch (PEXOperationCancelledException *ccex) {
                // Operation was cancelled - will be handled later
                @throw ccex;

            } @catch (PEXFtUploadException *ue) {
                // Upload exception - error was published.

            } @catch (NSException *ex) {
                // Generic exception.
                DDLogError(@"Exception in a upload process. exception=%@", ex);
                [self publishError:_uState.msgId error:PEX_FT_ERROR_GENERIC_ERROR];
            }
        }

        [_mgr publishProgress:_uState.msgId title:PEX_FT_PROGRESS_SENDING_NOTIFICATION progress:100];
        [self postUpload:_uState.msgId];

        // Final progress update.
        PEXFtProgress * progress = [[PEXFtProgress alloc] initWithMessageId:_uState.msgId progressCode:PEX_FT_PROGRESS_DONE progress:100];
        progress.done = YES;
        [_mgr publishProgress:progress];

        // Change state if no error.
        [PEXDbMessage setMessageType:cr messageId:_uState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADED];
    } @catch (PEXOperationCancelledException * cex){

        DDLogInfo(@"Operation was cancelled");
        [PEXDbMessage deleteById:cr messageId:_uState.msgId];
        return;

    } @catch (NSException * e) {
        DDLogError(@"Exception during file upload %@", e);
        return;
    }

    if (_uState.recoverableFault){
        DDLogInfo(@"Seems error is recoverable, we should try it later, several times");
    }

    // Change state if no error.
//    if (!errorOcurred){
//        [PEXDbMessage setMessageType:cr messageId:msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED];
//    }

    // After download, trigger DH key resync.
    // Download means somebody used our key, thus we
    // have to generate new ones.
    [PEXDhKeyGenManager triggerUserCheck];

    return;
}

/**
* send notification message
* @param messageId SipMessage id where nonce2 and filename is stored
*/
-(void) postUpload: (int64_t) messageId {
    @try {
        [PEXAmpDispatcher dispatchNewFileNotificationWithID:messageId];
    } @catch (NSException * e) {
        DDLogError(@"Notification message failed, exception=%@", e);
    }
}

-(void) uploadFailed {
    // Get error code
    NSInteger errCode = [_uState.dhelper getUploadErrorCode:_uState.updResult];
    if (errCode == -2) {
        // No such key on the server side.
        [self publishError:_uState.msgId error:PEX_FT_ERROR_UPD_UPLOAD_ERROR];
    } else if (errCode == -8) {
        // Quota exceeded.
        [self publishError:_uState.msgId error:PEX_FT_ERROR_UPD_QUOTA_EXCEEDED];
        _uState.recoverableFault = NO;
    } else if (errCode == -10) {
        // Quota exceeded.
        [self publishError:_uState.msgId error:PEX_FT_ERROR_UPD_FILE_TOO_BIG];
        _uState.recoverableFault = NO;
    } else {
        // Generic error
        [self publishError:_uState.msgId error:PEX_FT_ERROR_UPD_UPLOAD_ERROR];
    }

    DDLogVerbose(@"Operation error code=%ld", (long) errCode);
}

/**
* Wrapper for SOAP call getStoredFiles. Retry counter 3.
*/
-(PEXFtResult *) getDHKeyPart1: (NSString *) user response: (hr_ftGetDHKeyResponse **) resp {
    // Try to upload keys for several times until it succeeds.
    BOOL opSuccessful = NO;
    NSInteger curRetry = 0;
    PEXFtResult * mres;
    hr_ftGetDHKeyResponse * tmpResp = nil;

    for(; curRetry < 3; curRetry++) {
        _uState.throwIfCancel();

        // Cancellation & connectivity check.
        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            if (_interruptedDueToConnectionError){
                [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorUploadFailedNotConnected userInfo:nil];
            }
            break;
        }

        PEXDHCalls *call = [PEXDHCalls callsWithPrivData:_privData canceller: _canceller];
        mres = [call getDHKeysPart1:user domain:nil response:&tmpResp];
        if ([PEXFtResult wasError:mres] || tmpResp == nil){
            // Negative code means error so as empty response.
            DDLogError(@"Could not obtain DH key from server code=%ld, resp=%@, taskError=%d", (long)mres.code, tmpResp, (int) mres.soapTaskError);
            continue;
        }

        opSuccessful = YES;
        break;
    }

    if (opSuccessful){
        *resp = tmpResp;
    }

    return mres;
}

/**
* Wrapper for SOAP call getStoredFiles. Retry counter 3.
*/
-(PEXFtResult *) getDHKeyPart2: (NSString *) user nonce1: (NSString *) nonce1 response: (hr_ftGetDHKeyPart2Response **) resp {
    // Try to upload keys for several times until it succeeds.
    BOOL opSuccessful = NO;
    NSInteger curRetry = 0;
    PEXFtResult * mres;
    hr_ftGetDHKeyPart2Response * tmpResp = nil;

    for(; curRetry < 3; curRetry++) {
        _uState.throwIfCancel();

        // Cancellation & connectivity check.
        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            if (_interruptedDueToConnectionError){
                [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorUploadFailedNotConnected userInfo:nil];
            }
            break;
        }

        PEXDHCalls *call = [PEXDHCalls callsWithPrivData:_privData canceller: _canceller];
        mres = [call getDHKeysPart2:user nonce1:nonce1 domain:nil response:&tmpResp];
        if ([PEXFtResult wasError:mres] || tmpResp == nil){
            // Negative code means error so as empty response.
            DDLogError(@"Could not obtain DH key2 from server code=%ld, resp=%@, taskError=%d", (long)mres.code, tmpResp, (int) mres.soapTaskError);
            continue;
        }

        opSuccessful = YES;
        break;
    }

    if (opSuccessful){
        *resp = tmpResp;
    }

    return mres;
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
* Publishes error occurred in transfer.
* @param msgid
* @param error
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error{
    [_mgr publishError:msgid error:error isUpload:YES];
}

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
* @param errCode
* @param errString
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error errCode: (NSNumber *) errCode errString: (NSString *) errString nsError: (NSError *) nserror{
    [_mgr publishError:msgid error:error errCode:errCode errString:errString nsError:nserror isUpload:YES];
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
        [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorUploadFailedNotConnected userInfo:nil];
        [PEXFileTransferException raise:PEXFileTransferNotConnectedException format:@"Not connected"];
    }
}

@end

@implementation PEXFtUploadState
- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}

@end