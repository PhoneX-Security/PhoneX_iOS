//
// Created by Dusan Klinec on 03.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPjMsgSendAux : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSNumber * msgType;
@property(nonatomic) NSNumber * msgSubType;

- (instancetype)initWithMsgType:(NSNumber *)msgType msgSubType:(NSNumber *)msgSubType;
+ (instancetype)auxWithMsgType:(NSNumber *)msgType msgSubType:(NSNumber *)msgSubType;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToAux:(PEXPjMsgSendAux *)aux;
- (NSUInteger)hash;
- (NSString *)description;
@end