//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPbMessage.pb.h"

@class PEXPbAMPSimple;


@interface PEXAmpSimple : NSObject
@property(nonatomic, readonly) NSNumber * nonce; //Integer
@property(nonatomic, readonly) NSString * message;

- (instancetype)initWithNonce:(NSNumber *)nonce message:(NSString *)message;
+ (instancetype)simpleWithNonce:(NSNumber *)nonce message:(NSString *)message;

+(NSData *) buildSerializedMessage: (NSString *) message nonce: (int) nonce;
+(PEXPbAMPSimple *) buildMessage: (NSString *) message nonce: (int) nonce;
+(PEXAmpSimple *) loadMessage: (NSData *) serializedAmpSimple;

@end