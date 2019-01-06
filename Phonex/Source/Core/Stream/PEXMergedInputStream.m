//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import "PEXMergedInputStream.h"

@interface PEXMergedInputStream ()

@property(nonatomic) NSArray * streams;
@property (nonatomic) NSUInteger currentPart;
@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;
@property (nonatomic) BOOL allDataWritten;

@property (nonatomic) NSError * error;
@end

@implementation PEXMergedInputStream {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.currentPart = 0;
        self.length = 0;
        self.delivered = 0;
        self.allDataWritten = NO;
        self.error = nil;
        self.status = NSStreamStatusNotOpen;
        [self setupCFRunlooping];
    }

    return self;
}

- (id)initWithStream:(NSInputStream *)s1 {
    return [self initWithStream:s1 :nil :nil :nil :nil];
}

- (id)initWithStream:(NSInputStream *)s1 :(NSInputStream *)s2 {
    return [self initWithStream:s1 :s2 :nil :nil :nil];
}

- (id)initWithStream:(NSInputStream *)s1 :(NSInputStream *)s2 :(NSInputStream *)s3 {
    return [self initWithStream:s1 :s2 :s3 :nil :nil];
}

- (id)initWithStream:(NSInputStream *)s1 :(NSInputStream *)s2 :(NSInputStream *)s3 :(NSInputStream *)s4 {
    return [self initWithStream:s1 :s2 :s3 :s4 :nil];
}

- (id)initWithStream:(NSInputStream *)s1 :(NSInputStream *)s2 :(NSInputStream *)s3 :(NSInputStream *)s4 :(NSInputStream *)s5 {
    self = [self init];
    if (self == nil) {
        return nil;
    }

    NSMutableArray * tmpStreams = [NSMutableArray arrayWithCapacity:5];
    if (s1 != nil) [tmpStreams addObject:s1];
    if (s2 != nil) [tmpStreams addObject:s2];
    if (s3 != nil) [tmpStreams addObject:s3];
    if (s4 != nil) [tmpStreams addObject:s4];
    if (s5 != nil) [tmpStreams addObject:s5];

    if ([tmpStreams count] == 0){
        DDLogError(@"Empty streams");
        return nil;
    }

    self.streams = [NSArray arrayWithArray:tmpStreams];
    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInputStream read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
    NSInteger sent = 0;
    NSInteger read = 0;

    // All data was written, nothing to do anymore.
    if (self.allDataWritten || self.status == NSStreamStatusClosed){
        return 0;
    }

    // Stream error?
    if (self.error != nil || self.status == NSStreamStatusError){
        self.status = NSStreamStatusError;
        return -1;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Write all body parts.
    // Condition "self.delivered < self.length" removed for unknown data parts.
    while (sent < len && self.currentPart < self.streams.count)
    {
        NSInputStream * curElem = self.streams[self.currentPart];
        read = [curElem read:(buffer + sent) maxLength:(len - sent)];
        if (read < 0){
            // Error
            [self enqueueEvent:NSStreamEventErrorOccurred];
            return read;
        }

        sent            += read;
        self.delivered  += read;
        self.length     += read;

        // Termination check.
        if (read == 0
                || [curElem streamStatus] == NSStreamStatusAtEnd
                || [curElem streamStatus] == NSStreamStatusClosed
                || [curElem streamStatus] == NSStreamStatusError)
        {
            ++self.currentPart;

            // First stream is automatically opened, another has to be opened here.
            if (self.currentPart < self.streams.count){
                curElem = self.streams[self.currentPart];
                [curElem setDelegate:self];
                [curElem open];
            } else if (self.currentPart == self.streams.count){
                // Last element written.
                self.allDataWritten = YES;
                self.status = NSStreamStatusAtEnd;
                [self enqueueEvent:NSStreamEventEndEncountered];
                break;
            }

            continue;
        }
    }

    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable]){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    return sent;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)hasBytesAvailable
{
    // Take current reading stream into consideration, has to ask on stream data.
    if (self.allDataWritten){
        return YES; // force read to discover we are finished.
    }

    if (self.currentPart < self.streams.count){
        NSInputStream * curElem = self.streams[self.currentPart];
        return [curElem hasBytesAvailable];
    }

    // All parts written and still not everything -> force to read 0 to discover we are over.
    return YES;
}
- (void)open
{
    self.status = NSStreamStatusOpen;

    // Add proper delegate to all subparts.
    for(NSUInteger i=0; i < self.streams.count; ++i)
    {
        NSInputStream * curElem = self.streams[i];
        [curElem setDelegate:self];
    }

    // Open the first one.
    if (self.streams.count >= 1){
        NSInputStream * curElem = self.streams[0];
        [curElem open];
    }
}
- (void)close
{
    // Close all sub-parts.
    for(NSUInteger i=0; i < self.streams.count; ++i)
    {
        NSInputStream * curElem = self.streams[i];
        [curElem close];
    }

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

-(void) cancelStreamByError: (NSError *) e{
    self.error = e;
    [self enqueueEvent:NSStreamEventErrorOccurred];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Undocumented CFReadStream bridged methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) scheduleSubInCFRunLoop:(CFRunLoopRef) runLoop
                     forMode:(CFStringRef) mode
{
    // Schedule all streams added in parts.
    for(NSUInteger i=0; i < self.streams.count; ++i)
    {
        NSInputStream * curElem = self.streams[i];
        CFReadStreamScheduleWithRunLoop((__bridge CFReadStreamRef) curElem, runLoop, mode);
    }
}

- (void) unscheduleSubFromCFRunLoop:(CFRunLoopRef) runLoop
                         forMode:(CFStringRef) mode
{
    // Unschedule all streams added in parts.
    for(NSUInteger i=0; i < self.streams.count; ++i)
    {
        NSInputStream * curElem = self.streams[i];
        CFReadStreamUnscheduleFromRunLoop((__bridge CFReadStreamRef) curElem, runLoop, mode);
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (aStream == self){
        [self notifyDelegateAndCallback:self handleEvent:eventCode];
        return;
    }

    // Check events from sub-stream and modify it so it matches view for the wrapping stream.
    switch(eventCode){
        // NSStreamEventOpenCompleted -> Re-transmit only for first stream.
        case NSStreamEventOpenCompleted:
            if (self.currentPart != 0){
                return;
            }
            break;
            // NSStreamEventEndEncountered -> Ignore, we retransmit his for the last one..
        case NSStreamEventEndEncountered:
            return;
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
}
@end
