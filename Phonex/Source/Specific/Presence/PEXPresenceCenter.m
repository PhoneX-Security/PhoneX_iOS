//
// Created by Dusan Klinec on 27.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPresenceCenter.h"
#import "PEXSipUri.h"
#import "PEXUtils.h"
#import "PEXDbContact.h"
#import "PEXPbPush.pb.h"
#import "USAdditions.h"
#import "PEXPhonexSettings.h"
#import "PBGeneratedMessage+PEX.h"
#import "XMPPJID.h"
#import "PEXUserPrivate.h"
#import "PEXDBUserProfile.h"
#import "PEXService.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXCertRefreshParams.h"
#import "PEXConcurrentHashMap.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXPresenceUpdateEnvelope.h"
#import "PEXPresenceState.h"
#import "XMPPPresence.h"
#import "PEXGuiPresenceCenter.h"
#import "PEXDbContentProvider.h"
#import "PEXConnectivityChange.h"
#import "PEXPresenceUpdate.h"
#import "PEXXmppCenter.h"
#import "PEXXmppManager.h"
#import "PEXApplicationStateChange.h"

const NSTimeInterval PEX_PRESENCE_REBROADCAST_TIMEOUT = 30.0 * 60.0;
NSString *PEX_ACTION_LOCAL_PRESENCE_CHANGED = @"net.phonex.phonex.presence.action.local_update";
NSString *PEX_EXTRA_PRESENCE_STATE = @"net.phonex.presence.state";
NSString *PEX_ACTION_USER_ADDED = @"net.phonex.phonex.action.USER_ADDED";

@interface PEXPresenceCenter () {
    /**
    * Username -> presence state map.
    */
    PEXConcurrentHashMap * _presenceMap;

    /**
     * Cache for delayed presence updates for non-existing contacts.
     * User id -> Presence update.
    */
    NSCache * _delayedPresenceUpdate;
    NSMutableSet * _delayedPresenceUsers;
}
@property(nonatomic) BOOL registered;
@property(nonatomic) PEXPresenceUpdateMsg * lastGuiUpdate;

@end

@implementation PEXPresenceCenter {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        _presenceMap = [[PEXConcurrentHashMap alloc] initWithQueueName:@"presMap"];
        _delayedPresenceUpdate = [[NSCache alloc] init];
        _delayedPresenceUpdate.countLimit = 128;
        _delayedPresenceUsers = [[NSMutableSet alloc] init];
        self.registered = NO;
    }

    return self;
}

+ (PEXPresenceCenter *)instance {
    static PEXPresenceCenter *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for new presence notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
        [center addObserver:self selector:@selector(onUserAdded:) name:PEX_ACTION_USER_ADDED object:nil];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        //[center addObserver:self selector:@selector(receivePresenceNotification:) name:PEX_ACTION_LOCAL_PRESENCE_CHANGED object:nil];

        @synchronized (_delayedPresenceUpdate) {
            [_delayedPresenceUpdate removeAllObjects];
            [_delayedPresenceUsers removeAllObjects];
        }

        DDLogDebug(@"Presence center registered");
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

        DDLogDebug(@"Presence center unregistered");
        self.registered = NO;
    }
}

-(PEXPbPresencePush *) parsePushMessageFromPresence: (NSString *) textStatus error:(NSError **) pError {
    // Attempt to parse presence text into PushNotification.
    @try {
        if (![PEXUtils isEmpty:textStatus]
                && ![@"?" isEqualToString:textStatus]
                && ![@"online" isEqualToString:textStatus]
                && ![@"offline" isEqualToString:textStatus]
                && ![@"unknown" isEqualToString:textStatus]){

            NSData * bpush = [NSData dataWithBase64EncodedString:textStatus];
            return [PEXPbPresencePush parseFromData:bpush];
        }
    } @catch(NSException * ex){
        DDLogError(@"Cannot parse presence information, exception=%@", ex);
    }

    return nil;
}

/**
* Presence push message sent by contact in presence text.
*/
-(void) processPresencePushMessageForUser: (NSString *) buddyUri
                             presencePush: (PEXPbPresencePush *) presencePush
                              isAvailable: (NSNumber *) isAvailable
                            contentValues: (PEXDbContentValues *) cv2
                            certEventSend: (BOOL *) certEventSent
{
    DDLogVerbose(@"Extended presence notification for user '%@' [%@]", buddyUri, presencePush);

    BOOL sendEvent = NO;
    NSDate * notBefore = nil;
    NSString * certHash = nil;

    // If CV is null, create it anyway and store update to the database.
    PEXDbContentValues * cv = cv2;
    if (cv == nil){
        cv = [[PEXDbContentValues alloc] init];
    }

    // Status.
    if (presencePush.hasStatus){
        NSNumber * presenceType = @(presencePush.status);
        [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TYPE NSNumberAsInt: presenceType];
        // in case user is XMPP.Available but has presence status Offline, mark him in DB as offline - to have Contact list sorted properly
        [cv put:PEX_DBCL_FIELD_PRESENCE_ONLINE boolean: presencePush.status == PEXPbPresencePushPEXPbStatusOffline];
    } else {
        // If not present, set default state in order to reset previous one.
        [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TYPE integer: isAvailable ? PEXPbPresencePushPEXPbStatusOnline : PEXPbPresencePushPEXPbStatusOffline];
    }

    // Status text.
    if (presencePush.hasStatusText){
        [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TEXT string: [PEXUtils getStringMaxLen:presencePush.statusText length:512]];
    } else {
        // If not present set empty state to reset previous one.
        [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TEXT string: @""];
    }

    // Short cert hash.
    if (presencePush.hasCertHashShort){
        [cv put:PEX_DBCL_FIELD_PRESENCE_CERT_HASH_PREFIX string: [PEXUtils getStringMaxLen:presencePush.certHashShort length:512]];
        certHash = presencePush.certHashShort;
        sendEvent = YES;
    }

    // Certificate expiration.
    if (presencePush.hasCertNotBefore && presencePush.certNotBefore > 0){
        notBefore = [NSDate dateWithTimeIntervalSince1970:presencePush.certNotBefore/1000.0];
        [cv put:PEX_DBCL_FIELD_PRESENCE_CERT_NOT_BEFORE date:notBefore];
        sendEvent = YES;
    }

    // Update capabilities
    if (presencePush.hasCapabilitiesSkip){
        const BOOL capSkip = presencePush.capabilitiesSkip;

        if (!capSkip && presencePush.capabilities != nil){
            const int capCount = [presencePush.capabilities count];
            NSMutableSet * capSet = [[NSMutableSet alloc] initWithCapacity:capCount];
            for (int i=0; i < capCount; ++i){
                [capSet addObject:[presencePush capabilitiesAtIndex:i]];
            }

            NSString * capAcc = [PEXDbContact assembleCapabilities:capSet];
            DDLogVerbose(@"Updating caps for user %@; caps=%@", buddyUri, capAcc);

            if (![PEXUtils isEmpty:capAcc]){
                [cv put:PEX_DBCL_FIELD_CAPABILITIES string:capAcc];
            } else {
                [cv put:PEX_DBCL_FIELD_CAPABILITIES string:@""];
            }
        }
    }

    // Broadcast certificate check event.
    // Should be handled by background service to check it. It handles DoS policy & stuff...
    if (sendEvent) {
        // Broadcast certificate update to the certificate update service.
        PEXService * svc = [PEXService instance];

        // trigger certificate update service here.
        PEXCertRefreshParams * par = [PEXCertRefreshParams paramsWithUser:buddyUri forceRecheck:NO];
        par.becameOnlineCheck = NO;
        par.pushNotification = YES;
        par.notBefore = notBefore;
        par.existingCertHash2recheck = certHash;

        DDLogVerbose(@"Cert update by push notif for user: %@, par=%@", buddyUri, par);
        [svc.certUpdateManager triggerCertUpdate:@[par]];
    }
}

/**
* Sets all contacts for the given user to the offline presence.
*/
+(void) setOfflinePresence: (NSString *) contactOwner cr: (PEXDbContentProvider *) cr {
    // For now (single user mode) turn all contacts to offline.
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TYPE integer:PEXPbPresencePushPEXPbStatusOffline];
    [cv put:PEX_DBCL_FIELD_PRESENCE_ONLINE boolean:NO];
    [cv put:PEX_DBCL_FIELD_PRESENCE_LAST_UPDATE date: [NSDate date]];

    @try {
        [cr update:[PEXDbContact getURI] ContentValues:cv selection:@" WHERE 1" selectionArgs:@[]];
    } @catch(NSException * e){
        DDLogError(@"Exception, cannot update presence to offline, exception=%@", e);
    }
}

- (void)setOfflinePresence:(NSString *)contactOwner {
    [PEXPresenceCenter setOfflinePresence:contactOwner cr:[PEXDbAppContentProvider instance]];
}

- (void) updatePresence:(NSArray *) presenceUpdates {
    // TODO: optimize this for bulk presence updates like I did on Android. Bulk DB operations.
    if (presenceUpdates == nil || [presenceUpdates count] == 0){
        return;
    }

    for(PEXPresenceUpdate * upd in presenceUpdates){
        [self presenceUpdatedForUser:upd.xmppUser localUser:upd.xmppUser isAvailable:upd.isAvailable textStatus:upd.statusText];
    }
}

- (void)presenceUpdatedForUser:(XMPPJID *)user localUser:(XMPPJID *)localUser
                   isAvailable:(BOOL)isAvailable textStatus:(NSString *)textStatus
{
    // Determine if it is special server notifier account.
    // Then this is pure virtual account.
    NSString * buddyUri = [PEXSipUri getCanonicalSipContact:[user bare] includeScheme:NO];
    DDLogVerbose(@"Presence update received from [%@] to [%@], available=%d, status=%@",
            buddyUri, [localUser full], isAvailable, textStatus);

    // TODO: notifier suffix, handle system notifier account.
//    if (uinfo.userName.endsWith(NOTIFIER_SUFFIX)){
//        Log.df(TAG, "Special notifier account: [%s]", buddyUri);
//        handleServerPush(ctxt, buddyUri, isAvailable, protobufStatusText);
//        return;
//    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    @try {
        // at first fetch contact with given SIP
        // is contact already in database?
        PEXDbContact * contact = [PEXDbContact newProfileFromDbSip:cr sip:buddyUri projection:[PEXDbContact getLightProjection]];
        if (contact == nil){
            // Add to delayed presence, re-broadcasted when user is added.
            [self addDelayedPresence:[PEXPresenceUpdate updateWithIsAvailable:isAvailable
                                                                   statusText:textStatus
                                                                    timestamp:[NSDate date]
                                                                         user:buddyUri xmppUser:user]];

            DDLogWarn(@"User with sip [%@] was not found in contacts database.", buddyUri);
            return;
        }

        // Presence push notification for this contact.
        // Using Google Protocol Buffers to serialize complex structures
        // into presence status text information.
        PEXPbPresencePush * presencePush = [self parsePushMessageFromPresence:textStatus error:nil];

        // Call update on given user
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEX_DBCL_FIELD_PRESENCE_ONLINE boolean:isAvailable];
        [cv put:PEX_DBCL_FIELD_PRESENCE_LAST_UPDATE date: [NSDate date]];

        BOOL sendEvent = false;
        if (presencePush != nil){
            [self processPresencePushMessageForUser:buddyUri presencePush:presencePush isAvailable:@(isAvailable)
                                      contentValues:cv certEventSend: &sendEvent];

        } else if (!isAvailable){ // when presencePush is null but contact is not available
            [cv put:PEX_DBCL_FIELD_PRESENCE_STATUS_TYPE integer:PEXPbPresencePushPEXPbStatusOffline];
        }

        // If event for a certificate check was not broadcasted
        // (presence info does not convey certificate freshness information),
        // Inspect option that user came online after being offline - another
        // reason to check certificate.
        if (!sendEvent && !contact.presenceOnline && isAvailable && [PEXPhonexSettings checkCertificateOnBecomeOnlineEvent]){
            DDLogVerbose(@"Cert update by becoming online: %@; presStatus=%d", buddyUri, isAvailable);
            PEXService * svc = [PEXService instance];

            // trigger certificate update service here.
            PEXCertRefreshParams * par = [PEXCertRefreshParams paramsWithUser:buddyUri forceRecheck:NO];
            par.becameOnlineCheck = YES;
            [svc.certUpdateManager triggerCertUpdate:@[par]];
        }

        DDLogDebug(@"Going to update presence, buddy=%@; contentValues=[%@];", buddyUri, cv);
        [PEXDbContact updateContact:cr contactId:contact.id contentValues:cv];

    } @catch (NSException * e) {
        DDLogError(@"Can't update status. Exception=%@", e);
    }
}

/**
* Retrieves presence state for particular user from the persistent storage / cache.
*/
-(PEXPresenceState *) getPresenceState: (NSString *) usr {
    // Normalize user
    NSString * uKey = [PEXSipUri getCanonicalSipContact:usr includeScheme:NO];
    PEXPresenceState * state = [_presenceMap get:uKey];
    return state;
}

/**
* Set presence state to the persistent storage / cache.
*/
-(void) setPresenceState: (PEXPresenceState *) curState async: (BOOL) async{
    if (curState == nil || curState.user == nil){
        DDLogDebug(@"Cannot store nil state/user to the cache, state=%@", curState);
        return;
    }

    DDLogVerbose(@"Setting new presence for %@, pres=%@", curState.user, curState);
    [_presenceMap put:curState key:curState.user async:async];
}

/**
* Updates given presence state with presence update message and returns a new state object.
* Does not manipulate neither persistent storage nor data.
*/
-(PEXPresenceState *) updateStateFromMsg: (PEXPresenceUpdateMsg *) msg prevState: (PEXPresenceState *) prevState {
    PEXPresenceState * newState = [prevState copy];

    if (msg == nil){
        return newState;
    }

    if (msg.user == nil){
        DDLogError(@"Presence update message has empty user!");
        return newState;
    }

    // If previous state is nil, create a new one from message.
    // It is probably a first presence update.
    if (newState == nil){
        newState = [PEXPresenceState stateWithUser:msg.user];
        newState.isCallingRightNow = @(0);
        newState.isCellularCallingRightNow = @(0);
        newState.isInBackground = @(0);

        // Load stored presence state from persistent storage.
        newState.statusId = @([self getStoredPresenceForUser:msg.user]);
    }

    if (msg.isAvailable != nil){
        newState.isAvailable = msg.isAvailable;
    }

    if (msg.isCallingRightNow != nil){
        newState.isCallingRightNow = msg.isCallingRightNow;
    }

    if (msg.isCellularCallingRightNow != nil){
        newState.isCellularCallingRightNow = msg.isCellularCallingRightNow;
    }

    if (msg.sipRegistered != nil){
        newState.sipRegistered = msg.sipRegistered;
    }

    if (msg.statusId != nil){
        newState.statusId = msg.statusId;
    }

    if (msg.statusMessage != nil){
        newState.statusMessage = msg.statusMessage;
    }

    if (msg.isInBackground != nil){
        newState.isInBackground = msg.isInBackground;
    }

    newState.lastUpdate = msg;

    // Store last presence update time. Only if differs.
    if (![newState isEqualToState:prevState]){
        newState.lastUpdateTime = [NSDate date];
    }

    return newState;
}

-(PEXPbPresencePushPEXPbStatus) getStoredPresenceForUser: (NSString *) user {
    // TODO: refactor.
    PEX_GUI_PRESENCE pres = [[PEXUserAppPreferences instance] getGuiWantedPresence];
    return [PEXGuiPresenceCenter translateToPresenceState:pres];
}

-(void) setStateFromGui: (PEXPresenceUpdateMsg *) msg{
    self.lastGuiUpdate = msg;
    [self updatePresenceForLogged:msg fromUser:YES];
}

-(void) updatePresenceForLogged: (PEXPresenceUpdateMsg *) msg{
    [self updatePresenceForLogged:msg fromUser:NO];
}

-(void) updatePresenceForLogged: (PEXPresenceUpdateMsg *) msg fromUser: (BOOL) fromUser {
    if ([PEXUtils isEmpty:msg.user]){
        DDLogError(@"Presence update with empty user name");
    }

    PEXPresenceState * curState = [self getPresenceState:msg.user];
    PEXPresenceState * newState = [self updateStateFromMsg:msg prevState:curState];
    if (newState == nil){
        DDLogError(@"Cannot update presence - no data, msg=%@; state=%@", msg, curState);
        return;
    }

    // Check if the new state differs from the old state somehow, not to broadcast change while there is no change.
    // Saves battery life, bandwidth.
    if ([newState isEqualToState:curState]){
        // State is equal, but since we have no presence ACK yet, presence update might got lost on the way
        // to the server, to increase robustness against errors, re-transmit presence each 30 minutes.
        // TODO: When server side ACK is implemented do not rebroadcast, save battery life of this client and clients of my contacts.
        NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
        if (curState.lastUpdateSendTime != nil && (now - [curState.lastUpdateSendTime timeIntervalSince1970]) < PEX_PRESENCE_REBROADCAST_TIMEOUT){
            return;
        }

        DDLogVerbose(@"Presence state did not update, re-broadcasting, last broadcast: %@", curState.lastUpdateSendTime);
    }

    curState.lastUpdateSendTime = [NSDate date];
    [self setPresenceState:newState async:YES];

    // Broadcast local presence change.
    // Notification receivers are executed in notifier thread so use service worker.
    [PEXService executeWithName:@"presenceNotify" async:YES block:^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:PEX_ACTION_LOCAL_PRESENCE_CHANGED object:nil userInfo:@{PEX_EXTRA_PRESENCE_STATE : newState}];
    }];

    // If presence update didn't come from GUI, let GUI know about this update.
    // We may lost SIP registration, GUI may want to display this state somehow.
    if (!fromUser){
        PEXGuiPresenceCenter * guiPresCenter = [PEXGuiPresenceCenter instance];
        [guiPresCenter presenceStateUpdated: newState];
    }
}

- (PEXPresenceUpdateEnvelope *) updatePresenceAndGetMsgForLogged:(PEXPresenceUpdateMsg *)msg {
    PEXPresenceState * curState = [self getPresenceState:msg.user];
    PEXPresenceState * newState = [self updateStateFromMsg:msg prevState:curState];
    if (newState == nil){
        DDLogError(@"Cannot generate presence envelope - no data, msg=%@; state=%@", msg, curState);
        return nil;
    }

    [self setPresenceState:newState async:YES];

    // Broadcast local presence change.
    // Notification receivers are executed in notifier thread so use service worker.
    [PEXService executeWithName:@"presenceNotify" async:YES block:^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:PEX_ACTION_LOCAL_PRESENCE_CHANGED object:nil userInfo:@{PEX_EXTRA_PRESENCE_STATE : newState}];
    }];

    // If presence update didn't come from GUI, let GUI know about this update.
    // We may lost SIP registration, GUI may want to display this state somehow.
    PEXGuiPresenceCenter * guiPresCenter = [PEXGuiPresenceCenter instance];
    [guiPresCenter presenceStateUpdated: newState];

    // Generate presence data from updated new state.
    return [self generatePresenceDataFromState:newState];
}

- (PEXPresenceUpdateEnvelope *) generatePresenceData:(NSString *)user {
    PEXPresenceState * curState = [self getPresenceState:user];
    return [self generatePresenceDataFromState:curState];
}

- (PEXPresenceUpdateEnvelope *) generatePresenceDataFromState:(PEXPresenceState *)state {
    PEXPbPresencePush * pushData = [self buildPresenceMessage:state];
    NSString * presMsg = [self serializePresencePush:pushData];
    PEXPresenceUpdateEnvelope * puo = [PEXPresenceUpdateEnvelope envelopeWithIsAvailable:state.isAvailable statusMessage:presMsg];
    puo.state = state;
    return puo;
}

/**
* Builds presence push message from current internal state.
*/
-(PEXPbPresencePush *) buildPresenceMessage: (PEXPresenceState *) state {
    @try {
        PEXPbPresencePushBuilder * const presencePushBuilder = [[PEXPbPresencePushBuilder alloc] init];

        // Setting things to tell to the world.
        [presencePushBuilder setVersion:1];

        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        PEXDbUserProfile * account = nil;

        // Load fresh user data from private data.
        if (state != nil && state.user != nil) {
            account = [PEXDbUserProfile getProfileWithName:state.user cr:cr projection:[PEXDbUserProfile getFullProjection]];
            DDLogVerbose(@"PrivData is not null, loading profile data: %@", account);
        } else {
            DDLogError(@"Build presence msg: state or user is nil");
        }

        // Certificate related data from stored profile.
        if (account != nil) {
            // Certificate freshness, cert hash add only few characters - prefix.
            NSString * cHash = account.cert_hash;
            if (![PEXUtils isEmpty:cHash] && [cHash length] >= 10) {
                [presencePushBuilder setCertHashShort:[cHash substringToIndex:10]];
            } else {
                DDLogError(@"Certhash is probably empty: %@, id=%@, uname=%@, certPath=%@",
                        account.cert_hash, account.id, account.username, account.cert_path
                );
            }

            // Certificate created date (validity starts).
            if (account.cert_not_before != nil && [account.cert_not_before timeIntervalSince1970] > 0.0) {
                [presencePushBuilder setCertNotBefore:[PEXUtils millisFromDate:account.cert_not_before]];
            }
        } else {
            DDLogError(@"Build presence msg: account for user is nil, uname: %@", state.user);
        }

        // Status text and type from in-memory state.
        NSString * statusText = state.statusMessage;
        if ([PEXUtils isEmpty:statusText]){
            [presencePushBuilder setStatusText:statusText];
        }

        // Set extended status code.
        if (state.statusId != nil){
            [presencePushBuilder setStatus:[state.statusId integerValue]];
        } else {
            [presencePushBuilder setStatus:PEXPbPresencePushPEXPbStatusOnline];
        }

        // SIP registered state (if available for call).
        if (state.sipRegistered != nil){
            [presencePushBuilder setSipRegistered:[state.sipRegistered boolValue]];
        } else {
            [presencePushBuilder setSipRegistered:YES];
        }

        // In background -> set Away
        if (state.isInBackground != nil && [state.isInBackground boolValue]){
            [presencePushBuilder setStatus:PEXPbPresencePushPEXPbStatusAway];
        }

        // In-call status - only if allowed in prefs.
        // TODO: read preference value on this.
        if (   (state.isCallingRightNow != nil && [state.isCallingRightNow boolValue])
            || ([PEXPhonexSettings takeCellularCallsToBusyState]
                  && state.isCellularCallingRightNow != nil
                  && [state.isCellularCallingRightNow boolValue]))
        {
            [presencePushBuilder setStatus:PEXPbPresencePushPEXPbStatusOncall];
        }

        // Capabilities.
        presencePushBuilder.capabilitiesSkip = NO;
        for (NSString * cap in [PEXPhonexSettings getCapabilities]) {
            [presencePushBuilder addCapabilities:cap];
        }

        // Serialization and text conversion.
        PEXPbPresencePush * msg = [presencePushBuilder build];
        DDLogVerbose(@"Presence message built: [%@]", msg);

        return msg;
    } @catch (NSException * e) {
        DDLogError(@"Exception during generating presence text, exception=%@", e);
    }

    return nil;
}

-(NSString *) serializePresencePush: (PEXPbPresencePush *) msg {
    if (msg == nil){
        return nil;
    }

    return [[msg writeToCodedNSData] base64EncodedStringWithOptions:0];
}

- (void)didSendPresence:(XMPPPresence *)presence envelope:(PEXPresenceUpdateEnvelope *)envelope {
    // Signalize to GUI that presence was set.
    PEXGuiPresenceCenter * guiPresCenter = [PEXGuiPresenceCenter instance];
    [guiPresCenter presencePostSet: envelope.state];
}

/**
* Receive local user presence changes in order to broadcast new presence state.
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
    if (conChange == nil) {
        return;
    }

    // Notify GUI presence center so it can display current state of the connection.
    PEXGuiPresenceCenter * guiPresCenter = [PEXGuiPresenceCenter instance];
    [guiPresCenter onConnectivityChanged:conChange];
}

/**
* Receive local user presence changes in order to broadcast new presence state.
*/
- (void)onUserAdded:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_USER_ADDED isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    [PEXService executeWithName:@"userAddedAction" async:YES block:^{
        @try {
            [self rebroadcastDelayedPresence];
        } @catch(NSException * e){
            DDLogError(@"Exception when rebroadcasting, %@", e);
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
}

/**
* Triggers action for scanning delayed presence updates.
*/
+(void) broadcastUserAddedChange {
    [PEXService executeWithName:@"newUserAddedNotify" async:YES block:^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:PEX_ACTION_USER_ADDED object:nil userInfo:@{}];
    }];
}

/**
* Adds presence update to the delayed presence state.
* Stores for later, when user got inserted to the contact list, this update may be handy that time.
*/
-(void) addDelayedPresence: (PEXPresenceUpdate *) update{
    @synchronized (_delayedPresenceUpdate) {
        // Add only new one, due to rebroadcasting, it may happen older update is added.
        PEXPresenceUpdate * prevUpd = [_delayedPresenceUpdate objectForKey:update.user];
        if (prevUpd == nil || [PEXUtils compareDate:prevUpd.timestamp b:update.timestamp] < 0) {
            [_delayedPresenceUpdate setObject:update forKey:update.user];
            [_delayedPresenceUsers addObject:update.user];
        }
    }
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
    if (cache != _delayedPresenceUpdate) {
        DDLogWarn(@"Invalid eviction notif, cache: %@", cache);
        return;
    }

    if (obj == nil || ![obj isKindOfClass:[PEXPresenceUpdate class]]){
        DDLogWarn(@"Invalid eviction object %@", obj);
        return;
    }

    @synchronized (_delayedPresenceUpdate) {
        @try {
            PEXPresenceUpdate * upd = (PEXPresenceUpdate *) obj;
            [_delayedPresenceUsers removeObject:upd.user];

        } @catch(NSException * e){
            DDLogError(@"Ecveption when managing eviction %@", e);
        }
    }
}

/**
* Rebroadcasts delayed presence stored in the manager state.
* Useful if presence update came earlier that user got inserted to the contact list.
*/
-(void) rebroadcastDelayedPresence {
    DDLogVerbose(@"Rebroadcasting delayed presence, count: %d", (int) [_delayedPresenceUsers count]);

    // Copy to local array in the synchronized block, delete cache.
    NSMutableArray * updates = [[NSMutableArray alloc] initWithCapacity:[_delayedPresenceUsers count]];
    NSMutableArray * updatesPushBack = [[NSMutableArray alloc] initWithCapacity:[_delayedPresenceUsers count]];
    @synchronized (_delayedPresenceUpdate) {
        NSArray * keys = [_delayedPresenceUsers allObjects];
        for(NSString * user in keys){
            id obj = [_delayedPresenceUpdate objectForKey:user];
            if (obj == nil || ![obj isKindOfClass:[PEXPresenceUpdate class]]) {
                continue;
            }

            [updates addObject:obj];
        }

        [_delayedPresenceUpdate removeAllObjects];
        [_delayedPresenceUsers removeAllObjects];
    }

    // Process each presence update, allow to pass only if isAvailable = true and not older than 5 minutes.
    uint64_t curTime = [PEXUtils millisFromDate:[NSDate date]];
    for(PEXPresenceUpdate * upd in updates){
        if (upd.timestamp == nil){
            continue;
        }

        uint64_t mupd = [PEXUtils millisFromDate:upd.timestamp];

        // Freshness check. If it is too old, this presence update is discarded permanently.
        if ((curTime - mupd) > 1000 * 60 * 5){
            continue;
        }

        [updatesPushBack addObject:upd];
    }

    // Rebroadcasting happens here.
    DDLogVerbose(@"Final rebroadcasting, #of elements: %lu", (unsigned long)[updatesPushBack count]);
    [self updatePresence:updatesPushBack];
}

@end