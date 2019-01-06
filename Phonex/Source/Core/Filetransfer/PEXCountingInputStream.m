//
// Created by Dusan Klinec on 21.04.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCountingInputStream.h"

@interface PEXCountingInputStream () {}
@property (nonatomic) NSUInteger bytesRead;
@property (nonatomic, strong) NSInputStream *body;

@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL scheduledOnRunLoop;

@end

@implementation PEXCountingInputStream {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allDataWritten = NO;
        self.scheduledOnRunLoop = NO;
        self.bytesRead = 0;
        self.status = NSStreamStatusNotOpen;
        [self setupCFRunlooping];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStream:(NSInputStream *)stream;
{
    self               = [self init];
    self.body          = stream;
    self.bytesRead     = 0;
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInputStream read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    NSInteger read = 0;

    // End of the stream.
    // Known length variant: self.delivered >= self.length
    if (self.allDataWritten || self.status == NSStreamStatusClosed)
    {
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Write sub-stream section.
    read = [self.body read:buffer maxLength:len];
    if (read < 0){
        self.allDataWritten = YES;
        self.status = NSStreamStatusAtEnd;
        return read;
    }

    self.bytesRead += read;

    // Check termination
    if (read == 0
            || [self.body streamStatus] == NSStreamStatusAtEnd
            || [self.body streamStatus] == NSStreamStatusClosed
            || [self.body streamStatus] == NSStreamStatusError)
    {

        // This was the final piece
        self.allDataWritten = YES;
        self.status = NSStreamStatusAtEnd;
    }


    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable]){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    return read;
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