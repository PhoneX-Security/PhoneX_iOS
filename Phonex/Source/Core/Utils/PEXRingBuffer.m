//
// Created by Dusan Klinec on 01.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXRingBuffer.h"
#import "idn-int.h"

@interface PEXRingBuffer () {}
@property (nonatomic) NSUInteger buffSize;
@property (nonatomic) NSMutableData * buffer;
@property (nonatomic) NSUInteger fill;
@property (nonatomic) NSUInteger use;
@property (nonatomic) NSUInteger count;
@end

@implementation PEXRingBuffer {

}

- (instancetype)initWithBuffSize:(NSUInteger)buffSize {
    self = [super init];
    if (self) {
        _buffSize = buffSize;
        _buffer = [NSMutableData dataWithLength:buffSize];
        _fill  = 0;
        _use   = 0;
        _count = 0;
    }

    return self;
}

- (instancetype)init {
    return [self initWithBuffSize:2048];
}

+ (instancetype)bufferWithBuffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithBuffSize:buffSize];
}

- (BOOL) isEmpty {
    return _count == 0;
}

- (BOOL) isFull {
    return _count == _buffSize;
}

- (NSUInteger) getBytesAvailable {
    return _count;
}

- (NSUInteger) getSpaceAvailable {
    return _buffSize - _count;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (_count == 0){
        return 0;
    }

    NSInteger read = 0;
    uint8_t * bytes = [_buffer mutableBytes];

    // Number of bytes that can be read in this call.
    NSInteger bytesToRead = MIN(_count, len);

    // Number of bytes that can be copied right after _fill position without need to modulo.
    const NSInteger bytesToReadRight = MIN(bytesToRead, _buffSize - _use);

    // Phase 1 - memcpy up to the right boundary.
    if (bytesToReadRight > 0){
        memcpy(buffer, bytes + _use, bytesToReadRight);

        read        += bytesToReadRight;
        _use         = (_use + bytesToReadRight) % _buffSize;  // Should be 0.
        bytesToRead -= bytesToReadRight;
    }

    // Phase 2 - write rest of bytes after modular rotation.
    if (bytesToRead > 0){
        memcpy(buffer + read, bytes + _use, bytesToRead);

        read  += bytesToRead;
        _use   = (_use + bytesToRead) % _buffSize; // Should never need to modulo.
    }

    _count -= read;
    NSAssert(_count != 0 || _use == _fill, @"Cyclic buffer invariant failed");

    return read;
}

- (NSInteger)write:(uint8_t const *)buffer maxLength:(NSUInteger)bufferLen {
    if ([self isFull]){
        return 0;
    }

    NSInteger writtenTotal = 0;
    NSInteger written = 0;
    NSInteger curBufferLen = bufferLen;
    uint8_t * bytes = [_buffer mutableBytes];

    // Free space in ring buffer.
    const NSInteger freeSpace = _buffSize - _count;

    // Number of bytes that will be written in this call.
    NSInteger bytesToWrite = MIN(freeSpace, curBufferLen);

    // Number of bytes that can be copied right after _fill position without need to modulo.
    const NSInteger bytesToWriteRight = MIN(bytesToWrite, _buffSize - _fill);
    written = 0;

    // Phase 1 - memcpy to the right boundary.
    if (bytesToWriteRight > 0) {
        memcpy(bytes + _fill, buffer + writtenTotal, bytesToWriteRight);

        written      += bytesToWriteRight;
        writtenTotal += bytesToWriteRight;
        bytesToWrite -= bytesToWriteRight;
        _fill = (_fill + bytesToWriteRight) % _buffSize;  // Should be 0, if we reached the right boundary.
    }

    // Phase 2 - write rest of bytes after modular rotation.
    if (bytesToWrite > 0) {
        memcpy(bytes + _fill, buffer + writtenTotal, bytesToWrite);

        written      += bytesToWrite;
        writtenTotal += bytesToWrite;
        _fill = (_fill + bytesToWrite) % _buffSize; // Should never need to modulo.
    }

    _count += written;
    curBufferLen -= written;
    NSAssert(_count != _buffSize || _use == _fill, @"Cyclic buffer invariant failed");

    return writtenTotal;
}

- (uint8_t *)resetBufferIfEmpty {
    if (![self isEmpty]){
        return NULL;
    }

    _fill = 0;
    _use  = 0;
    return [_buffer mutableBytes];
}

- (BOOL) setBytesWritten: (NSUInteger) bytesWritten {
    if (_count + bytesWritten > _buffSize || ![self isEmpty]){
        return NO;
    }

    _fill   = (_fill + bytesWritten) % _buffSize; // Should never need to modulo.
    _count += bytesWritten;
    NSAssert(_count != _buffSize || _use == _fill, @"Cyclic buffer invariant failed");
    return YES;
}

- (uint8_t *)getReadingBuffer:(NSUInteger *)bytesAvailable {
    if ([self isEmpty]){
        return NULL;
    }

    if (bytesAvailable != NULL){
        *bytesAvailable = (NSUInteger)[self getContiguousReadBufferLen];
    }

    return [self getContiguousReadBuffer];
}

- (BOOL)setBytesRead:(NSUInteger)bytesRead {
    if (_count < bytesRead){
        return NO;
    }

    _use    = (_use + bytesRead) % _buffSize; // Should never need to modulo.
    _count -= bytesRead;
    NSAssert(_count != 0 || _use == _fill, @"Cyclic buffer invariant failed");
    return YES;
}

- (NSInteger)getContiguousWriteBufferLen {
    // Minimum from (space available in buffer, space to the right boundary).
    // First parameter for cases like   |    FeeeU    |, e=empty to use.
    // Second parameter for cases like  |    U   Feeee|, e=empty to use.
    return MIN(_buffSize - _count, _buffSize - _fill);
}

- (NSInteger)getContiguousReadBufferLen {
    // Minimum from (bytes available in buffer, bytes to the right boundary).
    // First parameter for cases like   |    UxxxF    |, e=bytes to use.
    // Second parameter for cases like  |    F   Uxxxx|, e=bytes to use.
    return MIN(_count, _buffSize - _use);
}

- (uint8_t *)getContiguousWriteBuffer {
    return [_buffer mutableBytes] + _fill;
}

- (uint8_t *)getContiguousReadBuffer {
    return [_buffer mutableBytes] + _use;
}

@end