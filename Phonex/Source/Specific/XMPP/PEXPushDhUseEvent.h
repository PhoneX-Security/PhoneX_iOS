//
// Created by Dusan Klinec on 29.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPushDhUseEvent : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSString * user;
@property(nonatomic) NSNumber * tstamp;

- (instancetype)initWithUser:(NSString *)user tstamp:(NSNumber *)tstamp;
+ (instancetype)eventWithUser:(NSString *)user tstamp:(NSNumber *)tstamp;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end