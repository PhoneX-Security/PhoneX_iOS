//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"


@interface PEXMergedInputStream : PEXRunLoopInputStream<NSStreamDelegate>
/**
* Total length of the input stream.
*/
@property (nonatomic, readonly) int64_t length;

/**
* Current part being streamed.
*/
@property (nonatomic, readonly) NSUInteger currentPart;

/**
* Number of bytes already read from this stream.
* Should hold: delivered <= length.
*/
@property (nonatomic, readonly) int64_t delivered;

/**
* YES value signalizes stream was read completely and there is no data left.
*/
@property (nonatomic, readonly) BOOL allDataWritten;

/**
* Init with sub-streams.
*/
- (id)initWithStream:(NSInputStream *)s1;
- (id)initWithStream:(NSInputStream *)s1 : (NSInputStream *) s2;
- (id)initWithStream:(NSInputStream *)s1 : (NSInputStream *) s2 : (NSInputStream *) s3;
- (id)initWithStream:(NSInputStream *)s1 : (NSInputStream *) s2 : (NSInputStream *) s3 : (NSInputStream *) s4;
- (id)initWithStream:(NSInputStream *)s1 : (NSInputStream *) s2 : (NSInputStream *) s3 : (NSInputStream *) s4 : (NSInputStream *) s5;
-(void) cancelStreamByError: (NSError *) e;

@end