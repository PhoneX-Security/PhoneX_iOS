//
// Created by Dusan Klinec on 05.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXConcurrentPriorityQueue.h"
#import "PEXPriorityQueue.h"
#import "PEXUtils.h"

// Keep all properties private in order to preserve thread safety.
@interface PEXConcurrentPriorityQueue () {
    // Dispatch queue to use for list control.
    dispatch_queue_t _queue;
}

@property (nonatomic, readwrite) PEXPriorityQueue * pqueue;
@end



@implementation PEXConcurrentPriorityQueue { }

- (instancetype)initWithQueue:(dispatch_queue_t)queue1 {
    if ((self = [super init]) == nil) return nil;
    if (queue1 == nil){
        // Create a new serial queue if none is provided.
        _queue = dispatch_queue_create("concurrent_hash_map", DISPATCH_QUEUE_SERIAL);
    } else {
        _queue = queue1;
    }

    self.pqueue = [[PEXPriorityQueue alloc] init];
    return self;
}

- (instancetype)initWithQueueName:(NSString *)queueName {
    return [self initWithQueue:dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL)];
}

- (instancetype)init {
    return [self initWithQueue:nil];
}

- (void)addObject:(id <PEXPriorityQueueObject>)object {
    [self addObject:object async:YES];
}

- (void)addObject:(id <PEXPriorityQueueObject>)object async:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.pqueue addObject:object];
    }];
}

- (id <PEXPriorityQueueObject>)pop {
    __block id <PEXPriorityQueueObject> ret = nil;
    dispatch_sync(_queue, ^{
        ret = [self.pqueue pop];
    });

    return ret;
}

- (void)resort:(id <PEXPriorityQueueObject>)object {
    [self resort:object async:YES];
}

- (void)resort:(id <PEXPriorityQueueObject>)object async:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.pqueue resort:object];
    }];
}

- (NSArray *)getBackendCopy {
    __block NSArray * arr = nil;
    dispatch_sync(_queue, ^{
        arr = [NSArray arrayWithArray:[self.pqueue getBackend]];
    });

    return arr;
}

- (id <PEXPriorityQueueObject>)first {
    __block id <PEXPriorityQueueObject> ret = nil;
    dispatch_sync(_queue, ^{
        ret = [self.pqueue first];
    });

    return ret;
}

- (NSUInteger)count {
    __block NSUInteger ret = 0;
    dispatch_sync(_queue, ^{
        ret = [self.pqueue count];
    });

    return ret;
}

- (void)clear {
    [self clearAsync:YES];
}

- (void)clearAsync:(BOOL)async {
    [PEXUtils executeOnQueue:_queue async:async block:^{
        [self.pqueue clear];
    }];
}


@end