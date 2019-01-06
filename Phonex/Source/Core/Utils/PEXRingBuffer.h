//
// Created by Dusan Klinec on 01.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXRingBuffer : NSObject
@property(nonatomic, readonly) NSUInteger buffSize;

- (instancetype)initWithBuffSize:(NSUInteger)buffSize;
+ (instancetype)bufferWithBuffSize:(NSUInteger)buffSize;

- (BOOL) isEmpty;
- (BOOL) isFull;
- (NSUInteger) getBytesAvailable;
- (NSUInteger) getSpaceAvailable;

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len;
- (NSInteger)write:(uint8_t const *)buffer maxLength:(NSUInteger)bufferLen;

/**
* If ring buffer is empty, resets writing target to the beginning of the buffer
* and returns internal buffer array.
*
* If buffer is not empty, NULL is returned.
*/
- (uint8_t *) resetBufferIfEmpty;

/**
* Return current native reading buffer part, with number of bytes available in this reading section.
* This is reading ring buffer, thus for complete read there may be 2 calls needed.
*/
- (uint8_t *) getReadingBuffer: (NSUInteger *) bytesAvailable;

/**
* Return length of the contiguous buffer for writing.
* Since we are using ring buffer it may wrap around.
*/
- (NSInteger) getContiguousWriteBufferLen;

/**
* Return length of the contiguous buffer for reading.
* Since we are using ring buffer it may wrap around.
*/
- (NSInteger) getContiguousReadBufferLen;

/**
* Returns contiguous buffer for writing even if ring buffer is not empty.
*/
- (uint8_t *) getContiguousWriteBuffer;

/**
* Returns contiguous buffer for reading even if ring buffer is not empty.
*/
- (uint8_t *)getContiguousReadBuffer;

/**
* Designed to be used in conjunction with resetBufferIfEmpty.
* This should be called when some data is written natively to the buffer using resetBufferIfEmpty
* and direct pointer to the memory.
*/
- (BOOL) setBytesWritten: (NSUInteger) bytesWritten;

/**
* Designed to be used in conjunction with getReadingBuffer.
* This should be called whe some data is read from native pointer using getReadingBuffer
* to advance internal pointers.
*/
- (BOOL) setBytesRead: (NSUInteger) bytesRead;

@end