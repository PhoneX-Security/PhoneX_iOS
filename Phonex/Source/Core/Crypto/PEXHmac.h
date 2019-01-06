//
// Created by Dusan Klinec on 21.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;

/**
* HMAC SHA-256
*/
@interface PEXHmac : NSObject
- (instancetype)initWithKey:(NSData *)key;
+ (instancetype)initWithKey:(NSData *)key;

+ (NSData *)hmac:(NSData *)payload key:(NSData *)key;
- (int) setKey: (NSData *) key;

- (int) update: (unsigned char const *) data len: (size_t) len;
- (int) update: (NSData *) chunk;

- (NSData *) final;
- (void)destroy;

/**
* Computes file digest from the file name using streaming read.
*/
+ (NSData *)getFileHMACFile:(NSString *)filePath key:(NSData *)key canceller:(id <PEXCanceller>)canceller;
+ (NSData *)getFileHMAC:(NSInputStream *)is      key:(NSData *)key canceller:(id <PEXCanceller>)canceller;
@end