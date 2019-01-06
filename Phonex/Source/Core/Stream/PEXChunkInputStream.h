//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"

/**
* Implements buffer-bound producer consumer pattern. Usable for turning dataDelivered callbacks e.g.,
* from NSURLConnection to the NSInputStream. Callbacks & run looping mode is supported
*/
@interface PEXChunkInputStream : PEXRunLoopInputStream<NSStreamDelegate>
/**
* Total length of the input stream.
* I.e., total number of bytes written to the stream buffer so far.
*/
@property (nonatomic, readonly) int64_t length;

/**
* Number of bytes already read from this stream.
* I.e., total number of bytes read from stream so far.
*/
@property (nonatomic, readonly) int64_t delivered;
@property (nonatomic, assign) BOOL shouldNotifyCoreFoundationAboutStatusChange;

-(instancetype) initWithBodyBufferSize:(NSUInteger)bodyBufferSize;
-(NSInteger) writeChunk: (uint8_t const *) buffer maxLength: (NSUInteger)bufferLen writeAll: (BOOL) writeAll;
-(NSInteger) writeDataChunk: (NSData const *) buffer;
-(void) finishWrite;

@end