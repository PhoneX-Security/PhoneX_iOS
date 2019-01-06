//
// Created by Dusan Klinec on 05.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXPriorityQueueObject;


@interface PEXConcurrentPriorityQueue : NSObject
- (instancetype)initWithQueue:(dispatch_queue_t)queue1;
- (instancetype) initWithQueueName: (NSString *) queueName;

- (void)addObject:(id<PEXPriorityQueueObject>)object;
- (void)addObject:(id<PEXPriorityQueueObject>)object async: (BOOL) async;
- (id<PEXPriorityQueueObject>)pop;
- (void)resort:(id<PEXPriorityQueueObject>)object;
- (void)resort:(id<PEXPriorityQueueObject>)object async: (BOOL) async;
- (NSArray *) getBackendCopy;

- (id<PEXPriorityQueueObject>)first;
- (NSUInteger)count;
- (void)clear;
- (void)clearAsync: (BOOL) async;
@end