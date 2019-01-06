//
// Created by Dusan Klinec on 19.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPushClistSyncEvent : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSString * user;
@property(nonatomic) NSNumber * tstamp;

- (instancetype)initWithUser:(NSString *)user tstamp:(NSNumber *)tstamp;
+ (instancetype)eventWithUser:(NSString *)user tstamp:(NSNumber *)tstamp;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

@end