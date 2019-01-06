//
// Created by Dusan Klinec on 02.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXOutputFunctionStream.h"
#import "PEXRingBuffer.h"
#import "PEXStreamFunction.h"
#import "PEXCanceller.h"
#import "idn-int.h"

@interface PEXOutputFunctionStream ()

@property(nonatomic) id<PEXStreamFunction> function;
@property(nonatomic) NSOutputStream * subStream;
@property(nonatomic) NSUInteger buffSize;
@property(nonatomic) NSMutableData * readBuffer;    // data read from stream goes here for processing.
@property(nonatomic) PEXRingBuffer * resultBuffer;  // processed data goes here and waits for being read.

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;

@property (nonatomic) BOOL streamDone;
@property (nonatomic) BOOL isFinished;
@property (nonatomic) BOOL scheduledOnRunLoop;

@end

@implementation PEXOutputFunctionStream {

}

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream {
    return [self initWithCanceller:nil function:function subStream:subStream buffSize:2048];
}

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [self initWithCanceller:nil function:function subStream:subStream buffSize:buffSize];
}

- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream {
    return [self initWithCanceller:canceller function:function subStream:subStream buffSize:2048];
}

- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize {
    self = [super init];
    if (self) {
        self.canceller = canceller;
        self.function = function;
        self.subStream = subStream;
        self.buffSize = buffSize;
        self.streamDone = NO;
        self.isFinished = NO;
        self.multipleSubWritesAllowed = YES;
        self.isCancelled = NO;
        self.closeSubStream = YES;
        self.readBuffer = [NSMutableData dataWithLength:_buffSize];
        self.resultBuffer = [PEXRingBuffer bufferWithBuffSize: [function getNeededOutputBufferSize:_buffSize]];
        [self setupCFRunlooping];
    }

    return self;
}

+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream {
    return [[self alloc] initWithFunction:function subStream:subStream];
}

+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithFunction:function subStream:subStream buffSize:buffSize];
}

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithCanceller:canceller function:function subStream:subStream buffSize:buffSize];
}

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream {
    return [[self alloc] initWithCanceller:canceller function:function subStream:subStream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSOutputStream write
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void) streamErrorHappened: (NSError *) err {
    self.status = NSStreamStatusError;
    [self enqueueEvent:NSStreamEventErrorOccurred];
}

-(void) checkStreamForSpace {
    if ([self.subStream hasSpaceAvailable]){
        [self enqueueEvent:NSStreamEventHasSpaceAvailable];
    }
}

/**
* Internal convenience function for dumping internal buffer to the output stream.
*/
-(NSInteger) dumpInternalBuffer: (BOOL) allowMultipleWrites {
    NSInteger written = 0;

    for(; ![_resultBuffer isEmpty]; ){
        NSInteger  curWritten = 0;
        NSUInteger readMaxLen = 0;
        uint8_t const * readBuff = [_resultBuffer getReadingBuffer:&readMaxLen];
        curWritten = [_subStream write:readBuff maxLength:readMaxLen];

        // Stream error write.
        if (curWritten < 0){
            [self streamErrorHappened:nil];
            return -1;
        } else if (curWritten == 0 && readMaxLen != 0){
            // Full capacity reached, a bit problem...
            break;
        }

        written += curWritten;
        [_resultBuffer setBytesRead:(NSUInteger)curWritten];

        // Stream may be finished.
        if ([self.subStream streamStatus] == NSStreamStatusAtEnd
                || [self.subStream streamStatus] == NSStreamStatusClosed
                || [self.subStream streamStatus] == NSStreamStatusError)
        {
            break;
        }

        // If multiple writes are not allowed, do only one.
        if (!allowMultipleWrites){
            break;
        }

        // Cancellation ?
        if (self.canceller != nil && [self.canceller isCancelled]){
            self.isCancelled = YES;
            break;
        }
    }

    [self notifyProgress:written];
    return written;
}

/**
* Internal convenience function to finalize data write. Full blocking.
*/
-(NSInteger) closeData {
    if (_streamDone){
        return 0;
    }

    // Phase I - try to dump our internal buffer, if there is some data.
    // In order to read cyclic buffer we need 2 passes in some cases.
    NSInteger written = [self dumpInternalBuffer: YES];
    if (self.isCancelled || written < 0){
        [self streamErrorHappened:nil];
        return -1;
    }

    // It is assumed our internal buffer is emptied now.
    // If not, we have to return 0 what can potentially mean writing to the size limited stream has ended.
    // Empty buffer is needed so we can get native pointer to the buffer array so it can be used by
    // function to write processed data to it.
    if (![_resultBuffer isEmpty]){
        [self streamErrorHappened:nil];
        return -1;
    }

    // Phase II - Fill final block to the buffer.
    written = 0;
    int success = [_function finalize:[_resultBuffer resetBufferIfEmpty] outLen:&written];
    if (success != 1){
        DDLogError(@"Function update did not return success value: %d", success);
        [self streamErrorHappened:nil];
        return -1;
    }

    // Advance internal buffer structures.
    [_resultBuffer setBytesWritten:(NSUInteger) written];

    // Phase III - Try to dump buffer again to the stream.
    written = [self dumpInternalBuffer: YES];
    if (self.isCancelled || written < 0){
        [self streamErrorHappened:nil];
        return -1;
    }

    // End reached.
    [self enqueueEvent:NSStreamEventEndEncountered];

    _streamDone = YES;
    return 0;
}

- (NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len {
    NSInteger written = 0;
    if (_isFinished || _streamDone){
        return 0;
    }

    // End of the stream.
    // Known length variant: self.delivered >= self.length
    if (_isFinished || self.status == NSStreamStatusClosed) {
        [self notifyProgress:0];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusWriting;

    // Phase I - try to dump our internal buffer, if there is some data.
    // In order to read cyclic buffer we need 2 passes in some cases.
    written = [self dumpInternalBuffer: self.multipleSubWritesAllowed];
    if (self.isCancelled || written < 0){
        [self streamErrorHappened:nil];
        return -1;
    }

    if (len == 0){
        [self checkStreamForSpace];
        return 0;
    }

    // It is assumed our internal buffer is emptied now.
    // If not, we have to return 0 what can potentially mean writing to the size limited stream has ended.
    // Empty buffer is needed so we can get native pointer to the buffer array so it can be used by
    // function to write processed data to it.
    if (![_resultBuffer isEmpty]){
        [self checkStreamForSpace];
        return 0;
    }

    // Phase II - Process by the function and store to the result buffer.
    written = 0;

    // Restrict write to the amount we can actually process due to output buffer size limitation.
    NSUInteger bytesToProcess = MIN(len, _buffSize);
    int success = [_function update:buffer len:bytesToProcess output:[_resultBuffer resetBufferIfEmpty] outputLen:&written];
    if (success != 1){
        DDLogError(@"Function update did not return success value: %d", success);
        [self streamErrorHappened:nil];
        return -1;
    }

    // Advance internal buffer structures.
    [_resultBuffer setBytesWritten:(NSUInteger) written];

    // Phase III - Try to dump buffer again to the stream.
    written = [self dumpInternalBuffer: self.multipleSubWritesAllowed];
    if (self.isCancelled || written < 0){
        [self streamErrorHappened:nil];
        return -1;
    }

    [self checkStreamForSpace];
    return bytesToProcess;
}

- (NSInteger) flush{
    // Phase I - try to dump our internal buffer, if there is some data.
    // In order to read cyclic buffer we need 2 passes in some cases.
    NSInteger written = [self dumpInternalBuffer: YES];
    if (self.isCancelled || written < 0){
        [self streamErrorHappened:nil];
        return -1;
    }

    return written;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream data availability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)hasSpaceAvailable {
    if (_isFinished || _streamDone) return NO;
    return [self.subStream hasSpaceAvailable];
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
    // If stream was not finalized, do it now and then close stream.
    [self closeData];
    if (self.closeSubStream) {
        [self.subStream close];
    }

    self.isFinished = YES;
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
                break;
                // NSStreamEventErrorOccurred -> propagate further.
            case NSStreamEventErrorOccurred:
                break;
                // NSStreamEventHasBytesAvailable -> new data, retransmit.
            case NSStreamEventHasBytesAvailable:
                break;
                // NSStreamEventHasSpaceAvailable -> re-transmit.
            case NSStreamEventHasSpaceAvailable:
                break;
            default:
                break;
        }

        [self notifyDelegateAndCallback:self handleEvent:eventCode];
    } else {

        [self notifyDelegateAndCallback:self handleEvent:eventCode];
    }
}

@end
