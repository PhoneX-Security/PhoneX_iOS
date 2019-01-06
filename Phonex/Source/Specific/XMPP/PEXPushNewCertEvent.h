//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* Simple holder class for newCert push notification.
* Push notification informs there may be a new certificate registered for this account making current certificate invalid,
* or, in general case, signalizing a new device connected with same login name.
*
* Class holds push notification details, such as related user name, time stamp of the push message, not before time of
* the new certificate which triggered this event and its certificate hash prefix.
*/
@interface PEXPushNewCertEvent : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSString * user;
@property(nonatomic) NSNumber * tstamp;
@property(nonatomic) int64_t notBefore;
@property(nonatomic) NSString * certHashPrefix;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

- (instancetype)initWithUser:(NSString *)user tstamp:(NSNumber *)tstamp notBefore:(int64_t)notBefore certHashPrefix:(NSString *)certHashPrefix;

+ (instancetype)eventWithUser:(NSString *)user tstamp:(NSNumber *)tstamp notBefore:(int64_t)notBefore certHashPrefix:(NSString *)certHashPrefix;

@end