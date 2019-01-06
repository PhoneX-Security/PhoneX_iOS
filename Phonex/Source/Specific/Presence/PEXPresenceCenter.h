//
// Created by Dusan Klinec on 27.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPbPush.pb.h"

@class PEXPbPresencePush;
@class XMPPJID;
@class PEXUserPrivate;
@class PEXPresenceUpdateMsg;
@class PEXPresenceUpdateEnvelope;
@class PEXPresenceState;
@class XMPPPresence;
@class PEXDbContentProvider;

FOUNDATION_EXPORT NSString *PEX_ACTION_LOCAL_PRESENCE_CHANGED;
FOUNDATION_EXPORT NSString *PEX_EXTRA_PRESENCE_STATE;

@interface PEXPresenceCenter : NSObject<NSCacheDelegate>
+ (PEXPresenceCenter *)instance;
-(void) doRegister;
-(void) doUnregister;

/**
* Bulk presence update.
*/
- (void) updatePresence:(NSArray *) presenceUpdates;

/**
* Contact presence update from XMPP framework goes here.
*/
-(void) presenceUpdatedForUser: (XMPPJID *) user localUser: (XMPPJID *) localUser
                   isAvailable: (BOOL) isAvailable textStatus: (NSString *) textStatus;

/**
* Reads stored presence state for given user.
*/
-(PEXPbPresencePushPEXPbStatus) getStoredPresenceForUser: (NSString *) user;

/**
* Call from GUI to set current user state.
*/
-(void) setStateFromGui: (PEXPresenceUpdateMsg *) msg;

/**
* Updates presence for logged user. Local one.
* Called on internal app presence updates events (e.g., registration change, status change, ...)
*/
-(void) updatePresenceForLogged: (PEXPresenceUpdateMsg *) msg;

/**
* Updates presence for logged user, local one and generates new presence message.
*/
-(PEXPresenceUpdateEnvelope *) updatePresenceAndGetMsgForLogged: (PEXPresenceUpdateMsg *) msg;

/**
* Generates presence data for given local user.
*/
-(PEXPresenceUpdateEnvelope *) generatePresenceData: (NSString *) user;

/**
* Generates presence data from presence state.
* Usually obtained from notifications.
*/
- (PEXPresenceUpdateEnvelope *) generatePresenceDataFromState:(PEXPresenceState *)state;

/**
* Presence was sent by underlying framework.
*/
- (void)didSendPresence:(XMPPPresence *)presence envelope:(PEXPresenceUpdateEnvelope *)envelope;

/**
* Sets all contacts as offline.
*/
+(void) setOfflinePresence: (NSString *) contactOwner cr: (PEXDbContentProvider *) cr;
-(void) setOfflinePresence: (NSString *) contactOwner;

/**
* Triggers action for scanning delayed presence updates.
*/
+(void) broadcastUserAddedChange;
@end