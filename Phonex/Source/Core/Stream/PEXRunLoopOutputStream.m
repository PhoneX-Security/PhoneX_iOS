//
// Created by Dusan Klinec on 02.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <objc/runtime.h>
#import "PEXRunLoopOutputStream.h"
#import "PEXCanceller.h"

#pragma mark - Core Foundation callbacks
static const void *PEXNSOutRetainCallBack(CFAllocatorRef allocator, const void *value) { return CFRetain(value); }
static void PEXNSOutReleaseCallBack(CFAllocatorRef allocator, const void *value)       { CFRelease(value); }
static void PEXNSOutRunLoopPerformCallBack(void *info);

#pragma mark - PEXRunLoopOutputStream()
@interface PEXRunLoopOutputStream() {
    // Variables for runloop scheduling.
@protected
    CFWriteStreamClientCallBack  _clientCallback;
    CFStreamClientContext       _clientContext;
    CFOptionFlags               _clientFlags;

    BOOL _runloopingInitialized;
    CFRunLoopSourceRef _runLoopSource;
    NSStreamEvent _pendingEvents;
    CFMutableSetRef _runLoopsSet;
    CFMutableDictionaryRef _runLoopsModes;
}

@property (nonatomic) BOOL shouldNotifyCoreFoundationAboutStatusChange;
@property (nonatomic) BOOL scheduledOnRunLoop;
@property (nonatomic, weak) id <NSStreamDelegate> delegate_x;
@end

@implementation PEXRunLoopOutputStream {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scheduledOnRunLoop = NO;
        self.status = NSStreamStatusNotOpen;
        self.error = nil;
        self.properties = [[NSMutableDictionary alloc] init];
        self.delegate_x = nil;
        _runloopingInitialized = NO;
    }

    return self;
}

- (void)dealloc {
    [self teardownCFRunlooping];
}

-(void) setupCFRunlooping {
    if (_runloopingInitialized){
        DDLogError(@"Runlooping already initialized");
        return;
    }

    _shouldNotifyCoreFoundationAboutStatusChange = NO;
    _clientCallback = NULL;
    _clientContext = (CFStreamClientContext) { 0 };
    CFRunLoopSourceContext runLoopSourceContext = {
            0, (__bridge void *)(self), NULL, NULL, NULL, NULL, NULL, NULL, NULL, PEXNSOutRunLoopPerformCallBack
    };

    _runLoopSource = CFRunLoopSourceCreate(NULL, 0, &runLoopSourceContext);
    CFSetCallBacks runLoopsSetCallBacks = {
            0, NULL, NULL, NULL, CFEqual, CFHash // CFRunLoop retains CFStream, so we will not.
    };

    _runLoopsSet = CFSetCreateMutable(NULL, 0, &runLoopsSetCallBacks);
    CFDictionaryKeyCallBacks runLoopsModesKeyCallBacks = {
            0, NULL, NULL, NULL, CFEqual, CFHash
    };

    CFDictionaryValueCallBacks runLoopsModesValueCallBacks = {
            0, PEXNSOutRetainCallBack, PEXNSOutReleaseCallBack, NULL, CFEqual
    };
    _runLoopsModes = CFDictionaryCreateMutable(NULL, 0, &runLoopsModesKeyCallBacks, &runLoopsModesValueCallBacks);
    _runloopingInitialized = YES;
}

-(void) teardownCFRunlooping {
    if (!_runloopingInitialized){
        return;
    }

    if (_clientContext.release) {
        _clientContext.release(_clientContext.info);
    }
    CFRelease(_runLoopSource);
    CFRelease(_runLoopsSet);
    CFRelease(_runLoopsModes);
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

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Undocumented CFReadStream private hack
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

- (void)enqueueEvent:(NSStreamEvent)event {
    _pendingEvents |= event;
    CFRunLoopSourceSignal(_runLoopSource);
    [self enumerateRunLoopsUsingBlock:^(CFRunLoopRef runLoop) {
        CFRunLoopWakeUp(runLoop);
    }];
}

- (NSStreamEvent)dequeueEvent {
    if (_pendingEvents == NSStreamEventNone) {
        return NSStreamEventNone;
    }
    NSStreamEvent event = 1UL << __builtin_ctz(_pendingEvents);
    _pendingEvents ^= event;
    return event;
}

- (void)streamEventTrigger {
    if (_status == NSStreamStatusClosed) {
        return;
    }
    NSStreamEvent event = [self dequeueEvent];
    while (event != NSStreamEventNone) {
        [self notifyDelegateAndCallback:self handleEvent:event];
        event = [self dequeueEvent];
    }
}

- (void)enumerateRunLoopsUsingBlock:(void (^)(CFRunLoopRef runLoop))block {
    CFIndex runLoopsCount = CFSetGetCount(_runLoopsSet);
    if (runLoopsCount > 0) {
        CFTypeRef runLoops[runLoopsCount];
        CFSetGetValues(_runLoopsSet, runLoops);
        for (CFIndex i = 0; i < runLoopsCount; ++i) {
            block((CFRunLoopRef)runLoops[i]);
        }
    }
}

- (void)addMode:(CFStringRef)mode forRunLoop:(CFRunLoopRef)runLoop {
    CFMutableSetRef modes = NULL;
    if (!CFDictionaryContainsKey(_runLoopsModes, runLoop)) {
        CFSetCallBacks modesSetCallBacks = {
                0, PEXNSOutRetainCallBack, PEXNSOutReleaseCallBack, NULL, CFEqual, CFHash
        };
        modes = CFSetCreateMutable(NULL, 0, &modesSetCallBacks);
        CFDictionaryAddValue(_runLoopsModes, runLoop, modes);
    } else {
        modes = (CFMutableSetRef)CFDictionaryGetValue(_runLoopsModes, runLoop);
    }
    CFStringRef modeCopy = CFStringCreateCopy(NULL, mode);
    CFSetAddValue(modes, modeCopy);
    CFRelease(modeCopy);
}

- (void)removeMode:(CFStringRef)mode forRunLoop:(CFRunLoopRef)runLoop {
    if (!CFDictionaryContainsKey(_runLoopsModes, runLoop)) {
        return;
    }
    CFMutableSetRef modes = (CFMutableSetRef)CFDictionaryGetValue(_runLoopsModes, runLoop);
    CFSetRemoveValue(modes, mode);
}

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

- (void)scheduleInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {
    CFSetAddValue(_runLoopsSet, runLoop);
    [self addMode:mode forRunLoop:runLoop];
    CFRunLoopAddSource(runLoop, _runLoopSource, mode);
    [self scheduleSubInCFRunLoop:runLoop forMode:mode];
    self.scheduledOnRunLoop = YES;
}

- (void)unscheduleFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {
    CFRunLoopRemoveSource(runLoop, _runLoopSource, mode);
    [self removeMode:mode forRunLoop:runLoop];
    CFSetRemoveValue(_runLoopsSet, runLoop);
    [self unscheduleSubFromCFRunLoop:runLoop forMode:mode];
    self.scheduledOnRunLoop = CFSetGetCount(_runLoopsSet) == 0;
}

- (void)scheduleSubInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {

}

- (void)unscheduleSubFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode {

}

- (void)unscheduleFromAllRunLoops {
    [self enumerateRunLoopsUsingBlock:^(CFRunLoopRef runLoop) {
        CFMutableSetRef runLoopModesSet = (CFMutableSetRef)CFDictionaryGetValue(_runLoopsModes, runLoop);
        CFIndex runLoopModesCount = CFSetGetCount(runLoopModesSet);
        if (runLoopModesCount > 0) {
            CFTypeRef runLoopModes[runLoopModesCount];
            CFSetGetValues(runLoopModesSet, runLoopModes);
            for (CFIndex j = 0; j < runLoopModesCount; ++j) {
                [self unscheduleFromCFRunLoop:runLoop forMode:(CFStringRef)runLoopModes[j]];
            }
        }
    }];
}

- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode {
    [self scheduleInCFRunLoop:[aRunLoop getCFRunLoop] forMode:(__bridge CFStringRef) mode];
}

- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode {
    [self unscheduleFromCFRunLoop:[aRunLoop getCFRunLoop] forMode:(__bridge CFStringRef) mode];
}

- (void)notifyClientCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (![aStream isKindOfClass:[NSInputStream class]]){
        return;
    }

    if (_clientCallback && (eventCode & _clientFlags) && _shouldNotifyCoreFoundationAboutStatusChange) {
        _clientCallback((__bridge CFWriteStreamRef)self, (CFStreamEventType)eventCode, _clientContext.info);
    }
}

- (void)notifyDelegateAndCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    // If we have some delegate set, report him this event.
    if ( [_delegate_x respondsToSelector:@selector(stream:handleEvent:)] ) {
        [_delegate_x stream:self handleEvent:eventCode];
    }

    // Notify user callback.
    [self notifyClientCallback:aStream handleEvent:eventCode];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    [self notifyDelegateAndCallback:self handleEvent:eventCode];
}

@end

#pragma mark - Core Foundation callbacks implementations

void PEXNSOutRunLoopPerformCallBack(void *info) {
    PEXRunLoopOutputStream *stream = (__bridge PEXRunLoopOutputStream *)info;

    // Dequeue event & calls notifyDelegateAndCallback.
    [stream streamEventTrigger];
}
