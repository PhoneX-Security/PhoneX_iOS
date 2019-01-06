//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPushTokenConfig : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSData * token;
@property(nonatomic) NSDate * whenCreated;

- (instancetype)initWithToken:(NSData *)token;
+ (instancetype)configWithToken:(NSData *)token;

- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToConfig:(PEXPushTokenConfig *)config;
- (NSUInteger)hash;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)copyWithZone:(NSZone *)zone;

@end