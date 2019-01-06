//
// Created by Dusan Klinec on 04.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskContainerEventSerializer.h"
#import "PEXUtils.h"
#define EXTRA_EVENT_SOURCE_ID "ExtraEventSourceID"

@implementation PEXTaskContainerEventSerializer {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.progressEventQueue = [[PEXPriorityQueue alloc] init];
        self.progressDispatchQueue = dispatch_queue_create("ProgressEventQueue", DISPATCH_QUEUE_SERIAL);
        self.eventCallbackBlock = nil;
    }

    return self;
}

- (void)addEvent:(int)source event:(const PEXTaskProgressedEvent *const)tev {
    if (self.eventCallbackBlock==nil){
        return;
    }

    // Hand-over to our progress processing engine.
    // Use async call on serial synchronization queue so thread safety is guaranteed.
    __weak PEXTaskContainerEventSerializer * weakSelf = self;
    dispatch_async(self.progressDispatchQueue, ^{
        [weakSelf processProgressedInternal:source event:tev];
    });
}

- (void)processProgressedInternal:(int)source event:(const PEXTaskProgressedEvent *const)tev {
    PEXTaskProgressedEvent * finalTev = tev;
    if (tev.started) {
        // Event was started, add it to the priority queue.
        // Define source to the dictionary.
        if (tev.userInfo == nil){
            tev.userInfo = [[NSMutableDictionary alloc] init];
        }
        tev.userInfo[@EXTRA_EVENT_SOURCE_ID] = @(source);

        DDLogVerbose(@"Adding event to the queue: %@", tev);
        [self.progressEventQueue addObject:tev];
    } else if (tev.finished) {
        // On finished, remove particular object from the priority queue.
        // Algorithm: find the event in the queue O(n), decrease its priority to high time, resort queue so it
        // has this element on the top, pop queue until there are no elements with weird time.
        NSMutableArray *back = self.progressEventQueue.getBackend;
        PEXTaskProgressedEvent *queueCounterpart = nil;
        double unrealTime = [[NSDate distantFuture] timeIntervalSince1970];

        for (id curId in back) {
            if (![curId isKindOfClass:[PEXTaskProgressedEvent class]]) {
                continue;
            }

            PEXTaskProgressedEvent *curTev = (PEXTaskProgressedEvent *) curId;
            if (curTev.container == tev.container
                    && curTev.subTaskId == tev.subTaskId
                    && [PEXUtils areNSNumbersEqual:curTev.taskStage b:tev.taskStage]
                    && [PEXUtils areNSNumbersEqual:curTev.subTaskStage b:tev.subTaskStage]) {
                curTev.timestampMilli = unrealTime;
                queueCounterpart = curTev;
                break;
            }
        }

        // Resort queue.
        if (queueCounterpart != nil) {
            DDLogVerbose(@"Removing from event queue: %@", queueCounterpart);
            [self.progressEventQueue resort:queueCounterpart];
        }

        // Remove until there is some with weird time.
        while (self.progressEventQueue.count > 1) {
            PEXTaskProgressedEvent *curElem = self.progressEventQueue.first;
            if (curElem.timestampMilli != unrealTime) {
                break;
            }

            [self.progressEventQueue pop];
        }
    }

    // Display event with the highest priority.
    if (self.progressEventQueue.count > 1) {
        finalTev = self.progressEventQueue.first;
    } else {
        return;
    }

    if (self.eventCallbackBlock==nil){
        return;
    }

    // Call update, resolve source.
    if (finalTev.userInfo != nil){
        id nsSrc = finalTev.userInfo[@EXTRA_EVENT_SOURCE_ID];
        if (nsSrc != nil && [nsSrc isKindOfClass:[NSNumber class]]){
            source = [((NSNumber *) nsSrc) integerValue];
        }
    }

    self.eventCallbackBlock(source, finalTev);
}

- (void)clear {
    [self.progressEventQueue clear];
}


@end