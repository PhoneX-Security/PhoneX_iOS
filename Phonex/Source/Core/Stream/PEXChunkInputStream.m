//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import <pthread.h>
#import "PEXChunkInputStream.h"
#import "idn-int.h"
#import "PEXDoubleCondition.h"

#define CONDITION_HAS_DATA 0
#define CONDITION_EMPTY 1

#pragma mark - PEXChunkInputStream()
@interface PEXChunkInputStream() {}
@property (nonatomic) NSMutableData * bodyBuffer;
@property (nonatomic) NSUInteger bodyBufferSize; // MAX
@property (nonatomic) NSInteger fill;
@property (nonatomic) NSInteger use;
@property (nonatomic) NSInteger count;
@property (nonatomic) PEXDoubleCondition * cond;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) BOOL hasDataSignalized;

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;

@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL scheduledOnRunLoop;

@property (nonatomic) NSStreamStatus status;
@property (nonatomic) NSError * error;
@property (nonatomic) NSMutableDictionary * properties;

@end

@implementation PEXChunkInputStream {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fill       = 0;
        self.use        = 0;
        self.count      = 0;
        self.isFinished = NO;
        self.hasDataSignalized = NO;
        self.cond       = [[PEXDoubleCondition alloc] init];
        self.bodyBufferSize = 8192;
        self.bodyBuffer = [NSMutableData dataWithLength:self.bodyBufferSize];
        self.status     = NSStreamStatusNotOpen;
        [self setDelegate:self];
        [self setupCFRunlooping];
    }

    return self;
}

- (instancetype)initWithBodyBufferSize:(NSUInteger)bodyBufferSize {
    self = [self init];
    if (self) {
        self.bodyBufferSize = bodyBufferSize;
        self.bodyBuffer = [NSMutableData dataWithLength:self.bodyBufferSize];
    }

    return self;
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInputStream read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: read http://stackoverflow.com/questions/13740132/streaming-nsxmlparser-with-nsinputstream

-(void) closeSource {
    self.allDataWritten = YES;
    self.status = NSStreamStatusAtEnd;
    [self enqueueEvent:NSStreamEventEndEncountered];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    [_cond lock];
    NSInteger sent = 0;
    NSInteger read = 0;
    uint8_t * bytes = [self.bodyBuffer mutableBytes];

    // End of the stream.
    // Known length variant: self.delivered >= self.length
    if (self.allDataWritten || self.status == NSStreamStatusClosed) {
        [self notifyProgress:sent];
        [_cond unlock];
        return 0;
    }

    if (_isFinished && _count == 0){
        [self closeSource];
        [_cond unlock];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Wait for some data to read.
    while(_count == 0){
        //[_cond wait:CONDITION_HAS_DATA];
        // Maximum wait time in condition wait is x seconds so we dont deadlock (soft deadlock).
        [_cond wait:CONDITION_HAS_DATA untilDate:[NSDate dateWithTimeIntervalSinceNow: 3.000]];

        // Finished write process
        if (_isFinished && _count == 0){
            [self closeSource];
            [_cond signal:CONDITION_EMPTY];
            [_cond unlock];
            return 0;
        }
    }

    if (_count == 0){
        DDLogError(@"Illegal state, signalled and we have nothing to read");
    }

    // Reset has data signalized information since reading reset this state.
    _hasDataSignalized = NO;

    // Number of bytes that can be read in this call.
    NSInteger bytesToRead = MIN(_count, len);

    // Number of bytes that can be copied right after _fill position without need to modulo.
    const NSInteger bytesToReadRight = MIN(bytesToRead, _bodyBufferSize - _use);

    // Phase 1 - memcpy up to the right boundary.
    if (bytesToReadRight > 0){
        memcpy(buffer, bytes + _use, bytesToReadRight);

        read        += bytesToReadRight;
        _use         = (_use + bytesToReadRight) % _bodyBufferSize;  // Should be 0.
        bytesToRead -= bytesToReadRight;
    }

    // Phase 2 - write rest of bytes after modular rotation.
    if (bytesToRead > 0){
        memcpy(buffer + read, bytes + _use, bytesToRead);

        read  += bytesToRead;
        _use   = (_use + bytesToRead) % _bodyBufferSize; // Should never need to modulo.
    }

    _count -= read;
    _delivered += read;
    NSAssert(_count != 0 || _use == _fill, @"Cyclic buffer invariant failed");

    // If not all data was written, broadcast we have bytes available, if we have.
    if (_count > 0){
        _hasDataSignalized = YES;
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    // Check if we reached stream end.
    if (_isFinished && _count == 0){
        [self closeSource];
        [_cond signal:CONDITION_EMPTY];
        [_cond unlock];
        return 0;
    } else if (_count < _bodyBufferSize){
        // Signalize to producers we have some space left.
        [_cond signal:CONDITION_EMPTY];
    }

    [_cond unlock];
    [self notifyProgress:read];
    return read;
}

- (NSInteger)writeChunk:(uint8_t const *)buffer maxLength:(NSUInteger)bufferLen writeAll:(BOOL)writeAll {
    [_cond lock];
    NSInteger writtenTotal = 0;
    NSInteger written = 0;
    NSInteger curBufferLen = bufferLen;
    uint8_t * bytes = [self.bodyBuffer mutableBytes];

    // Write code block. We we demand full write this has to repeat several times.
    do {
        // Wait if:
        //  a) writing is still not finished.
        //  b) buffer is full
        while (!_isFinished && (_count == _bodyBufferSize)) {
            // Maximum wait time in condition wait is x seconds so we dont deadlock (soft deadlock).
            //[_cond wait:CONDITION_EMPTY];
            [_cond wait:CONDITION_EMPTY untilDate:[NSDate dateWithTimeIntervalSinceNow:3.000]];
        }

        // If has finished, no data can be written anymore.
        if (_isFinished || _allDataWritten) {
            writtenTotal = -1;
            goto writtenBlock;
        }

        // Free space in ring buffer.
        const NSInteger freeSpace = _bodyBufferSize - _count;

        // Number of bytes that will be written in this call.
        NSInteger bytesToWrite = MIN(freeSpace, curBufferLen);

        // Number of bytes that can be copied right after _fill position without need to modulo.
        const NSInteger bytesToWriteRight = MIN(bytesToWrite, _bodyBufferSize - _fill);
        written = 0;

        // Phase 1 - memcpy to the right boundary.
        if (bytesToWriteRight > 0) {
            memcpy(bytes + _fill, buffer + writtenTotal, bytesToWriteRight);

            written      += bytesToWriteRight;
            writtenTotal += bytesToWriteRight;
            bytesToWrite -= bytesToWriteRight;
            _fill = (_fill + bytesToWriteRight) % _bodyBufferSize;  // Should be 0, if we reached the right boundary.
        }

        // Phase 2 - write rest of bytes after modular rotation.
        if (bytesToWrite > 0) {
            memcpy(bytes + _fill, buffer + writtenTotal, bytesToWrite);

            written      += bytesToWrite;
            writtenTotal += bytesToWrite;
            _fill = (_fill + bytesToWrite) % _bodyBufferSize; // Should never need to modulo.
        }

        _count += written;
        _length += written;
        curBufferLen -= written;
        NSAssert(_count != _bodyBufferSize || _use == _fill, @"Cyclic buffer invariant failed");

        // If not all data was written, broadcast we have bytes available, if we have.
        if (_count > 0 && !_hasDataSignalized) {
            _hasDataSignalized = YES;
            [self enqueueEvent:NSStreamEventHasBytesAvailable];
        }

        [_cond signal:CONDITION_HAS_DATA];
    } while(writeAll && curBufferLen > 0);

    [_cond unlock];
    return writtenTotal;

writtenBlock:
    [_cond signal:CONDITION_HAS_DATA];
    [_cond unlock];
    return writtenTotal;
}

- (NSInteger)writeDataChunk:(NSData const *)buffer {
    return [self writeChunk:[buffer bytes] maxLength:[buffer length] writeAll:YES];
}

- (void)finishWrite {
    [_cond lock];
     _isFinished = YES;
    [_cond broadcast:CONDITION_HAS_DATA];
    [_cond broadcast:CONDITION_EMPTY];

    // Signalize byte availability if we have some bytes
    if (_count > 0){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    } else {
        // Should send end encoutered, but anyway force reader to read 0.
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    [_cond unlock];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream data availability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL) hasBytesAvailable {
    BOOL res = NO;
    [_cond lock];
    if (self.allDataWritten || self.isFinished) {
        res = YES; // force read to discover we are finished.
    } else {
        res = _count > 0;
    }
    [_cond unlock];
    return res;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)open
{
    [_cond lock];
    self.status = NSStreamStatusOpen;
    [_cond unlock];

    [self enqueueEvent:NSStreamEventOpenCompleted];
}
- (void)close
{
    [_cond lock];
    self.status = NSStreamStatusClosed;
    [_cond unlock];
}
- (NSStreamStatus)streamStatus
{
    [_cond lock];
    if (self.status != NSStreamStatusClosed && self.allDataWritten)
    {
        self.status = NSStreamStatusAtEnd;
    }
    [_cond unlock];

    return self.status;
}

- (void)notifyProgress:(NSInteger)sent{
//    if (self.progressBlock == nil){
//        return;
//    }
//
//    __weak __typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (weakSelf == nil || weakSelf.progressBlock == nil){
//            return;
//        }
//
//        weakSelf.progressBlock(weakSelf, sent);
//    });
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    [self notifyDelegateAndCallback:self handleEvent:eventCode];
}

@end
