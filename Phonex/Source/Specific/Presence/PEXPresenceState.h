//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPresenceUpdateMsg;

/**
* Current presence state for one logged user.
*/
@interface PEXPresenceState : NSObject <NSCoding, NSCopying>
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
* Message that caused last presence update.
*/
@property(nonatomic) PEXPresenceUpdateMsg * lastUpdate;

/**
* Datetime of the last update of the presence state.
*/
@property(nonatomic) NSDate * lastUpdateTime;

/**
* Datetime of the last presence broadcast to the server.
* Attempt is counted here, not real delivery (nor ACK from server).
*/
@property(nonatomic) NSDate * lastUpdateSendTime;

/**
* Background status
* Boolean.
*/
@property(nonatomic) NSNumber * isInBackground;

- (instancetype)initWithUser:(NSString *)user;
+ (instancetype)stateWithUser:(NSString *)user;

- (NSString *)description;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;

/**
* Last update field is excluded from comaprison.
*/
- (BOOL)isEqualToState:(PEXPresenceState *)state;
- (NSUInteger)hash;
@end