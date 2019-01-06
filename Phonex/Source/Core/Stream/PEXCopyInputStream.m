//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import "PEXCopyInputStream.h"

@interface PEXCopyInputStream()

@property (nonatomic, strong) NSInputStream *body;
@property (nonatomic, strong) NSMutableData *bodyCopy;

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;

@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL scheduledOnRunLoop;
@end

@implementation PEXCopyInputStream

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allDataWritten = NO;
        self.scheduledOnRunLoop = NO;
        self.status = NSStreamStatusNotOpen;
        self.bodyCopy = [[NSMutableData alloc] init];
        [self setupCFRunlooping];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStream:(NSInputStream *)stream
{
    self               = [self init];
    self.body          = stream;
    self.delivered     = 0;
    self.length        = 0;
    return self;
}

- (NSData *) getData {
    return [NSData dataWithData:self.bodyCopy];
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
        [self notifyProgress:sent];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Write sub-stream section.
    // Previously here was also "self.delivered < (self.length - 2)" making sure that we are still
    // writing body stream data but for unknown length stream data we just don't know total length
    // so we write all the provided buffer with stream data until there are still some.
    while (sent < len)
    {
        read = [self.body read:buffer + sent maxLength:len - sent];
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
                || [self.body streamStatus] == NSStreamStatusError)
        {

            // This was the final piece
            self.allDataWritten = YES;
            self.status = NSStreamStatusAtEnd;

            break;
        }
    }

    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable]){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    // Copy stream data to the buffer.
    if (self.copyStream && sent > 0){
        [self.bodyCopy appendBytes:buffer length:(NSUInteger) sent];
    }

    [self notifyProgress:sent];
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

- (void)notifyProgress:(NSInteger)sent{
    if (self.progressBlock == nil){
        return;
    }

    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf == nil || weakSelf.progressBlock == nil){
            return;
        }

        weakSelf.progressBlock(weakSelf, sent);
    });
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