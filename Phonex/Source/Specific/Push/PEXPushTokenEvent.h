//
// Created by Dusan Klinec on 09.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushTokenConfig;


@interface PEXPushTokenEvent : NSObject <NSCoding, NSCopying>
@property(nonatomic) PEXPushTokenConfig * token;
@property(nonatomic) NSDate * when;
@property(nonatomic) BOOL uploadFinished;

- (instancetype)initWithToken:(PEXPushTokenConfig *)token;
+ (instancetype)eventWithToken:(PEXPushTokenConfig *)token;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)copyWithZone:(NSZone *)zone;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToEvent:(PEXPushTokenEvent *)event;

- (NSUInteger)hash;

@end