//
// Created by Dusan Klinec on 02.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;


@interface PEXRunLoopOutputStream : NSOutputStream<NSStreamDelegate>
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic) BOOL isCancelled;

@property (nonatomic) NSStreamStatus status;
@property (nonatomic) NSError * error;
@property (nonatomic) NSMutableDictionary * properties;

- (void) enqueueEvent:(NSStreamEvent)event;
- (NSStreamEvent) dequeueEvent;
- (void) streamEventTrigger;
- (void) enumerateRunLoopsUsingBlock:(void (^)(CFRunLoopRef runLoop))block;
- (void) addMode:(CFStringRef)mode forRunLoop:(CFRunLoopRef)runLoop;
- (void) removeMode:(CFStringRef)mode forRunLoop:(CFRunLoopRef)runLoop;
- (BOOL) setCFClientFlags:(CFOptionFlags)inFlags callback:(CFWriteStreamClientCallBack)inCallback context:(CFStreamClientContext *)inContext;
- (void) unscheduleFromAllRunLoops;
- (void) scheduleInRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode;
- (void) removeFromRunLoop:(NSRunLoop *) aRunLoop forMode:(NSString *) mode;
- (void) notifyClientCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
- (void) notifyDelegateAndCallback:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
- (void) scheduleInCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode;
- (void) unscheduleFromCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode;

/**
* Designated user callback for registering in runloop (if desired).
*/
- (void) scheduleSubInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode;

/**
* Designated user callback for unregistering from runloop (if desired).
*/
- (void) unscheduleSubFromCFRunLoop:(CFRunLoopRef) runLoop forMode:(CFStringRef) mode;

/**
* NSStreamDelegate method. May be overriden.
*/
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;

- (id <NSStreamDelegate> )delegate;
- (void)setDelegate:(id<NSStreamDelegate>)aDelegate;

-(void) setupCFRunlooping;
-(void) teardownCFRunlooping;

@end