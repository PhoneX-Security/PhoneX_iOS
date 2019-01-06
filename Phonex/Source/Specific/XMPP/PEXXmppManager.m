//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXXmppManager.h"
#import "XMPPReconnect.h"
#import "XMPPStream.h"
#import "XMPPAutoPing.h"
#import "XMPPPing.h"
#import "XMPPRoster.h"
#import "XMPPStreamManagement.h"
#import "PEXUserPrivate.h"
#import "GCDAsyncSocket.h"
#import "PEXSecurityCenter.h"
#import "XMPPPresence.h"
#import "XMPPRosterMemoryStorage.h"
#import "PEXUtils.h"
#import "PEXPresenceCenter.h"
#import "PEXPresenceUpdateEnvelope.h"
#import "XMPPPresence+XEP_0172.h"
#import "XMPPPubSub.h"
#import "XMPPInternal.h"
#import "XMPPJID.h"
#import "PEXPresenceState.h"
#import "PEXService.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXConnectivityChange.h"
#import "PEXXMPPPhxPushModule.h"
#import "PEXXMPPSimplePacketSendRecord.h"
#import "PEXXMPPPushProcessor.h"
#import "PEXApplicationStateChange.h"
#import "XMPPIDTracker.h"
#import "PEXOpenUDID.h"
#import "PEXMessageDigest.h"
#import "PEXStringUtils.h"
#import "PEXMessageManager.h"
#import "PEXMovingAverage.h"
#import "PEXXmppPhxPushInfo.h"

NSString *PEX_ACTION_XMPP_CONNECTION = @"net.phonex.phonex.xmpp.action.connection";
NSString *PEX_EXTRA_XMPP_CONNECTION = @"net.phonex.phonex.xmpp.extra.connection";

NSString * const PEXXMPPManagerErrorDomain = @"PEXXMPPManagerErrorDomain";
NSInteger const PEXXMPPConnectError = 1;
NSInteger const PEXXMPPDisconnectError = 2;

NSInteger const PEXNoPrivDataCode = 1;
NSInteger const PEXAlreadyConnectedCode = 2;
NSInteger const PEXNotConnectedCode = 3;

NSInteger const PEXPingFailLimit = 3;
double const PEX_DISCONNECTED_AVERAGE_FACTOR = 0.015;

typedef PEXXMPPPhxPushInfo * (^pex_xmpp_request_block)();

@interface PEXXmppManager () {
    volatile NSUInteger _pingFailCounter;
    NSDate *_lastReconnectAttempt;
    NSDate *_lastKeepAlive;
    NSDate *_lastMessageActivity;
}

@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(nonatomic) BOOL isConnectInitialized;
@property(nonatomic) BOOL isConnectivityValid;
@property(nonatomic) BOOL isConnected;
@property(nonatomic) BOOL registered;
@property(nonatomic) PEXPresenceUpdateEnvelope * lastEnvelope;

@property(nonatomic) NSInteger consecutiveFailedConnectCtr;
@property(nonatomic) PEXMovingAverage * disconnectedErrorRate;
@property(nonatomic) PEXMovingAverage * connectSuccessRate;
@property(nonatomic) PEXMovingAverage * bgConnectionStability;
@property(nonatomic) NSDate * lastSuccessfulConnect;
@property(nonatomic) NSDate * lastConnectivityUp;
@property(nonatomic) NSDate * lastConnectivityDown;
@property(nonatomic) NSString * resourceId;

/**
* Auto reconnect XMPP module.
*/
@property(nonatomic) XMPPReconnect * xmppReconnect;

/**
* Auto ping XMPP module for detecting connectivity loss.
*/
@property(nonatomic) XMPPAutoPing * xmppAutoPing;

/**
* XMPP ping module - responds to server pings.
*/
@property(nonatomic) XMPPPing * xmppPing;

/**
* Roster (i.e., contact list) XMPP module.
*/
@property(nonatomic) XMPPRoster * xmppRoster;

/**
* Primary storage for roster.
* Currently we use memory storage since it is loaded after
* each login but this functionality may change in the future.
*/
@property(nonatomic) id<XMPPRosterStorage> xmppRosterStorage;

/**
* Stream management module for XMPP (global IQ acknowledgements).
* Not used at the moment since there is no server support for this feature.
*/
@property(nonatomic) XMPPStreamManagement * xmppStreamManagement;

/**
* PHX push message extension. Handles urn:xmpp:phx namespace, push messages.
*/
@property(nonatomic) PEXXMPPPhxPushModule * xmppPush;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * pushQueryRec;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * presQueryRec;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * activityRec;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * pushTokenRec;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * pushAck;
@property(nonatomic) PEXXMPPSimplePacketSendRecord * pushReq;

/**
* XMPP Push processor module. Parses and reacts on push message received from server.
*/
@property(nonatomic) PEXXMPPPushProcessor * pushProcessor;

@end

@implementation PEXXmppManager {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        _dispatchQueue = dispatch_queue_create("net.phonex.xmppmanager.queue", NULL);
        _isConnectInitialized = NO;
        _isConnected = NO;
        _registered = NO;
        _isConnectivityValid = NO;
        _pingFailCounter = 0;
        _disconnectedErrorRate = [PEXMovingAverage averageWithSmoothingFactor:PEX_DISCONNECTED_AVERAGE_FACTOR current:0.0 valMax:@(1.0) valMin:@(0.0)];
        _connectSuccessRate = [PEXMovingAverage averageWithSmoothingFactor:PEX_DISCONNECTED_AVERAGE_FACTOR current:1.0 valMax:@(1.0) valMin:@(0.0)];
        _bgConnectionStability = [PEXMovingAverage averageWithSmoothingFactor:PEX_DISCONNECTED_AVERAGE_FACTOR current:1.0 valMax:@(1.0) valMin:@(0.0)];

        _pushQueryRec = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        _presQueryRec = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        _activityRec = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        _pushTokenRec = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        _pushAck = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        _pushReq = [[PEXXMPPSimplePacketSendRecord alloc] initSentinel];
        DDLogInfo(@"XMPP manager initialized");
    }

    return self;
}

-(void) resetState {
    _isConnectInitialized = NO;
    _isConnected = NO;
    _registered = NO;
    _isConnectivityValid = NO;
    _pingFailCounter = 0;
    _lastSuccessfulConnect = nil;
    _lastConnectivityDown = nil;
    _lastConnectivityUp = nil;
    _consecutiveFailedConnectCtr = 0;
    _disconnectedErrorRate.current = 0.0;
    _connectSuccessRate.current = 1.0;
    _bgConnectionStability.current = 1.0;
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

- (void)updatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;
}

- (pex_status)connect {
    return [self connect:nil];
}

-(pex_status) connect: (NSError **) pError {
    if (self.privData == nil){
        DDLogError(@"No private data in XMPP manager, cannot connect.");
        [PEXUtils setError:pError domain:PEXXMPPManagerErrorDomain code:PEXXMPPConnectError subCode:PEXNoPrivDataCode];
        return PEXNoPrivDataCode;
    }

    if (self.isConnectInitialized){
        DDLogError(@"XMPP manager is already connected, please call quit before connecting.");
        [PEXUtils setError:pError domain:PEXXMPPManagerErrorDomain code:PEXXMPPConnectError subCode:PEXAlreadyConnectedCode];
        return PEXAlreadyConnectedCode;
    }

    // Create a new XMPP stream.
    self.xmppStream = [[XMPPStream alloc] init];

    // Workaround to pass IPV6-only network test.
    //
    GCDAsyncSocket * socket = [self.xmppStream valueForKey:@"asyncSocket"];
    [socket setIPv4PreferredOverIPv6:NO];

    // Set XMPP user identifier (JID).
    self.resourceId = [self generateResource:self.privData] ;
    self.xmppStream.myJID = [XMPPJID jidWithString:self.privData.username resource: self.resourceId];

    // Set this object as a delegate for XMPP calls.
    [self.xmppStream addDelegate:self delegateQueue:self.dispatchQueue];

    // Strictly require TLS
    self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicyRequired;

    // Add reconnect object to the stream.
    self.xmppReconnect = [[XMPPReconnect alloc] init];
    self.xmppReconnect.autoReconnect = YES;
    [self.xmppReconnect activate:self.xmppStream];
    [self.xmppReconnect addDelegate:self delegateQueue:self.dispatchQueue];

    // Add auto ping support.
    self.xmppAutoPing = [[XMPPAutoPing alloc] initWithDispatchQueue:self.dispatchQueue];
    self.xmppAutoPing.pingInterval = 90;
    [self.xmppAutoPing activate:self.xmppStream];
    [self.xmppAutoPing addDelegate:self delegateQueue:self.dispatchQueue];

    // For now - memory roster storage.
    self.xmppRosterStorage = [[XMPPRosterMemoryStorage alloc] init];

    // Add roster support.
    self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage dispatchQueue:self.dispatchQueue];
    self.xmppRoster.autoFetchRoster = YES;
    [self.xmppRoster activate:self.xmppStream];
    [self.xmppRoster addDelegate:self delegateQueue:self.dispatchQueue];

    // Add ping support so we respond to server ping requests.
    self.xmppPing = [[XMPPPing alloc] initWithDispatchQueue:self.dispatchQueue];
    self.xmppPing.respondsToQueries = YES;
    [self.xmppPing activate:self.xmppStream];
    [self.xmppPing addDelegate:self delegateQueue:self.dispatchQueue];

    self.xmppPush = [[PEXXMPPPhxPushModule alloc] initWithDispatchQueue:self.dispatchQueue];
    [self.xmppPush activate:self.xmppStream];
    [self.xmppPush addDelegate:self delegateQueue:self.dispatchQueue];

    self.pushProcessor = [[PEXXMPPPushProcessor alloc] initWithMgr:self dispatchQueue:self.dispatchQueue];
    self.lastPresence = nil;

    // Connect
    NSError *error = nil;
    _lastReconnectAttempt = [NSDate date];
    if (![self.xmppStream connectWithTimeout:30.0 error:&error]){
        DDLogError(@"Oops, I probably forgot something: %@", error);
    }

    self.isConnectInitialized = YES;
    DDLogInfo(@"XMPP connect() called, JID=%@, username=%@", self.xmppStream.myJID, self.privData.username);
    return PEX_SUCCESS;
}

- (pex_status)quit {
    return [self quit: nil];
}

-(pex_status) quit: (NSError **) pError {
    if (!self.isConnectInitialized){
        DDLogError(@"XMPP manager is not connected, cannot disconnect.");
        [PEXUtils setError:pError domain:PEXXMPPManagerErrorDomain code:PEXXMPPDisconnectError subCode:PEXNotConnectedCode];
        return PEXNotConnectedCode;
    }

    self.isConnected = NO;

    // Disconnect.
    [self.xmppStream disconnect];

    // Remove this object as a delegate.
    [self.xmppStream removeDelegate:self];

    // Remove further delegates from modules.
    [self.xmppReconnect deactivate];
    [self.xmppReconnect removeDelegate:self];

    [self.xmppAutoPing deactivate];
    [self.xmppAutoPing removeDelegate:self];

    [self.xmppPing deactivate];
    [self.xmppPing removeDelegate:self];

    [self.xmppRoster deactivate];
    [self.xmppRoster removeDelegate:self];

    [self resetState];
    self.isConnectInitialized = NO;
    DDLogVerbose(@"XMPP manager disconnect call ended.");
    return PEX_SUCCESS;
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for new presence notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(receivePresenceNotification:) name:PEX_ACTION_LOCAL_PRESENCE_CHANGED object:nil];
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        // Register on message sent event -> update last activity
        [center addObserver:self selector:@selector(onMessageSent:) name:PEX_ACTION_MESSAGE_STORED_FOR_SENDING object:nil];

        DDLogDebug(@"XMPP manager registered");
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

        DDLogDebug(@"XMPP manager unregistered");
        self.registered = NO;
    }
}

-(void) keepAlive {
    // Refresh connectivity status since while in background we may miss some.
    PEXService * svc = [PEXService instance];
    _isConnectivityValid = [svc isConnectivityWorking];
    _lastKeepAlive = [NSDate date];

    // If everything works, just ping the server.
    // If connectivity works and not connected, try to reconnect.
    if (_isConnected && _isConnectivityValid) {
        DDLogVerbose(@"Sending simple ping to the XMPP server");
        [_xmppPing sendPingToServer];
        [_bgConnectionStability update:1.0];

    } else if (!_isConnected && _isConnectivityValid){
        // Keep alive reset counters so we try to reconnect.
        _pingFailCounter = 0;

        // Reconnect here, connectivity is valid.
        [self triggerReconnect];

        // Not connected on keep-alive while connectivity is OK.
        [_bgConnectionStability update:0.0];

    } else {
        DDLogVerbose(@"No keep-alive action. Connected: %d, connectivityValid: %d", _isConnected, _isConnectivityValid);
    }
}

-(void) triggerReconnect {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"xmppReConn" async:YES block:^{
        PEXXmppManager * mgr = weakSelf;
        if (!mgr.isConnected && mgr.isConnectivityValid){
            // Keep alive reset counters so we try to reconnect.
            _pingFailCounter = 0;
            _lastReconnectAttempt = [NSDate date];

            DDLogDebug(@"!is_connected & works -> connect");
            [mgr.xmppReconnect manualStart];
        }
    }];
}

-(BOOL) isStreamDisconnected {
    return _xmppStream == nil || [_xmppStream isDisconnected];
}

// ---------------------------------------------
#pragma mark - XMPP send API
// ---------------------------------------------

// TODO:[medium] Refactor sending API so new request do not overwrite existing sending attempt. Via completion handlers, blocks.
// TODO:[medium    The sending record should be encapsulated in the PushInfo, stored in queue inside XMPP framework.

-(void) trySendPushQuery {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.pushQueryRec) {
            [weakSelf.pushQueryRec resetForNextSending];
        }

        [weakSelf trySendPushQueryInt: YES];
    }];
}

-(void) trySendPushQueryInt: (BOOL) newAttempt {
    [self trySendRequestInt:_pushQueryRec newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush preparePushQuery:nil];
    }];
}

-(void) trySendPresenceQuery{
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.presQueryRec) {
            [weakSelf.presQueryRec resetForNextSending];
        }

        [weakSelf trySendPresenceQueryInt: YES];
    }];
}

-(void) trySendPresenceQueryInt: (BOOL) newAttempt {
    [self trySendRequestInt:_presQueryRec newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush preparePresenceQuery:nil];
    }];
}

-(void) trySendActivity{
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.activityRec) {
            [weakSelf.activityRec resetForNextSending];
        }

        [weakSelf trySendActivityInt: YES];
    }];
}

-(void) trySendActivityInt: (BOOL) newAttempt {
    [self trySendRequestInt:_activityRec newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush prepareCurrentActiveQuery:nil];
    }];
}

-(void) trySendPushAck: (NSString *) jsonEncoded onFinished: (id<PEXXmppQueryFinished>) onFinished {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.pushAck) {
            [weakSelf.pushAck resetForNextSending];
            weakSelf.pushAck.auxData = jsonEncoded;
            weakSelf.pushAck.onFinishedHandler = onFinished;
        }

        [weakSelf trySendPushAckInt: YES];
    }];
}

-(void) trySendPushAckInt: (BOOL) newAttempt {
    [self trySendRequestInt:_pushAck newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush preparePushAckQuery:(NSString *) _pushAck.auxData completionHandler:nil];
    }];
}

-(void) trySendPushReq: (NSString *) jsonEncoded onFinished: (id<PEXXmppQueryFinished>) onFinished {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.pushReq) {
            [weakSelf.pushReq resetForNextSending];
            weakSelf.pushReq.auxData = jsonEncoded;
            weakSelf.pushReq.onFinishedHandler = onFinished;
        }

        [weakSelf trySendPushReqInt: YES];
    }];
}

-(void) trySendPushReqInt: (BOOL) newAttempt {
    [self trySendRequestInt:_pushReq newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush preparePushRequestQuery:(NSString *) _pushReq.auxData completionHandler:nil];
    }];
}

-(void) trySendPushToken: (PEXPushTokenConfig *) token onFinished: (id<PEXXmppQueryFinished>) onFinished {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        @synchronized (weakSelf.pushTokenRec) {
            [weakSelf.pushTokenRec resetForNextSending];
            weakSelf.pushTokenRec.auxData = token;
            weakSelf.pushTokenRec.onFinishedHandler = onFinished;
        }

        [weakSelf trySendPushTokenInt: YES];
    }];
}

-(void) trySendPushTokenInt: (BOOL) newAttempt {
    [self trySendRequestInt:_pushTokenRec newAttempt:newAttempt requestBlock:^PEXXMPPPhxPushInfo * {
        return [self.xmppPush preparePushTokenQuery:(PEXPushTokenConfig *) _pushTokenRec.auxData completionHandler:nil];
    }];
}

/**
 * General push sending method.
 * Used by all other sending methods for data delivery to server.
 */
-(void) trySendRequestInt: (PEXXMPPSimplePacketSendRecord *) record newAttempt: (BOOL) newAttempt requestBlock:(pex_xmpp_request_block) reqBlock{
    PEXXMPPPhxPushInfo * queryInfo = nil;
    if ([record isFinished] || newAttempt){
        @synchronized (record) {
            queryInfo = reqBlock();
            record.queryInfo = queryInfo;
            record.packetId = queryInfo.packetId;
            record.sentCount = 0;
            record.tryAfterConnectivityOn = NO;
            record.sending = YES;
            record.sendStarted = [NSDate date];
        }

        [self.xmppPush sendQuery:queryInfo];
        DDLogVerbose(@"Push sent, first time, newAttempt: %d, packetId: %@, qType: %@", newAttempt, record.packetId, [queryInfo qTypeToString]);

    } else {
        // Sending was not finished from previous attempt.
        if (!_isConnected){
            DDLogVerbose(@"Not connected, deferred to connection become valid, sndCtr: %d, packetId: %@, qType: %@",
                    record.sentCount, record.packetId, [record.queryInfo qTypeToString]);

            record.tryAfterConnectivityOn = YES;
            [self checkForSuddenConnectivityDrop];
            return;
        }

        // TODO: If too many retries and still connected, wait for new connected event / app state active event.
        // ...
        NSString * prevPacketId = record.packetId;
        @synchronized (record) {
            queryInfo = reqBlock();
            record.queryInfo = queryInfo;
            record.packetId = queryInfo.packetId;
            record.sentCount += 1;
            record.tryAfterConnectivityOn = NO;
            record.sending = YES;
        }

        [self.xmppPush sendQuery:queryInfo];
        DDLogVerbose(@"Push sent, sendCtr: %d, packetId: %@, prevPacket: %@, qType: %@",
                record.sentCount, record.packetId, prevPacketId, [queryInfo qTypeToString]);
    }
}

// ---------------------------------------------
#pragma mark - General
// ---------------------------------------------

/**
* Publish presence of the local user. Generated by PresenceCenter.
*/
-(void) publishPresence: (PEXPresenceUpdateEnvelope *) presUpdate{
    XMPPPresence * pres = nil;

    NSString * type = nil;
    if (presUpdate != nil && presUpdate.isAvailable != nil && ![presUpdate.isAvailable boolValue]){
        type = @"unavailable";
        pres = [[XMPPPresence alloc] initWithType:type];
    } else {
        pres = [[XMPPPresence alloc] init];
    }

    NSXMLElement *status = [NSXMLElement elementWithName:@"status"];
    [status setStringValue:presUpdate.statusMessage];
    [pres addChild:status];
    DDLogVerbose(@"Publishing presence: %@", pres);

    self.lastPresence = pres;
    self.lastEnvelope = presUpdate;
    if (!_isConnected){
        DDLogDebug(@"Cannot send presence, not connected. Connectivity: %d", self.isConnectivityValid);
        [self checkForSuddenConnectivityDrop];
        return;
    }

    [[self xmppStream] sendElement:pres];
}

-(void) sendMessageTo: (NSString *) to body: (NSString *) messageStr  {
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageStr];

    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:to];
    [message addChild:body];

    if (!_isConnected){
        DDLogDebug(@"Cannot send presence, not connected. Connectivity: %d", self.isConnectivityValid);
        return;
    }

    [self.xmppStream sendElement:message];
}

-(void) checkForSuddenConnectivityDrop {
    // If we are not connected and connectivity is valid, check what happened.
    if (_isConnected || !_isConnectivityValid || !_isConnectInitialized){
        DDLogVerbose(@"isConnected %d, conValid: %d, initOk: %d", _isConnected, _isConnectivityValid, _isConnectInitialized);
        return;
    }

    // If keep alive is working as it should, we leave it for keep-alive.
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval lastKeep = _lastKeepAlive == nil ? 0 : [_lastKeepAlive timeIntervalSince1970];
    if (curTime - lastKeep <= 60.0*15.0) {
        return;
    }

    DDLogWarn(@"Last keep alive happened a long time ago: %@", _lastKeepAlive);
    NSTimeInterval lastReconnect = _lastReconnectAttempt == nil ? 0 : [_lastReconnectAttempt timeIntervalSince1970];
    if (curTime - lastReconnect <= 60.0 * 15.0){
        DDLogVerbose(@"Last reconnect is too early, do not trigger background killer. %@", _lastReconnectAttempt);
        return;
    }

    // Try to trigger reconnect.
    DDLogVerbose(@"Triggering reconnect.");
    [self triggerReconnect];
}

-(void) recheckDeferred: (BOOL) justConnected {
    const BOOL connected = [self isConnected];

    if (connected && _presQueryRec != nil && _presQueryRec.tryAfterConnectivityOn){
        DDLogVerbose(@"Resend presence query");
        [self trySendPresenceQuery];
    }

    // Push ACK upload.
    if (connected
            && _pushAck != nil
            && _pushAck.tryAfterConnectivityOn
            && !_pushAck.doneFlag
            && !_pushAck.sending)
    {
        DDLogVerbose(@"Resend push ack");
        [self trySendPushAckInt: NO];
    }

    // Push REQ upload.
    if (connected
            && _pushReq != nil
            && _pushReq.tryAfterConnectivityOn
            && !_pushReq.doneFlag
            && !_pushReq.sending)
    {
        DDLogVerbose(@"Resend push req");
        [self trySendPushReqInt: NO];
    }
}

-(NSString *) generateResource:(PEXUserPrivate *) privData {
    return [PEXUtils generateResource:privData.username];
}

// ---------------------------------------------
#pragma mark - Event handlers
// ---------------------------------------------

/**
* Receive local user presence changes in order to broadcast new presence state.
*/
- (void)receivePresenceNotification:(NSNotification *)notification {
    DDLogInfo(@"received intent in MessageReceiver, action:%@", notification);
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_LOCAL_PRESENCE_CHANGED isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXPresenceState * state = notification.userInfo[PEX_EXTRA_PRESENCE_STATE];
    DDLogVerbose(@"Presence notification received. state=%@", state);
    if (state == nil) {
        return;
    }

    if (state.lastUpdate != nil && !state.lastUpdate.doUpdatePresence){
        DDLogVerbose(@"Ignoring this update.");
        return;
    }

    // Build new presence and publish it.
    [PEXService executeWithName:@"presencePublish" async:YES block:^{
        PEXPresenceCenter * pc = [PEXPresenceCenter instance];
        PEXPresenceUpdateEnvelope * puo = [pc generatePresenceDataFromState:state];

        if (puo == nil){
            DDLogError(@"Presence update is nil, probably incorrect state: %@", state);
            return;
        }

        [self publishPresence:puo];
    }];
}

-(void) onConnected: (BOOL) connected {
    self.isConnected = connected;
    if (connected){
        // Mark connection as working (since we authenticated right now), reset ping timeout counters.
        [self onValidMessageReceived: nil];
        _lastSuccessfulConnect = [NSDate date];
        _consecutiveFailedConnectCtr = 0;

    } else {
        _consecutiveFailedConnectCtr += 1;
    }

    // Connect success rate.
    [_connectSuccessRate update:connected ? 1.0:0.0];

    if ([PEXUtils isEmpty: self.privData.username]){
        DDLogError(@"Empty user name in priv data %p", self.privData.username);
    }

    // Publish fresh presence data asap.
    PEXPresenceUpdateMsg *msg = [PEXPresenceUpdateMsg msgWithUser:self.privData.username];
    msg.isAvailable = @(self.isConnected);
    if (!connected){
        msg.doUpdatePresence = NO;
    }

    // Trigger update. Proper update should come back here in notification.
    PEXPresenceCenter * pc = [PEXPresenceCenter instance];
    [pc updatePresenceForLogged:msg];

    // Broadcast connection info with notification center.
    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_XMPP_CONNECTION object:nil userInfo:@{ PEX_EXTRA_XMPP_CONNECTION : @(connected) }];

    if (connected) {
        DDLogVerbose(@"On connected async resend");
        // Inform about current active state.
        [self trySendActivity];

        // Request all recent push notifications once authenticated.
        [self trySendPushQuery];

        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
            [weakSelf recheckDeferred: YES];
        }];
    }
}

-(pex_status) onLoginCompleted {
    return [self connect];
}

/**
* Receive local user presence changes in order to broadcast new presence state.
*/
- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil || !self.isConnectInitialized) {
        return;
    }

    if (![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil){
        return;
    }

    __weak __typeof(self) weakSelf = self;

    // If IP has changed, try to re-send last presence.
    // If connection is not valid, reconnect should happen.
    if (conChange.recheckIPChange && self.isConnected && self.lastPresence != nil) {
        [PEXService executeWithName:@"xmppLastPres" async:YES block:^{
            PEXXmppManager * mgr = weakSelf;
            DDLogVerbose(@"IPrecheck, re-sending last presence update");
            [[mgr xmppStream] sendElement:mgr.lastPresence];
        }];
    }

    // Do reconnect only if disconnected.
    if (conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    BOOL works = conChange.connectionWorks == PEX_CONN_IS_UP;
    self.isConnectivityValid = works;

    // Connectivity statistics for future watchdog.
    if (works){
        _lastConnectivityUp = [NSDate date];
    } else {
        _lastConnectivityDown = [NSDate date];
    }

    // If XMPP stream is connected, disconnect it in case of reachability indicates no connection.
    // Otherwise if reachability indicates working connection start reconnecting again.
    [PEXService executeWithName:@"xmppConn" async:YES block:^{
        PEXXmppManager * mgr = weakSelf;
        if ((mgr.isConnected || ![mgr isStreamDisconnected]) && !works){
            DDLogDebug(@"is_connected & !works -> disconnect");
            [mgr.xmppStream disconnect];

        } else if (!mgr.isConnected && works){
            DDLogDebug(@"!is_connected & works -> connect");
            _lastReconnectAttempt = [NSDate date];
            [mgr.xmppReconnect manualStart];
        }
    }];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change == nil){
        DDLogError(@"Illegal notification state");
        return;
    }

    PEXPresenceUpdateMsg * msg = [PEXPresenceUpdateMsg msgWithUser: self.privData.username];
    PEXPresenceCenter * pc = [PEXPresenceCenter instance];

    // KeepAlive was disabled in iOS 10.
    __weak __typeof(self) weakSelf = self;
    if (change.stateChange == PEX_APPSTATE_DID_ENTER_BACKGROUND){
        DDLogVerbose(@"App in background - keep alive handler.");
        [self keepAlive];

        // Disable client initiated pings, throttling.
        [_xmppAutoPing deactivate];
        [self trySendActivity];

        // Set all contacts to offline, new presence is queried on transition to active state, but only online contacts are pushed.
        [[PEXService instance] setAllToOffline];

        // Background -> indicate this with presence update
        msg.isInBackground = @(1);
        [pc updatePresenceForLogged:msg];
    }

    // On foreground enter re-register again to reset all potential backoffs.
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        // Enable client initiated pings, throttling recovery.
        [_xmppAutoPing activate:_xmppStream];
        [self trySendActivity];

        DDLogVerbose(@"Did become active - keep alive");
        [PEXService executeWithName:@"didActive" async:YES block:^{
            [weakSelf keepAlive];
        }];

        msg.isInBackground = @(0);
        [pc updatePresenceForLogged:msg];
    }
}

- (void)onMessageSent:(NSNotification *)notification {
    // Do not send activity update on each message sending. Do it each 30 seconds.
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    if (_lastMessageActivity == nil || (curTime - [_lastMessageActivity timeIntervalSince1970]) >= 30.0) {
        DDLogVerbose(@"Message sent event -> update activity");
        _lastMessageActivity = [NSDate date];
        [self trySendActivity];
    }
}

- (void)onValidMessageReceived:(XMPPStream *)sender {
    // Mark connection as working, reset ping timeout counters.
    _pingFailCounter = 0;
}

- (void)onSendAttemptFailed {
    _pingFailCounter += 1;
    DDLogVerbose(@"Fail counter incremented: %d", (int)_pingFailCounter) ;
    if (_pingFailCounter < PEXPingFailLimit){
        return;
    }

    PEXService * svc = [PEXService instance];
    if ([svc isInBackground] && ([self isConnected] || ![self isStreamDisconnected])){
        DDLogVerbose(@"In background, disconnect from XMPP.");

        // Disconnect XMPP stream in serial executor.
        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:@"failSoDisconnect" async:YES block:^{
            if ([weakSelf isConnected] || ![weakSelf isStreamDisconnected]) {
                DDLogVerbose(@"Disconnecting XMPP stream.");
                [weakSelf.xmppStream disconnect];
            }
        }];
    }
}

// ---------------------------------------------
#pragma mark - Reporting
// ---------------------------------------------

-(NSString *) xmppReport {
    @try {
        return [NSString stringWithFormat:@"Connected: %d, ConnectivityValid: %d, StreamDisconnected: %d, "
                                                  "LastKeepAlive: %@, LastReconnectAtempt: %@, "
                                                  "pingFailCtr: %ld, lastAutoPing: %@, disconnectErrorRate: %lf, "
                                                  "connectSuccessRate: %lf, lastSuccessConnect: %@, consecConnectError: %d, "
                                                  "lastConnUp: %@, lastConnDown: %@, bgConStabilityRate: %lf",
                        _isConnected,
                        _isConnectivityValid,
                        [self isStreamDisconnected],
                        _lastKeepAlive,
                        _lastReconnectAttempt,
                        (long) _pingFailCounter,
                        [NSDate dateWithTimeIntervalSinceReferenceDate:[_xmppAutoPing lastReceiveTime]],
                        _disconnectedErrorRate.current,
                        _connectSuccessRate.current,
                        _lastSuccessfulConnect,
                        (int) _consecutiveFailedConnectCtr,
                        _lastConnectivityUp,
                        _lastConnectivityDown,
                        _bgConnectionStability.current
        ];
    } @catch(NSException * e){
        DDLogError(@"Exception in log report generation %@", e);
        return @"ERROR";
    }
}

-(NSString *) xmppReportForUI {
    NSDate * lastAutoPing = [NSDate dateWithTimeIntervalSinceReferenceDate:[_xmppAutoPing lastReceiveTime]];
    NSDate * lastKeepAlive = _lastKeepAlive;
    NSDate * lastReconnectAttempt = _lastKeepAlive;
    NSDate * lastSuccessfulConnect = _lastKeepAlive;
    NSDate * lastConnectivityUp = _lastKeepAlive;
    NSDate * lastConnectivityDown = _lastKeepAlive;
    return [NSString stringWithFormat:@"Connected: %d"
                                              "\nConnectivityValid: %d"
                                              "\nStreamDisconnected: %d"
                                              "\nLastKeepAlive: %@, %@"
                                              "\nLastReconnectAtempt: %@, %@"
                                              "\nLastAutoPing: %@, %@"
                                              "\nlastSuccessConnect: %@, %@"
                                              "\nlastConnUp: %@, %@"
                                              "\nlastConnDown: %@, %@"
                                              "\npingFailCtr: %ld, "
                                              "\ndisconnectErrorRate: %lf, "
                                              "\nconnectSuccessRate: %lf, "
                                              "\nconsecConnectError: %d, "
                                              "\nbgConStabilityRate: %lf",
                    _isConnected,
                    _isConnectivityValid,
                    [self isStreamDisconnected],
                    lastKeepAlive, [PEXUtils dateDiffFromNowFormatted:lastKeepAlive compact:YES],
                    lastReconnectAttempt, [PEXUtils dateDiffFromNowFormatted:lastReconnectAttempt compact:YES],
                    lastAutoPing, [PEXUtils dateDiffFromNowFormatted:lastAutoPing compact:YES],
                    lastSuccessfulConnect, [PEXUtils dateDiffFromNowFormatted:lastSuccessfulConnect compact:YES],
                    lastConnectivityUp, [PEXUtils dateDiffFromNowFormatted:lastConnectivityUp compact:YES],
                    lastConnectivityDown, [PEXUtils dateDiffFromNowFormatted:lastConnectivityDown compact:YES],
                    (long) _pingFailCounter,
                    _disconnectedErrorRate.current,
                    _connectSuccessRate.current,
                    (int) _consecutiveFailedConnectCtr,
                    _bgConnectionStability.current
    ];
}

// ---------------------------------------------
#pragma mark - XMPP stream delegates
// ---------------------------------------------

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
    /*
     * Properly secure your connection by setting kCFStreamSSLPeerName
     * to your server domain name
     */
    settings[(NSString *) kCFStreamSSLPeerName] = self.xmppStream.myJID.domain;

    // Set custom SSL validation.
    settings[GCDAsyncSocketManuallyEvaluateTrust] = @(YES);

    // Set client certificate / identity.
    SecIdentityRef myIdent = self.privData.identity;
    SecIdentityRef certArray[1] = { myIdent };
    CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray, 1, NULL);
    settings[(NSString *)kCFStreamSSLCertificates] = CFBridgingRelease(myCerts);

    DDLogInfo(@"XMPP stream security settings prepared. Identity=%@", myIdent);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveTrust:(SecTrustRef)trust
 completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    // The delegate method should likely have code similar to this,
    // but will presumably perform some extra security code stuff.
    // For example, allowing a specific self-signed certificate that is known to the app.
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bgQueue, ^{
        CFIndex trustCertificateCount = SecTrustGetCertificateCount(trust);

        // Obtain trust root CA anchors.
        NSArray *anchors = [PEXSecurityCenter getServerTrustAnchors];
        SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) anchors);
        SecTrustSetAnchorCertificatesOnly(trust, YES);

        // Validate certificate & trust zone against given trust anchors.
        SecTrustResultType result = kSecTrustResultDeny;
        OSStatus status = SecTrustEvaluate(trust, &result);

        // Send result to the completion handler.
        BOOL inCertWeTrust = status == noErr && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified);
        DDLogInfo(@"XMPP certificate verification result:%d, certCount=%ld, anchors=%lu",
                inCertWeTrust, trustCertificateCount, (unsigned long)anchors.count);

        completionHandler(inCertWeTrust);
    });
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogInfo(@"XMPP connected, going to authenticate");

    if (![self.xmppStream isSecure]) {
        NSError *error = nil;
        BOOL result = [self.xmppStream secureConnection:&error];

        if (!result) {
            DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
        }
    }
    else {
        if ([PEXUtils isEmpty:self.privData.xmppPass]) {
            DDLogError(@"XMPP password is empty during auth.");
        }

        NSError *error = nil;
        BOOL result = [self.xmppStream authenticateWithPassword:self.privData.xmppPass error:&error];

        if (!result) {
            DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
        }
    }
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@, isSecure=%d", THIS_FILE, THIS_METHOD, sender.isSecure);
    //self.viewController.statusLabel.text = @"XMPP STARTTLS...";
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogVerbose(@"%@: %@, authenticated=%d", THIS_FILE, THIS_METHOD, sender.isAuthenticated);
    [self onConnected:YES];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    DDLogVerbose(@"%@: %@ - error: %@", THIS_FILE, THIS_METHOD, error);
    [self onConnected:NO];
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogVerbose(@"%@: %@ Disconnected, error=%@", THIS_FILE, THIS_METHOD, error);

    // Signalize non-availability.
    [self onConnected:NO];

    // Consider as failed.
    if (error != nil) {
        [self onSendAttemptFailed];
        DDLogWarn(@"XMPP disconnected with error: %@, report: %@", error, [self xmppReport]);
    }

    // Disconnection statistics.
    [_disconnectedErrorRate update:error != nil ? 1.0 : 0.0];

    // Connectivity invalid -> do nothing.
    if (!self.isConnectivityValid){
        return;
    }

    // Background mode -> do nothing.
    PEXService * svc = [PEXService instance];
    if ([svc isInBackground]){
        return;
    }

    // Start reconnect if connection was not quit.
    if (self.isConnectInitialized) {
        _lastReconnectAttempt = [NSDate date];
        [self.xmppReconnect manualStart];
    }
}

- (void)xmppStreamWillConnect:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    sender.enableBackgroundingOnSocket = YES;
    // TODO: develop a proxy for inner services tunelling. One TLS proxy to local services.
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidStartNegotiation:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didNotRegister:(NSXMLElement *)error {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (id <XMPPCustomBinding>)xmppStreamWillBind:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return nil;
}

- (NSString *)xmppStream:(XMPPStream *)sender alternativeResourceForConflictingResource:(NSString *)conflictingResource {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return nil;
}

- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq {
    DDLogVerbose(@"%@: %@, IQ=%@", THIS_FILE, THIS_METHOD, iq);
    return iq;
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender willReceiveMessage:(XMPPMessage *)message {
    DDLogVerbose(@"%@: %@, message=%@", THIS_FILE, THIS_METHOD, message);
    return message;
}

- (XMPPPresence *)xmppStream:(XMPPStream *)sender willReceivePresence:(XMPPPresence *)presence {
    DDLogVerbose(@"%@: %@, presence=%@", THIS_FILE, THIS_METHOD, presence);
    return presence;
}

- (void)xmppStreamDidFilterStanza:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: sender];
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    DDLogVerbose(@"%@: %@, message=%@", THIS_FILE, THIS_METHOD, message);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: sender];
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    DDLogVerbose(@"%@: %@, presence=%@", THIS_FILE, THIS_METHOD, presence);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: sender];

    // Buddy went offline/online
    XMPPJID *myUsername = [sender myJID];
    XMPPJID *presenceFromUser = [presence from];
    NSString *presenceType = [presence type]; // online/offline
    NSString *status = presence.status;
    BOOL isAvailable = presenceType == nil || ![presenceType isEqualToString:@"unavailable"];

    // Push presence information to the presence center.
    [[PEXPresenceCenter instance] presenceUpdatedForUser:presenceFromUser localUser:myUsername
                                             isAvailable:isAvailable textStatus:status];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(NSXMLElement *)error {
    DDLogVerbose(@"%@: %@, error=%@", THIS_FILE, THIS_METHOD, error);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: sender];
}

- (XMPPIQ *)xmppStream:(XMPPStream *)sender willSendIQ:(XMPPIQ *)iq {
    DDLogVerbose(@"%@: %@, IQ=%@", THIS_FILE, THIS_METHOD, iq);
    return iq;
}

- (XMPPMessage *)xmppStream:(XMPPStream *)sender willSendMessage:(XMPPMessage *)message {
    DDLogVerbose(@"%@: %@, sendMessage=%@", THIS_FILE, THIS_METHOD, message);
    return message;
}

- (XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence {
    DDLogVerbose(@"%@: %@, presence=%@", THIS_FILE, THIS_METHOD, presence);
    return presence;
}

- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq {
    DDLogVerbose(@"%@: %@, iq=%@", THIS_FILE, THIS_METHOD, iq);

}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    DDLogVerbose(@"%@: %@, message=%@", THIS_FILE, THIS_METHOD, message);

}

- (void)xmppStream:(XMPPStream *)sender didSendPresence:(XMPPPresence *)presence {
    DDLogVerbose(@"%@: %@, presence=%@", THIS_FILE, THIS_METHOD, presence);

    // Notify presence manager about sending a presence packet to the server.
    [PEXService executeWithName:@"presenceSent" async:YES block:^{
        PEXPresenceCenter * pc = [PEXPresenceCenter instance];
        [pc didSendPresence:presence envelope: self.lastEnvelope];
    }];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendIQ:(XMPPIQ *)iq error:(NSError *)error {
    DDLogVerbose(@"%@: %@, iq: %@, error: %@", THIS_FILE, THIS_METHOD, iq, error);
    [self onSendAttemptFailed];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    DDLogVerbose(@"%@: %@, error=%@", THIS_FILE, THIS_METHOD, error);
    [self onSendAttemptFailed];
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendPresence:(XMPPPresence *)presence error:(NSError *)error {
    DDLogVerbose(@"%@: %@, presence=%@, error=%@", THIS_FILE, THIS_METHOD, presence, error);
    [self onSendAttemptFailed];
}

- (void)xmppStreamDidChangeMyJID:(XMPPStream *)xmppStream {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStreamWasToldToDisconnect:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStreamDidSendClosingStreamStanza:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender {
    DDLogVerbose(@"%@: %@, sender: %@", THIS_FILE, THIS_METHOD, sender);

    // Connection failed - as if we would be pinging the server with no success.
    [self onSendAttemptFailed];
}

- (void)xmppStream:(XMPPStream *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender didRegisterModule:(id)module {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender willUnregisterModule:(id)module {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender didSendCustomElement:(NSXMLElement *)element {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppStream:(XMPPStream *)sender didReceiveCustomElement:(NSXMLElement *)element {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppReconnect:(XMPPReconnect *)sender didDetectAccidentalDisconnect:(SCNetworkReachabilityFlags)connectionFlags {
    DDLogVerbose(@"%@: %@, reachability: %lu", THIS_FILE, THIS_METHOD, (unsigned long) connectionFlags);
    // TODO: handle somehow...
}

- (BOOL)xmppReconnect:(XMPPReconnect *)sender shouldAttemptAutoReconnect:(SCNetworkReachabilityFlags)reachabilityFlags {
    PEXService * svc = [PEXService instance];
    BOOL connWorks = [svc isConnectivityWorking];
    BOOL inBackground = [svc isInBackground];
    DDLogVerbose(@"%@: %@, reachabilityFlags: %lu, connWorks: %d, inBackground: %d", THIS_FILE, THIS_METHOD, (unsigned long) reachabilityFlags, connWorks, inBackground);
    if (reachabilityFlags == 0 && !connWorks){
        return NO;
    }

    // If in background mode, we have to throttle the activity.
    if (inBackground){
        DDLogVerbose(@"In background, connectivity works. Fail counter: %d", (int) _pingFailCounter);
        return _pingFailCounter < PEXPingFailLimit;
    }

    return YES;
}

- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq {
    DDLogVerbose(@"%@: %@, iq=%@", THIS_FILE, THIS_METHOD, iq);

}

- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
    DDLogVerbose(@"%@: %@, rosterItem=%@", THIS_FILE, THIS_METHOD, item);

}

- (void)xmppAutoPingDidSendPing:(XMPPAutoPing *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

}

- (void)xmppAutoPingDidReceivePong:(XMPPAutoPing *)sender {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: nil];
}

- (void)xmppAutoPingDidTimeout:(XMPPAutoPing *)sender {
    DDLogVerbose(@"%@: %@, sender: %@", THIS_FILE, THIS_METHOD, sender);
    // If 3 consecutive ping fails && in background && connected, disconnect from XMPP and wait for foreground || connectivity recovery || in next keep-alive.
    // Takes any received packet into account as ping response / update counters.
    [self onSendAttemptFailed];
}

- (void)xmppPing:(XMPPPing *)sender didReceivePong:(XMPPIQ *)pong withRTT:(NSTimeInterval)rtt {
    DDLogVerbose(@"%@: %@, pong=%@, rtt=%f", THIS_FILE, THIS_METHOD, pong, rtt);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: nil];
}

- (void)xmppPing:(XMPPPing *)sender didNotReceivePong:(NSString *)pingID dueToTimeout:(NSTimeInterval)timeout {
    DDLogVerbose(@"%@: %@, pingId: %@, timeout: %f", THIS_FILE, THIS_METHOD, pingID, timeout);
    // If 3 consecutive ping fails && in background && connected, disconnect from XMPP and wait for foreground || connectivity recovery || in next keep-alive.
    // Takes any received packet into account as ping response / update counters.
    [self onSendAttemptFailed];
}

// ---------------------------------------------
#pragma mark - XMPP send callbacks
// ---------------------------------------------

- (void)xmppPushReceived:(PEXXMPPPhxPushModule *)sender msg:(XMPPIQ *)msg json:(NSString *)json {
    DDLogVerbose(@"Jsontext: %@", json);
    // Mark connection as working, reset ping timeout counters.
    [self onValidMessageReceived: nil];
    // Process JSON push update
    [self.pushProcessor handlePush:json];
}

- (void)xmppPushQuery:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.pushQueryRec != nil && [packetId isEqualToString:weakSelf.pushQueryRec.packetId]) {
            if (resp) {
                [weakSelf.pushQueryRec onSuccess];

            } else {
                [weakSelf.pushQueryRec onFail];
                [weakSelf trySendPushQueryInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.pushQueryRec.packetId, resp != nil, weakSelf.pushQueryRec);
        }
    }];
}

- (void)xmppPresenceQuery:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.presQueryRec != nil && [packetId isEqualToString:weakSelf.presQueryRec.packetId]) {
            if (resp) {
                [weakSelf.presQueryRec onSuccess];

            } else {
                [weakSelf.presQueryRec onFail];
                [weakSelf trySendPresenceQueryInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.presQueryRec.packetId, resp != nil, weakSelf.presQueryRec);
        }
    }];
}

- (void)xmppActiveQuery:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.activityRec != nil && [packetId isEqualToString:weakSelf.activityRec.packetId]) {
            if (resp) {
                [weakSelf.activityRec onSuccess];

            } else {
                [weakSelf.activityRec onFail];
                [weakSelf trySendActivityInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.activityRec.packetId, resp != nil, weakSelf.activityRec);
        }
    }];
}

- (void)xmppSetToken:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.pushTokenRec != nil && [packetId isEqualToString:weakSelf.pushTokenRec.packetId]) {
            [weakSelf.pushTokenRec storeLastResult:sender response:resp withInfo:packetInfo];
            if (resp) {
                [weakSelf.pushTokenRec onSuccess];

            } else {
                [weakSelf.pushTokenRec onFail];
                [weakSelf trySendPushTokenInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.pushTokenRec.packetId, resp != nil, weakSelf.pushTokenRec);
        }
    }];
}

- (void)xmppPushReq:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.pushReq != nil && [packetId isEqualToString:weakSelf.pushReq.packetId]) {
            [weakSelf.pushReq storeLastResult:sender response:resp withInfo:packetInfo];
            if (resp) {
                [weakSelf.pushReq onSuccess];

            } else {
                [weakSelf.pushReq onFail];
                [weakSelf trySendPushReqInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.pushReq.packetId, resp != nil, weakSelf.pushReq);
        }
    }];

}

- (void)xmppPushAck:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo {
    DDLogVerbose(@"%@: %@, resp=%@, packetId=%@", THIS_FILE, THIS_METHOD, resp, [packetInfo elementID]);

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:nil async:YES onQueue:_dispatchQueue block:^{
        NSString * packetId = [packetInfo elementID];
        if (weakSelf.pushAck != nil && [packetId isEqualToString:weakSelf.pushAck.packetId]) {
            [weakSelf.pushAck storeLastResult:sender response:resp withInfo:packetInfo];
            if (resp) {
                [weakSelf.pushAck onSuccess];

            } else {
                [weakSelf.pushAck onFail];
                [weakSelf trySendPushAckInt:NO];

            }
        }  else {
            DDLogVerbose(@"PacketID does not match, signalled: %@, lastOne: %@, success: %d, whole: %@",
                    packetId, weakSelf.pushAck.packetId, resp != nil, weakSelf.pushAck);
        }

    }];
}

@end