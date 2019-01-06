//
// Created by Dusan Klinec on 04.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPriorityQueue.h"
#import "PEXTaskContainerEvents.h"

/**
* Serializer for events from PEXTaskContainer about subtask progress.
* Idea: show the most recent task progress update to the user. If this task
* is finished, show second most recent that is still in progress.
* There may be multiple running tasks in parallel.
*/
@interface PEXTaskContainerEventSerializer : NSObject

// Queue for serializing progress updates.
@property (nonatomic) dispatch_queue_t progressDispatchQueue;

// Priority queue for task events.
@property (nonatomic) PEXPriorityQueue * progressEventQueue;

// Block for updating progress with new event.
@property (nonatomic, copy) void (^eventCallbackBlock)(int, const PEXTaskProgressedEvent *const);

// Add task progressed event to the queue.
- (void)addEvent:(int)source event:(const PEXTaskProgressedEvent *const)tev;
- (void)clear;
@end