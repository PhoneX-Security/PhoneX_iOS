//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMessageManager.h"
#import "PEXContentObserver.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbUserCertificate.h"
#import "PEXUserPrivate.h"
#import "PEXRegex.h"
#import "PEXUtils.h"
#import "PEXSipUri.h"
#import "PEXCertificate.h"
#import "PEXAmpDispatcher.h"
#import "PEXMessageDigest.h"
#import "PEXTransportProtocolDispatcher.h"
#import "PEXDbContact.h"
#import "PEXCancelledException.h"
#import "PEXCanceller.h"
#import "PEXPjHelper.h"
#import "PEXCertRefreshTask.h"
#import "PEXCertRefreshParams.h"
#import "PEXDBMessage.h"
#import "PEXDBUserProfile.h"
#import "PEXCryptoUtils.h"
#import "PEXService.h"
#import "PEXConnectivityChange.h"
#import "PEXApplicationStateChange.h"
#import "PEXConcurrentHashMap.h"
#import "PEXDbMergeCursor.h"
#import "PEXDbEmptyCursor.h"
#import "PEXStringUtils.h"
#import "PEXFileToSendEntry.h"
#import "PEXDhKeyHelper.h"
#import "PEXFtTransferManager.h"
#import "PEXFtUploadParams.h"
#import "PEXFileTransferException.h"
#import "PEXSelectedFileContainer.h"
#import "PEXDbFileTransfer.h"
#import "PEXFtUtils.h"
#import "PEXReport.h"
#import "pjsip/sip_msg.h"

NSString *PEX_ACTION_CHECK_MESSAGE_DB = @"net.phonex.phonex.message.action.check_message_db";
NSString *PEX_ACTION_MESSAGE_RECEIVED = @"net.phonex.phonex.message.action.message_received";
NSString *PEX_ACTION_MESSAGE_STORED_FOR_SENDING = @"net.phonex.phonex.message.action.message_stored_for_sending";

/**
* After user confirms file rejection this intent is broadcasted from confirm dialog.
*/
NSString * PEX_ACTION_REJECT_FILE_CONFIRMED = @"net.phonex.service.ACTION_REJECT_FILE_CONFIRMED";
NSString * PEX_EXTRA_REJECT_FILE_CONFIRMED_MSGID = @"net.phonex.service.EXTRA_REJECT_FILE_CONFIRMED_MSGID";
NSString * PEX_ACTION_ACCEPT_FILE_CONFIRMED = @"net.phonex.service.ACTION_ACCEPT_FILE_CONFIRMED";
NSString * PEX_EXTRA_ACCEPT_FILE_CONFIRMED_MSGID = @"net.phonex.service.EXTRA_ACCEPT_FILE_CONFIRMED_MSGID";

NSString * PEX_EXTRA_TO = @"EXTRA_TO";
#define RESEND_BACKOFF_THRESHOLD 3
#define RESEND_STACK_BACKOFF_THRESHOLD 3

/**
* Content observer for message changes.
*/
@interface PEXMessageObserver : NSObject <PEXContentObserver> {}
@property(nonatomic, weak) PEXMessageManager * manager;
@property(nonatomic) PEXUri * destUri;
- (instancetype)initWithManager:(PEXMessageManager *)manager;
+ (instancetype)observerWithManager:(PEXMessageManager *)manager;
@end

/**
* Content observer for certificate observer.
*/
@interface PEXCertificateObserver : NSObject <PEXContentObserver> {}
@property(nonatomic, weak) PEXMessageManager * manager;
@property(nonatomic) PEXUri * destUri;
- (instancetype)initWithManager:(PEXMessageManager *)manager;
+ (instancetype)observerWithManager:(PEXMessageManager *)manager;
@end

@interface PEXMessageEventReceiver : NSObject {}
@property(nonatomic, weak) PEXMessageManager * manager;
- (void) receiveNotification:(NSNotification *) notification;
- (instancetype)initWithManager:(PEXMessageManager *)manager;
+ (instancetype)receiverWithManager:(PEXMessageManager *)manager;
@end

/**
* Task waits for connectivity to appear valid for specified amount of time.
* After that another few seconds is paused for stacks to get registered.
*/
static const int CONN_TASK_MAX_RETRY_COUNT = 10;
static const double CONN_TASK_TIMEOUT = 5.0;

@interface PEXWaitForConnectivityTask : NSThread {}
@property(nonatomic, weak) PEXMessageManager * manager;
- (instancetype)initWithManager:(PEXMessageManager *)manager;
+ (instancetype)taskWithManager:(PEXMessageManager *)manager;
@end

@interface PEXBackoffFutureTimer : NSObject
@property(nonatomic) NSString * to;
@property(nonatomic) NSDate * expiration;
@property(nonatomic) long delay;
@property(nonatomic) NSTimer * timer;
@end

/**
* Private extension of the message manager.
*/
@interface PEXMessageManager () { }

/**
* A serial working queue for background jobs.
*/
@property(nonatomic) NSOperationQueue * workerQueue;

@property(nonatomic) BOOL registered;
@property(nonatomic) volatile NSNumber * connected;

@property(nonatomic) PEXMessageObserver * messageObserver;
@property(nonatomic) PEXCertificateObserver * certificateObserver;
@property(nonatomic) NSCache * certCache;
@property(nonatomic) PEXWaitForConnectivityTask * connTask;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic) PEXMessageEventReceiver * msgReceiver;

@property(nonatomic) PEXConcurrentHashMap * futureResendAlarms; // to (NSString) -> PEXBackoffFutureTimer

-(BOOL) isConnected;
-(void) onWaitingThreadFinish;

+(NSString * ) getSelectOutgoing;
+(NSString * ) getSelectIncoming;
+(NSString * ) getSelectToProcess;
@end

@implementation PEXMessageManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.workerQueue = [[NSOperationQueue alloc] init];
        self.workerQueue.maxConcurrentOperationCount = 1;
        self.workerQueue.name = @"msgQueue";

        self.registered = NO;
        self.certCache = [[NSCache alloc] init];
        self.certCache.countLimit = 5;
        self.fetchCertIfMissing = YES;
        self.canceller = nil;
        self.connTask = nil;
        self.msgReceiver = nil;
        self.futureResendAlarms = [[PEXConcurrentHashMap alloc] initWithQueueName:@"backoffMap"];
    }

    return self;
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

+ (instancetype)managerWithPrivData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithPrivData:privData];
}

+(NSString * ) getSelectOutgoing {
    static dispatch_once_t once;
    static NSString * select;
    dispatch_once(&once, ^{
        select = [NSString stringWithFormat:@"(%@=0 AND %@=1)", PEX_MSGQ_FIELD_IS_PROCESSED, PEX_MSGQ_FIELD_IS_OUTGOING];
    });
    return select;
}

+(NSString * ) getSelectIncoming {
    static dispatch_once_t once;
    static NSString * select;
    dispatch_once(&once, ^{
        select = [NSString stringWithFormat:@"(%@=0 AND %@=0 AND %@!=%d)",
                        PEX_MSGQ_FIELD_IS_PROCESSED,
                        PEX_MSGQ_FIELD_IS_OUTGOING,
                        PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                        PEX_AMP_FTRANSFER];
    });
    return select;
}

+(NSString * ) getSelectToProcess {
    static dispatch_once_t once;
    static NSString * select;
    dispatch_once(&once, ^{
        select = [NSString stringWithFormat:@"((%@) OR (%@))", [self getSelectIncoming], [self getSelectOutgoing]];
    });
    return select;
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];

        // Register message database observer.
        if (self.messageObserver == nil) {
            self.messageObserver = [PEXMessageObserver observerWithManager:self];
            [cr registerObserver:self.messageObserver];
        }

        // Register certificate database observer.
        if (self.certificateObserver == nil) {
            [self.certCache removeAllObjects];
            self.certificateObserver = [PEXCertificateObserver observerWithManager:self];
            [cr registerObserver:self.certificateObserver];
        }

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        if (self.msgReceiver == nil) {
            self.msgReceiver = [PEXMessageEventReceiver receiverWithManager:self];

            [center addObserver:self.msgReceiver selector:@selector(receiveNotification:) name:PEX_ACTION_CHECK_MESSAGE_DB object:nil];
            [center addObserver:self.msgReceiver selector:@selector(receiveNotification:) name:PEX_ACTION_MESSAGE_RECEIVED object:nil];
            [center addObserver:self.msgReceiver selector:@selector(receiveNotification:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
            [center addObserver:self.msgReceiver selector:@selector(receiveNotification:) name:PEX_ACTION_REJECT_FILE_CONFIRMED object:nil];
            [center addObserver:self.msgReceiver selector:@selector(receiveNotification:) name:PEX_ACTION_ACCEPT_FILE_CONFIRMED object:nil];
        }

        // Register on app state changes.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        DDLogDebug(@"Message manager registered");
        self.registered = YES;
    }
}

-(void) doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];

        // UNRegister message database observer.
        if (self.messageObserver != nil) {
            [cr unregisterObserver:self.messageObserver];
            self.messageObserver = nil;
        }

        // UNRegister certificate database observer.
        if (self.certificateObserver != nil) {
            [cr unregisterObserver:self.certificateObserver];
            self.certificateObserver = nil;
        }

        // UNRegister observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        if (self.msgReceiver != nil){
            [center removeObserver:self.msgReceiver];
            self.msgReceiver = nil;
        }

        [center removeObserver:self];
        DDLogDebug(@"Message manager unregistered");
        self.registered = NO;
        self.connected = nil;
    }
}

/**
* Empties work queue.
*/
-(void) quit {
    [self.workerQueue cancelAllOperations];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        DDLogVerbose(@"Application lives again, check messages");
        [self triggerCheck];
    }
}

/**
* Event triggered on connectivity change.
* @param recovered    If true, connectivity was recovered, otherwise lost.
*/
-(void) onConnectivityChange: (BOOL) recovered{
    self.connected = @(recovered);
    // If connectivity was recovered, schedule task to refresh the database.
    // There may be messages in the queue qaiting to be sent.
    if (!recovered){
        return;
    }

    if (self.connTask != nil){
        if ([self.connTask isExecuting]){
            return;
        } else {
            self.connTask = nil; // cleanup;
        }
    }

    self.connTask = [PEXWaitForConnectivityTask taskWithManager:self];
    [self.connTask start];
    DDLogVerbose(@"Connectivity thread started");
}

/**
* Event triggered as some account get logged in and may be used to send waiting messages.
*/
-(void) onAccountLoggedIn{
    // If connection task is running, do nothing. It will be triggered later.
    if (self.connTask != nil && [self.connTask isExecuting]){
        return;
    }

    // Cleaning database, sanitizing back to consistent state.
    [self dbCheckTask: YES];

    // Trigger database check.
    DDLogVerbose(@"Triggering database check by account change.");
    [self triggerCheck];
}

-(void) dbCheckTask: (BOOL) justStarted {
    [self addTaskWithName:@"msgdbCheck" toQueue:^(PEXMessageManager *mgr) {
        DDLogVerbose(@"Msg db check mgr=%@", mgr);
        if (mgr == nil){
            return;
        }

        [mgr dbCheckInt: justStarted];
    }];
}

-(void) dbCheckInt: (BOOL) justStarted {
    // Check database consistency, lost messages.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Check all DBMessages that have state PENDING of BACKOFF and do not have corresponding message queue entries.
    // For those re-enqueue a new queue message record, update message time.
    [self dbCheckWithoutQueuedMsg: cr];

    // If just started -> set all to not processed to start over again.
    if (justStarted){
        // Reset all messages waiting for feedback form PJSIP. They are never going to have it. System was restarted.
        //
        // Get all messages from the queue - for debugging purposes, generating a log report.
        [self messageQueueLogReport:cr];

        // Set all messages in the queue to not processed.
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEX_MSGQ_FIELD_IS_PROCESSED integer:0];
        int affected = [cr updateEx:[PEXDbMessageQueue getURI] ContentValues:cv selection:@"" selectionArgs:@[]];
        DDLogDebug(@"Number of rows affected by switch to unprocessed: %d", affected);
        return;
    }

    // If check called during normal run it is hard to say whether the feedback for a message is lost or not.
    // Check messages intended for backoff that are quite a long time after backoff trigger and still stucked in that state.
    [self dbCheckOldProcessed:cr];
}

/**
* Waiting thread finishes waiting for connectivity.
*/
-(void) onWaitingThreadFinish {
    self.connTask = nil; // cleanup.
    if ([self isConnected]){
        DDLogVerbose(@"Check triggered from connectivity thread.");
        [self dbCheckTask:NO];
        [self triggerCheck];
    }
}

/**
* DB check initialized from AlarmManager for specific user
* @param to SIP of receiver who initialized backoff alarm
*/
-(void) triggerAlarmCheck: (NSString *)to {
    DDLogDebug(@"Message backoff timer fired, to=%@", to);
    [self.futureResendAlarms remove:to async:YES];
    [self triggerCheck];
}

/**
* Manually triggers the database check.
* Check is performed on own executor.
*/
-(void) triggerCheck {
    [self addTaskWithName:@"trigger" toQueue:^(PEXMessageManager *mgr) {
        DDLogVerbose(@"Manual trigger of the DB check. mgr=%@", mgr);
        if (mgr == nil){
            return;
        }

        [mgr databaseChanged:NO uri:nil fromObserver:NO];
    }];
}

/**
* Broadcasts intent to re-check database.
* Called from outside to trigger check in the message manager.
* @param ctxt
*/
+(void) triggerCheck {
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    // Post notification to the notification center.
    [center postNotificationName:PEX_ACTION_CHECK_MESSAGE_DB object:nil userInfo:nil];
}

- (void)keepAlive:(BOOL)async {
    [self dbCheckTask:NO];
    [self triggerCheck];
}

/**
* Confirms acceptance or rejection of the transfer.
*
* @param msgId
* @param accept
*/
+(void) confirmTransfer:(NSNumber *) msgId accept: (BOOL) accept{
    @try {
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

        // Post notification to the notification center.
        [center postNotificationName: accept ? PEX_ACTION_ACCEPT_FILE_CONFIRMED : PEX_ACTION_REJECT_FILE_CONFIRMED object:nil userInfo:@{
                (accept ? PEX_EXTRA_ACCEPT_FILE_CONFIRMED_MSGID : PEX_EXTRA_REJECT_FILE_CONFIRMED_MSGID) : msgId
        }];

    } @catch (NSException * t) {
        DDLogError(@"Unable to confirm file transfer for msg: %@, exception: %@", msgId, t);
    }
}

-(void) onTransferConfirmation: (NSNumber *) msgId accept: (BOOL) accept{
    DDLogVerbose(@"Transfer confirmation file with msgid: %@, accept: %d", msgId, accept);
    if (msgId == nil || [msgId longLongValue] < 0){
        return;
    }

    [PEXService executeWithName:@"ftConfirm" async:YES block:^{
        [PEXMessageManager onFileAcceptReject:msgId accept:accept];
    }];
}

/**
* Helper for accepting / rejecting files.
*
* @param ctxt
* @param messageId
* @param isAccepted
*/
+(void) onFileAcceptReject: (NSNumber *) msgId accept: (BOOL) accept{
    PEXDbMessage * msg = [PEXDbMessage initById:[PEXDbAppContentProvider instance] messageId:[msgId longLongValue]];
    if (!accept){
        [PEXFtUtils setMessageToRejected:[msgId longLongValue] cr:[PEXDbAppContentProvider instance]];
    }

    [PEXFtTransferManager dispatchDownloadTransfer:msg accept:@(accept)];
}

/**
* Removes metadata prefix added by MSILO Opensips module
* Matching regex [Offline Message ... ] ...
*/
+(NSString *) removeOfflineMessageMetadata: (NSString *) body{
    NSRegularExpression * regex = [PEXRegex regularExpressionWithString: @"(?i)^\\s*\\[offline.+?\\]\\s*" isCaseSensitive:NO error:nil];
    return [regex stringByReplacingMatchesInString:body options:0 range:NSMakeRange(0, body.length) withTemplate:@""];
}

+ (PEXMessageManager *)instance {
    static PEXMessageManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

/**
* Clears certificate cache - called on a certificate update event.
*/
-(void) clearCertCache {
    // NSCache is synchronized internally.
    [self.certCache removeAllObjects];

    DDLogDebug(@"Cert cache cleared");
}

/**
* Returns true if connectivity is valid - can be used.
*/
-(BOOL) isConnected {
    // Ask system if we are connected. Use stored value from last connectivity change notification.
    if (self.connected == nil){
        // Application should not be able to login without connection, thus return yes.
        // Later connectivity indicator should be available.
        return YES;
    }

    return [self.connected boolValue];
}

/**
* Acknowledged received
* @param statusErrorCode - status code (positive or negative) from PjSip
*/
-(void) acknowledgmentFromPjSip: (NSString*) to returnedFinalMessage: (NSString *) returnedFinalMessage
                       statusOk: (BOOL) statusOk reasonErrorText: (NSString *) reasonErrorText
                statusErrorCode: (int) statusErrorCode
{
    [self addTaskWithName:@"ack" toQueue:^(PEXMessageManager * mgr){
        DDLogDebug(@"Receiving [%d] pjsip acknowledgment for message sent to [%@]", statusOk, to);
        NSString * finalMessageHash = [PEXMessageManager computeMessageHash:returnedFinalMessage];

        // Load sip message ID here.
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        NSNumber * msgID = nil; // invalid id
        PEXDbCursor * c = [cr query:[PEXDbMessageQueue getURI]
                         projection:[PEXDbMessageQueue getSendingAckProjection]
                          selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=? AND %@=1",
                                                               PEX_MSGQ_FIELD_TO, PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH, PEX_MSGQ_FIELD_IS_PROCESSED]
                      selectionArgs:@[to, finalMessageHash]
                          sortOrder:nil];
        if (c != nil) {
            @try {
                if ([c moveToFirst]){
                    msgID = [c getInt64:[c getColumnIndex:PEX_MSGQ_FIELD_ID]];
                }
            } @catch (NSException * e) {
                DDLogError(@"Error while getting message ID, exception=%@", e);
            } @finally {
                [PEXUtils closeSilentlyCursor:c];
            }
        }

        if (msgID == nil){
            DDLogError(@"Received acknowledgment for non-existing message in message queue, to=[%@], hash=[%@]", to, finalMessageHash);
            return;
        }

        PEXDbMessageQueue * queuedMessage = [PEXDbMessageQueue getById:cr messageId:[msgID longLongValue]];
        if (statusErrorCode == PJSIP_SC_ACCEPTED){
            queuedMessage.isOffline = @(YES);
        }

        if (statusOk){
            // error code may represent something like "Offline message"
            PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_ACK_POSITIVE pjsipErrorCode:statusErrorCode pjsipErrorText:reasonErrorText];
            // after positive ack, we can delete the message
            [mgr deleteAndReportToAppLayer:queuedMessage state:state];

        } else {
            // report negative ack back to app layer
            PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_ACK_NEGATIVE pjsipErrorCode:statusErrorCode pjsipErrorText:reasonErrorText];
            // statusInt - this has unknown function, do not report back
            PEXAmpDispatcher * ampDispatcher = [[PEXAmpDispatcher alloc] init];
            [ampDispatcher reportState:queuedMessage sendingState:state];

            // Plan resend (if max hasnt been reached yet)
            // Mark as unprocessed (counter was already increased after message was sent).
            if (queuedMessage.sendCounter != nil && [queuedMessage.sendCounter integerValue] >= [mgr getMaxResendAttempts]){
                DDLogInfo(@"Maximum number of resends has been reached [%@], marking as failed", queuedMessage.sendCounter);
                [mgr deleteAndReportToAppLayer:queuedMessage state:[PEXSendingState getReachedMaxNumOfResends]];

            } else if (queuedMessage.sendCounter != nil && [queuedMessage.sendCounter integerValue] < RESEND_BACKOFF_THRESHOLD){
                DDLogDebug(@"Planning immediate resend of message with id [%@]", queuedMessage.id);
                [mgr setMessageProcessed:[msgID longLongValue] isProcessed:NO];

            } else {
                [mgr setupBackoffResend:queuedMessage stackError:NO];
            }
        }
    }];
}

-(void) onTransferFinished: (int64_t) msgId queueMsgId: (int64_t) queueMsgId statusOk: (BOOL) statusOk recoverable: (BOOL) recoverable
{
    if (queueMsgId < 0){
        DDLogError(@"Cannot accept transfer finish event, negative queue id.");
        return;
    }

    [self addTaskWithName:@"ack" toQueue:^(PEXMessageManager * mgr){
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        DDLogDebug(@"Receiving FT ack for message id=%lld qMsgId=%lld, ok=%d", msgId, queueMsgId, statusOk);

        PEXDbMessageQueue * queuedMessage = [PEXDbMessageQueue getById:cr messageId:queueMsgId];
        // If there is non-recoverable error, remove and do not process message again.
        if ((!statusOk && !recoverable) || queuedMessage == nil){
            DDLogVerbose(@"Non-recoverable error detected, setting to failed state");
            [mgr deleteAndReportToAppLayer:queuedMessage state:[PEXSendingState getGenericFail]];

            // Delete temporary files associated with given message id.
            [PEXDbFileTransfer deleteTempFileByDbMessageId:msgId cr:cr];

        } else if (statusOk){
            // error code may represent something like "Offline message"
            PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_ACK_POSITIVE pjsipErrorCode:200 pjsipErrorText:nil];
            // after positive ack, we can delete the message
            [mgr deleteAndReportToAppLayer:queuedMessage state:state];

        } else {
            // report negative ack back to app layer
            PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_ACK_NEGATIVE pjsipErrorCode:-1 pjsipErrorText:nil];
            // statusInt - this has unknown function, do not report back
            PEXAmpDispatcher * ampDispatcher = [[PEXAmpDispatcher alloc] init];
            [ampDispatcher reportState:queuedMessage sendingState:state];

            // Plan resend (if max hasnt been reached yet)
            // Mark as unprocessed (counter was already increased after message was sent).
            if (queuedMessage.sendCounter != nil && [queuedMessage.sendCounter integerValue] >= [mgr getMaxResendAttempts]){
                DDLogInfo(@"Maximum number of resents has been reached [%@], marking as failed", queuedMessage.sendCounter);
                [mgr deleteAndReportToAppLayer:queuedMessage state:[PEXSendingState getReachedMaxNumOfResends]];

            } else if (queuedMessage.sendCounter != nil && [queuedMessage.sendCounter integerValue] < RESEND_BACKOFF_THRESHOLD){
                DDLogDebug(@"Planning immediate resend of message with id [%@]", queuedMessage.id);
                [mgr increaseSendCtr:queueMsgId sendCtr:queuedMessage.sendCounter qMessage:queuedMessage];
                [mgr setMessageProcessed:queueMsgId isProcessed:NO];

            } else {
                [mgr increaseSendCtr:queueMsgId sendCtr:queuedMessage.sendCounter qMessage:queuedMessage];
                [mgr setupBackoffResend:queuedMessage stackError:NO];
            }
        }
    }];
}

-(int) increaseSendCtr:(int64_t) queueMsgId sendCtr: (NSNumber *) sendCtr qMessage: (PEXDbMessageQueue *) qMessage {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
    int newSendCtr = sendCtr == nil ? 1 : sendCtr.intValue + 1;
    [args put:PEX_MSGQ_FIELD_SEND_COUNTER integer:newSendCtr];

    if (qMessage != nil) {
        qMessage.sendCounter = @(newSendCtr);
    }

    return [PEXDbMessageQueue updateMessage:[PEXDbAppContentProvider instance] messageId:queueMsgId cv:args];
}

-(int) increaseSendAttemptCtr:(int64_t) queueMsgId sendCtr: (NSNumber *) sendCtr qMessage: (PEXDbMessageQueue *) qMessage {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
    int newSendCtr = sendCtr == nil ? 1 : sendCtr.intValue + 1;
    [args put:PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER integer:newSendCtr];

    if (qMessage != nil) {
        qMessage.sendAttemptCounter = @(newSendCtr);
    }

    return [PEXDbMessageQueue updateMessage:[PEXDbAppContentProvider instance] messageId:queueMsgId cv:args];
}

/**
* Loads messages stored in the database stored for further processing.
*/
-(PEXDbCursor *) loadMessagesToProcess: (BOOL) incoming outgoing: (BOOL) outgoing {
    if (!incoming && !outgoing){
        return nil;
    }

    PEXDbCursor * cOutgoingText = [PEXDbEmptyCursor instance];
    PEXDbCursor * cOutgoingNotifs = [PEXDbEmptyCursor instance];
    PEXDbCursor * cIncoming = [PEXDbEmptyCursor instance];
    PEXDbCursor * cIncomingTransfer = [PEXDbEmptyCursor instance];
    PEXDbCursor * cOutgoingTransfer = [PEXDbEmptyCursor instance];

    @try{
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        if (incoming){
            cIncoming = [cr query:[PEXDbMessageQueue getURI]
                       projection:[PEXDbMessageQueue getFullProjection]
                        selection:[NSString stringWithFormat:@" WHERE %@", [PEXMessageManager getSelectIncoming]]
                    selectionArgs:@[]
                        sortOrder:[NSString stringWithFormat:@" ORDER BY %@ ASC", PEX_MSGQ_FIELD_TIME]];
        }

        if (outgoing){
            // Text messages are processed one by one, to preserve ordering.
            // Outgoing file transfer notification is included in this also so ordering is preserved.
            cOutgoingText = [cr query:[PEXDbMessageQueue getOldestPerRecipientURI]
                           projection:[PEXDbMessageQueue getFullProjection]
                            selection:[NSString stringWithFormat:@"WHERE %@=1 AND ((%@=%d) OR (%@=%d))",
                                            PEX_MSGQ_FIELD_IS_OUTGOING,
                                            PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                                            PEX_AMP_TEXT,
                                            PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                                            PEX_AMP_NOTIFICATION_CHAT]
                        selectionArgs:@[]
                            sortOrder:nil];

            if (cOutgoingText == nil){
                DDLogWarn(@"cursorOutgoingTexts is null");
            } else {
                DDLogVerbose(@"cursorOutgoingTexts is not null, size is [%d]", [cOutgoingText getCount]);
            }

            // Notifications are processed in parallel
            // TODO processing FileNotifs in parallel means that they can be send in mix
            cOutgoingNotifs = [cr query:[PEXDbMessageQueue getURI]
                             projection:[PEXDbMessageQueue getFullProjection]
                              selection:[NSString stringWithFormat:@"WHERE %@=1 AND %@=%d AND %@=0",
                                              PEX_MSGQ_FIELD_IS_OUTGOING,
                                              PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                                              PEX_AMP_NOTIFICATION,
                                              PEX_MSGQ_FIELD_IS_PROCESSED]
                          selectionArgs:@[]
                              sortOrder:[NSString stringWithFormat:@" ORDER BY %@ ASC", PEX_MSGQ_FIELD_TIME]];

            // File transfer requests processed in parallel.
            cOutgoingTransfer = [cr query:[PEXDbMessageQueue getURI]
                             projection:[PEXDbMessageQueue getFullProjection]
                              selection:[NSString stringWithFormat:@"WHERE %@=1 AND %@=%d AND %@=0",
                                              PEX_MSGQ_FIELD_IS_OUTGOING,
                                              PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                                              PEX_AMP_FTRANSFER,
                                              PEX_MSGQ_FIELD_IS_PROCESSED]
                          selectionArgs:@[]
                              sortOrder:[NSString stringWithFormat:@" ORDER BY %@ ASC", PEX_MSGQ_FIELD_TIME]];

            if (cOutgoingTransfer != nil) {
                DDLogVerbose(@"cOutgoingTransfer is not null, size is [%d]", [cOutgoingTransfer getCount]);
            }

            // File transfer requests processed in parallel.
            // Download is ingoing message but behaves like upload, connectivity is required, backoff & so on.
            cIncomingTransfer = [cr query:[PEXDbMessageQueue getURI]
                               projection:[PEXDbMessageQueue getFullProjection]
                                selection:[NSString stringWithFormat:@"WHERE %@=0 AND %@=%d AND %@=0",
                                                PEX_MSGQ_FIELD_IS_OUTGOING,
                                                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                                                PEX_AMP_FTRANSFER,
                                                PEX_MSGQ_FIELD_IS_PROCESSED]
                            selectionArgs:@[]
                                sortOrder:[NSString stringWithFormat:@" ORDER BY %@ ASC", PEX_MSGQ_FIELD_TIME]];
        }
    } @catch(NSException * ex){
        DDLogError(@"Exception in loading messages to process, exception=%@", ex);
    }

    //return cOutgoingText;
    return [PEXDbMergeCursor mergeCursors:cIncoming c2:cOutgoingText c3:cOutgoingNotifs c4:cOutgoingTransfer c5:cIncomingTransfer];
}

/**
* Callback from ContentObserver.
* Should be executed on handler thread.
*
* Currently handles decryption and encryption.
*
* @param selfChange
*/
-(void) databaseChanged: (BOOL) selfChange uri: (PEXUri *) uri fromObserver: (BOOL) fromObserver{
    // Identity is required for the operation, if does not
    // exist, try to load, if it is not possible, do nothing.
    if (self.privData == nil){
        DDLogError(@"User identity not found.");
        return;
    }

    // Ignore changes caused by own processing.
    // TODO: fix self change reporting, does not work for now...
//    if (selfChange){
//        DDLogVerbose(@"Ignoring self-change.");
//        return;
//    }

    // Detect if we have valid connectivity, if not, do not process messages for encryption.
    BOOL connectivityValid = [self isConnected];

    // Select those messages in conversation which are encrypted and not decrypted yet.
    PEXDbCursor * c = [self loadMessagesToProcess:YES outgoing:connectivityValid];

    if (c == nil){
        DDLogDebug(@"Cursor is null, no messages to process");
        return;
    }

    // Get number of results, if is empty -> nothing to do.
    const int msgCount = [c getCount];
    if (msgCount == 0){
        [PEXUtils closeSilentlyCursor: c];

        DDLogVerbose(@"Nothing to process, connectivity=%d", connectivityValid);
        return;
    }

    DDLogVerbose(@"Messages waiting for processing: %d, net=%d", msgCount, connectivityValid);
    for(int cur = 0; [c moveToNext]; ++cur){
        PEXDbMessageQueue * msg = nil;

        @try {
            msg = [[PEXDbMessageQueue alloc] initWithCursor:c];
            if (msg.id == nil || [msg.id isEqualToNumber:@(0)]){
                DDLogError(@"Invalid message id? Msg: %@", msg);
            }

            DDLogDebug(@"processing message %d/%d; protocolType/Version=%@/%@; id=%@", cur, msgCount,
                    msg.transportProtocolType, msg.transportProtocolVersion, msg.id);

            // Obtain canonical contact name, required for loading a certificate.
            NSString * const remoteContact = [PEXSipUri getCanonicalSipContact:msg.getRemoteContact includeScheme:NO];

            if (msg.isOutgoing != nil && [msg.isOutgoing boolValue]){
                [self processOutgoingMessage:remoteContact msg:msg];
            } else {
                [self processIncomingMessage:remoteContact msg:msg];
            }

        } @catch(NSException * e){
            DDLogError(@"Exception during decrypting message, exception=%@", e);
        }
    }

    [PEXUtils closeSilentlyCursor: c];
}

/**
* Processes incoming message
* Assumes identity is already loaded.
*
* @param remote		remote party identifier in canonical form.
* @param msg			Message to decrypt.
*/
-(void) processIncomingMessage: (NSString const * const) remote msg: (PEXDbMessageQueue *) msg{
    DDLogDebug(@"Processing incoming message from [%@], message [%@]", remote, msg);
    if (msg == nil || msg.id == nil){
        DDLogWarn(@"Mallformed message");
        return;
    }

    if (msg.isProcessed != nil && [msg.isProcessed boolValue]){
        DDLogInfo(@"Outgoing message to process is marked as processed, do not send.");
        // processed messages - Do not give a fuck
        return;
    }
    // do not send messages that have planned future backoff - to avoid adding more unsuccessful trials and possibly extending backoff time
    else if (msg.resendTime != nil && [[NSDate date] compare:msg.resendTime] == NSOrderedAscending) {
        DDLogInfo(@"Outgoing message to process has resend time [%@] set in the future, do not send yet.", msg.resendTime);
        return;
    }

    // Try to encrypt/decrypt the given message.
    @try {
        // Loads certificate for the sender.
        PEXCertificate * remoteCert = [self fetchCertificate:remote];

        if (remoteCert == nil){
            // TODO: propagate missing cert also to SipMessages
            // setMessageInvalid(msg.getId(), SipMessage.ERROR_MISSING_CERT);

            [self deleteMessage:[msg.id longLongValue]];
            DDLogWarn(@"certificate is missing for user: %@", remote);
            return;
        }

        // Message is marked as processed so we are waiting for acknowledgment
        [self setMessageProcessed:[msg.id longLongValue] isProcessed:YES];
        BOOL processingOK = NO;

        @try {
            PEXTransportProtocolDispatcher * transportDispatcher =
                    [PEXTransportProtocolDispatcher dispatcherWithRemoteCert:remoteCert userIdentity:self.privData];
            [transportDispatcher receive:msg];
            processingOK = YES;

        } @catch (NSException * e){
            DDLogError(@"processIncomingMessage(), exception=%@", e);
        } @finally {
            // If this is filetransfer type, do not delete it, it will be deleted once
            // download is complete, if no fail hapenned.
            if (!processingOK || [msg.messageProtocolType integerValue] != PEX_AMP_FTRANSFER){
                [self deleteMessage:[msg.id longLongValue]];
            }
        }
    } @catch (NSException * e){
        DDLogWarn(@"Exception during decrypting message, exception=%@", e);
        [self deleteMessage:[msg.id longLongValue]];
    }
}

-(void) processOutgoingMessage: (NSString const * const) remote msg: (PEXDbMessageQueue *) msg{
    // Can obtain message which is failed and should be re-sended.
    if (msg == nil || msg.id == nil || msg.from == nil){
        DDLogError(@"Mallformed message");
        return;
    }

    if (msg.isProcessed != nil && [msg.isProcessed boolValue]){
        DDLogInfo(@"Outgoing message to process is marked as processed, do not send.");
        // processed messages - Do not give a fuck
        return;
    }

    // do not send messages that have planned future backoff - to avoid adding more unsuccessful trials and possibly extending backoff time
    else if (msg.resendTime != nil && [[NSDate date] compare:msg.resendTime] == NSOrderedAscending) {
        DDLogInfo(@"Outgoing message to process has resend time [%@] set in the future, do not send yet.", msg.resendTime);
        return;
    }

    // Obtain user record for the local user.
    PEXDbContentProvider *contentProvider = [PEXDbAppContentProvider instance];
    PEXDbUserProfile * sender = [PEXDbUserProfile getProfileWithName:msg.from cr:contentProvider projection:[PEXDbUserProfile getFullProjection]];

    if (sender == nil || sender.id == nil){
        [self deleteAndReportToAppLayer:msg state:[PEXSendingState getInvalidDestination]];
        DDLogError(@"Cannot get local user for the sender: %@", msg.from);
        return;
    }

    // Test if it is possible to send this message somehow.
    BOOL accountValid = NO;
    @try {
        // TODO: test if current account is valid - SIP registered / XMPP registered.
        accountValid = YES; //service.getBinder().isAccountSipValid(remote, (int) sender.id);
    } @catch (NSException * e) {
        DDLogError(@"Cannot verify if account is valid, exception=%@", e);
    }

    // If account is not valid, do not try to send message, it wouldn't succeed anyway.
    // Such message has to wait in queue until there is some valid account.
    if (!accountValid){
        DDLogDebug(@"Account [%@] is not valid to send to [%@]", sender.id, remote);
        return;
    }

    // Plaintext is in the body of the sip message.
    // try and synchronized block in case of troubles
    @try {
        // Loads certificate for the sender.
        PEXCertificate * remoteCert = [self fetchCertificate:remote];

        if (remoteCert == nil){
            // SipMessage.setMessageError(getContext().getContentResolver(), msg.getId(), SipMessage.MESSAGE_TYPE_ENCRYPT_FAIL, SipMessage.ERROR_MISSING_CERT, "");

            [self deleteAndReportToAppLayer:msg state:[PEXSendingState getMissingRemoteCert]];
            DDLogWarn(@"certificate is missing for user: %@", remote);
            return;
        }

        // Message is marked as processed so we are waiting for acknowledgment
        [self setMessageProcessed:[msg.id longLongValue] isProcessed:YES];

        PEXAmpDispatcher * ampDispatcher = [[PEXAmpDispatcher alloc] init];
        [ampDispatcher reportState:msg sendingState:[PEXSendingState getSending]];

        // transmit message
        PEXTransportProtocolDispatcher * transportDispatcher =
                [PEXTransportProtocolDispatcher dispatcherWithRemoteCert:remoteCert userIdentity:self.privData];

        // TODO unify setters so we do not have to think of every possible setter that is required for transmit call
        transportDispatcher.messageQueueListener = self;
        [transportDispatcher transmit: msg];
    }
    @catch (NSException * e) {
        DDLogError(@"Exception in message fragment background task, exception=%@", e);
        [self deleteAndReportToAppLayer:msg state:[PEXSendingState getGenericFail]];
        return;
    }
}

/**
* Tries to load remote certificate if available, otherwise try to fetch it from the server.
*
* @param remote
* @return
* @throws Exception
*/
-(PEXCertificate *) fetchCertificate: (NSString const * const) remote {
    // Control variables telling whether is needed to perform
    // certificate server re-check.
    // Certificate may be old, missing or invalid. Check it to be sure, before
    // starting encryption with it.
    BOOL recheckNeeded = NO;
    NSString * existingCertHash2recheck = nil;

    // Certificate might be in the middle of synchronization right now,
    // if it is, wait for sync finish.
    const uint64_t waitStarted = [PEXUtils currentTimeMillis];
    const uint64_t waitDeadline = waitStarted + 1000*3;

    uint64_t curTime = waitStarted;
    BOOL certSyncInProgress = NO;
    while(curTime <= waitDeadline){
        [self throwIfCancelled];

        certSyncInProgress = [self isCertSyncInProgress: remote];
        if (!certSyncInProgress){
            break;
        }

        // Sleep 500 ms.
        [NSThread sleepForTimeInterval:0.5];
        curTime = [PEXUtils currentTimeMillis];
    }

    // load certificate for remoteSip, certificate update might just finished.
    PEXDbUserCertificate * sc = [self getCertificate:remote];
    if (sc != nil && sc.certificateStatus != nil && [sc.certificateStatus isEqualToNumber:@(CERTIFICATE_STATUS_OK)]){
        @try {
            return [PEXCertificate certificateWithCert:[sc getCertificateObj]];
        } @catch(NSException * e){
            DDLogError(@"Certificate format is crippled for user %@, exception=%@", remote, e);
        }
    }


    // If remote certificate fetching is not permitted, quit.
    if (!self.fetchCertIfMissing){
        return nil;
    }

    // certificate not found in database: re-query it
    DDLogDebug(@"Certificate for remote user is not stored locally, loading from server");
    existingCertHash2recheck = nil;
    [self throwIfCancelled];

    DDLogDebug(@"Certificate re-check: %d; hash=%@", recheckNeeded, existingCertHash2recheck);

    // Obtain domain part
    PEXSIPURIParsedSipContact * parsedUri = [PEXSipUri parseSipContact:remote];
    if (parsedUri == nil || parsedUri.domain == nil || [PEXUtils isEmpty:parsedUri.domain]){
        DDLogWarn(@"Sip is invalid, no domain found: %@", remote);
        return nil;
    }

    // Re-use re-check certificate code
    PEXCertRefreshParams * refreshParam = [PEXCertRefreshParams paramsWithUser:remote forceRecheck:NO existingCertHash2recheck:existingCertHash2recheck];
    PEXCertRefreshTask * refreshTask = [[PEXCertRefreshTask alloc] initWithPrivData:self.privData params:refreshParam];

    [refreshTask refreshCertificates];
    if ([refreshTask didLoadedValidCertificateForUser:remote]){
        return [refreshTask getResultCertificate:remote];
    }

    return nil;
}

-(BOOL) isCertSyncInProgress: (NSString const * const) remote {
    // TODO: implement certificate synchronization & its detection.
    return NO;
}

/**
* Assumes normalized user name without scheme.
* @param user
* @return
*/
-(PEXDbUserCertificate *) getCertificate: (NSString *) user{
    // Is in LRU cache? If yes, return directly.
    // NSCache is synchronized internally.
    id sc = [self.certCache objectForKey:user];
    if (sc != nil && [sc isMemberOfClass:[PEXDbUserCertificate class]]){
        return (PEXDbUserCertificate *) sc;
    }

    // Load certificate for user from local database.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbUserCertificate * remoteCert = [PEXDbUserCertificate newCertificateForUser: user cr:cr projection:[PEXDbUserCertificate getFullProjection]];
    if (remoteCert == nil){
        DDLogDebug(@"Certificate not found for user: %@", user);
        remoteCert = [[PEXDbUserCertificate alloc] init];
        remoteCert.certificateStatus = @(CERTIFICATE_STATUS_MISSING);
    }

    // NSCache is synchronized internally.
    [self.certCache setObject:remoteCert forKey:user];
    return remoteCert;
}

// delete message with reason for deleting (SendingState), which is reported back to application layer
-(int) deleteAndReportToAppLayer: (PEXDbMessageQueue *) msg state: (PEXSendingState *) state{
    if (msg == nil || msg.id == nil){
        DDLogDebug(@"Message is null / id is null");
        return 0;
    }

    if (msg.isProcessed == nil || ![msg.isProcessed boolValue]){
        [self setMessageProcessed:[msg.id longLongValue] isProcessed:YES];
    }

    if (msg.isOffline != nil && [msg.isOffline boolValue]){
        [self setMessageOffline:[msg.id longLongValue] isOffline:YES];
    }

    PEXAmpDispatcher * ampDispatcher = [[PEXAmpDispatcher alloc] init];
    [ampDispatcher reportState:msg sendingState:state];
    return [self deleteMessage:[msg.id longLongValue]];
}

// in some cases (bad HMAC, do not even store the message, just delete)
-(int) deleteMessage: (int64_t) messageId {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    return [cr delete:[PEXDbMessageQueue getURI]
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]];
}

-(int) setMessageProcessed: (int64_t) messageId isProcessed: (BOOL) isProcessed {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_IS_PROCESSED boolean: isProcessed];

    DDLogDebug(@"Setting message with id [%lld] as processed [%d]", messageId, isProcessed);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    return [PEXDbMessageQueue updateMessage:cr messageId:messageId cv:cv];
}

-(int) setMessageOffline: (int64_t) messageId isOffline: (BOOL) isOffline {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_IS_OFFLINE boolean: isOffline];

    DDLogDebug(@"Setting message with id [%lld] as offline [%d]", messageId, isOffline);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    return [PEXDbMessageQueue updateMessage:cr messageId:messageId cv:cv];
}

// when sending, we store final message for possible resend (so we do not have to compute all values again)
-(int) storeFinalMessageWithHash: (int64_t) messageId finalMessage: (NSString *) finalMessage {
    NSString * hash = [PEXMessageManager computeMessageHash:finalMessage];

    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_FINAL_MESSAGE string: finalMessage];
    [cv put:PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH string:hash];

    DDLogDebug(@"Storing hash for outgoing message id [%lld], hash [%@]", messageId, hash);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    return [cr update:[PEXDbMessageQueue getURI]
        ContentValues:cv
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]];
}

/**
* Adds given task to the internal queue.
*/
-(void) addTaskToQueue: (void (^)(PEXMessageManager * mgr)) task {
    [self addTaskWithName:@"" toQueue:task];
}

-(void) addTaskWithName: (NSString*) name toQueue: (void (^)(PEXMessageManager * mgr)) task {
    // Wrap block with another block - weak self reference.
    __weak __typeof(self) weakSelf = self;
    [self.workerQueue addOperationWithBlock: ^{ @autoreleasepool {
        __strong PEXMessageManager * mgr = weakSelf;
        DDLogVerbose(@"<mgr_task_%@>", name);
        task(mgr);
        DDLogVerbose(@"</mgr_task_%@>", name);
    }}];
}

/**
* Returns whether current operation should be cancelled.
* Uses local canceller.
*
* @return
*/
-(BOOL) isCancelled{
    if (self.canceller == nil) return NO;
    return [self.canceller isCancelled];
}

/**
* Throws OperationCancelledException if canceller cancels.
* @throws OperationCancelledException
*/
-(void) throwIfCancelled {
    if ([self isCancelled]) [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Message manager cancelled"];
}

/**
* Handles unsuccessful message send attempt.
*
* @param mDesc
*/
-(void) handleSendFailed: (PEXMessageSentDescriptor *) mDesc{
    if (mDesc == nil || mDesc.messageId <= 0){
        return;
    }

    PEXDbAppContentProvider * cr = (PEXDbAppContentProvider *) [PEXDbAppContentProvider instance];
    PEXDbMessageQueue * msg = [PEXDbMessageQueue getById:cr messageId:mDesc.messageId];
    if (msg == nil){
        DDLogWarn(@"Message is null, id=%lld", mDesc.messageId);
        return;
    }

    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];

    // Get message send date.
    NSDate * msgDate = msg.time;
    NSDate * curTime = [NSDate date];

    // Fix potentially incorrect date.
    if (msgDate == nil){
        msgDate = curTime;
        [args put:PEX_MSGQ_FIELD_TIME date: msgDate];
    }

    // For monitoring lost messages (send, without feedback from PJSIP), blocking sending queue.
    [args put:PEX_MSGQ_FIELD_LAST_SEND_CALL date: [NSDate date]];

    // Increase message send attempt.
    [self increaseSendAttemptCtr:[msg.id longLongValue] sendCtr:msg.sendAttemptCounter qMessage:msg];

    // If message is too old, switch to failed.
    if (msg.sendAttemptCounter == nil || [msg.sendAttemptCounter integerValue] < RESEND_STACK_BACKOFF_THRESHOLD) {
        // If message is young, convert back to queued message and send rightaway.
        [args put:PEX_MSGQ_FIELD_IS_PROCESSED boolean:NO];
        // Ciphertext is cleared so new one is generated before sending. It may contain time sensitive / counter data
        // which may need to be regenerated with each resend attempt.
        [args put:PEX_MSGQ_FIELD_FINAL_MESSAGE string:@""];
        [args put:PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH string:@""];
        [PEXDbMessageQueue updateMessage:cr messageId:mDesc.messageId cv:args];
        DDLogVerbose(@"Message returned to queue again [%@] without backoff.", msg);
        return;

    } else if (msg.sendAttemptCounter != nil && [msg.sendAttemptCounter integerValue] > [self getMaxResendStackAttempts]){
        // Resend attempt number is way too high, mark message as failed.
        DDLogInfo(@"Maximum number of stack resends has been reached [%@], marking as failed", msg.sendAttemptCounter);
        [self deleteAndReportToAppLayer:msg state:[PEXSendingState getSendingFail]];
        return;

    } else {
        // Message should be backed off and send later. Something may be wrong with the stack / connectivity.
        // This causes message is not re-sent immediatelly, preventing rapid sending of the message on msg update.
        DDLogVerbose(@"Message with id %@ set to backoff. Attempt ctr: %@", [msg id], [msg sendAttemptCounter]);
        [PEXDbMessageQueue updateMessage:cr messageId:mDesc.messageId cv:args];
        [self setupBackoffResend:msg stackError:YES];
    }
}

/**
* Event triggered when message was passed to the message stack for sending.
* @param mDesc
*/
-(void) onMessageSent: (PEXMessageSentDescriptor *) mDesc{
    if (mDesc == nil || mDesc.messageId <= 0){
        return;
    }

    // Handle unsuccessful send message attempt.
    if (mDesc.sendResult == nil) {
        DDLogDebug(@"Unable to send message to [%@], sendStatus: %d, desc=%@", mDesc.recipient, mDesc.stackSendStatus, mDesc);
        [self handleSendFailed:mDesc];
        return;
    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    int counter = [PEXDbMessageQueue loadSendCounter:cr messageId:mDesc.messageId];

    // successful sending => update send counter
    if (mDesc.messageId > 0){
        PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
        [args put:PEX_MSGQ_FIELD_SEND_COUNTER integer: ++counter];

        // For monitoring lost messages (send, without feedback from PJSIP), blocking sending queue.
        [args put:PEX_MSGQ_FIELD_LAST_SEND_CALL date: [NSDate date]];

        [PEXDbMessageQueue updateMessage:cr messageId:mDesc.messageId cv:args];
        DDLogDebug(@"Updated msg [id=%lld]", mDesc.messageId);
    } else {
        DDLogError(@"onMessageSent(): QueuedMessage has negative ID [%lld]", mDesc.messageId);
    }
}

/**
* Send a bunch of files to a remote party.
*/
-(void) sendFile: (NSString *) from  to: (NSString *) to title: (NSString *) title desc: (NSString *) desc files: (NSArray *) files {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbUserProfile * acc = [PEXDbUserProfile getProfileWithName:from cr:cr projection:[PEXDbUserProfile getAccProjection]];

    if (acc == nil || acc.id == nil){
        DDLogError(@"Cannot send message, user is null [%@]", acc);
        return;
    }

    @try {
        NSString * remoteSip = [PEXSipUri getCanonicalSipContact:to includeScheme:NO];
        NSArray * fileList = [self sanitizeFileSendList:files];
        NSString * msgBody = [PEXMessageManager getMsgBodyForFiles:title desc:desc files:fileList];

        // Save new message to the database.
        // Message manager will take care of it.
        PEXDbMessage * msg = [PEXDbMessage
                messageWithFrom:from
                             to:remoteSip
                        contact:remoteSip
                           body:msgBody
                       mimeType:PEXDBMessage_MIME_FILE
                           date:[NSDate date]
                           type:@(PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING)
                       fullFrom:remoteSip];

        msg.isOutgoing = @(YES);
        msg.read = @(NO);
        msg.sendDate = [NSDate date];
        PEXDbUri const * const lastInsertedUri = [cr insert:[PEXDbMessage getURI] contentValues:[msg getDbContentValues]];

        // Now dispatch the message (= put in MessageQueue).
        if (lastInsertedUri != nil && lastInsertedUri.itemId != nil){
            DDLogVerbose(@"Message about to dispatch, id=%@", lastInsertedUri.itemId);
            msg.id = lastInsertedUri.itemId;

            PEXFtUploadParams * params = [[PEXFtUploadParams alloc] init];
            params.title = title;
            params.desc = desc;
            params.destinationSip = remoteSip;
            params.msgId = [lastInsertedUri itemId];
            params.files = fileList;
            [PEXAmpDispatcher dispatchNewFileUpload:msg params:params];
            DDLogDebug(@"Message stored to the message queue.");

        } else {
            DDLogError(@"New outgoing message was not added to the DB");
        }

    } @catch (NSException * e){
        DDLogError(@"Not able to send message, exception=%@", e);
    }
}

-(void) sendMessage: (NSString *) from to: (NSString *) to body: (NSString *) body {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbUserProfile * acc = [PEXDbUserProfile getProfileWithName:from cr:cr projection:[PEXDbUserProfile getAccProjection]];

    if (acc == nil || acc.id == nil){
        DDLogError(@"Cannot send message, user is null [%@]", acc);
        return;
    }

    [PEXReport logUsrEvent:PEX_EVENT_SENT_TEXT_MESSAGE];
    @try {
        NSString * remoteSip = [PEXSipUri getCanonicalSipContact:to includeScheme:NO];

        // Save new message to the database.
        // Message manager will take care of it.
        PEXDbMessage * msg = [PEXDbMessage
                messageWithFrom:from
                             to:remoteSip
                        contact:remoteSip
                           body:body
                       mimeType:PEXDBMessage_MIME_TEXT
                           date:[NSDate date]
                           type:@(PEXDBMessage_MESSAGE_TYPE_QUEUED)
                       fullFrom:remoteSip];

        msg.isOutgoing = @(YES);
        msg.read = @(NO);
        msg.randNum = @([PEXCryptoUtils secureRandomUInt32:YES]);
        msg.sendDate = [NSDate date];
        DDLogDebug(@"Inserting SipMessage in DB [%@]", msg);

        PEXDbUri const * const lastInsertedUri = [cr insert:[PEXDbMessage getURI] contentValues:[msg getDbContentValues]];

        // Now dispatch the message (= put in MessageQueue).
        if (lastInsertedUri != nil && lastInsertedUri.itemId != nil){
            DDLogVerbose(@"Message about to dispatch, id=%@", lastInsertedUri.itemId);
            [PEXAmpDispatcher dispatchTextMessage: [[lastInsertedUri itemId] longLongValue]];
            [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_MESSAGE_STORED_FOR_SENDING object:nil userInfo:@{}];

        } else {
            DDLogError(@"Message added to the DB, but no ID returned %@", msg);
        }

        DDLogDebug(@"Message stored to the message queue.");
    } @catch (NSException * e){
        DDLogError(@"Not able to send message, exception=%@", e);
    }
}

+ (NSString *)computeMessageHash:(NSString *)message {
    return [PEXMessageDigest bytes2base64: [PEXMessageDigest md5Message:message]];
}

+ (NSString *)computeMessageHashData:(NSData *)message {
    return [PEXMessageDigest bytes2base64: [PEXMessageDigest md5:message]];
}

+ (void) readAllForSip: (NSString * const) sip
{
    if (sip == nil || [PEXStringUtils isEmpty:sip]){
        DDLogError(@"Invalid SIP argment: %@", sip);
        return;
    }

    // Get all message ids where read is zero. So we can send update
    PEXDbContentProvider * const cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * const cursor = [cr query:[PEXDbMessage getURI]
                                projection:[PEXDbMessage getFullProjection]
                                 selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=0 AND %@=0",
                                           PEXDBMessage_FIELD_FROM,
                                           PEXDBMessage_FIELD_IS_OUTGOING,
                                           PEXDBMessage_FIELD_READ]
                             selectionArgs:@[sip]
                                 sortOrder:nil];

    if (cursor == nil)
    {
        DDLogError(@"NULL cursor for messages read!");
        return;
    }

    NSMutableArray * const idArray = [[NSMutableArray alloc] init];
    NSMutableArray * const mrandArray = [[NSMutableArray alloc] init];

    while([cursor moveToNext])
    {
        PEXDbMessage * currentMessage = [PEXDbMessage messageFromCursor:cursor];

        if (currentMessage == nil)
        {
            DDLogError(@"NULL message !");
            continue;
        }

        [idArray addObject:[currentMessage.id stringValue]]; // For DB Query it has to be string.
        [mrandArray addObject:currentMessage.randNum];
    }

    // Set given messages as read.
    // Use only IDs so there is no race condition for messages received meanwhile.
    PEXDbContentValues * const cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_READ integer:1];
    [cv put:PEXDBMessage_FIELD_READ_DATE date:[NSDate date]];

    [[PEXDbAppContentProvider instance]
        update:[PEXDbMessage getURI]
        ContentValues:cv
        selection:[NSString stringWithFormat:@"WHERE %@ IN(%@)",
                   PEXDBMessage_FIELD_ID, [PEXUtils generateDbPlaceholders:(int)[idArray count]]]
        selectionArgs:idArray];

    // If there are some messages to ACK read, call dispatcher.
    if ([mrandArray count] > 0)
    {
        // Notify AMP dispatcher for read messages.
        [PEXAmpDispatcher dispatchReadAckNotification:[[PEXAppState instance] getPrivateData].username
                                                   to:sip nonces:mrandArray];
    }
}

+ (void) readMessage: (const PEXDbMessage * const) message
{
    if (message == nil){
        DDLogError(@"Message to ACK is nil!");
        return;
    }

    // Update read field.
    PEXDbContentValues * const cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_READ integer:1];
    [cv put:PEXDBMessage_FIELD_READ_DATE date:[NSDate date]];

    [[PEXDbAppContentProvider instance]
     update:[PEXDbMessage getURI]
     ContentValues:cv
     selection:[PEXDbMessage getWhereForId]
     selectionArgs:[PEXDbMessage getWhereForIdArgs:message.id]];

    // Notify dispatcher.
    [PEXAmpDispatcher dispatchReadAckNotification:message.to to:message.from nonces:@[message.randNum]];
}

+ (void) removeAllForContact: (const PEXDbContact * const) contact
{
    // so as not to delete all message when deleting a conversation with self

    PEXDbContentProvider * const cr = [PEXDbAppContentProvider instance];

    NSString * const where =
    ([[[PEXAppState instance] getPrivateData].username isEqualToString:contact.sip] ?
     [PEXDbMessage getWhereForSelf] :
     [PEXDbMessage getWhereForContact]);

    [PEXFtTransferManager deleteTransferRecords:cr forUser:contact.sip];

    [self removeAllForWhere:where arguments:[PEXDbMessage getWhereForContactArgs:contact] forProvider:cr];

    [PEXDbMessageQueue deleteQueuedMessages:cr to:contact.sip];
}

+ (void)removeMessageForId: (NSNumber * const) messageId
{
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    [PEXFtTransferManager deleteTransferRecords:cr withMessageId:[messageId longLongValue]];

    [cr
            delete: [PEXDbMessage getURI]
         selection: [PEXDbMessage getWhereForId]
     selectionArgs: @[messageId]];

    [PEXDbMessageQueue deleteQueuedMessage:cr withId:messageId];
}

+ (void) removeAllOlderThan: (const int64_t)seconds
{
    PEXDbContentProvider * const cr = [PEXDbAppContentProvider instance];

    PEXDbCursor * const cursor =
            [cr query:[PEXDbMessage getURI]
           projection:[PEXDbMessage getFullProjection]
            selection:[PEXDbMessage getWhereForOlderThan]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", seconds]]
            sortOrder:nil];

    NSMutableArray * const ids = [[NSMutableArray alloc] init];
    while (cursor && [cursor moveToNext])
    {
        const NSNumber * const id = [PEXDbMessage messageFromCursor:cursor].id;
        if (id)
            [ids addObject:id];
    }

    if (ids && (ids.count > 0))
    {
        [PEXFtTransferManager deleteTransferRecords:cr forMessageIds:ids];

        [cr delete:[PEXDbMessage getURI]
         selection:[PEXDbMessage getWhereForIds:ids]
     selectionArgs:[PEXDbMessage getWhereForIdsArgs:ids]];

        [PEXDbMessageQueue deleteQueuedMessages:cr forIds:ids];
    }

}

+ (void) removeAllForWhere: (NSString * const) where arguments: (NSArray * const) arguments
               forProvider: (PEXDbAppContentProvider * const) cr {
    [cr
            delete:[PEXDbMessage getURI]
         selection:where
     selectionArgs:arguments];
}

- (void)onBackoffTimerFired:(NSTimer *)timer {
    PEXBackoffFutureTimer * backoff = timer.userInfo;
    if (backoff == nil){
        DDLogWarn(@"Backoff timer is nil");
        return;
    }

    [self triggerAlarmCheck:backoff.to];
}

-(int) getMaxResendAttempts{
    // Up to 16 resends is currently required - it means that resend happends up to 335 s (TCP connection of remote contact should be disconnected,
    // it should be at this time sent as offline message)
    int resendAttempts = RESEND_BACKOFF_THRESHOLD + 16;
    DDLogVerbose(@"Current maximum number of resend attempts is [%d]", resendAttempts);
    return resendAttempts;
}

-(int) getMaxResendStackAttempts{
    int resendAttempts = RESEND_STACK_BACKOFF_THRESHOLD + 100;
    DDLogVerbose(@"Current maximum number of stack resend attempts is [%d]", resendAttempts);
    return resendAttempts;
}

-(NSTimeInterval) resendStackTimeDelay: (int) counter {
    // returns number of seconds
    if (counter <= 5) {
        return 1.0;
    } else if (counter <= 10){
        return 3.0;
    } else if (counter <= 25){
        return 10.0;
    } else {
        return 30.0;
    }
}

-(NSTimeInterval) resendTimeDelay: (int) counter{
    // returns number of seconds
    switch (counter){
        case 0:
            return 10.0;
        case 1:
            return 15.0;
        case 2:
            return 20.0;
        default:
            return 30.0;
    }
}

-(void) setupBackoffResend: (PEXDbMessageQueue *) msg stackError: (BOOL) stackError {
    // first check if there is a backoff planned for the same user
    // if so, synchronize backoff sending
    PEXBackoffFutureTimer * curBackoff = [self.futureResendAlarms get:msg.to];
    NSDate * resendTime = curBackoff != nil ? curBackoff.expiration : nil;

    long timeDelay;
    int backoffResendCounter;
    if (stackError){
        // Message could not be sent due to internal error.
        backoffResendCounter = [msg.sendAttemptCounter intValue] - RESEND_STACK_BACKOFF_THRESHOLD;
        timeDelay = (long) [self resendStackTimeDelay:backoffResendCounter] * 1000;

    } else {
        // Normal sending backoff due to connectivity problems / remote side / server unreachability.
        backoffResendCounter = [msg.sendCounter intValue] - RESEND_BACKOFF_THRESHOLD;
        timeDelay = (long) [self resendTimeDelay:backoffResendCounter] * 1000;
    }

    BOOL alarmExists = YES;

    if (curBackoff == nil){
        curBackoff = [[PEXBackoffFutureTimer alloc] init];
    }

    if (resendTime == nil){
        alarmExists = NO;
        resendTime = [NSDate dateWithTimeIntervalSinceNow:timeDelay / 1000.0];
    }

    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_IS_PROCESSED boolean:NO];
    [cv put:PEX_MSGQ_FIELD_RESEND_TIME date:resendTime];

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    int updated = [PEXDbMessageQueue updateMessage:cr messageId:[msg.id longLongValue] cv:cv];
    if (!updated){
        DDLogError(@"setupBackoffResend: Wrong number of updated messages [%d]", updated);
        return;
    }

    // update app layer
    PEXAmpDispatcher * ampDispatcher = [[PEXAmpDispatcher alloc] init];
    [ampDispatcher reportState:msg sendingState:[PEXSendingState getBackoff]];

    // If alarm for the user already exists, do not create a new one. One per user.
    if (alarmExists){
        DDLogInfo(@"Setting message with id [%@] to backoff resend; resendPlanned [%@], stackError: %d, #resends: %d. No new timer. Delay: %ld ",
                msg.id, resendTime, stackError, backoffResendCounter, timeDelay);
        return;
    }

    // Let AlarmManager invoke Intent for db check in given timeout
    msg.resendTime = resendTime;

    DDLogInfo(@"Setting message with id [%@] to backoff resend; resendTime [%@], stackError: %d, #resends: %d, "
            "resend in [%ld] millis, alarm!", msg.id, msg.resendTime, stackError, backoffResendCounter, timeDelay);

    curBackoff.expiration = resendTime;
    curBackoff.delay = timeDelay;
    curBackoff.to = msg.to;
    curBackoff.timer = [NSTimer timerWithTimeInterval:(timeDelay + 500) / 1000.0 target:self
                                             selector:@selector(onBackoffTimerFired:)
                                             userInfo:curBackoff repeats:NO];

    // Set timer to execute on main runloop. Should be most reliable way for both foreground / background mode.
    [[NSRunLoop mainRunLoop] addTimer:curBackoff.timer forMode:NSRunLoopCommonModes];

    // Store to concurrent map.
    [self.futureResendAlarms put:curBackoff key:msg.to async:NO];

    // INFO: queue is re-checked in each keep alive cycle so no backoff message is lost.
}

/**
* Called from upload task when file name collision was detected and needs to be fixed in notification message.
*/
+(void) fileNotificationMessageFnameUpdate: (PEXFtUploadParams *) params newFnames: (NSArray *) files {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_BODY string: [PEXMessageManager getMsgBodyForFnames:params.title desc:params.desc files:files]];
    [PEXDbMessage updateMessage:[PEXDbAppContentProvider instance] messageId:(uint64_t)[params.msgId longLongValue] contentValues:cv];
}

+(NSString *) getMsgBodyForFnames: (NSString *) title desc: (NSString *) desc files: (NSArray *) files {
    NSMutableString * msgBody = [[NSMutableString alloc] init];
    if (![PEXStringUtils isEmpty:title]){
        [msgBody appendString:title];
        if (files.count > 0){
            [msgBody appendString:@"\n\n"];
        }
    }

    if (files == nil || files.count == 0){
        return [NSString stringWithString:msgBody];
    }

    const NSUInteger cnt = files.count;
    NSUInteger curCtr = 0;
    for(NSString * fname in files){
        [msgBody appendString:fname];
        curCtr += 1;

        if (curCtr != cnt){
            [msgBody appendString:@"\n"];
        }
    }

    return [NSString stringWithString:msgBody];
}

+(NSString *) getMsgBodyForFiles: (NSString *) title desc: (NSString *) desc files: (NSArray *) files {
    NSMutableArray * fnames = [[NSMutableArray alloc] init];
    for(PEXFileToSendEntry * fe in files){
        NSString * fname = [PEXDhKeyHelper sanitizeFileName:fe.origFileName];
        [fnames addObject:fname];
    }

    return [self getMsgBodyForFnames:title desc:desc files:fnames];
}

-(NSArray *) sanitizeFileSendList: (NSArray *) files {
    NSMutableArray * newFiles = [[NSMutableArray alloc] initWithCapacity:files.count];
    for(id obj in files){
        if (obj == nil || [obj isKindOfClass:[NSNull class]]){
            DDLogError(@"Error, empty / null path in file2send array");
            continue;
        }

        if ([obj isKindOfClass:[NSString class]]) {
            [newFiles addObject:[PEXFileToSendEntry entryWithFile:(NSString *) obj]];
        } else if ([obj isKindOfClass:[NSURL class] ]){
            [newFiles addObject:[PEXFileToSendEntry entryWithURL:(NSURL *) obj]];
        } else if ([obj isKindOfClass:[PEXFileToSendEntry class]]){
            [newFiles addObject:obj];
        } else if ([obj isKindOfClass:[PEXSelectedFileContainer class]]){
            PEXSelectedFileContainer * container = (PEXSelectedFileContainer *) obj;
            PEXFileToSendEntry * etr = [PEXFileToSendEntry entryWithFile:container.url isAsset:container.isAsset];
            etr.origFileName = container.filename;
            etr.origSize     = container.size;
            [newFiles addObject:etr];
        } else {
            [NSException raise:PEXFileTransferGenericException format:@"Unknown entry in files param."];
        }
    }

    return [NSArray arrayWithArray:newFiles];
}

-(void) dbCheckOldProcessed:(PEXDbContentProvider *) cr {
    // Select all processed outgoing messages, which are not subject to backoff (fire timer older than X seconds)
    // and which had last send call Y seconds ago (so expiration had chance to trigger a feedback, but feedback got lost).
    // Messages subject to backoff have processed flag set to 0. 1 is set just before sending.
    // Only messages older than Z seconds are processed (too recent messages might be just in processing).
    NSDate * createTimeThr = [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] - 5*60];
    NSDate * resendTimeThr = [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] - 5*60];
    NSDate * lastSendThr = [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] - 5*60];
    // Numeric timestamp representation suitable for SQL query.
    NSNumber * createTimeThrNum = [PEXDbContentValues getNumericDateRepresentation:createTimeThr];
    NSNumber * resentTimeThrNum = [PEXDbContentValues getNumericDateRepresentation:resendTimeThr];
    NSNumber * lastSendThrNum = [PEXDbContentValues getNumericDateRepresentation:lastSendThr];

    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_IS_PROCESSED boolean:NO];

    // If there are such messages, set processed to 0 so they start over again.
    int affected = [cr updateEx:[PEXDbMessageQueue getURI]
                  ContentValues:cv
                      selection:[NSString stringWithFormat: @"WHERE %@=1 AND %@=1 AND %@ < ? AND %@ < ? AND %@ < ?",
                                                            PEX_MSGQ_FIELD_IS_PROCESSED,
                                                            PEX_MSGQ_FIELD_IS_OUTGOING,
                                                            PEX_MSGQ_FIELD_RESEND_TIME,
                                                            PEX_MSGQ_FIELD_LAST_SEND_CALL,
                                                            PEX_MSGQ_FIELD_TIME]
                  selectionArgs:@[resentTimeThrNum, lastSendThrNum, createTimeThrNum]];

    if (affected > 0) {
        DDLogWarn(@"Messages recovered from blocked state: %d", affected);
    }
}

-(void) dbCheckWithoutQueuedMsg:(PEXDbContentProvider *) cr {
    // 1. Select all outgoing messages from PEXDbMessage in states (queued, queued backoff, pending) and are older than X seconds.
    //      Do not load messages just sent, or just delivered. Avoid race conditions.
    NSDate * createTimeThr = [NSDate dateWithTimeIntervalSince1970: [[NSDate date] timeIntervalSince1970] - 2*60];
    // Numeric timestamp representation suitable for SQL query.
    NSNumber * createTimeThrNum = [PEXDbContentValues getNumericDateRepresentation:createTimeThr];
    PEXDbCursor * c = [cr query:[PEXDbMessage getURI]
                     projection:[PEXDbMessage getLightProjection]
                      selection:
                              [NSString stringWithFormat: @"WHERE %@=1 AND %@ IN(?,?,?) AND %@ < ?",
                                                          PEXDBMessage_FIELD_IS_OUTGOING,
                                                          PEXDBMessage_FIELD_TYPE,
                                                          PEXDBMessage_FIELD_DATE
                              ]
                  selectionArgs:@[
                          @(PEXDBMessage_MESSAGE_TYPE_PENDING),
                          @(PEXDBMessage_MESSAGE_TYPE_QUEUED),
                          @(PEXDBMessage_MESSAGE_TYPE_QUEUED_BACKOFF),
                          createTimeThrNum
                  ]
                      sortOrder:nil];
    if (c == nil){
        DDLogError(@"Cursor is nil");
        return;
    }

    NSMutableArray * ids = [NSMutableArray array];
    NSMutableSet * idsToRemove = [NSMutableSet set];
    @try {
        while([c moveToNext]){
            PEXDbMessage * cur = [PEXDbMessage messageFromCursor:c];
            [ids addObject:[cur.id stringValue]];
            [idsToRemove addObject:cur.id];
        }
    } @catch(NSException * e) {
        DDLogError(@"Exception when dumping message queue, %@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    // If there are no such messages -> nothing to do.
    DDLogVerbose(@"Messages with sending states to check: %d, %@", (int)[ids count], ids);
    if ([ids count] == 0){
        return;
    }

    // 2. Select all message queue messages with reference id in given set of values from the previous query.
    PEXDbCursor * cq = [cr query:[PEXDbMessageQueue getURI]
                      projection:[PEXDbMessageQueue getFullProjection]
                       selection:[NSString stringWithFormat: @"WHERE %@=1 AND %@ IN (%@)",
                                                             PEX_MSGQ_FIELD_IS_OUTGOING,
                                                             PEX_MSGQ_FIELD_REFERENCED_ID,
                                                             [PEXUtils generateDbPlaceholders:(int) [ids count]]]
                   selectionArgs:ids
                       sortOrder:nil];
    if (cq == nil){
        DDLogError(@"Cursor is nil");
        return;
    }

    @try {
        while([cq moveToNext]){
            PEXDbMessageQueue * cur = [[PEXDbMessageQueue alloc] initWithCursor:cq];
            [idsToRemove removeObject:cur.referencedId];
        }
    } @catch(NSException * e) {
        DDLogError(@"Exception when dumping message queue, %@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:cq];
    }

    // No messages to set to failed.
    DDLogVerbose(@"Messages with missing sending queue record: %d, %@", (int)[idsToRemove count], idsToRemove);
    if ([idsToRemove count] == 0){
        return;
    }

    // 3. Update such messages to state FAILED, if they still have given state and timing as in the first query (no race condition / update meanwhile)
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_TYPE integer:PEXDBMessage_MESSAGE_TYPE_FAILED];

    // Same arguments are repeated so if messages got updated in another thread we are not modifying it with old data.
    NSMutableArray * args = [NSMutableArray array];
    [args addObjectsFromArray:@[
            @(PEXDBMessage_MESSAGE_TYPE_PENDING),
            @(PEXDBMessage_MESSAGE_TYPE_QUEUED),
            @(PEXDBMessage_MESSAGE_TYPE_QUEUED_BACKOFF),
            createTimeThrNum
    ]];
    [args addObjectsFromArray:[idsToRemove allObjects]];

    int affected = [cr updateEx:[PEXDbMessage getURI]
                  ContentValues:cv
                      selection:[NSString stringWithFormat: @"WHERE %@=1 AND %@ IN(?,?,?) AND %@ < ? AND %@ IN (%@)",
                                                            PEXDBMessage_FIELD_IS_OUTGOING,
                                                            PEXDBMessage_FIELD_TYPE,
                                                            PEXDBMessage_FIELD_DATE,
                                                            PEXDBMessage_FIELD_ID,
                                                            [PEXUtils generateDbPlaceholders:(int) [idsToRemove count]]]
                  selectionArgs:args];

    if (affected > 0){
        DDLogWarn(@"There were %d messages without corresponding sending part", affected);
    }
}

-(void) messageQueueLogReport:(PEXDbContentProvider *) cr {
    PEXDbCursor * c = [cr query:[PEXDbMessageQueue getURI] projection:[PEXDbMessageQueue getFullProjection]
                      selection:@"" selectionArgs:@[] sortOrder:nil];

    if (c == nil){
        DDLogError(@"Null cursor");
        return;
    }

    @try {
        unsigned int cntTotal = 0;
        unsigned int cntProcessed = 0;

        while([c moveToNext]){
            PEXDbMessageQueue * cur = [[PEXDbMessageQueue alloc] initWithCursor:c];
            cntTotal += 1;

            if ([cur.isProcessed boolValue]){
                cntProcessed += 1;
            }
        }

        DDLogInfo(@"Message queue contains %u messages, %u processed", cntTotal, cntProcessed);
    } @catch(NSException * e) {
        DDLogError(@"Exception when dumping message queue, %@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}
@end

// Implementation of the message content observer.
@implementation PEXMessageObserver
- (instancetype)initWithManager:(PEXMessageManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        self.destUri = [PEXDbMessageQueue getURI];
    }

    return self;
}

+ (instancetype)observerWithManager:(PEXMessageManager *)manager {
    return [[self alloc] initWithManager:manager];
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    PEXMessageManager * sMgr = self.manager;
    if (sMgr == nil){
        DDLogError(@"Message manager is nil!");
        return;
    }

    if (![self.destUri matches:uri]) {
        return;
    }

    DDLogVerbose(@"DB observer change detected, self=%d, uri=%@", selfChange, [uri uri2string]);
    [sMgr addTaskWithName:@"msgObserver" toQueue:^(PEXMessageManager *mgr) {
        [mgr databaseChanged:selfChange uri:uri fromObserver:YES];
    }];
}

@end

// Implementation of the certificate content observer.
// Idea: Flush certificate cache on certificate update.
@implementation PEXCertificateObserver
- (instancetype)initWithManager:(PEXMessageManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        self.destUri = [PEXDbUserCertificate getURI];
    }

    return self;
}

+ (instancetype)observerWithManager:(PEXMessageManager *)manager {
    return [[self alloc] initWithManager:manager];
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    PEXMessageManager * sMgr = self.manager;
    if (sMgr == nil || ![self.destUri matchesBase:uri]) {
        return;
    }

    [sMgr addTaskWithName:@"crt" toQueue:^(PEXMessageManager * mgr){
        [mgr clearCertCache];
    }];
}

@end

// Task waiting for connectivity being restored, starts DB re-check.
@implementation PEXWaitForConnectivityTask
- (instancetype)initWithManager:(PEXMessageManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
    }

    return self;
}

+ (instancetype)taskWithManager:(PEXMessageManager *)manager {
    return [[self alloc] initWithManager:manager];
}

- (void)main { @autoreleasepool {
    int retryCount = 0;
    PEXMessageManager *sMgr = self.manager;
    if (sMgr == nil) {
        return;
    }

    while (retryCount < CONN_TASK_MAX_RETRY_COUNT && ![sMgr isConnected]) {
        [NSThread sleepForTimeInterval:CONN_TASK_TIMEOUT];
    }

    // Beware, here connectivity can or does not have to be valid.
    [NSThread sleepForTimeInterval:CONN_TASK_TIMEOUT];
    [sMgr onWaitingThreadFinish];
}}

@end

@implementation PEXMessageSentDescriptor

- (instancetype)initWithMessageId:(int64_t)messageId accountId:(int64_t)accountId message:(NSString *)message msg2store:(NSString *)msg2store recipient:(NSString *)recipient isResend:(BOOL)isResend sendResult:(PEXToCall *)sendResult {
    self = [super init];
    if (self) {
        self.messageId = messageId;
        self.accountId = accountId;
        self.message = message;
        self.msg2store = msg2store;
        self.recipient = recipient;
        self.isResend = isResend;
        self.sendResult = sendResult;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.accountId=%qi", self.accountId];
    [description appendFormat:@", self.messageId=%qi", self.messageId];
    [description appendFormat:@", self.message=%@", self.message];
    [description appendFormat:@", self.msg2store=%@", self.msg2store];
    [description appendFormat:@", self.recipient=%@", self.recipient];
    [description appendFormat:@", self.isResend=%d", self.isResend];
    [description appendFormat:@", self.sendResult=%@", self.sendResult];
    [description appendFormat:@", self.stackSendStatus=%i", self.stackSendStatus];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.accountId = [coder decodeInt64ForKey:@"self.accountId"];
        self.messageId = [coder decodeInt64ForKey:@"self.messageId"];
        self.message = [coder decodeObjectForKey:@"self.message"];
        self.msg2store = [coder decodeObjectForKey:@"self.msg2store"];
        self.recipient = [coder decodeObjectForKey:@"self.recipient"];
        self.isResend = [coder decodeBoolForKey:@"self.isResend"];
        self.stackSendStatus = [coder decodeIntForKey:@"self.stackSendStatus"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.accountId forKey:@"self.accountId"];
    [coder encodeInt64:self.messageId forKey:@"self.messageId"];
    [coder encodeObject:self.message forKey:@"self.message"];
    [coder encodeObject:self.msg2store forKey:@"self.msg2store"];
    [coder encodeObject:self.recipient forKey:@"self.recipient"];
    [coder encodeBool:self.isResend forKey:@"self.isResend"];
    [coder encodeInt:self.stackSendStatus forKey:@"self.stackSendStatus"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXMessageSentDescriptor *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.accountId = self.accountId;
        copy.messageId = self.messageId;
        copy.message = self.message;
        copy.msg2store = self.msg2store;
        copy.recipient = self.recipient;
        copy.isResend = self.isResend;
        copy.sendResult = self.sendResult;
        copy.stackSendStatus = self.stackSendStatus;
    }

    return copy;
}


+ (instancetype)descriptorWithMessageId:(int64_t)messageId accountId:(int64_t)accountId message:(NSString *)message msg2store:(NSString *)msg2store recipient:(NSString *)recipient isResend:(BOOL)isResend sendResult:(PEXToCall *)sendResult {
    return [[self alloc] initWithMessageId:messageId accountId:accountId message:message msg2store:msg2store recipient:recipient isResend:isResend sendResult:sendResult];
}

@end

// Receive notifications / intents from the system to re-check queue database.
@implementation PEXMessageEventReceiver
- (instancetype)initWithManager:(PEXMessageManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
    }

    return self;
}

+ (instancetype)receiverWithManager:(PEXMessageManager *)manager {
    return [[self alloc] initWithManager:manager];
}

- (void)receiveNotification:(NSNotification *)notification {
    PEXMessageManager *sMgr = self.manager;
    if (sMgr == nil) {
        DDLogWarn(@"Intent received, manager is null.");
        return;
    }

    DDLogInfo(@"received intent in MessageReceiver, action:%@", notification);
    if (notification == nil) {
        return;
    }

    if ([PEX_ACTION_CHECK_MESSAGE_DB isEqualToString:notification.name]
            || [PEX_ACTION_MESSAGE_RECEIVED isEqualToString:notification.name])
    {
        [sMgr triggerCheck];
    } else if ([PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]) {
        PEXConnectivityChange *conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
        if (conChange == nil) {
            DDLogWarn(@"Connectivity change is nil");
            return;
        }

        if (conChange.sip == PEX_CONN_NO_CHANGE && conChange.xmpp == PEX_CONN_NO_CHANGE) {
            DDLogVerbose(@"Not an interesting change: %@", conChange);
            return;
        }

        BOOL recovered = conChange.sipWorks == PEX_CONN_IS_UP && conChange.xmppWorks == PEX_CONN_IS_UP;
        [sMgr addTaskWithName:@"conn" toQueue:^(PEXMessageManager *mgr) {
            [mgr onConnectivityChange:recovered];
        }];

    } else if ([PEX_ACTION_REJECT_FILE_CONFIRMED isEqualToString:notification.name]){
        NSNumber * msgId = notification.userInfo[PEX_EXTRA_REJECT_FILE_CONFIRMED_MSGID];
        if (msgId == nil){
            DDLogError(@"Intent does not have desired extra value");
            return;
        }

        [sMgr onTransferConfirmation:msgId accept:NO];

    } else if ([PEX_ACTION_ACCEPT_FILE_CONFIRMED isEqualToString:notification.name]){
        NSNumber * msgId = notification.userInfo[PEX_EXTRA_ACCEPT_FILE_CONFIRMED_MSGID];
        if (msgId == nil){
            DDLogError(@"Intent does not have desired extra value");
            return;
        }

        [sMgr onTransferConfirmation:msgId accept:YES];

    } else {
        DDLogError(@"Unknown action %@", notification);
    }
}

@end

@implementation PEXBackoffFutureTimer
@end