//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import "PEXCopyOutputStream.h"

@interface PEXCopyOutputStream() {
    // Variables for runloop scheduling.
    CFWriteStreamClientCallBack _clientCallback;
    CFStreamClientContext       _clientContext;
    CFOptionFlags               _clientFlags;
}

@property (nonatomic, strong) NSOutputStream *body;
@property (nonatomic, strong) NSMutableData *bodyCopy;

@property (nonatomic) int64_t length;
@property (nonatomic) int64_t delivered;

@property (nonatomic) BOOL allDataWritten;
@property (nonatomic) BOOL scheduledOnRunLoop;

@property (nonatomic) NSStreamStatus status;
@property (nonatomic, weak) id <NSStreamDelegate> delegate_x;
@end

@implementation PEXCopyOutputStream

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allDataWritten = NO;
        self.scheduledOnRunLoop = NO;
        self.status = NSStreamStatusNotOpen;
        self.bodyCopy = [[NSMutableData alloc] init];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Init methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStream:(NSOutputStream *)stream
{
    self               = [self init];
    self.body          = stream;
    self.delivered     = 0;
    self.length        = 0;
    return self;
}

- (id <NSStreamDelegate> )delegate {
    return self.delegate_x;
}

- (void)setDelegate:(id<NSStreamDelegate>)aDelegate {
    if (aDelegate == nil) {
        self.delegate_x = self;
    }
    else {
        self.delegate_x = aDelegate;
    }
}

- (NSData *) getData {
    return [NSData dataWithData:self.bodyCopy];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSOutputStream write
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)write:(uint8_t const *)buffer maxLength:(NSUInteger)len
{
    NSInteger sent = 0;
    NSInteger written = 0;

    if (len == 0){
        return 0;
    }

    // End of the stream.
    // Known length variant: self.delivered >= self.length
    if (self.allDataWritten || self.status == NSStreamStatusClosed)
    {
        [self notifyProgress:sent];
        return 0;
    }

    // Otherwise switch stream status to reading -> some data available, apparently.
    self.status = NSStreamStatusWriting;

    // Write sub-stream section.
    // Previously here was also "self.delivered < (self.length - 2)" making sure that we are still
    // writing body stream data but for unknown length stream data we just don't know total length
    // so we write all the provided buffer with stream data until there are still some.
    while (sent < len)
    {
        written = [self.body write:buffer + sent maxLength:len - sent];
        if (written < 0){
            sent = written;
            break;
        }

        sent           += written;
        self.delivered += written;
        self.length    += written;

        // Check termination
        if (written == 0
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
    if ([self hasSpaceAvailable]){
        [self notifyEvent:NSStreamEventHasSpaceAvailable];
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

-(BOOL) hasSpaceAvailable {
    if (self.allDataWritten) return YES; // force read to discover we are finished.
    return [self.body hasSpaceAvailable];
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
#pragma mark - Undocumented CFWriteStream private hack
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
* Hack so we can a) implement private method for runloop scheduling b) not being rejected from app store for implementing
* private method (directly).
*/
+ (BOOL) resolveInstanceMethod:(SEL) selector
{
    NSString * name = NSStringFromSelector(selector);

    if ([name hasPrefix:@"_"])
    {
        name = [name substringFromIndex:1];
        SEL aSelector = NSSelectorFromString(name);
        Method method = class_getInstanceMethod(self, aSelector);

        if (method)
        {
            class_addMethod(self,
                    selector,
                    method_getImplementation(method),
                    method_getTypeEncoding(method));
            return YES;
        }
    }
    return [super resolveInstanceMethod:selector];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Undocumented CFWriteStream bridged methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) setCFClientFlags:(CFOptionFlags)inFlags
                 callback:(CFWriteStreamClientCallBack)inCallback
                  context:(CFStreamClientContext *)inContext {

    if (inCallback != NULL) {
        _clientFlags = inFlags;
        _clientCallback = inCallback;
        memcpy(&_clientContext, inContext, sizeof(CFStreamClientContext));

        if (_clientContext.info && _clientContext.retain) {
            _clientContext.retain(_clientContext.info);
        }
    }
    else {
        _clientFlags = kCFStreamEventNone;
        _clientCallback = NULL;
        if (_clientContext.info && _clientContext.release) {
            _clientContext.release(_clientContext.info);
        }

        memset(&_clientContext, 0, sizeof(CFStreamClientContext));
    }

    return YES;
}

- (void) scheduleInCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Schedule sub-stream.
    if (self.body != nil) {
        CFWriteStreamScheduleWithRunLoop((__bridge CFWriteStreamRef) self.body, runLoop, mode);
    }

    self.scheduledOnRunLoop = YES;
}

- (void) unscheduleFromCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode
{
    // Unchedule sub-stream.
    if (self.body != nil) {
        CFWriteStreamUnscheduleFromRunLoop((__bridge CFWriteStreamRef) self.body, runLoop, mode);
    }

    self.scheduledOnRunLoop = NO;
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
    [self scheduleInCFRunLoop:[aRunLoop getCFRunLoop] forMode:(__bridge CFStringRef) mode];
}

- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode
{
    [self unscheduleFromCFRunLoop:[aRunLoop getCFRunLoop] forMode:(__bridge CFStringRef) mode];
}

- (void)notifyClientCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (![aStream isKindOfClass:[NSOutputStream class]]){
        return;
    }

    if (_clientCallback && (eventCode & _clientFlags)) {
        _clientCallback((__bridge CFWriteStreamRef)self, (CFStreamEventType)eventCode, _clientContext.info);
    }
}

- (void)notifyDelegateAndCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    // If we have some delegate set, report him this event.
    if ( [self.delegate respondsToSelector:@selector(stream:handleEvent:)] ) {
        [self.delegate stream:self handleEvent:eventCode];
    }

    // Notify user callback.
    [self notifyClientCallback:aStream handleEvent:eventCode];
}

- (void)notifyEvent:(NSStreamEvent)eventCode{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf notifyDelegateAndCallback:weakSelf handleEvent:eventCode];
    });
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