//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtDownloadOperation.h"
#import "PEXFtTransferManager.h"
#import "PEXCanceller.h"
#import "NSError+PEX.h"
#import "PEXDhKeyHelper.h"
#import "PEXDbContentProvider.h"
#import "PEXDbAppContentProvider.h"
#import "PEXCancelledException.h"
#import "PEXService.h"
#import "PEXFileTransferException.h"
#import "PEXDHKeyGenOperation.h"
#import "PEXFtDownloadEntry.h"
#import "PEXDBMessage.h"
#import "PEXFtDownloadFileParams.h"
#import "PEXSipUri.h"
#import "hr.h"
#import "PEXDHCalls.h"
#import "PEXFtResult.h"
#import "PEXStringUtils.h"
#import "PEXDhKeyGenManager.h"
#import "PEXDbDhKey.h"
#import "PEXDbUserCertificate.h"
#import "PEXFtHolder.h"
#import "PEXFtDownloadException.h"
#import "PEXTransferProgress.h"
#import "PEXTransferProgressWithBlock.h"
#import "PEXDbReceivedFile.h"
#import "PEXUtils.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXDbFileTransfer.h"
#import "PEXMessageManager.h"
#import "PEXSystemUtils.h"

const NSInteger PEXFtErrorDownloadFailed              = 8001;
const NSInteger PEXFtErrorDownloadFailedNotConnected  = 8002;
const NSInteger PEXFtErrorDownloadFailedException     = 8003;
const NSInteger PEXDownloadOnWifiThreshold            = 1024 * 1024 * 3;

@interface PEXFtDownloadState : NSObject {}
@property(nonatomic) int64_t                   msgId;
@property(nonatomic) int64_t                   queueMsgId;
@property(nonatomic) NSString                * nonce2;
@property(nonatomic) NSString                * sender;
@property(nonatomic) PEXDbMessage            * msg;

@property(nonatomic) PEXFtDownloadFileParams * params;
@property(nonatomic) hr_ftStoredFile         * storedFile;
@property(nonatomic) PEXDbDhKey              * dhOffline;
@property(nonatomic) PEXDbUserCertificate    * senderCrt;
@property(nonatomic) PEXDhKeyHelper          * dhelper;
@property(nonatomic) PEXFtHolder             * ftHolder;
@property(nonatomic) PEXFtFileDownloadResult * downResult;
@property(nonatomic) PEXFtUnpackingResult    * unpackResult;
@property(nonatomic) BOOL                      deleteOnly;
@property(nonatomic) BOOL                      deletedFromServer;
@property(nonatomic) BOOL                      downloadPackRightNow;
@property(nonatomic) PEXPbMetaFile           * metaFile;
@property(nonatomic) NSMutableArray          * transferFiles;
@property(nonatomic) NSNumber                * transferRecordId;
@property(nonatomic) PEXDbFileTransfer       * transferRecord;

@property(nonatomic) NSMutableArray          * filePaths;
@property(nonatomic) BOOL                      didErrorOccurr;
@property(nonatomic) BOOL                      didTimeout;
@property(nonatomic) BOOL                      didCancel;
@property(nonatomic) BOOL                      didMacFail;
@property(nonatomic) BOOL                      recoverableFault;
@property(nonatomic) PEXFtError                errCode;
@property(nonatomic, copy) dispatch_block_t    throwIfCancel;
@property(nonatomic, copy) cancel_block        cancelBlock;
@end

@interface PEXFtDownloadOperation () {
    volatile BOOL _wasCancelled;
    NSString * _domain;
    PEXFtDownloadState * _dState;
    PEXFtDownloadEntry * _curEntry;
}

@property(nonatomic) NSError * opError;
@property(nonatomic) PEXService * svc;
@property(nonatomic) BOOL interruptedDueToConnectionError;
@end

@implementation PEXFtDownloadOperation {}
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
            _opError = [NSError errorWithDomain:PEXFtErrorDomain code:PEXFtErrorDownloadFailedException userInfo:@{PEXExtraException : e}];
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
        DDLogError(@"Priv data is nil!");
        return;
    }

    // Register to message receiver, react on cancellation requests.
    NSNotificationCenter * notifCtr = [NSNotificationCenter defaultCenter];
    [notifCtr addObserver:self selector:@selector(onCancelEvent:) name:PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER object:nil];

    /**
    * While there are some files to download.
    */
    while (![self wasCancelled] && ![_mgr isDownloadQueueEmpty]){
        @autoreleasepool {
            _curEntry = [_mgr pollDownloadQueue];
            if (_curEntry == nil || _curEntry.params == nil) {
                continue;
            }

            if (_curEntry.cancelled) {
                [PEXDbMessage setMessageType:cr messageId:[_curEntry.params.msgId longLongValue] messageType:PEXDBMessage_MESSAGE_TYPE_FILE_READY];
                continue;
            }

            // Process this single FT request.
            @try {
                [self processMessage:_curEntry];
            } @catch(NSException * e){
                DDLogError(@"Uncaught exception in ft processing, exception=%@", e);
            }

            PEXMessageManager * msgMgr = [PEXMessageManager instance];
            [msgMgr onTransferFinished:_dState.msgId queueMsgId:_dState.queueMsgId statusOk:!_dState.didErrorOccurr recoverable:_dState.recoverableFault];

            // After download, trigger DH key resync.
            // Download means somebody used our key, thus we
            // have to generate new ones.
            [PEXDhKeyGenManager triggerUserCheck];
        }
    }

    // Unregister mesage receiver (cancellation events).
    [notifCtr removeObserver:self];
    DDLogInfo(@"Finished properly, nonce2: %@", _dState.nonce2);
}

/**
* Sets message to READY state, or if meta was downloaded, to DOWNLOADED_META.
*/
-(void) setFinalMessageOKType: (PEXDbContentProvider *) cr {
    int messageType = PEXDBMessage_MESSAGE_TYPE_FILE_READY;
    if (_dState.transferRecord != nil && [_dState.transferRecord isMetaDone]){
        messageType = PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META;
    }

    [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:messageType];
}

-(BOOL) loadDbMessage: (PEXDbContentProvider *) cr{
    // Load msg from DB if message is not null.
    if (_dState.msgId < 0) {
        return NO;
    }

    _dState.msg = [PEXDbMessage initById:cr messageId: _dState.msgId];
    if (_dState.msg == nil){
        DDLogError(@"No such message in DB with id: %lld", _dState.msgId);
        return NO;

    } else if (_dState.msg.fileNonce == nil){
        DDLogError(@"No nonce stored within SipMessage, it does not correspont to any uploaded file");
        [self publishError:_dState.msgId error:PEX_FT_ERROR_DOWN_NO_SUCH_FILE_FOR_NONCE];
        return NO;
    }

    // If nonce2 specified by parameter is null, take the one from message.
    if ([PEXStringUtils isEmpty:_dState.nonce2]){
        _dState.nonce2 = _dState.msg.fileNonce;
    } else {
        // If nonce2 is non-null, it has to correspond to the one in message ID.
        if (![_dState.nonce2 isEqualToString:_dState.msg.fileNonce]){
            DDLogWarn(@"Nonce2 from parameter [%@] does not correspond to nonce in msg [%@]", _dState.nonce2, _dState.msg.fileNonce);
        }
    }

    return YES;
}

-(void) loadStoredFilesFromServer {
    // Soap call to load meta data from server - list of files with given nonce.
    //
    hr_ftGetStoredFilesResponse * resp = nil;
    PEXFtResult * mres = [self getStoredFiles:_dState.nonce2 response:&resp];
    _dState.throwIfCancel();

    if ([PEXFtResult wasError:mres] || resp == nil){
        _dState.recoverableFault = YES;

        DDLogError(@"Could not get number of stored files: %@", mres);
        [self setErrorToMsg:PEX_FT_ERROR_BAD_RESPONSE];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"Bad response, try again later"];
    }

    // Response from server - stored files with given nonce2.
    hr_ftStoredFileList * storedFiles = resp.storedFile;
    DDLogInfo(@"%d file(s) stored on server for given nonce [nonce2=%@]", (int) storedFiles.file.count, _dState.nonce2);
    if (storedFiles.file.count <= 0){
        // Non-recoverable fault.
        DDLogError(@"No such file for given nonce: %@", _dState.nonce2);
        [self setErrorToMsg:PEX_FT_ERROR_DOWN_NO_SUCH_FILE_FOR_NONCE];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"No stored file(s) for given nonce2=%@", _dState.nonce2];
    }

    _dState.storedFile = storedFiles.file[0];
    _dState.sender     = [PEXSipUri getCanonicalSipContact:_dState.storedFile.sender includeScheme:NO];
}

-(void) loadCert: (PEXDbContentProvider *) cr {
    // Loads remote party certificate.
    _dState.senderCrt = [PEXDbUserCertificate newCertificateForUser:_dState.sender cr:cr projection:[PEXDbUserCertificate getFullProjection]];
    if(_dState.senderCrt == nil){
        DDLogError(@"Could not find certificate for %@", _dState.sender);
        [self setErrorToMsg:PEX_FT_ERROR_CERTIFICATE_MISSING];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"No stored certificate for user=%@", _dState.sender];
    }
}

-(void) loadKey: (PEXDbContentProvider *) cr {
    // Loads DHkeys for given nonce2.
    _dState.dhOffline = [PEXDbDhKey getByNonce2:_dState.nonce2 cr:cr];
    if (_dState.dhOffline == nil){
        DDLogError(@"Could not find DH keys for nonce2: %@", _dState.nonce2);
        [self setErrorToMsg:PEX_FT_ERROR_DHKEY_MISSING];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"No stored dhkey for given nonce2=%@", _dState.nonce2];
    }
}

-(void) prepareDhelper {
    _dState.dhelper = [[PEXDhKeyHelper alloc] init];
    _dState.dhelper.privData = _privData;
    _dState.dhelper.mySip = _privData.username;
    _dState.dhelper.myCert = _privData.cert;
    _dState.dhelper.privKey = _privData.privKey;
    _dState.dhelper.connectionTimeoutMilli = 30000; // TODO: make timeouts to work.
    _dState.dhelper.readTimeoutMilli = 30000;       // TODO: make timeouts to work.
    _dState.dhelper.userSip = _dState.sender;
    _dState.dhelper.sipCert = _dState.senderCrt.getCertificateObj;
    _dState.dhelper.canceller = _canceller;
    _dState.dhelper.cancelBlock = _dState.cancelBlock;
}

-(void) computeHolder {
    [self prepareDhelper];

    // Create holder for file dependent data
    // Encryption keys will be derived.
    _dState.ftHolder = [_dState.dhelper processFileTransfer:_dState.dhOffline ukey:_dState.storedFile.key];
}

-(void) downloadFile: (NSUInteger)fileTypeIdx allowRedownload: (BOOL) allowRedownload{
    // Key is loaded from the server, can continue with upload.
    __weak __typeof(self) weakSelf = self;
    PEXTransferProgressWithBlock * txprogress = [PEXTransferProgressWithBlock blockWithProgressBlock:
            ^(NSNumber *partial, double total)
            {
                const int pcnts = MIN((int)(ceil(total * 100.0)), 100);
                [weakSelf.mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_DOWNLOADING progress:pcnts];
            }];

    _dState.dhelper.debug = NO;
    _dState.dhelper.txprogress = txprogress;

    // Was transfer cancelled?
    _dState.throwIfCancel();

    //
    // Start download.
    PEXFtFileDownloadResult * downResult = [_dState.dhelper downloadFile:_dState.ftHolder fileIdx:fileTypeIdx allowRedownload:allowRedownload];
    if (downResult.downloaderFinishCode == kWAIT_RESULT_CANCELLED){
        [PEXCancelledException raise:PEXFileTransferGenericException format:@"Operation cancelled"];
    }

    if (downResult.code == 206){
        DDLogInfo(@"Partial content returning;");
    }

    // Handle 404 errors.
    if (downResult.code / 100 == 4){
        _dState.recoverableFault = NO;
        DDLogDebug(@"Return code after download is 400 family: %d, error=%@", (int) downResult.code, downResult.error);
        [_dState.dhelper cleanFiles:_dState.ftHolder];

        [self setErrorToMsg:PEX_FT_ERROR_DOWN_NO_SUCH_FILE_FOR_NONCE errCode:@(downResult.code) errString:nil nsError:nil];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"Download failed, code=%ld", (long)downResult.code];
    }

    if (downResult.downloaderFinishCode == kWAIT_RESULT_TIMEOUTED || downResult.error != nil) {
        _dState.recoverableFault = YES;
        _dState.didTimeout = YES;
    }

    if ((downResult.code / 100) != 2 || downResult.downloaderFinishCode == kWAIT_RESULT_TIMEOUTED || downResult.error != nil){
        _dState.recoverableFault = YES; // may be recoverable.
        DDLogDebug(@"Return code after download: %ld, error=%@", (long)downResult.code, downResult.error);
        [_dState.dhelper cleanFiles:_dState.ftHolder];

        [self setErrorToMsg:PEX_FT_ERROR_DOWN_DOWNLOAD_ERROR errCode:@(downResult.code) errString:nil nsError:nil];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"Download failed, code=%ld", (long)downResult.code];
    }
}

-(void) decryptFile: (NSUInteger)fileTypeIdx {
    // Try to decrypt it.
    BOOL decryptionOk = [_dState.dhelper decryptFile:_dState.ftHolder fileIdx:fileTypeIdx];
    if (!decryptionOk){
        DDLogError(@"Decryption was not successful");
        [PEXDhKeyHelper cleanAllFiles:_dState.ftHolder fileIdx:fileTypeIdx];

        [self setErrorToMsg: PEX_FT_ERROR_DOWN_DECRYPTION_ERROR];
        [PEXFtDownloadException raise:PEXFileTransferGenericException format:@"Decryption error"];
    }
}

-(void) storeTransferRecord {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbFileTransfer    * tr = [[PEXDbFileTransfer alloc] init];

    tr.nonce2 = _dState.nonce2;
    tr.messageId = @(_dState.msgId);
    tr.isOutgoing = @(NO);
    if (_dState.ftHolder != nil && _dState.ftHolder.c != nil) {
        tr.nonce1 = _dState.ftHolder.nonce1;
        tr.nonceb = [_dState.ftHolder.nonceb base64EncodedStringWithOptions:0];
        tr.salt1 = [_dState.ftHolder.salt1 base64EncodedStringWithOptions:0];
        tr.saltb = [_dState.ftHolder.saltb base64EncodedStringWithOptions:0];
        tr.c = [_dState.ftHolder.c base64EncodedStringWithOptions:0];
    }

    tr.numOfFiles   = _dState.transferFiles == nil ? nil : @([_dState.transferFiles count]);
    tr.title        = _dState.metaFile.title;
    tr.descr        = _dState.metaFile.xdescription;
    tr.thumb_dir    = [_dState.dhelper getThumbDirectory];
    tr.deletedFromServer = @(NO);
    tr.dateCreated  = [NSDate date];
    tr.dateFinished = nil;
    tr.statusCode   = @(0);

    tr.metaState = @(PEX_FT_FILEDOWN_TYPE_NONE);
    tr.packState = @(PEX_FT_FILEDOWN_TYPE_NONE);

    // For delete-only case, mark this request so we can handle connection interrupt and crashes.
    if (_dState.deleteOnly) {
        tr.shouldDeleteFromServer = @(YES);
    }

    PEXDbUri const * const insUri = [cr insert:[PEXDbFileTransfer getURI] contentValues:[tr getDbContentValues]];
    _dState.transferRecord        = tr;
    _dState.transferRecordId      = insUri.itemId;
}

-(void) recoverFromTransferRecord {
    PEXDbFileTransfer * tr = _dState.transferRecord;
    PEXFtHolder       * ft = [[PEXFtHolder alloc] init];
    ft.nonce2 = [NSData dataWithBase64EncodedString: _dState.nonce2];
    ft.c      = tr.c      == nil ? nil : [NSData dataWithBase64EncodedString: tr.c];
    ft.nonce1 = tr.nonce1 == nil ? nil : tr.nonce1;
    ft.nonceb = tr.nonceb == nil ? nil : [NSData dataWithBase64EncodedString: tr.nonceb];
    ft.salt1  = tr.salt1  == nil ? nil : [NSData dataWithBase64EncodedString: tr.salt1];
    ft.saltb  = tr.saltb  == nil ? nil : [NSData dataWithBase64EncodedString: tr.saltb];
    _dState.sender = [PEXSipUri getCanonicalSipContact:_dState.msg.from includeScheme:NO];

    [self loadCert:[PEXDbAppContentProvider instance]];
    [self prepareDhelper];
    [_dState.dhelper computeCi:ft];

    _dState.ftHolder = ft;
    _dState.deletedFromServer = tr.deletedFromServer == nil ? NO : [tr.deletedFromServer boolValue];
}

-(void) fetchAndProcessMeta {
    // Download meta file from server. Should be fast, it is a quite small file.
    // One can also stop download after fetching meta object, to limit only to meta file
    // or limit meta file by size.
    DDLogVerbose(@"Going to download meta for %@", _dState.nonce2);
    [self downloadFile:PEX_FT_META_IDX allowRedownload:YES];
    DDLogVerbose(@"Downloaded file name=[%@] length=[%@]",
            _dState.ftHolder.filePath[PEX_FT_META_IDX],
            _dState.ftHolder.fileSize[PEX_FT_META_IDX]);
    _dState.throwIfCancel();

    // Try to decrypt already downloaded file.
    DDLogVerbose(@"Going to decrypt meta for %@", _dState.nonce2);
    [self decryptFile:PEX_FT_META_IDX];
    DDLogVerbose(@"Decrypted file name=[%@] length=[%@]",
            _dState.ftHolder.filePath[PEX_FT_META_IDX],
            _dState.ftHolder.fileSize[PEX_FT_META_IDX]);

    // Process meta message
    @try {
        _dState.metaFile = [_dState.dhelper reconstructMetaFile:_dState.ftHolder];
        DDLogVerbose(@"Meta file fetched: %@", _dState.metaFile);

        [self processMetaFile];
    } @catch(NSException * e){
        DDLogVerbose(@"Meta file could not be parsed, exception=%@", e);

        // Try backward compatible version, without length delimiter.
        _dState.metaFile = [_dState.dhelper reconstructMetaFileOld:_dState.ftHolder];
        DDLogVerbose(@"Meta file (old) fetched: %@", _dState.metaFile);

        [self processMetaFile];
    }
}

-(void) processMetaFile {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Read meta file, extract information about files and construct its representation.
    NSInteger prefOrder = 0;
    for(PEXPbMetaFileDetail * fDetail in _dState.metaFile.files){
        PEXFtDownloadFile * downFile = [PEXFtDownloadFile fileWithMeta:fDetail];
        if ([PEXStringUtils isEmpty:downFile.fileName]){
            DDLogError(@"Downloaded file has empty file name; Cannot process...");
            continue;
        }

        // If prefOrder is not defined, define it here.
        if (downFile.prefOrder == nil){
            downFile.prefOrder = @(prefOrder);
        }

        [_dState.transferFiles addObject:downFile];
        prefOrder += 1;
    }

    // Extract meta file thumb zip if there is such zip file.
    if (       _dState.metaFile != nil
            && _dState.ftHolder.filePath[PEX_FT_META_IDX] != nil
            && [PEXUtils fileExistsAndIsAfile:_dState.ftHolder.filePath[PEX_FT_META_IDX]])
    {
        [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_FILE_EXTRACTION progress:-1];
        [self unpackMetaThumbs];
    }

    // Store results for meta files, with potential thumbs.
    int64_t totalFileSize = 0;
    DDLogVerbose(@"Meta indicates %lu files, nonce2: %@", (unsigned long) [_dState.transferFiles count], _dState.metaFile);
    for(PEXFtDownloadFile * fldwn in _dState.transferFiles){
        @try {
            PEXDbReceivedFile *recvFile = [[PEXDbReceivedFile alloc] init];
            recvFile.nonce2        = _dState.nonce2;
            recvFile.msgId         = @(_dState.msgId);
            recvFile.transferId    = _dState.transferRecordId;
            recvFile.isAsset       = @(NO);
            recvFile.dateReceived  = [NSDate date];
            recvFile.recordType    = @(PEX_RECV_FILE_META);
            recvFile.thumbFileName = fldwn.thumbFname;
            recvFile.fileName      = fldwn.fileName;   // file index.
            recvFile.size          = fldwn.fileSize;
            recvFile.title         = fldwn.title;
            recvFile.desc          = fldwn.desc;
            recvFile.fileMetaHash  = fldwn.xhash == nil ? nil : [fldwn.xhash base64EncodedStringWithOptions:0];
            recvFile.mimeType      = fldwn.mimeType;
            recvFile.prefOrder     = fldwn.prefOrder;

            totalFileSize += [fldwn.fileSize longLongValue];
            PEXDbUri const * const insUri = [cr insert:[PEXDbReceivedFile getURI] contentValues:[recvFile getDbContentValues]];
            if (insUri != nil){
                fldwn.receivedFileId = insUri.itemId;
            }

        } @catch (NSException *e) {
            DDLogError(@"Cannot store downloaded files, exception=%@", e);
        }
    }

    // Decide whether to continue with file download - depending on the file size and connection type.
    if(_dState.params.downloadFullIfOnWifiAndUnderThreshold){
        NetworkStatus netStat = [_svc getCurentNetworkStatus];
        if (netStat == ReachableViaWiFi && totalFileSize < PEXDownloadOnWifiThreshold){
            DDLogVerbose(@"Reachable via WIFI and total file size is less than threshold. Size=%lld", totalFileSize);
            _dState.downloadPackRightNow = YES;
        }
    }
}

-(void) unpackMetaThumbs {
    PEXFtUnpackingOptions *unpackOptions = [[PEXFtUnpackingOptions alloc] init];

    // Overwrite existing thumbs so they are not duplicated over the cache directory if this is
    // repeated download. Thumb name should be unique since it is prepended with nonce2 and unique in zip.
    unpackOptions.actionOnConflict          = PEX_FILECOPY_OVERWRITE;
    unpackOptions.createDirIfMissing        = YES;
    unpackOptions.deleteArchiveOnSuccess    = NO;
    unpackOptions.deleteMetaOnSuccess       = YES;
    unpackOptions.deleteNewFilesOnException = YES;
    unpackOptions.fnamePrefix               = [PEXDhKeyHelper getFilenameFromBase64:_dState.nonce2];
    unpackOptions.destinationDirectory      = [_dState.dhelper getThumbDirectory];
    PEXFtUnpackingResult * thumbUnpackRes   = nil;

    @try {
        thumbUnpackRes = [_dState.dhelper unzipArchiveAtFile:_dState.ftHolder.filePath[PEX_FT_META_IDX] options:unpackOptions];

        // Store extracted file paths to the result structures.
        for (PEXFtUnpackingFile * fl in thumbUnpackRes.files) {
            DDLogVerbose(@"Thumb file: %@", fl.destination);

            // Look for corresponding file.
            BOOL fileFound = NO;
            for(PEXFtDownloadFile * fldwn in _dState.transferFiles){
                if (fl.originalFname == nil || ![fl.originalFname isEqualToString:fldwn.thumbNameInZip]){
                    continue;
                }

                fldwn.thumbFname = [fl.destination lastPathComponent];
                fldwn.thumbPath  = fl.destination;
                fileFound = YES;
                break;
            }

            if (!fileFound){
                DDLogVerbose(@"Corresponding main file not found, removing thumb.");
                [PEXUtils removeFile:fl.destination];
            }
        }
    } @catch(NSException * e){
        DDLogError(@"Exception during thumbs unpacking, exception=%@", e);
    }
}

-(void) fetchAndProcessPack {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Download pack itself.
    DDLogVerbose(@"Going to download pack for %@", _dState.nonce2);
    [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_CONNECTING_TO_SERVER progress:-1];
    [self downloadFile:PEX_FT_ARCH_IDX allowRedownload:YES];
    DDLogVerbose(@"Downloaded name=[%@] length=[%@]",
            _dState.ftHolder.filePath[PEX_FT_ARCH_IDX],
            _dState.ftHolder.fileSize[PEX_FT_ARCH_IDX]);
    _dState.throwIfCancel();

    // Try to decrypt it.
    DDLogVerbose(@"Going to decrypt pack for %@", _dState.nonce2);
    [self decryptFile:PEX_FT_ARCH_IDX];
    DDLogVerbose(@"Decrypted name=[%@] length=[%@]",
            _dState.ftHolder.filePath[PEX_FT_ARCH_IDX],
            _dState.ftHolder.fileSize[PEX_FT_ARCH_IDX]);

    // Was transfer cancelled?
    _dState.throwIfCancel();

    // Extract downloaded files. Obeys policy specified by a parameter.
    [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_FILE_EXTRACTION progress:-1];
    PEXFtUnpackingOptions *unpackOptions    = [[PEXFtUnpackingOptions alloc] init];
    unpackOptions.actionOnConflict          = _dState.params.conflictAction;
    unpackOptions.createDirIfMissing        = _dState.params.createDestinationDirIfNeeded;
    unpackOptions.deleteArchiveOnSuccess    = YES;
    unpackOptions.deleteMetaOnSuccess       = YES;
    unpackOptions.deleteNewFilesOnException = YES;
    unpackOptions.destinationDirectory      = _dState.params.destinationDirectory;
    _dState.unpackResult                    = [_dState.dhelper unzipArchive:_dState.ftHolder options:unpackOptions];

    // Store extracted file paths to the result structures.
    NSUInteger prefOrder = 0;
    for (PEXFtUnpackingFile * fl in _dState.unpackResult.files) {
        DDLogVerbose(@"Extracted file: %@", fl.destination);
        [_dState.filePaths addObject:fl.destination];

        // Look for corresponding file.
        NSNumber * recvFileId = nil;
        for(PEXFtDownloadFile * fldwn in _dState.transferFiles){
            if (fl.originalFname == nil || ![fl.originalFname isEqualToString:fldwn.fileName]){
                continue;
            }

            if (fldwn.receivedFileId == nil){
                continue;
            }

            recvFileId = fldwn.receivedFileId;
            break;
        }

        // Try to fetch this file, it may be already downloaded by meta downloader.
        PEXDbReceivedFile * recvFile = recvFileId == nil ? nil : [[PEXDbReceivedFile alloc] initWithId:recvFileId cr:cr];

        // If is nil, try to download via message id and original file name.
        if (recvFile == nil){
            recvFile = [[PEXDbReceivedFile alloc] initWithMsgId:@(_dState.msgId)  fileName:fl.originalFname cr:cr];
        }

        // If exists, update existing record created during meta upload. If not, something went wrong with meta (skipped?).
        if (recvFile != nil){
            recvFile.path = [[NSURL fileURLWithPath:fl.destination] absoluteString];
            recvFile.size = @([PEXUtils fileSize:fl.destination error:nil]);
            recvFile.fileHash = [fl.sha256 base64EncodedStringWithOptions:0];
            recvFile.recordType = @(PEX_RECV_FILE_FULL);

            [cr update:[PEXDbReceivedFile getURI] ContentValues:[recvFile getDbContentValues]
             selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBRF_FIELD_ID]  selectionArgs:@[[recvFile.id stringValue]]];
        } else {
            // Store received file to the database.
            @try {
                recvFile = [[PEXDbReceivedFile alloc] init];
                recvFile.msgId         = @(_dState.msgId);
                recvFile.transferId    = _dState.transferRecordId;
                recvFile.isAsset       = @(NO);
                recvFile.dateReceived  = [NSDate date];
                recvFile.fileName      = fl.originalFname;
                recvFile.nonce2        = _dState.nonce2;
                recvFile.path          = [[NSURL fileURLWithPath:fl.destination] absoluteString];
                recvFile.fileHash      = [fl.sha256 base64EncodedStringWithOptions:0];
                recvFile.recordType    = @(PEX_RECV_FILE_FULL);
                recvFile.size          = @([PEXUtils fileSize:fl.destination error:nil]);
                recvFile.prefOrder     = @(prefOrder);

                [cr insert:[PEXDbReceivedFile getURI] contentValues:[recvFile getDbContentValues]];
            } @catch (NSException *e) {
                DDLogError(@"Cannot store downloaded files, exception=%@", e);
            }
        }

        prefOrder += 1;
    }
}

-(BOOL) updateFtRecord {
    if (_dState.transferRecord == nil || _dState.transferRecordId == nil){
        DDLogError(@"Cannot update file transfer progress, nil encountered");
        return NO;
    }

    return [[PEXDbAppContentProvider instance] update:[PEXDbFileTransfer getURI]
                                        ContentValues:[_dState.transferRecord getDbContentValues]
                                            selection:[NSString stringWithFormat: @"WHERE %@=?", PEX_DBFT_FIELD_ID]
                                        selectionArgs:@[[_dState.transferRecordId stringValue]]];
}

-(void) setErrorToMsg: (PEXFtError) err {
    [self setErrorToMsg:err errCode:nil errString:nil nsError:nil];
}

-(void) setErrorToMsg: (PEXFtError) err errCode: (NSNumber *) errCode errString: (NSString *) errString nsError: (NSError *) nserror{
    DDLogInfo(@"Error %d set, nonce2: %@, msgId: %lld", err, _dState.nonce2, _dState.msgId);
    _dState.didErrorOccurr = YES;
    _dState.errCode        = err;
    [self publishError:_dState.msgId error:err errCode: errCode errString: errString nsError: nserror];
}

/**
* Main entry method for processing download request.
*/
-(void) processMessage: (PEXFtDownloadEntry *) e {
    _dState = [[PEXFtDownloadState alloc] init];
    _dState.msgId = [e.params.msgId longLongValue];
    _dState.queueMsgId = [e.params.queueMsgId longLongValue];
    _dState.nonce2 = e.params.nonce2;
    _dState.didErrorOccurr = YES;
    _dState.recoverableFault = NO;
    _dState.params = e.params;
    _dState.deleteOnly = e.deleteOnly || e.params.deleteOnly;
    _dState.downloadPackRightNow |= e.params.downloadFullArchiveNow;
    _dState.didTimeout = NO;
    _dState.didCancel = NO;
    _dState.didMacFail = NO;
    e.processingStarted = YES;

    DDLogVerbose(@"Starting processing nonce2: %@", _dState.nonce2);
    [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_RETRIEVING_FILE progress:0];
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Load corresponding DB message.
    if (![self loadDbMessage:cr]) {
        return;
    }

    // Simple cancelling detection.
    __weak __typeof(self) weakSelf = self;
    __weak __typeof(e) weakE = e;
    _dState.throwIfCancel = ^{
        [weakSelf checkIfCancelled];
        if (weakE.cancelled) {
            [PEXCancelledException raise:PEXFileTransferGenericException format:@"Operation cancelled"];
        }
    };

    _dState.cancelBlock = ^BOOL {
        return [weakSelf wasCancelled] || weakE.cancelled;
    };

    @try {
        // Detect if the record was processed at some point and try to recover from the stored state.
        PEXDbFileTransfer * ftTmp = [[PEXDbFileTransfer alloc] initWithNonce2:_dState.nonce2 msgId:_dState.msgId cr:cr];
        if (ftTmp != nil){
            _dState.transferRecord   = ftTmp;
            _dState.transferRecordId = ftTmp.id;

            // Recover crypto state from file transfer record.
            _dState.throwIfCancel();
            [self recoverFromTransferRecord];
            DDLogVerbose(@"FT record restored from DB for %@, msgId: %lld", _dState.nonce2, _dState.msgId);
        }

        // User may want to delete / reject this file at any point.
        if (_dState.deleteOnly && (_dState.transferRecord == nil || !_dState.deletedFromServer)) {
            // Store transfer information so we have marked it for deletion.
            DDLogVerbose(@"FT record marked as delete-only: %@", _dState.nonce2);
            _dState.throwIfCancel();
            [self storeTransferRecord];

            [self deleteOnly:e msgId:_dState.msgId nonce2:_dState.nonce2 msg:_dState.msg];
            return;
        }

        // If the record is nil or key was not computed yet, download has to proceed this step.
        _dState.throwIfCancel();
        if (_dState.transferRecord == nil || ![_dState.transferRecord isKeyComputingDone]) {
            // Do SOAP call to fetch stored files associated with given nonce2.
            DDLogVerbose(@"Starting FT fetch for %@", _dState.nonce2);
            [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META];
            [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_LOADING_INFORMATION progress:-1];

            // SOAP call for getting stored files on the server corresponding to given nonce2. Loads also key information.
            [self loadStoredFilesFromServer];

            // Loads user certificate and DHKey.
            [self loadKey:cr];
            [self loadCert:cr];

            // Was transfer cancelled?
            _dState.throwIfCancel();

            // initialize DHKeyHelper for processing the protocol
            [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_COMPUTING_ENC_KEYS progress:-1];

            // Initialize DHKeyHelper and compute FTHolder data (enc keys). If security error occurs, exception is thrown.
            [self computeHolder];

            // Store all transfer related info so we can decrypt archive file with this information.
            [self storeTransferRecord];

            // Remove DHKeys from database.
            // After previous step all data needed for archive file decryption is stored in filetransfer DB record.
            [PEXDbDhKey delete:_dState.nonce2 user:_dState.sender cr:cr];
        }

        // Meta file processing.
        // Meta file fetch - is it needed?
        // TODO: handle partial downloads of the meta/pack files.
        if (![_dState.transferRecord isMetaDone]) {
            _dState.throwIfCancel();
            DDLogVerbose(@"Going to fetch meta file for %@", _dState.nonce2);

            // Download & decrypt meta file so we have detailed information about transmitted files, including thumbs.
            // After this step there should be TransferRecord and ReceivedFile records in database with info.
            [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_CONNECTING_TO_SERVER progress:-1];
            _dState.transferRecord.metaState = @(PEX_FT_FILEDOWN_TYPE_STARTED);
            [self updateFtRecord];

            [self fetchAndProcessMeta];

            // Meta file is considered processed at this point
            _dState.transferRecord.metaState = @(PEX_FT_FILEDOWN_TYPE_DONE);
            [self updateFtRecord];

            // Store downloaded meta state = we have meta information now. Try to load thumbs in view.
            [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META];
        }

        if (![_dState.transferRecord isPackDone] && !_dState.downloadPackRightNow) {
            // File is ready to be downloaded, archive file was not fetched now.
            [self setFinalMessageOKType:cr];
        }

        // Archive / pack file processing.
        // If meta indicates pack should be downloaded right now, do it.
        // TODO: handle partial downloads of the meta/pack files.
        if (![_dState.transferRecord isPackDone] && _dState.downloadPackRightNow) {
            _dState.throwIfCancel();
            DDLogVerbose(@"Going to fetch archive file for %@", _dState.nonce2);
            [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING];

            // This downloads, decrypts, verifies and extracts archive file content.
            [self fetchAndProcessPack];
            _dState.transferRecord.packState = @(PEX_FT_FILEDOWN_TYPE_DONE);
            [_dState.transferRecord clearCryptoMaterial];
            [self updateFtRecord];

            // Mark message as downloaded. Process finished with this message.
            [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED];
        }

        // File downloaded, delete it from the server if successful to save inbox space and server resources.
        if ([_dState.transferRecord isPackDone] && _deleteFromServer) {
            [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_DELETING_FROM_SERVER progress:-1];

            // Mark for deletion so it is deleted even after the succeding delete attempt fails.
            _dState.transferRecord.shouldDeleteFromServer = @(1);
            [self updateFtRecord];

            // Clean download artifacts.
            [_dState.dhelper cleanFiles:_dState.ftHolder];

            // Delete from server call.
            _dState.deletedFromServer = [self deleteFileFromServer:_dState.nonce2 domain:nil];

            // If delete process was successful, mark deletion to the DB so manager knows it succeeds and
            // it does not have to repeat it.
            if (_dState.deletedFromServer){
                _dState.transferRecord.deletedFromServer = @(1);
                _dState.transferRecord.dateFinished = [NSDate date];
                [self updateFtRecord];

                // Mark message as downloaded. Process finished with this message.
                [PEXDbMessage setMessageType:cr messageId:_dState.msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED];
            }
        }

        // Finished.
        _dState.didErrorOccurr = NO;
        [_mgr publishDone:_dState.msgId];

        // TODO: catch timeout exceptions and handle them somehow.
//    } @catch (SocketTimeoutException tex){
//        // Timeout exception.
//        Log.i(TAG, "Socket timeout exception.");
//        publishError(msgId, FileTransferError.TIMEOUT);

    } @catch (PEXCancelledException *cex) {
        // Cancelled.
        DDLogInfo(@"Operation was cancelled");
        _dState.didCancel = YES;
        _dState.didErrorOccurr = YES;
        _dState.recoverableFault = NO; // Not recoverable, do not try to re-download after user cancelled it previously.

        [_mgr publishProgress:_dState.msgId title:PEX_FT_PROGRESS_CANCELLED progress:100];
        [self setFinalMessageOKType:cr];

    } @catch (PEXFtDownloadException *de) {
        // Download exception - error was as progress status.
        DDLogError(@"DownloadException, exception=%@", de);
        _dState.didErrorOccurr = YES;

    } @catch (NSException *e) {
        // Generic exception.
        DDLogError(@"Exception in a download process exception=%@.", e);
        _dState.didErrorOccurr = YES;

        [self setErrorToMsg:PEX_FT_ERROR_GENERIC_ERROR];
    }

    // Store result of the download to the LRU cache.
    if (e.storeResult) {
        // TODO: store result to manager
//        results.put(nonce2,
//                new DownloadResult(
//                errorOcurred ? FileTransferError.GENERIC_ERROR : FileTransferError.NONE,
//                System.currentTimeMillis(),
//                filePaths));
    }

    // Error handling block.
    if (_dState.didErrorOccurr) {
        if (_dState.recoverableFault) {
            // Recoverable fault - set message state appropriately so it can be tried later.
            DDLogInfo(@"Seems error is recoverable, we should try it later, several times");
            [self setFinalMessageOKType:cr];

        } else if (!_dState.deletedFromServer && !_dState.didCancel && !_dState.didTimeout) {   // TODO: VERIFY in case of timeout!!!
            // Non-recoverable file, delete from server to free space.
            _dState.deletedFromServer = [self deleteFileFromServer:_dState.nonce2 domain:nil];
        }
    }
}

-(void) deleteOnly: (PEXFtDownloadEntry *) e msgId: (int64_t) msgId nonce2: (NSString *) nonce2 msg: (PEXDbMessage *) msg {
    // TODO: if failed several times, should be tried later - request is stored in FileTransfer record.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    @try {
        // If the file should be only deleted from the server.
        [_mgr publishProgress:msgId title:PEX_FT_PROGRESS_DELETING_FROM_SERVER progress:-1];
        _dState.deletedFromServer = [self deleteFileFromServer:nonce2 domain:nil];
        if (_dState.deletedFromServer) {
            [_mgr publishProgress:msgId title:PEX_FT_PROGRESS_DELETED_FROM_SERVER progress:100];
            [PEXDbMessage setMessageType:cr messageId:msgId messageType:PEXDBMessage_MESSAGE_TYPE_FILE_REJECTED];

            // If delete process was successful, mark deletion to the DB so manager knows it succeeds and
            // it does not have to repeat it.
            if (_dState.transferRecord == nil){
                [self storeTransferRecord];
            }

            _dState.transferRecord.deletedFromServer = @(1);
            [self updateFtRecord];

        } else {
            DDLogError(@"Error during deleting file from server");
            [_mgr publishProgress:msgId title:PEX_FT_PROGRESS_ERROR progress:100];
        }

        // Delete corresponding DH keys from the local database (server gets updated also
        // during next dhsync).
        [PEXDbDhKey delete:nonce2 user:msg.getRemoteParty cr:cr];
    // TODO: catch timeout exceptions and handle them somehow.
    //    } @catch (SocketTimeoutException tex){
    //        // Timeout exception.
    //        Log.i(TAG, "Socket timeout exception.");
    //        publishError(msgId, FileTransferError.TIMEOUT);

    } @catch (PEXCancelledException * cex){
        // Cancelled.
        DDLogInfo(@"Operation was cancelled");
        [_mgr publishProgress:msgId title:PEX_FT_PROGRESS_CANCELLED progress:100];
        [self setFinalMessageOKType:cr];

    } @catch (PEXFtDownloadException * de){
        // Download exception - error was as progress status.
        DDLogError(@"DownloadException, exception=%@", de);

    } @catch (NSException * e) {
        // Generic exception.
        DDLogError(@"Exception in a download process exception=%@.", e);

        [self publishError:msgId error:PEX_FT_ERROR_GENERIC_ERROR];
    }

    // Store result of the download to the LRU cache.
    if (e.storeResult){
        // TODO: store result to manager
//        results.put(nonce2,
//                new DownloadResult(
//                errorOcurred ? FileTransferError.GENERIC_ERROR : FileTransferError.NONE,
//                System.currentTimeMillis(),
//                filePaths));
    }
}

/**
* Wrapper for SOAP call getStoredFiles. Retry counter 3.
*/
-(PEXFtResult *) getStoredFiles: (NSString *) nonce2 response: (hr_ftGetStoredFilesResponse **) resp {
    // Try to upload keys for several times until it succeeds.
    BOOL opSuccessful = NO;
    NSInteger curRetry = 0;
    PEXFtResult * mres;
    hr_ftGetStoredFilesResponse * tmpResp = nil;

    for(; curRetry < 3; curRetry++) {
        // Cancellation & connectivity check.
        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            if (_interruptedDueToConnectionError){
                _dState.recoverableFault = YES;
                [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorDownloadFailedNotConnected userInfo:nil];
            }
            break;
        }

        PEXDHCalls *call = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];
        mres = [call getStoredFiles:@[nonce2] domain:nil response:&tmpResp];
        if ([PEXFtResult wasError:mres] || tmpResp == nil){
            // Negative code means error so as empty response.
            DDLogError(@"Could not obtain files from server code=%ld, resp=%@", (long)mres.code, tmpResp);
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
* Deletes file from the server to save server mailbox capacity.
* @param nonce2
* @param domain 		Domain of the user for SOAP call, if null, uses loaded identity.
* @throws Exception
*/
-(BOOL) deleteFileFromServer: (NSString *) nonce2 domain: (NSString *) domain {
    NSString * domain2use = domain;
    if (domain2use == nil){
        if (_privData == nil){
            DDLogError(@"Cannot determine domain to use");
            return false;
        }

        // Get my domain
        _domain = [PEXSipUri getDomainFromSip:_privData.username parsed:nil];
        domain2use = _domain;
    }

    // Try to upload keys for several times until it succeeds.
    BOOL opSuccessful = NO;
    NSInteger curRetry = 0;
    for(; curRetry < 3; curRetry++) {
        // Cancellation & connectivity check.
        _interruptedDueToConnectionError = ![_svc isConnectivityWorking];
        if ([self wasCancelled] || _interruptedDueToConnectionError){
            if (_interruptedDueToConnectionError){
                _dState.recoverableFault = YES;
                [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorDownloadFailedNotConnected userInfo:nil];
            }
            break;
        }

        PEXDHCalls *call = [PEXDHCalls callsWithPrivData:self.privData canceller:self.canceller];
        hr_ftDeleteFilesResponse * resp = nil;
        PEXFtResult * mres = [call deleteFileFromServer:@[nonce2] domain:domain2use response:&resp];
        if ([PEXFtResult wasError:mres] || resp == nil){
            // Negative code means error so as empty response.
            DDLogError(@"Could not remove files from server code=%ld, resp=%@", (long)mres.code, resp);
            continue;
        }

        opSuccessful = YES;
        break;
    }

    return opSuccessful;
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
    [_mgr publishError:msgid error:error isUpload:NO];
}

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
* @param errCode
* @param errString
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error errCode: (NSNumber *) errCode errString: (NSString *) errString nsError: (NSError *) nserror{
    [_mgr publishError:msgid error:error errCode:errCode errString:errString nsError:nserror isUpload:NO];
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
        [self chainErrorWithDomain:PEXFtErrorDomain code:PEXFtErrorDownloadFailedNotConnected userInfo:nil];
        [PEXFileTransferException raise:PEXFileTransferNotConnectedException format:@"Not connected"];
    }
}

@end

@implementation PEXFtDownloadState
- (instancetype)init {
    self = [super init];
    if (self) {
        _didCancel = NO;
        _didErrorOccurr = NO;
        _didTimeout = NO;
        _didMacFail = NO;
        _recoverableFault = NO;
        _errCode = PEX_FT_ERROR_NONE;
        _deletedFromServer = NO;
        _downloadPackRightNow = NO;
        _deleteOnly = NO;
        _filePaths = [[NSMutableArray alloc] init];
        _transferFiles = [[NSMutableArray alloc] init];
    }

    return self;
}


@end