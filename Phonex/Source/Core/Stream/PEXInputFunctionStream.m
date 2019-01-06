//
// Created by Dusan Klinec on 31.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import "PEXInputFunctionStream.h"
#import "PEXCanceller.h"
#import "PEXStreamFunction.h"
#import "PEXRingBuffer.h"


@interface PEXInputFunctionStream ()

@property(nonatomic) id<PEXStreamFunction> function;
@property(nonatomic) NSInputStream * subStream;
@property(nonatomic) NSUInteger buffSize;
@property(nonatomic) NSMutableData * readBuffer;    // data read from stream goes here for processing.
@property(nonatomic) PEXRingBuffer * resultBuffer;  // processed data goes here and waits for being read.

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;

@property (nonatomic) BOOL streamDone;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) BOOL scheduledOnRunLoop;

@end

@implementation PEXInputFunctionStream {

}

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream {
    return [self initWithCanceller:nil function:function subStream:subStream buffSize:2048];
}

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [self initWithCanceller:nil function:function subStream:subStream buffSize:buffSize];
}

- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream {
    return [self initWithCanceller:canceller function:function subStream:subStream buffSize:2048];
}

- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize {
    self = [super init];
    if (self) {
        self.canceller = canceller;
        self.function = function;
        self.subStream = subStream;
        self.buffSize = buffSize;
        self.streamDone = NO;
        self.isFinished = NO;
        self.closeSubStream = YES;
        self.multipleSubReadsAllowed = YES;
        self.readBuffer = [NSMutableData dataWithLength:_buffSize];
        self.resultBuffer = [PEXRingBuffer bufferWithBuffSize: [function getNeededOutputBufferSize:_buffSize]];
        [self setupCFRunlooping];
    }

    return self;
}

+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream {
    return [[self alloc] initWithFunction:function subStream:subStream];
}

+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithFunction:function subStream:subStream buffSize:buffSize];
}

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithCanceller:canceller function:function subStream:subStream buffSize:buffSize];
}

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream {
    return [[self alloc] initWithCanceller:canceller function:function subStream:subStream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInputStream read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    NSInteger read = 0;
    uint8_t * bytesRead = [_readBuffer mutableBytes];

    // End of the stream - do nothing.
    if (_isFinished || self.status == NSStreamStatusClosed) {
        [self notifyProgress:0];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Part I  - read result buffer first.
    read = [_resultBuffer read:buffer maxLength:len];
    _delivered += read;

    // Cancellation test.
    if (self.canceller != nil && [self.canceller isCancelled]){
        _isFinished = YES;
        self.isCancelled = YES;
        self.status = NSStreamStatusAtEnd;
        [self enqueueEvent:NSStreamEventEndEncountered];
        return -2;
    }

    // Part II - read input stream, check for the end.
    // This part may be blocking due to substream reading.
    for (; read < len && !_streamDone; ){
        NSInteger curRead = 0;

        // At this point, all data from result buffer are gone.
        NSAssert([_resultBuffer isEmpty], @"Result buffer must be empty at this point");
        uint8_t * outBuff = [_resultBuffer resetBufferIfEmpty];
        int outBuffLen = 0;
        int success    = 0;

        // Read data from substream and process it.
        curRead = [_subStream read:bytesRead maxLength:_buffSize];

        // Check for error.
        if (curRead < 0){
            // Stream reading error.
            self.status = NSStreamStatusError;
            [self enqueueEvent:NSStreamEventErrorOccurred];
            return -1;
        }

        // Encrypt data if there is non-empty read buffer.
        if (curRead > 0){
            // Call function on data, write to result buffer.
            success = [_function update:bytesRead len:(NSUInteger) curRead output:outBuff outputLen:&outBuffLen];
            if (success != 1) {
                DDLogError(@"Function did not return success value: %d", success);
                return -1;
            }

            // Move fill pointer in the ring buffer and read next data to the user's read buffer.
            [_resultBuffer setBytesWritten:(NSUInteger) outBuffLen];

            // If the buffer is closing
        } else if (curRead == 0
                || [_subStream streamStatus] == NSStreamStatusAtEnd
                || [_subStream streamStatus] == NSStreamStatusClosed
                || [_subStream streamStatus] == NSStreamStatusError)
        {
            // Stream finished - finalize function.
            _streamDone = YES;
            success = [_function finalize:outBuff outLen:&outBuffLen];
            if (success != 1 || curRead < 0 || [_subStream streamStatus] == NSStreamStatusError){
                DDLogError(@"Function finalization did not return success value: %d", success);
                self.status = NSStreamStatusError;
                [self enqueueEvent:NSStreamEventErrorOccurred];
                return -1;
            }

            // Move fill pointer in the ring buffer and read next data to the user's read buffer.
            [_resultBuffer setBytesWritten:(NSUInteger) outBuffLen];

        }

        // Write processed data to the user's read buffer.
        curRead = [_resultBuffer read:buffer + read maxLength:(len - read)];
        read += curRead;
        _delivered += curRead;

        if (!self.multipleSubReadsAllowed || ![_resultBuffer isEmpty]){
            break;
        }

        if (self.canceller != nil && [self.canceller isCancelled]){
            self.isCancelled = YES;
            _isFinished = YES;
            self.status = NSStreamStatusAtEnd;
            [self enqueueEvent:NSStreamEventEndEncountered];
            return -2;
        }
    }

    // Bytes available signalization.
    if (![_resultBuffer isEmpty] || (!_streamDone && [_subStream hasBytesAvailable])){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    // If stream reading is over.
    if ((_streamDone && [_resultBuffer isEmpty]) || (self.canceller != nil && [self.canceller isCancelled])){
        _isFinished = YES;
        self.status = NSStreamStatusAtEnd;
        [self enqueueEvent:NSStreamEventEndEncountered];
    }

    [self notifyProgress:read];
    return read;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream data availability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL) hasBytesAvailable {
    if (_isFinished) return YES;                // force read to discover we are finished.
    if (![_resultBuffer isEmpty]) return YES;   // If we have some data in buffer, return definitelly yes.
    return (!_streamDone && [_subStream hasBytesAvailable]);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)open
{
    self.status = NSStreamStatusOpen;

    [self.subStream setDelegate:self];
    [self.subStream open];
}
- (void)close
{
    if (self.closeSubStream) {
        [self.subStream close];
    }

    self.status = NSStreamStatusClosed;
}
- (NSStreamStatus)streamStatus
{
    if (self.status != NSStreamStatusClosed && self.isFinished)
    {
        self.status = NSStreamStatusAtEnd;
    }
    return self.status;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Runloop-ed stream reader & writer.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)scheduleSubInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {
    // Schedule sub-stream.
    if (self.subStream != nil) {
        CFReadStreamScheduleWithRunLoop((__bridge CFReadStreamRef) self.subStream, runLoop, mode);
    }

    self.scheduledOnRunLoop = YES;
}

- (void)unscheduleSubFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {
    // Unchedule sub-stream.
    if (self.subStream != nil) {
        CFReadStreamUnscheduleFromRunLoop((__bridge CFReadStreamRef) self.subStream, runLoop, mode);
    }

    self.scheduledOnRunLoop = NO;
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
    if (aStream == _subStream){
        // Check events from sub-stream and modify it so it matches view for the wrapping stream.

        switch(eventCode){
            // NSStreamEventOpenCompleted -> Re-transmit.
            case NSStreamEventOpenCompleted:
                break;
            // NSStreamEventEndEncountered -> Ignore, we retransmit his for the last one..
            case NSStreamEventEndEncountered:
                eventCode = NSStreamEventHasBytesAvailable;
                break;
            // NSStreamEventErrorOccurred -> propagate further.
            case NSStreamEventErrorOccurred:
                break;
            // NSStreamEventHasBytesAvailable -> new data, retransmit.
            case NSStreamEventHasBytesAvailable:
                break;
            // NSStreamEventHasSpaceAvailable -> nonsense.
            case NSStreamEventHasSpaceAvailable:
                return;
            default:
                break;
        }

        [self notifyDelegateAndCallback:self handleEvent:eventCode];
    } else {

        [self notifyDelegateAndCallback:self handleEvent:eventCode];
    }
}

@end