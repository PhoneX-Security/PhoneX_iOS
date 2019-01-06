//
// Created by Dusan Klinec on 24.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMultipartElement.h"
#import "PEXMultipartUploadStream.h"
#import "PEXUtils.h"
#import <objc/runtime.h>

NSString * PEX_CONTENT_TYPE_TEXT = @"text/plain;charset=UTF-8";
NSString * PEX_CONTENT_TYPE_OCTET = @"application/octet-stream";

#define kHeaderStringFormat @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n"
#define kHeaderDataFormat @"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\nContent-Type: %@\r\n\r\n"
#define kHeaderPathFormat @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n"
#define kHeaderPathFormatBinary @"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n"

@interface PEXMultipartElement(){}
@property (nonatomic) NSString * name;
@property (nonatomic, strong) NSData *headers;
@property (nonatomic, strong) NSInputStream *body;
@property (nonatomic) NSUInteger headersLength;

@property (nonatomic) int64_t bodyLength;
@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;
@property (nonatomic) BOOL sizeUnknown;
@property (nonatomic) BOOL streamReadingFinished;
@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL substreamOpened;
@property (nonatomic) BOOL scheduledOnRunLoop;
@property (nonatomic) int64_t finalStreamSize;
@end

@implementation PEXMultipartElement
- (void)updateLength
{
    self.length = self.headersLength + self.bodyLength + 2;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sizeUnknown = NO;
        self.streamReadingFinished = NO;
        self.allDataWritten = NO;
        self.substreamOpened = NO;
        self.scheduledOnRunLoop = NO;
        self.finalStreamSize = 0;
        self.status = NSStreamStatusNotOpen;
        [self setupCFRunlooping];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (id)initWithName:(NSString *)name boundary:(NSString *)boundary string:(NSString *)string
{
    self               = [self init];
    self.headers       = [[NSString stringWithFormat:kHeaderStringFormat, boundary, name] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.name          = name;
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    self.body          = [NSInputStream inputStreamWithData:stringData];
    self.bodyLength    = stringData.length;
    [self updateLength];
    return self;
}
- (id)initWithName:(NSString *)name boundary:(NSString *)boundary data:(NSData *)data contentType:(NSString *)contentType
{
    self               = [self init];
    self.headers       = [[NSString stringWithFormat:kHeaderDataFormat, boundary, name, contentType] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.name          = name;
    self.body          = [NSInputStream inputStreamWithData:data];
    self.bodyLength    = [data length];
    [self updateLength];
    return self;
}
- (id)initWithName:(NSString *)name boundary:(NSString *)boundary data:(NSData *)data contentType:(NSString *)contentType filename:(NSString*)filename
{
    self               = [self init];
    self.headers       = [[NSString stringWithFormat:kHeaderPathFormat, boundary, name, filename, contentType] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.name          = name;
    self.body          = [NSInputStream inputStreamWithData:data];
    self.bodyLength    = [data length];
    [self updateLength];
    return self;
}
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary path:(NSString *)path
{
    self               = [self init];
    if (!filename)
    {
        filename = path.lastPathComponent;
    }
    self.headers       = [[NSString stringWithFormat:kHeaderPathFormat, boundary, name, filename, [PEXUtils guessMIMETypeFromExtension:path.pathExtension]] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.name          = name;
    self.body          = [NSInputStream inputStreamWithFileAtPath:path];
    self.bodyLength    = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL][NSFileSize] unsignedIntegerValue];
    [self updateLength];
    return self;
}
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary stream:(NSInputStream *)stream streamLength:(NSUInteger)streamLength
{
    self               = [self init];
    self.headers       = [[NSString stringWithFormat:kHeaderPathFormat, boundary, name, filename, [PEXUtils guessMIMETypeFromExtension:filename.pathExtension]] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.body          = stream;
    self.bodyLength    = streamLength;
    self.name          = name;
    [self updateLength];
    return self;
}
- (id)initWithName:(NSString *)name filename:(NSString *)filename boundary:(NSString *)boundary stream:(NSInputStream *)stream
{
    self               = [self init];
    self.headers       = [[NSString stringWithFormat:kHeaderPathFormat, boundary, name, filename, [PEXUtils guessMIMETypeFromExtension:filename.pathExtension]] dataUsingEncoding:NSUTF8StringEncoding];
    self.headersLength = [self.headers length];
    self.body          = stream;
    self.bodyLength    = 0;
    self.sizeUnknown   = YES;
    self.name          = name;
    [self updateLength];
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
        [self notifyProgress:sent];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusReading;

    // Write headers section.
    if (self.delivered < self.headersLength && sent < len)
    {
        read            = MIN((NSInteger)(self.headersLength - self.delivered), (len - sent));
        [self.headers getBytes:buffer + sent range:NSMakeRange((NSUInteger) self.delivered, (NSUInteger) read)];
        sent           += read;
        self.delivered += sent;
    }

    // Write sub-stream section.
    // Previously here was also "self.delivered < (self.length - 2)" making sure that we are still
    // writing body stream data but for unknown length stream data we just don't know total length
    // so we write all the provided buffer with stream data until there are still some.
    while (!self.streamReadingFinished && self.delivered >= self.headersLength && sent < len)
    {
        // Open stream if it is not already.
        if (!self.substreamOpened){
            [self.body setDelegate:self];
            [self.body open];
            self.substreamOpened = YES;
        }

        read = [self.body read:buffer + sent maxLength:len - sent];
        if (read < 0){
            // Error;
            [self enqueueEvent:NSStreamEventErrorOccurred];
            [self notifyProgress:read];
            return read;
        }

        sent           += read;
        self.delivered += read;
        self.finalStreamSize += read;
        if (self.sizeUnknown){
            self.bodyLength += read;
            [self updateLength];
        }

        // Check termination
        if (read == 0
                || [self.body streamStatus] == NSStreamStatusAtEnd
                || [self.body streamStatus] == NSStreamStatusClosed
                || [self.body streamStatus] == NSStreamStatusError)
        {
            self.streamReadingFinished = YES;
            break;
        }
    }

    // Write \r\n
    // Do not rely on the known body length. Write after stream reading has finished.
    // If \r was not written, do it.
    if (self.streamReadingFinished && (self.delivered - self.finalStreamSize) == self.headersLength && sent < len)
    {
        *(buffer + sent) = '\r';
        sent ++; self.delivered ++;
    }

    // If \n was not written, do it.
    if (self.streamReadingFinished && (self.delivered - self.finalStreamSize) == (self.headersLength + 1) && sent < len)
    {
        *(buffer + sent) = '\n';
        sent ++; self.delivered ++;

        // This was the final piece
        self.allDataWritten = YES;
        self.status = NSStreamStatusAtEnd;

        // Broadcast end encountered event.
        [self enqueueEvent:NSStreamEventEndEncountered];
    }

    // If not all data was written, broadcast we have bytes available, if we have.
    if ([self hasBytesAvailable]){
        [self enqueueEvent:NSStreamEventHasBytesAvailable];
    }

    [self notifyProgress:sent];
    return sent;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream data availability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(BOOL) isWritingHeaderData {
    return !self.allDataWritten && !self.streamReadingFinished && self.delivered < self.headersLength;
}

-(BOOL) isWritingStreamData {
    return !self.allDataWritten && !self.streamReadingFinished && self.delivered >= self.headersLength;
}

-(BOOL) hasStreamingDataAvailable {
    // If substream was not opened, return YES so it is opened.
    return !self.substreamOpened || [self.body hasBytesAvailable];
}

-(BOOL) isWritingFooterData {
    if (self.allDataWritten || !self.streamReadingFinished) return NO;
    int64_t deliveredWithoutBody = (self.delivered - self.finalStreamSize);
    return (deliveredWithoutBody == self.headersLength || deliveredWithoutBody == (self.headersLength + 1));
}

-(BOOL) hasBytesAvailable {
    if (self.allDataWritten) return YES; // force read to discover we are finished.
    return [self isWritingHeaderData]
            || ([self isWritingStreamData] && [self hasStreamingDataAvailable])
            ||  [self isWritingFooterData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Stream manipulation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)open
{
    // Open myself - for events.
    //[super open];

    self.status = NSStreamStatusOpen;

    // Set this object as stream delegate so we receive events and re-broadcast them as own.
    [self.body setDelegate:self];

    // Open successful && data available (headers).
    [self enqueueEvent:NSStreamEventOpenCompleted];
    [self enqueueEvent:NSStreamEventHasBytesAvailable];
}
- (void)close
{
    // Close myself - for events.
    //[super close];

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
#pragma mark - Undocumented CFReadStream private hack
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

        weakSelf.progressBlock(weakSelf, sent, self.length, self.delivered, self.sizeUnknown);
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

    // Check events from sub-stream and modify it so it matches view for the wrapping stream.
    switch(eventCode){
        // NSStreamEventOpenCompleted -> Ignore, already sent (for static data).
        case NSStreamEventOpenCompleted:
            return;
        // NSStreamEventEndEncountered -> bytes available (static data, footer), mark stream finished.
        case NSStreamEventEndEncountered:
            self.streamReadingFinished = YES;
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

    // Notify listeners.
    [self notifyDelegateAndCallback:self handleEvent:eventCode];
}
@end
