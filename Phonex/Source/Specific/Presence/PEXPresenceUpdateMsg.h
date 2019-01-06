//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPresenceUpdateMsg : NSObject <NSCoding, NSCopying>
/**
* Which user profile this presence update message targets.
*/
@property(nonatomic) NSString * user;

/**
* Main presence indicator.
* Boolean.
*/
@property(nonatomic) NSNumber * isAvailable;

/**
* Current online status (e.g., online, away, busy, invisible).
*/
@property(nonatomic) NSNumber * statusId;

/**
* Current SIP registration status.
* Boolean.
*/
@property(nonatomic) NSNumber * sipRegistered;

/**
* Whether user is currently on call.
* Boolean.
*/
@property(nonatomic) NSNumber * isCallingRightNow;

/**
* Whether user is currently on call using cellular network.
* Boolean.
*/
@property(nonatomic) NSNumber * isCellularCallingRightNow;

/**
* Current user status message.
* If nil no update will be made.
*/
@property(nonatomic) NSString * statusMessage;

/**
* Flag indicating whether to send presence update with this message.
* If set to NO, presence update will not be broadcasted remotely.
* Used when indicating XMPP lost connection.
*/
@property(nonatomic) BOOL doUpdatePresence;

/**
* Update key for this presence update. Notifier may inform caller that this presence was set
* referencing update with this key.
*/
@property(nonatomic) NSString * updateKey;

/**
* Background status
* Boolean.
*/
@property(nonatomic) NSNumber * isInBackground;

- (instancetype)initWithUser:(NSString *)user;
+ (instancetype)msgWithUser:(NSString *)user;

- (NSString *)description;
- (id)copyWithZone:(NSZone *)zone;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end