//
// Created by Dusan Klinec on 19.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushTokenEvent;
@class PEXPushTokenConfig;
@class PEXPushAckRegister;

extern NSString * PEX_ACTION_CLIST_CHECK;
extern NSString * PEX_EXTRA_CLIST_CHECK;

extern NSString * PEX_ACTION_DHKEYS_CHECK;
extern NSString * PEX_EXTRA_DHKEYS_CHECK;

extern NSString * PEX_ACTION_PUSH_CONTACT_CERT_UPDATE;
extern NSString * PEX_EXTRA_PUSH_CONTACT_CERT_UPDATE;

extern NSString * PEX_ACTION_PUSH_PAIRING_REQUEST;
extern NSString * PEX_EXTRA_PUSH_PAIRING_REQUEST;

extern NSString * PEX_ACTION_PUSH_LOGOUT;
extern NSString * PEX_EXTRA_PUSH_LOGOUT;

/**
* General management class taking care about push related events and their processing.
*
* E.g., it processes push request for contactlist refresh and takes care about finishing this request according to the protocol.
*/
@interface PEXPushManager : NSObject
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic, readonly) NSError * pushTokenError;
@property(nonatomic, readonly) PEXPushTokenEvent * deferredTokenEvent;
@property(nonatomic, readonly) PEXPushAckRegister * ackRegister;

-(void) doRegister;
-(void) doUnregister;

/**
* Called when private data gets updated. Manager performs internal management on this event, e.g. triggering upload
* of delayed device token information.
*/
-(void) updatePrivData: (PEXUserPrivate *) privData;

/**
* Called by app delegate when application has obtained new device token for apple push notifications.
*/
-(void) onDeviceTokenUpdated: (NSData *) deviceToken;

/**
* Called by app delegate when application fail to register to apple push notification server.
* Signalizes that APN should be considered as not working and to disable related features.
*/
-(void) onDeviceTokenFail: (NSError *) error;

/**
 * Called when remote push notification was received by app delegate.
 * Caller is main thread, usually.
 */
- (void)onRemotePushReceived: (NSDictionary *) pushDict;

/**
* Called by service when login process is completed. May trigger sending delayed device token update.
*/
- (void)onLoginCompleted;
@end