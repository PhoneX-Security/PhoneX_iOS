//
// Created by Dusan Klinec on 19.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushManager.h"
#import "PEXService.h"
#import "PEXConnectivityChange.h"
#import "PEXPushClistSyncEvent.h"
#import "PEXCListFetchTask.h"
#import "PEXTaskEventWrapper.h"
#import "PEXPushDhUseEvent.h"
#import "PEXDhKeyGenManager.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXPushContactCertUpdatedEvent.h"
#import "PEXApplicationStateChange.h"
#import "PEXPushTokenEvent.h"
#import "PEXUtils.h"
#import "PEXPushTokenConfig.h"
#import "PEXXmppCenter.h"
#import "PEXXmppManager.h"
#import "PEXXmppQueryFinishedSimple.h"
#import "PEXAppVersionUtils.h"
#import "PEXMessageDigest.h"
#import "PEXPushPairingRequestEvent.h"
#import "PEXPairingFetchParams.h"
#import "PEXPairingFetchTask.h"
#import "PEXPushLogoutEvent.h"
#import "PEXGuiLoginController.h"
#import "PEXCryptoUtils.h"
#import "PEXPushAckRegister.h"
#import "PEXPushAckMsg.h"
#import "PEXPushAckPart.h"
#import "PEXPushAckEvent.h"

NSString * PEX_ACTION_CLIST_CHECK = @"net.phonex.action.clistCheck";
NSString * PEX_EXTRA_CLIST_CHECK = @"net.phonex.extra.clistCheck";

NSString * PEX_ACTION_DHKEYS_CHECK = @"net.phonex.action.DHKEYS_CHECK";
NSString * PEX_EXTRA_DHKEYS_CHECK = @"net.phonex.extra.DHKEYS_CHECK";

NSString * PEX_ACTION_PUSH_CONTACT_CERT_UPDATE = @"net.phonex.phonex.cert.action.pushcontactupdated";
NSString * PEX_EXTRA_PUSH_CONTACT_CERT_UPDATE = @"net.phonex.phonex.cert.extra.pushcontactupdated";

NSString * PEX_LAST_DHCHECK_PUSH = @"net.phonex.action.lastdhpushcheck";
NSString * PEX_LAST_CONTACT_CERT_UPDATE_PUSH = @"net.phonex.action.lastcontact_cert_update";
NSString * PEX_LAST_PAIRING_REQUEST_PUSH = @"net.phonex.action.lastpairing_request_push";

NSString * PEX_ACTION_PUSH_PAIRING_REQUEST = @"net.phonex.action.pairingRequest";
NSString * PEX_EXTRA_PUSH_PAIRING_REQUEST = @"net.phonex.extra.pairingRequest";

NSString * PEX_ACTION_PUSH_LOGOUT = @"net.phonex.action.logoutEvt";
NSString * PEX_EXTRA_PUSH_LOGOUT = @"net.phonex.extra.logoutEvt";
NSString * PEX_LAST_LOGOUT_EVENT_PUSH = @"net.phonex.action.last_logoutEvt";

@interface PEXPushManager () {}
@property(nonatomic) BOOL registered;
@property(nonatomic) PEXPushClistSyncEvent * deferredEvent;
@property(nonatomic) PEXPushPairingRequestEvent * deferredPairingEvent;
@property(nonatomic) PEXPushAckEvent * deferredAckEvent;

@property(nonatomic) PEXPushAckRegister * ackRegister;

@property(nonatomic) NSError * pushTokenError;
@property(nonatomic) PEXPushTokenEvent * deferredTokenEvent;

@end

@implementation PEXPushManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ackRegister = [[PEXPushAckRegister alloc] init];
    }

    return self;
}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // Register on connectivity changes & clistSync events.
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
        [center addObserver:self selector:@selector(onAppStateChange:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];
        [center addObserver:self selector:@selector(onClistSync:) name:PEX_ACTION_CLIST_CHECK object:nil];
        [center addObserver:self selector:@selector(onDhKeyCheck:) name:PEX_ACTION_DHKEYS_CHECK object:nil];
        [center addObserver:self selector:@selector(onContactCertUpdated:) name:PEX_ACTION_PUSH_CONTACT_CERT_UPDATE object:nil];
        [center addObserver:self selector:@selector(onPairingRequest:) name:PEX_ACTION_PUSH_PAIRING_REQUEST object:nil];
        [center addObserver:self selector:@selector(onLogoutEvent:) name:PEX_ACTION_PUSH_LOGOUT object:nil];
        self.registered = YES;
    }
}

- (void)dealloc {
    if (self.registered) {
        [self doUnregister];
    }
}

- (void)doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];
        self.registered = NO;
    }
}

- (void)updatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;
    [self onDeviceTokenUploadTriggered];
}

/**
* Main processing point for clistSync event, takes care about finishing the request.
* Should be called on the serial queue so deferredEvent is not susceptible to race condition. One instance should check
* only one user at the time. Serial event for this object is needed, at least for clistSync.
*/
-(void) clistEvent: (PEXPushClistSyncEvent *) evt{
    // Get time of the last successful contact list sync.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    NSTimeInterval lastSync = [prefs getDoublePrefForKey:PEX_CLIST_FETCH_LAST_FINISH_TSTAMP defaultValue:0.0];
    NSTimeInterval msgTime  = [evt.tstamp longLongValue] / 1000.0;

    if (lastSync >= msgTime){
        // Last sync is more recent that received push message, ignore it since we have fresh info.
        return;
    }

    // Do the clistSync task.
    _deferredEvent = evt;

    // Clist sync task start here.
    PEXCListFetchTask * task = [[PEXCListFetchTask alloc] init];
    PEXCListFetchParams * param = [[PEXCListFetchParams alloc] init];
    param.sip = _privData.username;
    param.dbId = [_privData.accountId longLongValue];
    param.resetPresence = NO;
    param.updateClistTable = YES;
    param.cr = [PEXDbAppContentProvider instance];
    task.params = param;
    task.privData = _privData;

    __weak __typeof(self) weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onClistFetchCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    [task addListener:ew];

    // Progress & task init.
    [task prepareForPerform];

    // Run task in blocking mode here.
    DDLogVerbose(@"Starting contact list fetch task");
    [task start];
}

- (void) onClistFetchCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (ev.didFinishCancelled || ev.didFinishWithError){
        DDLogError(@"Task failed: %@", ev);
        return;
    }

    // Everything is ok, remove deferred event.
    _deferredEvent = nil;
    DDLogVerbose(@"ClistSync finished with success.");
}

/**
* Main processing point for clistSync event, takes care about finishing the request.
* Should be called on the serial queue so deferredEvent is not susceptible to race condition. One instance should check
* only one user at the time. Serial event for this object is needed, at least for clistSync.
*/
-(void) dhCheckEvent: (PEXPushDhUseEvent *) evt{
    // Get time of the last successful contact list sync.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    NSTimeInterval lastSync = [prefs getDoublePrefForKey:PEX_LAST_DHCHECK_PUSH defaultValue:0.0];
    NSTimeInterval msgTime  = [evt.tstamp longLongValue] / 1000.0;

    if (lastSync >= msgTime){
        // Last sync is more recent that received push message, ignore it since we have fresh info.
        return;
    }

    [prefs setDoublePrefForKey:PEX_LAST_DHCHECK_PUSH value:msgTime];
    [PEXDhKeyGenManager triggerUserCheck];
}

/**
* Main processing point for contact certificate update.
* Should be called on the serial queue so deferredEvent is not susceptible to race condition.
*/
-(void) contactCertUpdateEvent: (PEXPushContactCertUpdatedEvent *) evt{
    // Get time of the last successful contact list sync.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    NSTimeInterval lastSync = [prefs getDoublePrefForKey:PEX_LAST_CONTACT_CERT_UPDATE_PUSH defaultValue:0.0];
    NSTimeInterval msgTime  = [evt.tstamp longLongValue] / 1000.0;

    if (lastSync >= msgTime){
        // Last sync is more recent that received push message, ignore it since we have fresh info.
        return;
    }

    DDLogVerbose(@"Push notification for cert update - all users.");
    [prefs setDoublePrefForKey:PEX_LAST_CONTACT_CERT_UPDATE_PUSH value:msgTime];
    [[PEXCertificateUpdateManager instance] triggerCertUpdateForAll:NO];
}

/**
* Main processing point for pairingRequest event,.
* Should be called on the serial queue so deferredEvent is not susceptible to race condition.
*/
-(void) pairingRequestEvent: (PEXPushPairingRequestEvent *) evt{
    // Get time of the last successful contact list sync.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    NSTimeInterval lastSync = [prefs getDoublePrefForKey:PEX_LAST_PAIRING_REQUEST_PUSH defaultValue:0.0];
    NSTimeInterval msgTime  = [evt.tstamp longLongValue] / 1000.0;

    if (lastSync >= msgTime){
        // Last sync is more recent that received push message, ignore it since we have fresh info.
        return;
    }

    // Do the pairing fetch task.
    _deferredPairingEvent = evt;

    // Start pairing request fetch task (fetch + sync local database).
    PEXPairingFetchParams * param = [[PEXPairingFetchParams alloc] init];
    PEXPairingFetchTask * task = [[PEXPairingFetchTask alloc] init];
    param.sip = _privData.username;
    param.dbId = [_privData.accountId longLongValue];
    task.params = param;
    task.privData = _privData;

    __weak __typeof(self) weakSelf = self;
    PEXTaskEventWrapper * ew = [[PEXTaskEventWrapper alloc] initWithEndedBlock: ^(PEXTaskEvent const * const ev){
        [weakSelf onPairingFetchCompleted: (PEXTaskFinishedEvent const *const) ev];
    }];

    [task addListener:ew];

    // Progress & task init.
    [task prepareForPerform];

    // Run task in blocking mode here.
    DDLogVerbose(@"Starting pairing fetch task");
    [task start];
}

- (void) onPairingFetchCompleted: (PEXTaskFinishedEvent const * const) ev{
    if (ev.didFinishCancelled || ev.didFinishWithError){
        DDLogError(@"Task failed: %@", ev);
        return;
    }

    // Everything is ok, remove deferred event.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    [prefs setDoublePrefForKey:PEX_LAST_PAIRING_REQUEST_PUSH value:[_deferredPairingEvent.tstamp longLongValue] / 1000.0];
    _deferredPairingEvent = nil;
    DDLogVerbose(@"PairingSync finished with success.");
}

/**
* Main processing point for pairingRequest event,.
* Should be called on the serial queue so deferredEvent is not susceptible to race condition.
*/
-(void) logoutEvent: (PEXPushLogoutEvent *) evt{
    // Get time of the last successful contact list sync.
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    NSTimeInterval lastSync = [prefs getDoublePrefForKey:PEX_LAST_LOGOUT_EVENT_PUSH defaultValue:0.0];
    NSTimeInterval msgTime  = [evt.tstamp longLongValue] / 1000.0;

    if (lastSync >= msgTime){
        // Last sync is more recent that received push message, ignore it since we have fresh info.
        return;
    }

    [prefs setDoublePrefForKey:PEX_LAST_LOGOUT_EVENT_PUSH value:[evt.tstamp longLongValue] / 1000.0];

    // Logout is also ignored if current user logged in has a newer certificate than this logout request.
    PEXX509 *myCert = self.privData.cert;
    if (myCert == nil || !myCert.isAllocated){
        DDLogError(@"Current certificate is nil!");
        return;
    }

    // Get current cert date - if notification is older, ignore it.
    NSDate   * notBeforeDate = [PEXCryptoUtils getNotBefore:myCert.getRaw];
    int64_t notBefore        = (int64_t) ceil([notBeforeDate timeIntervalSince1970] * 1000.0);

    // Check according to the request.
    if ([evt.tstamp longLongValue] <= notBefore){
        DDLogVerbose(@"Logout event is older than our new certificate, ignoring. tStamp: %lld, crt: %lld", [evt.tstamp longLongValue], notBefore);
        return;
    }

    // Do the logout.
    DDLogInfo(@"Logout event is being processed, tstamp: %lld, lastEvt: %f, crt: %lld", [evt.tstamp longLongValue], lastSync, notBefore);
    [DDLog flushLog];

    [[PEXGuiLoginController instance] performLogoutWithMessage:PEXStr(@"txt_logout_server_command")];
}

/**
* Concat list sync event listener. Push notification indicating there might be a change in the contact list so we
* are requested to update it.
* Extracts information from notification and starts cert check in master serial queue.
*/
- (void)onClistSync:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_CLIST_CHECK] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushClistSyncEvent * evt = notification.userInfo[PEX_EXTRA_CLIST_CHECK];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Contact list synchronization verification.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"clistSync" async:YES block:^{
        [weakSelf clistEvent:evt];
    }];
}

/**
* Concat list sync event listener. Push notification indicating there might be a change in the contact list so we
* are requested to update it.
* Extracts information from notification and starts cert check in master serial queue.
*/
- (void)onDhKeyCheck:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_DHKEYS_CHECK] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushDhUseEvent * evt = notification.userInfo[PEX_EXTRA_DHKEYS_CHECK];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Contact list synchronization verification.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"dhUse" async:YES block:^{
        [weakSelf dhCheckEvent:evt];
    }];
}

/**
* Contact certificate update sync event listener.
*/
- (void)onContactCertUpdated:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_PUSH_CONTACT_CERT_UPDATE] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushContactCertUpdatedEvent * evt = notification.userInfo[PEX_EXTRA_PUSH_CONTACT_CERT_UPDATE];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Contact list synchronization verification.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"contactCertUpdate" async:YES block:^{
        [weakSelf contactCertUpdateEvent:evt];
    }];
}

/**
 * Pairing request event listener. Push notification indicating there might be a change in the pairing database.
 * Extracts information from notification and starts pairing check in master serial queue.
 */
- (void)onPairingRequest:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_PUSH_PAIRING_REQUEST] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushPairingRequestEvent * evt = notification.userInfo[PEX_EXTRA_PUSH_PAIRING_REQUEST];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Contact list synchronization verification.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"pairingSync" async:YES block:^{
        [weakSelf pairingRequestEvent:evt];
    }];
}

/**
 * Notification that this instance should immediatelly log out.
 */
- (void)onLogoutEvent:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_PUSH_LOGOUT] == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    PEXPushLogoutEvent * evt = notification.userInfo[PEX_EXTRA_PUSH_LOGOUT];
    if (evt == nil){
        DDLogError(@"Invalid action extras");
        return;
    }

    // Contact list synchronization verification.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"LogoutReq" async:YES block:^{
        [weakSelf logoutEvent:evt];
    }];
}

/**
* Receive connectivity changes so we can react on this - process deferred cert check request which failed due to connection error.
*/
- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil) {
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

    // If XMPP is connected, trigger sending delayed device token.
    if (conChange.xmppWorks == PEX_CONN_IS_UP){
        [self onDeviceTokenUploadTriggered];
    }

    if (conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    // IP changed?
    BOOL recovered = conChange.connection == PEX_CONN_GOES_UP;
    if (!recovered){
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"clistSyncOnConn" async:YES block:^{
        PEXPushManager * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (mgr.deferredEvent != nil){
            [mgr clistEvent:mgr.deferredEvent];
        }

        if (mgr.deferredPairingEvent != nil){
            [mgr pairingRequestEvent:mgr.deferredPairingEvent];
        }
    }];
}

- (void)onRemotePushReceived: (NSDictionary *) pushDict {
    WEAKSELF;
    [PEXService executeOnGlobalQueueWithName:@"pushProcess" async:YES block:^{
        [weakSelf processAckMessages:pushDict];

        // Reset badge number / recalculate based on our metrics.
        // TODO:[low] refactor to notifications to decrease coupling.
        [[PEXGuiNotificationCenter instance] notifyAllListeners];
    }];
}

-(void)processAckMessages: (NSDictionary *) pushDict  {
    @try {
        if (pushDict[@"phx"] == nil){
            DDLogVerbose(@"Push message does not contain phx key");
            return;
        }

        NSDictionary * phx = pushDict[@"phx"];
        if (phx[@"msg"] == nil || ![phx[@"msg"] isKindOfClass:[NSArray class]]){
            DDLogVerbose(@"phx->msg is nil or invalid: %@", phx[@"msg"]);
        }

        PEXPushAckMsg * ackMsg = [[PEXPushAckMsg alloc] init];
        ackMsg.tstamp = (long)[PEXUtils currentTimeMillis];

        // Process push messages individually.
        NSArray * msgs = phx[@"msg"];
        for(NSDictionary * cMsg in msgs){
            // Parsing of the push message.
            // It could be decoupled later to a separate parser code, not needed for now.
            NSNumber * badge = [PEXUtils getAsNumber:cMsg[@"b"]];
            NSNumber * timestamp = [PEXUtils getAsNumber:cMsg[@"t"]];
            NSNumber * expiration = [PEXUtils getAsNumber:cMsg[@"e"]];
            NSString * action = cMsg[@"p"];
            NSString * key = cMsg[@"k"];
            if ([PEXUtils isEmpty:action] || timestamp == nil){
                DDLogWarn(@"Malformed push message: %@", cMsg);
                continue;
            }

            PEXPushAckPart * ackPart = [[PEXPushAckPart alloc] init];
            ackPart.action = action;
            ackPart.timestamp = timestamp;
            ackPart.key = key;

            [ackMsg addPart:ackPart];
        }

        [self ackMessages:ackMsg];

    } @catch (NSException *e){
        DDLogError(@"Exception in processing push notifications %@", e);
    }
}

/**
 * Acknowledges given array of PEXPushRequestPart
 */
-(void)ackMessages: (PEXPushAckMsg *) ackMsg {
    // On each new ACK the new ACK event is built, for better coupling with response waiting.
    // When query finishes with some response from server we have particular event stored in completion handler.
    // If it would be the same object, race conditions would happen. If we have for each request individual object
    // completion handler affects only the object related with the particular request. If it happen
    // to be the current deferred event, we are done with sending, if not, object is updated and when completion
    // handler finishes, ARC deallocates it.
    @synchronized (self) {
        self.deferredAckEvent = [[PEXPushAckEvent alloc] init];
        self.deferredAckEvent.sending = YES;
        self.deferredAckEvent.ackMsg = ackMsg;
        self.deferredAckEvent.timestamp = [NSDate date];
    }

    [self triggerAckUpload];
}

-(void) triggerAckUpload {
    __weak __typeof(self) weakSelf = self;
    if (self.deferredAckEvent == nil || !self.deferredAckEvent.sending){
        return;
    }

    [PEXService executeWithName:@"ackUpload" async:YES block:^{
        PEXPushManager * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (mgr.deferredAckEvent != nil && mgr.deferredAckEvent.sending) {
            [mgr tryAckUpload:mgr.deferredAckEvent];
        }
    }];
}

-(void) tryAckUpload: (PEXPushAckEvent *) evt {
    if (evt == nil || !evt.sending){
        DDLogVerbose(@"Ack upload record not active");
        return;
    }

    if (self.privData == nil || [PEXUtils isEmpty:self.privData.username]){
        DDLogVerbose(@"Private data not found, cannot upload");
        return;
    }

    PEXService * svc = [PEXService instance];
    PEXXmppManager * xmppManager = svc.xmppCenter.xmppManager;

    // Completion handler.
    WEAKSELF;
    PEXXmppQueryFinishedSimple * onFinished = [PEXXmppQueryFinishedSimple simpleWithPexFinishedBlock:
            ^(PEXXMPPPhxPushModule *sender, XMPPIQ *resp, PEXXMPPPhxPushInfo *pingInfo, PEXXMPPSimplePacketSendRecord *sendRec)
            {
                DDLogVerbose(@"Ack upload finished, response=%@, evt: %@", resp, evt);
                if (resp){
                    @synchronized (weakSelf) {
                        evt.sending = NO;
                    }

                    // TODO:[low] sending finishes, update ACK register so we do not ack older messages that we just did.
                    // ...
                }
            }];

    // Build JSON representation.
    NSMutableDictionary * jsonSrc = [evt.ackMsg getSerializationBase];
    if(jsonSrc == nil){
        DDLogError(@"Serialization result empty");
        evt.sending = NO;
        return;
    }

    NSError * jsonError = nil;
    NSString * json = [PEXUtils serializeToJSON:jsonSrc error:&jsonError];
    if (json == nil || jsonError != nil){
        DDLogError(@"JSON serialization error: %@", jsonError);
        evt.sending = NO;
        return;
    }

    [xmppManager trySendPushAck:json onFinished:onFinished];
}

- (void)onDeviceTokenFail:(NSError *)error {
    self.pushTokenError = error;
    // TODO: mark apple push notification system as disabled.
}

- (void)onDeviceTokenUpdated:(NSData *)deviceToken {
    // Reset token error, may be some from previously failed attempts.
    self.pushTokenError = nil;
    // Store new deferred event so it can be transmitted to the server when possible.
    PEXPushTokenConfig * tokConfig = [PEXPushTokenConfig configWithToken:deviceToken];
    PEXPushTokenEvent * evt = [PEXPushTokenEvent eventWithToken:tokConfig];
    self.deferredTokenEvent = evt;
    // This call may be called when app is not yet logged in. In that case we have to wait.
    [self onDeviceTokenUploadTriggered];
}

/**
* Called when there is a chance deferred token can be uploaded to the server.
* Called from various sources / threads, thus executes in the main executor.
*/
- (void) onDeviceTokenUploadTriggered {
    __weak __typeof(self) weakSelf = self;
    if (self.deferredTokenEvent == nil){
        return;
    }

    [PEXService executeWithName:@"tokenUpload" async:YES block:^{
        PEXPushManager * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (mgr.deferredTokenEvent != nil) {
            [mgr tryDeviceTokenUpload:mgr.deferredTokenEvent];
        }
    }];
}

/**
* Working method called from the executor thread, takes care about sending deferred event passed as a parameter.
* If succeeds, real deferred event is cleared.
*/
-(void) tryDeviceTokenUpload: (PEXPushTokenEvent *) evt {
    if (evt == nil || evt.uploadFinished){
        DDLogVerbose(@"Device token nil or already uploaded");
        return;
    }

    if (self.privData == nil || [PEXUtils isEmpty:self.privData.username]){
        DDLogVerbose(@"Private data not found, cannot upload");
        return;
    }

    // Send special XMPP message containing the token. Wait for response. If response is OK, delete deferred event / set as uploaded.
    // If response is invalid, wait for app reconnect event.
    PEXService * svc = [PEXService instance];
    PEXXmppManager * xmppManager = svc.xmppCenter.xmppManager;
    PEXXmppQueryFinishedSimple * onFinished = [PEXXmppQueryFinishedSimple simpleWithPexFinishedBlock:
            ^(PEXXMPPPhxPushModule *sender, XMPPIQ *resp, PEXXMPPPhxPushInfo *pingInfo, PEXXMPPSimplePacketSendRecord *sendRec)
    {
        DDLogVerbose(@"Token upload finished, response=%@", resp);
        if (resp){
            evt.uploadFinished = YES;
        }
    }];

    [xmppManager trySendPushToken:evt.token onFinished:onFinished];
}

- (void)onLoginCompleted {
    [self onDeviceTokenUploadTriggered];
}

- (void)onAppStateChange:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        // If check was completed 12 hours ago or more, trigger a new check...
        [self onDeviceTokenUploadTriggered];
    }
}

@end