//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushAckMsg;


@interface PEXPushAckEvent : NSObject <NSCoding, NSCopying>
@property (nonatomic) PEXPushAckMsg * ackMsg;
@property (nonatomic) NSDate * timestamp;
@property (nonatomic) NSString * packetId;
@property (nonatomic) BOOL sending;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToEvent:(PEXPushAckEvent *)event;
- (NSUInteger)hash;
- (NSString *)description;
@end