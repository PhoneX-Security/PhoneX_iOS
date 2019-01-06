//
// Created by Dusan Klinec on 14.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjManager+Threads.h"
#import "PEXSystemUtils.h"

@interface PEXPjThreadHolder : NSObject {
    pj_thread_desc _desc;
    pj_thread_t * _pjThread;
}
@property(nonatomic, weak) NSThread * thread;
@property(nonatomic) NSString * key;

- (instancetype)initWithThread:(NSThread *)thread;
- (pj_thread_desc *) getDesc;
- (pj_thread_t **) getPPjThread;
@end

@implementation PEXPjManager (Threads)
-(void) freeThreads {
    [_pjThreads removeAllObjects];
}

- (BOOL) threadRegistered {
    return pj_thread_is_registered() == TRUE;
}

- (void) registerCurrentThread {
    NSThread * curThread = [NSThread currentThread];
    NSString * threadKey = [PEXSystemUtils getCurrentThreadKey];

    PEXPjThreadHolder * holder = [[PEXPjThreadHolder alloc] initWithThread:curThread];
    holder.key = threadKey;

    pj_status_t status;
    status = pj_thread_register([holder.key cStringUsingEncoding:NSASCIIStringEncoding], *[holder getDesc], [holder getPPjThread]);
    DDLogInfo(@"Registered thread [%@], total=%lu", holder.key, (unsigned long)[_pjThreads count]);

    if (status == PJ_SUCCESS){
        _pjThreads[holder.key] = holder;
    } else {
        DDLogError(@"Error in registering a thread");
    }
}

- (void) registerCurrentThreadIfNotRegistered {
    if ([self threadRegistered]){
        return;
    }

    NSThread * curThread = [NSThread currentThread];
    NSString * threadName = [curThread name];
    PEXPjThreadHolder * holder = _pjThreads[threadName];
    if (holder != nil && holder.thread != nil && [curThread isEqual:holder.thread]) {
        DDLogWarn(@"Current thread already should have been registered. Thread: %@", curThread);
    }

    [self registerCurrentThread];
}

@end

@implementation PEXPjThreadHolder
- (instancetype)initWithThread:(NSThread *)thread {
    self = [super init];
    if (self) {
        self.thread = thread;
        _pjThread = NULL;
    }

    return self;
}

- (pj_thread_desc *)getDesc {
    return &_desc;
}

- (pj_thread_t **)getPPjThread {
    return &_pjThread;
}

@end