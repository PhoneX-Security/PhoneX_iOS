//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtTransferManager.h"
#import "PEXConcurrentHashMap.h"
#import "PEXConcurrentRingQueue.h"
#import "PEXService.h"
#import "PEXConnectivityChange.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXCanceller.h"
#import "PEXApplicationStateChange.h"
#import "PEXContactAddTask.h"
#import "PEXContactRemoveTask.h"
#import "PEXFtDownloadFileParams.h"
#import "PEXFtDownloadEntry.h"
#import "PEXFtProgress.h"
#import "PEXDBMessage.h"
#import "PEXDbAppContentProvider.h"
#import "PEXFtDownloadOperation.h"
#import "PEXFtUploadParams.h"
#import "PEXFtUploadEntry.h"
#import "PEXFtUploadOperation.h"
#import "PEXGuiFileUtils.h"
#import "PEXDbReceivedFile.h"
#import "PEXDbFileTransfer.h"
#import "PEXDbContentProvider.h"
#import "PEXAmpDispatcher.h"
#import "PEXReport.h"

NSString * const PEX_ACTION_FTRANSFET_UPDATE_PROGRESS_DB = @"net.phonex.phonex.ft.action.progress";
NSString * const PEX_EXTRA_FTRANSFET_UPDATE_PROGRESS_DB  = @"net.phonex.phonex.ft.extra.progress";

NSString * const PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER   = @"net.phonex.phonex.ft.action.cancel";
NSString * const PEX_EXTRA_FTRANSFET_DO_CANCEL_TRANSFER_ID = @"net.phonex.phonex.ft.extra.cancel";

@interface PEXFtTransferManager () {}
/**
* Operation queue for download and upload tasks.
* Serial queue for execution in background.
*/
@property(nonatomic) NSOperationQueue * downloadOpqueue;
@property(nonatomic) NSOperationQueue * uploadOpqueue;

/**
* Main scheduling structure for file downloads.
* Stores PEXFtDownloadEntry.
*/
@property(nonatomic) PEXConcurrentRingQueue * downloadQueue;

/**
* Main scheduling structure for file uploads.
* Stores PEXFtUploadEntry.
*/
@property(nonatomic) PEXConcurrentRingQueue * uploadQueue;

/**
* Stores download / upload progress.
* Stores PEXFtProgress.
*/
@property(nonatomic) PEXConcurrentHashMap *opProgress;

@property(nonatomic) BOOL registered;
@property(nonatomic) BOOL shouldStartTaskOnConnectionRecovered;
@property(nonatomic) BOOL lastUploadTaskNoConnection;
@property(nonatomic) NSError * lastUploadTaskError;
@property(nonatomic) NSError * lastCheckTaskError;
@end

@implementation PEXFtTransferManager {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloadOpqueue = [[NSOperationQueue alloc] init];
        self.downloadOpqueue.maxConcurrentOperationCount = 1;   // Serial queue;
        self.downloadOpqueue.name = @"ftDownloadQueue";
        self.uploadOpqueue = [[NSOperationQueue alloc] init];
        self.uploadOpqueue.maxConcurrentOperationCount = 1;   // Serial queue;
        self.downloadOpqueue.name = @"ftUploadQueue";

        self.downloadQueue = [[PEXConcurrentRingQueue alloc] initWithQueueName:@"ft.download" capacity:32];
        self.uploadQueue   = [[PEXConcurrentRingQueue alloc] initWithQueueName:@"ft.upload"   capacity:32];
        self.opProgress = [[PEXConcurrentHashMap alloc] initWithQueueName:@"ft.progress"];

        self.registered = NO;
        self.shouldStartTaskOnConnectionRecovered = NO;
        self.lastUploadTaskNoConnection = NO;
        self.writeErrorToMessage = YES;
        self.lastUploadTaskError = nil;
        self.lastCheckTaskError = nil;
    }

    return self;
}

+ (PEXFtTransferManager *)instance {
    static PEXFtTransferManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)onAccountLoggedIn {

}

/**
* Receive connectivity changes so we can react on this.
*/
- (void)onConnectivityChangeNotification:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil || conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    // IP changed?
    BOOL recovered = conChange.connection == PEX_CONN_GOES_UP;
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"connChange" async:YES block:^{
        PEXFtTransferManager * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (recovered && mgr.shouldStartTaskOnConnectionRecovered) {
            DDLogVerbose(@"Connectivity recovered & previous task failed.");

            // TODO: start previously interrupted tasks.
            // ...

            mgr.shouldStartTaskOnConnectionRecovered = NO;
        } else if (recovered) {
            // Connectivity recovered -> may check DH keys if the last check happened long time ago.
            // TODO: consider starting depending of the queue size.
        }
    }];
}

- (void)onCertUpdated:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_UPDATED_USERS] == nil){
        return;
    }

    NSArray * usersChanged = notification.userInfo[PEX_EXTRA_UPDATED_USERS];
    if (usersChanged == nil || [usersChanged count] == 0){
        return;
    }

    // Certificate check, mine (local) vs. database (new, updated).
    DDLogVerbose(@"Cert changed, trigger user check");
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"selfCertCheck" async:YES block:^{
        // TODO: flush certificate caches, try to re-download failed files.
    }];
}

- (void)onUserUpdated:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil){
        return;
    }

    DDLogVerbose(@"User added/removed.");
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"selfCertCheck" async:YES block:^{
        // TODO: delete files ?
    }];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        // If check was completed 12 hours ago or more, trigger a new check...
        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:@"ftOnAppActive" async:YES block:^{
            // TODO: consider doing something?
        }];
    }
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for connectivity notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onConnectivityChangeNotification:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];

        // Register on certificate updates.
        [center addObserver:self selector:@selector(onCertUpdated:) name:PEX_ACTION_CERT_UPDATED object:nil];

        // Register to user added/removed event.
        [center addObserver:self selector:@selector(onUserUpdated:) name:PEX_ACTION_CONTACT_ADDED object:nil];
        [center addObserver:self selector:@selector(onUserUpdated:) name:PEX_ACTION_CONTACT_REMOVED object:nil];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        DDLogDebug(@"FTTransfer Manager registered");
        self.registered = YES;
    }
}

-(void) doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        [center removeObserver:self];
        DDLogDebug(@"Message manager unregistered");
        self.registered = NO;
    }
}

-(void) quit {
    [self.downloadOpqueue cancelAllOperations];
    [self.uploadOpqueue cancelAllOperations];
}

- (void)doCancel {
    // TODO: implement cancellation of all tasks.
}

+(void) dispatchDownloadTransfer: (PEXDbMessage *) msg accept: (NSNumber *) accept {
    PEXFtDownloadFileParams *params = [PEXFtTransferManager getDefaultDownloadParams:msg.fileNonce msgId:msg.id];
    if (accept != nil){
        if ([accept boolValue]){
            params.fileTypeIdx               = PEX_FT_ARCH_IDX;
            params.downloadFullArchiveNow    = YES;
            params.deleteOnSuccess           = YES;
        } else {
            params.deleteOnly                = YES;
            params.fileTypeIdx               = PEX_FT_META_IDX;
            params.downloadFullArchiveNow    = NO;
            params.deleteOnSuccess           = YES;
        }
    }

    [self initDownloadProcessProgress:msg accept:accept];
    [PEXAmpDispatcher dispatchNewFileDownload:msg params:params];
}

/**
* Initiates download progress in UI.
*
* @param ctxt
* @param msgId
* @param accept
*/
+(void) initDownloadProcessProgress: (PEXDbMessage *) msg accept: (NSNumber *) accepted{
    [PEXService executeWithName:@"ftDownInit" async:YES block:^{
        int newMsgType;
        if (accepted != nil && ![accepted boolValue]) {
            newMsgType = PEXDBMessage_MESSAGE_TYPE_FILE_REJECTED;
        } else if (accepted != nil) {
            newMsgType = PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING;
        } else {
            newMsgType = PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META;
        }

        [PEXDbMessage setMessageType:[PEXDbAppContentProvider instance] messageId:[msg.id longLongValue] messageType:newMsgType];
        [[PEXFtTransferManager instance] publishProgress:[msg.id longLongValue] title:PEX_FT_PROGRESS_IN_QUEUE progress:-1 isUpload:NO];
    }];
}

-(void) enqueueFile2Download: (PEXFtDownloadFileParams *) params {
    [self enqueueFile2Download:params storeResult:YES deleteOnly:NO];
}

+ (PEXFtDownloadFileParams * ) getDefaultDownloadParams: (NSString *) nonce2 msgId:(NSNumber *)msgId {
    PEXFtDownloadFileParams * params = [[PEXFtDownloadFileParams alloc] init];
    params.destinationDirectory      = [PEXGuiFileUtils getFileTransferPath];
    params.msgId                     = msgId;
    params.createDestinationDirIfNeeded = YES;
    params.nonce2                    = nonce2;
    params.fileTypeIdx               = PEX_FT_META_IDX;
    params.downloadFullArchiveNow    = NO;
    params.deleteOnSuccess           = NO;
    params.downloadFullIfOnWifiAndUnderThreshold = YES;
    return params;
}

- (void)enqueueDownload:(NSString *)nonce2 msgId:(NSNumber *)msgId {
    PEXFtDownloadFileParams * params = [PEXFtTransferManager getDefaultDownloadParams:nonce2 msgId:msgId];
    [self enqueueFile2Download:params];
}

- (void)enqueueDownloadAccept:(NSString *)nonce2 msgId:(NSNumber *)msgId {
    PEXFtDownloadFileParams * params = [PEXFtTransferManager getDefaultDownloadParams:nonce2 msgId:msgId];
    params.fileTypeIdx               = PEX_FT_ARCH_IDX;
    params.downloadFullArchiveNow    = YES;
    params.deleteOnSuccess           = YES;
    [self enqueueFile2Download:params];
}

- (void)enqueueDownloadReject:(NSString *)nonce2 msgId:(NSNumber *)msgId {
    PEXFtDownloadFileParams * params = [PEXFtTransferManager getDefaultDownloadParams:nonce2 msgId:msgId];
    params.deleteOnly                = YES;
    params.fileTypeIdx               = PEX_FT_META_IDX;
    params.downloadFullArchiveNow    = NO;
    params.deleteOnSuccess           = YES;
    [self enqueueFile2Download:params];
}

/**
* Add new file to download queue.
*
* @param params
* @param storeResult
*/
-(void) enqueueFile2Download: (PEXFtDownloadFileParams *) params storeResult: (BOOL) storeResult deleteOnly: (BOOL) deleteOnly {
    PEXFtDownloadEntry * le = [[PEXFtDownloadEntry alloc] init];
    le.storeResult = storeResult;
    le.params = params;
    le.deleteOnly = deleteOnly || params.deleteOnly;

    // TODO: Check if not already present.
    [self.downloadQueue pushBack:le async:YES];

    // Start new task.
    PEXFtDownloadOperation *task = [[PEXFtDownloadOperation alloc] initWithMgr:self privData:self.privData];
    __weak __typeof(task) weakTask = task;
    __weak __typeof(self) weakSelf = self;
    task.canceller = self.canceller;
    // TODO: configure download operation.
    // ...

    task.completionBlock = ^{
        PEXFtDownloadOperation * cTask = weakTask;
        PEXFtTransferManager    * cMgr = weakSelf;
        if (cTask == nil || cMgr == nil){
            DDLogVerbose(@"Completion block - nil");
            return;
        }

        [PEXReport logUsrEvent:PEX_EVENT_FILE_DOWNLOAD];
        // TODO: add logic for completion.
        // TODO: If there are some jobs in queue and there is no task, start a new one.

//        if (cTask.interruptedDueToConnectionError || cTask.opError != nil) {
//            DDLogDebug(@"ConnectionInterrupted:%d error=%@", cTask.interruptedDueToConnectionError, cTask.opError);
//            mgr.lastUploadTaskNoConnection = cTask.interruptedDueToConnectionError;
//            mgr.shouldStartTaskOnConnectionRecovered |= cTask.interruptedDueToConnectionError;
//            mgr.lastUploadTaskError = cTask.opError;
//        }
//
//        [mgr onKeyCheckCompleted: cTask];
    };

    // Start task if it is not running.
    // Wait some amount of time in order to group multiple users in one check (optimization).
    // Schedules new task only if there is none scheduled or previous has finished.
    DDLogVerbose(@"Download task added to the queue");
    [self.downloadOpqueue addOperation:task];

    // Add to progress monitor.
    [self publishProgress:[params.msgId longLongValue] title:PEX_FT_PROGRESS_IN_QUEUE progress:-1];
    [self expireProgress];
}

/**
* Add new file to upload queue.
*
* @param params
*/
-(void) enqueueFile2Upload: (PEXFtUploadParams *) params {
    PEXFtUploadEntry * le = [[PEXFtUploadEntry alloc] init];
    le.params = params;

    // TODO: Check if not already present.
    [self.uploadQueue pushBack:le async:YES];

    // Start new task.
    PEXFtUploadOperation *task = [[PEXFtUploadOperation alloc] initWithMgr:self privData:self.privData];
    __weak __typeof(task) weakTask = task;
    __weak __typeof(self) weakSelf = self;
    task.canceller = self.canceller;
    // TODO: configure download operation.
    // ...

    task.completionBlock = ^{
        PEXFtUploadOperation * cTask = weakTask;
        PEXFtTransferManager    * cMgr = weakSelf;
        if (cTask == nil || cMgr == nil){
            DDLogVerbose(@"Completion block - nil");
            return;
        }

        [PEXReport logUsrEvent:PEX_EVENT_SENT_FILE_SOMEONE];
        // TODO: add logic for completion.
        // TODO: If there are some jobs in queue and there is no task, start a new one.
    };

    // Start task if it is not running.
    // Wait some amount of time in order to group multiple users in one check (optimization).
    // Schedules new task only if there is none scheduled or previous has finished.
    DDLogVerbose(@"Upload task added to the queue");
    [self.uploadOpqueue addOperation:task];

    // Add to progress monitor.
    [self publishProgress:[params.msgId longLongValue] title:PEX_FT_PROGRESS_IN_QUEUE progress:-1];
    [self expireProgress];
}

+ (NSString *) getThumbFolder {
    return [PEXDhKeyHelper getThumbDirectory];
}

/**
* Deletes all file transfer records associated with given message id.
*/
+ (void)deleteTransferRecords: (PEXDbContentProvider *) cr withMessageId: (int64_t)dbMessageId {
    // Delete thumbs.
    [PEXDbReceivedFile deleteThumbs:dbMessageId thumbDir:[self getThumbFolder] cr:cr];

    // Delete transfer files.
    [PEXDbReceivedFile deleteByDbMessageId:dbMessageId cr:cr];

    // Delete temporary files (meta, pack).
    [PEXDbFileTransfer deleteTempFileByDbMessageId:dbMessageId cr:cr];

    // Delete file transfer record.
    [PEXDbFileTransfer deleteByDbMessageId:dbMessageId cr:cr];
}

+ (void)deleteTransferRecords:(PEXDbContentProvider *)cr forUser:(NSString *)username
{
    [self deleteTransferRecords:cr forMessageIds:[PEXDbMessage getAllFileMsgIdsRelatedToUser:username cr:cr]];
}

+ (void)deleteTransferRecords:(PEXDbContentProvider *)cr forMessageIds:(NSArray * const)ids
{
    for(NSNumber * id in ids){
        if (id == nil){
            DDLogError(@"Invalid id, nil!");
            continue;
        }

        [self deleteTransferRecords:cr withMessageId:[id longLongValue]];
    }
}

- (BOOL)isDownloadQueueEmpty {
    return [self.downloadQueue isEmpty];
}

- (PEXFtDownloadEntry *)peekDownloadQueue {
    return [self.downloadQueue top];
}

- (PEXFtDownloadEntry *)pollDownloadQueue {
    return [self.downloadQueue popFront];
}

- (BOOL)isUploadQueueEmpty {
    return [self.uploadQueue isEmpty];
}

- (PEXFtUploadEntry *)peekUploadQueue {
    return [self.uploadQueue top];
}

- (PEXFtUploadEntry *)pollUploadQueue {
    return [self.uploadQueue popFront];
}

-(void) cancelTransfer: (PEXDbMessage *) message{
    if (message == nil || message.isOutgoing == nil || message.id == nil){
        DDLogError(@"Message to cancel transfer is nil");
        return;
    }

    if ([message.isOutgoing boolValue]){
        [self cancelUpload:[message.id longLongValue]];
    } else {
        [self cancelDownload:[message.id longLongValue]];
    }
}

/**
* Cancels transfer in queue.
* @param messageId
*/
-(void) cancelDownload: (int64_t) messageId{
    __weak __typeof(self) weakSelf = self;
    __block BOOL foundInQueue = NO;

    [self.downloadQueue enumerateAsync:NO usingBlock:^(id anObject, NSUInteger idx, BOOL *stop) {
        *stop = NO;

        PEXFtDownloadEntry * e = (PEXFtDownloadEntry *) anObject;
        if (e == nil || e.params.msgId == nil){
            return;
        }

        if ([e.params.msgId isEqualToNumber:@(messageId)]){
            e.cancelled = YES;
            *stop = YES;
            foundInQueue = YES;

            [weakSelf publishProgress:messageId title:PEX_FT_PROGRESS_CANCELLED progress:100];
        }
    }];

    // Transmit cancellation event message;
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER object:nil
                                                      userInfo:@{PEX_EXTRA_FTRANSFET_DO_CANCEL_TRANSFER_ID : @(messageId)}];

    // TODO: should we return here? Not update? Setting to cancelled may be race conditioning.
    if (foundInQueue){
        return;
    }

    // If message is not found in this queue, it may be probably some old message.
    DDLogVerbose(@"Message to cancel was not found in queue, id=%llu", messageId);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    PEXDbMessage * msg = [PEXDbMessage initById:cr messageId:messageId projection:@[PEXDBMessage_FIELD_ID, PEXDBMessage_FIELD_TYPE]];
    if (msg == nil){
        DDLogDebug(@"Message is null");
        return;
    }

    // If in downloading state, move to the ready state.
    // Download probably crashed at some point.
    if (msg.type != nil && (msg.type.integerValue == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING || msg.type.integerValue == PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META)){
        DDLogVerbose(@"Message type set to ready");
        [PEXDbMessage setMessageType:cr messageId:messageId messageType: PEXDBMessage_MESSAGE_TYPE_FILE_READY];
    }
}

/**
* Cancels transfer in queue.
* @param messageId
*/
-(void) cancelUpload: (int64_t) messageId{
    __weak __typeof(self) weakSelf = self;
    __block BOOL foundInQueue = NO;

    [PEXReport logUsrEvent:PEX_EVENT_CANCEL_UPLOAD];
    [self.uploadQueue enumerateAsync:NO usingBlock:^(id anObject, NSUInteger idx, BOOL *stop) {
        *stop = NO;

        PEXFtUploadEntry * e = (PEXFtUploadEntry *) anObject;
        if (e == nil || e.params.msgId == nil){
            return;
        }

        if ([e.params.msgId isEqualToNumber:@(messageId)]){
            e.cancelled = YES;
            *stop = YES;
            foundInQueue = YES;

            [weakSelf publishProgress:messageId title:PEX_FT_PROGRESS_CANCELLED progress:100];
        }
    }];

    // Transmit cancellation event message;
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER object:nil
                                                      userInfo:@{PEX_EXTRA_FTRANSFET_DO_CANCEL_TRANSFER_ID : @(messageId)}];

    // TODO: should we return here? Not update? Setting to cancelled may be race conditioning.
    if (foundInQueue){
        return;
    }

    // If message is not found in this queue, it may be probably some old message.
    DDLogVerbose(@"Message to cancel was not found in queue, id=%llu", messageId);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    PEXDbMessage * msg = [PEXDbMessage initById:cr messageId:messageId projection:@[PEXDBMessage_FIELD_ID, PEXDBMessage_FIELD_TYPE]];
    if (msg == nil){
        DDLogDebug(@"Message is null");
        return;
    }

    // if the message exists, it should be erradicated
    DDLogVerbose(@"Going to remove message");
    [PEXDbMessage deleteById:cr messageId:messageId];
}

-(void) checkForFailedTransfers {
    // TODO: call this after login to check for failed transfers and to re-queue them.
    // TODO: consider calling on connectivity change.
}

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error isUpload:(BOOL) isUpload{
    [self publishError:msgid error:error errCode:nil errString:nil nsError:nil isUpload: isUpload];
}

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
* @param errCode
* @param errString
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error errCode: (NSNumber *) errCode errString: (NSString *) errString nsError: (NSError *) nserror isUpload:(BOOL) isUpload{
    PEXFtProgress * p = [[PEXFtProgress alloc] init];
    p.messageId = msgid;
    p.title     = @"Error";

    // error should not look like finished file transfer, i.e. progress 100%
    p.progress = 0;

    p.error = error;
    p.errorCode = errCode;
    p.errorString = errString;
    p.nsError = nserror;
    p.done = YES;
    p.upload = isUpload;

    [self publishProgress:p];

    // Store error codes to the message
    if (_writeErrorToMessage)
    {
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        const bool tryTransferAgain = [PEXFtProgress isTryAgainError:error];

        const int fileType =
                (tryTransferAgain ? PEXDBMessage_MESSAGE_TYPE_FILE_READY :
                        isUpload ? PEXDBMessage_MESSAGE_TYPE_FILE_UPLOAD_FAIL : PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOAD_FAIL);

        [PEXDbMessage setMessageError:cr messageId:msgid
                          messageType:fileType
                              errCode:error
                              errText:errString];
    }
}

/**
* Publishes progress by specifying progress details.
* @param msgid
* @param title
* @param progress
*/
-(void) publishProgress: (int64_t) msgid title: (PEXFtProgressEnum) title progress: (int) progress isUpload: (BOOL) isUpload{
    PEXFtProgress * p = [[PEXFtProgress alloc] initWithMessageId:msgid progressCode:title progress:progress];
    p.upload = isUpload;
    [self publishProgress:p];
}

/**
* Publishes progress by specifying progress details.
* @param msgid
* @param title
* @param progress
*/
-(void) publishProgress: (int64_t) msgid title: (PEXFtProgressEnum) title progress: (int) progress{
    PEXFtProgress * p = [[PEXFtProgress alloc] initWithMessageId:msgid progressCode:title progress:progress];
    [self publishProgress:p];
}

/**
* Publishes DONE progress event.
* @param msgid
*/
-(void) publishDone: (int64_t) msgid{
    PEXFtProgress * p = [[PEXFtProgress alloc] initWithMessageId:msgid progressCode:PEX_FT_PROGRESS_DONE progress:100];
    p.done = YES;

    [self publishProgress:p];
}

/**
* Goes through transfer progress structure and removes old records.
*/
-(void) expireProgress {
    NSUInteger size = [_opProgress count];
    if (size < 25){
        return;
    }

    NSDate * cur = [NSDate date];
    NSTimeInterval curTime = [cur timeIntervalSince1970];

    NSSet  * set = [_opProgress keyset];
    for(NSNumber * key in set){
        @try {
            if (key == nil){
                continue;
            }

            PEXFtProgress * progress = [_opProgress get:key];
            if (progress == nil){
                continue;
            }

            NSDate * when = progress.when;
            if (when != nil && curTime - [when timeIntervalSince1970] > 60*60*3){
                [_opProgress remove:key async:NO];
            }
        } @catch(NSException * e){
            DDLogError(@"Exception in expiring transfer info %@", e);
        }
    }
}

/**
* Method for publishing a download progress.
* If the progress is changed, it is broadcasted by intent.
* @param progress
*/
-(void) publishProgress: (PEXFtProgress *) progress{
    const int64_t msgid = progress.messageId;

    // Check if the event actually changed, if not (same progress update), do not broadcast event.
    // Useful for download process (e.g., downloaded 48%, downloaded 48%, ...)
    PEXFtProgress * prevMapping = [self.opProgress put:progress key:@(msgid)];
    if (prevMapping!=nil && [progress isEqualToProgress:prevMapping]){
        // If the previous progress object is the same as current, do not notify
        // end user about this.
        return;
    }

    // Sending progress by intent - broadcasting changes.
    [PEXService executeWithName:nil async:YES block:^{
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

        // Post notification to the notification center.
        [center postNotificationName:PEX_ACTION_FTRANSFET_UPDATE_PROGRESS_DB object:nil userInfo:@{
                PEX_EXTRA_FTRANSFET_UPDATE_PROGRESS_DB : progress
        }];
    }];

    // Expire records.
    if (progress != nil && progress.done){
        [self expireProgress];
    }
}


@end
