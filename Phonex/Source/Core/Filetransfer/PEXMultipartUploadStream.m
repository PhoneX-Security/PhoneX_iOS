//
// Created by Dusan Klinec on 23.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMultipartUploadStream.h"
#import "PEXMultipartElement.h"
#import <objc/runtime.h>

#define kFooterFormat @"--%@--\r\n"

@interface PEXMultipartUploadStream() {}
@property (nonatomic, strong) NSMutableArray *parts;
@property (nonatomic, strong) NSData *footer;
@property (nonatomic) NSUInteger currentPart;
@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;
@property (nonatomic) int64_t totalStreamSize;
@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL indeterminatePart;
@property (nonatomic) NSString *boundary;
@end

@implementation PEXMultipartUploadStream
- (void)updateLength
{
    self.length = self.footer.length + [[self.parts valueForKeyPath:@"@sum.length"] unsignedIntegerValue];
}
- (id)init
{
    self = [super init];
    if (self)
    {
        self.totalStreamSize = 0;
        self.allDataWritten = NO;
        self.indeterminatePart = NO;
        self.status = NSStreamStatusNotOpen;
        self.parts    = [NSMutableArray array];

        // Generate new boundary string & regenerate boundary dependent parts.
        [self generateBoundary];

        //[self setDelegate:self];
        [self updateLength];
        [self setupCFRunlooping];
    }
    return self;
}

-(void) regenerateBoundaryDependentParts {
    self.footer   = [[NSString stringWithFormat:kFooterFormat, self.boundary] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)generateBoundary
{
    self.boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
    [self regenerateBoundaryDependentParts];
    return self.boundary;
}

- (void)setNewBoundary:(NSString *)aBoundary {
    self.boundary = aBoundary;
    [self regenerateBoundaryDependentParts];
}

- (void)addPart: (PEXMultipartElement *) part {
    [self.parts addObject:part];
    self.indeterminatePart |= part.sizeUnknown;
    part.idx = [self.parts count] - 1;

    __weak __typeof(self) weakSelf = self;
    part.progressBlock = ^(PEXMultipartElement *e, NSInteger read, int64_t totalLength, int64_t deliveredLength, BOOL indeterminate) {
        PEXMultipartUploadStream * str = weakSelf;
        if (str == nil || str.elementProgressBlock == nil){
            return;
        }

        str.elementProgressBlock(e, read, totalLength, deliveredLength, indeterminate);
    };

    [self updateLength];
}

- (NSArray *)getParts {
    return [NSArray arrayWithArray:self.parts];
}

- (PEXMultipartElement *)writeStringToStream:(NSString *) key data: (NSData *) data{
    PEXMultipartElement * e;
    e = [[PEXMultipartElement alloc] initWithName:key
                                         boundary:_boundary
                                             data:data
                                      contentType:PEX_CONTENT_TYPE_TEXT];
    [self addPart:e];
    return e;
}

- (PEXMultipartElement *)writeStringToStream:(NSString *) key string: (NSString *) string{
    return [self writeStringToStream:key data:[string dataUsingEncoding:NSUTF8StringEncoding]];
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
        [self notifyProgress:0];
        return 0;
    }

    // Stream error?
    if (self.error != nil || self.status == NSStreamStatusError){
        self.status = NSStreamStatusError;
        [self notifyProgress:-1];
        return -1;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Write all body parts.
    // Condition "self.delivered < self.length" removed for unknown data parts.
    while (sent < len && self.currentPart < self.parts.count)
    {
        PEXMultipartElement * curElem = self.parts[self.currentPart];
        read = [curElem read:(buffer + sent) maxLength:(len - sent)];
        if (read < 0){
            // Error
            [self enqueueEvent:NSStreamEventErrorOccurred];
            [self notifyProgress:read];
            return read;
        }

        sent            += read;
        self.delivered  += read;
        self.totalStreamSize += read;

        // Update length if reading indeterminate part.
        if (curElem.sizeUnknown){
            [self updateLength];
        }

        // Termination check.
        if (read == 0
                || [curElem streamStatus] == NSStreamStatusAtEnd
                || [curElem streamStatus] == NSStreamStatusClosed
                || [curElem streamStatus] == NSStreamStatusError)
        {
            ++self.currentPart;

            // First stream is automatically opened, another has to be opened here.
            if (self.currentPart < self.parts.count){
                curElem = self.parts[self.currentPart];
                [curElem setDelegate:self];
                [curElem open];
            }

            continue;
        }
    }

    // Write footer.
    // When all parts were written and there is still some room in the buffer.
    if (self.currentPart >= self.parts.count && sent < len) {
        NSInteger deliveredFooter = (NSInteger) (self.delivered - self.totalStreamSize);
        if (deliveredFooter < self.footer.length) {
            read = MIN(self.footer.length - deliveredFooter, len - sent);
            [self.footer getBytes:buffer + sent range:NSMakeRange((NSUInteger) deliveredFooter, (NSUInteger) read)];

            sent += read;
            self.delivered += read;

            // Check if we have written the final piece of data.
            deliveredFooter = (NSInteger) (self.delivered - self.totalStreamSize);
            if (deliveredFooter >= self.footer.length) {
                self.allDataWritten = YES;
                self.status = NSStreamStatusAtEnd;

                // Broadcast end encountered event.
                [self enqueueEvent:NSStreamEventEndEncountered];
            }
        }
    }

    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable]){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    [self notifyProgress:sent];
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

    if (self.currentPart < self.parts.count){
        PEXMultipartElement * curElem = self.parts[self.currentPart];
        return [curElem hasBytesAvailable];
    }

    // All parts written and still not everything -> footer left, available right now.
    return YES;
}
- (void)open
{
    self.status = NSStreamStatusOpen;

    // Add proper delegate to all subparts.
    for(NSUInteger i=0; i < self.parts.count; ++i)
    {
        PEXMultipartElement * curElem = self.parts[i];
        [curElem setDelegate:self];
    }

    // Open the first one.
    if (self.parts.count >= 1){
        PEXMultipartElement * curElem = self.parts[0];
        [curElem open];
    }

    // Open successful && data available (headers).
    [self enqueueEvent:NSStreamEventOpenCompleted];
}
- (void)close
{
    // Close all sub-parts.
    for(NSUInteger i=0; i < self.parts.count; ++i)
    {
        PEXMultipartElement * curElem = self.parts[i];
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
- (void) scheduleSubInCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Schedule all streams added in parts.
    for(NSUInteger i=0; i < self.parts.count; ++i)
    {
        PEXMultipartElement * curElem = self.parts[i];
        [curElem scheduleInCFRunLoop:runLoop forMode:mode];
    }
}

- (void) unscheduleSubFromCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Unschedule all streams added in parts.
    for(NSUInteger i=0; i < self.parts.count; ++i)
    {
        PEXMultipartElement * curElem = self.parts[i];
        [curElem unscheduleFromCFRunLoop:runLoop forMode:mode];
    }
}

- (void)notifyProgress: (NSInteger)sent{
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

    // Check events from sub-stream and modify it so it matches view for the wrapping stream.
    switch(eventCode){
        // NSStreamEventOpenCompleted -> Ignore, already sent (for static data).
        case NSStreamEventOpenCompleted:
            return;
            // NSStreamEventEndEncountered -> bytes available (static data, footer), for last stream.
        case NSStreamEventEndEncountered:
            if (self.currentPart+1 == self.parts.count) {
                eventCode = NSStreamEventHasBytesAvailable;
            } else {
                return;
            }
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
}
@end

