//
// Created by Dusan Klinec on 25.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLengthDelimitedInputStream.h"


@interface PEXLengthDelimitedInputStream()

@property (nonatomic, strong) NSInputStream *body;

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;
@property (nonatomic) int32_t maxLen;

@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL scheduledOnRunLoop;
@end

@implementation PEXLengthDelimitedInputStream

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allDataWritten = NO;
        self.scheduledOnRunLoop = NO;
        self.maxLen = -1;
        self.status = NSStreamStatusNotOpen;
        [self setupCFRunlooping];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStream:(NSInputStream *)stream length: (int32_t) length;
{
    self               = [self init];
    self.body          = stream;
    self.delivered     = 0;
    self.length        = 0;
    self.maxLen        = length;
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInputStream read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    NSInteger sent = 0;
    NSInteger read = 0;

    // End of the stream.
    // Known length variant: self.delivered >= self.length
    if (self.allDataWritten || self.status == NSStreamStatusClosed)
    {
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    NSInteger maxLenToRead = len;
    if (_maxLen >= 0){
        maxLenToRead = MIN(_maxLen - _delivered, len);
    }

    // Write sub-stream section.
    // Previously here was also "self.delivered < (self.length - 2)" making sure that we are still
    // writing body stream data but for unknown length stream data we just don't know total length
    // so we write all the provided buffer with stream data until there are still some.
    while (sent < maxLenToRead)
    {
        read = [self.body read:buffer + sent maxLength:maxLenToRead - sent];
        if (read < 0){
            sent = read;
            break;
        }

        sent           += read;
        self.delivered += read;
        self.length    += read;

        // Check termination
        if (read == 0
                || [self.body streamStatus] == NSStreamStatusAtEnd
                || [self.body streamStatus] == NSStreamStatusClosed
                || [self.body streamStatus] == NSStreamStatusError
                || _maxLen <= _delivered)
        {

            // This was the final piece
            self.allDataWritten = YES;
            self.status = NSStreamStatusAtEnd;

            break;
        }
    }

    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable] && maxLenToRead >= 0){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    return sent;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream data availability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL) hasBytesAvailable {
    if (self.allDataWritten) return YES; // force read to discover we are finished.
    return [self.body hasBytesAvailable];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)open
{
    self.status = NSStreamStatusOpen;

    // Set this object as stream delegate so we receive events and re-broadcast them as own.
    [self.body setDelegate:self];
    [self.body open];
}
- (void)close
{
    // Close substream.
    [self.body close];

    self.status = NSStreamStatusClosed;
}
- (NSStreamStatus)streamStatus
{
    if (self.status != NSStreamStatusClosed && self.allDataWritten)
    {
        self.status = NSStreamStatusAtEnd;
    }
    return self.status;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Undocumented CFReadStream bridged methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) scheduleSubInCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Schedule sub-stream.
    if (self.body != nil) {
        CFReadStreamScheduleWithRunLoop((__bridge CFReadStreamRef) self.body, runLoop, mode);
    }

    self.scheduledOnRunLoop = YES;
}

- (void) unscheduleSubFromCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Unchedule sub-stream.
    if (self.body != nil) {
        CFReadStreamUnscheduleFromRunLoop((__bridge CFReadStreamRef) self.body, runLoop, mode);
    }

    self.scheduledOnRunLoop = NO;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (aStream == self){
        [self notifyDelegateAndCallback:self handleEvent:eventCode];
        return;
    }

    if (aStream != self.body){
        DDLogError(@"Reporting state for unknown stream");  // This handler is intended only for substream.
        return;
    }

    // Notify listeners.
    [self notifyDelegateAndCallback:self handleEvent:eventCode];
}
@end