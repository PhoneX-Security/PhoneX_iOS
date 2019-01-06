//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"
#import "PEXPriorityQueue.h"
#import "PEXTaskFinishedEvent.h"
#import "PEXSubTaskEvents.h"

@class PEXTaskContainer;
@class PEXSubTask;

@interface PEXTaskProgressedEvent : PEXTaskEvent <PEXPriorityQueueObject>
// Identifier, so observer knows who sent this.
// User can alo extract progress information from this object.
@property (nonatomic, weak) PEXTaskContainer * container;
// Informs which subtask is this event related to.
// Subtask progress may be extracted from this field.
@property (nonatomic, weak) PEXSubTask * subTask;
// Numerical id of the subtask in the given container.
@property (nonatomic) int subTaskId;

// If yes it says taskStarted generated this.
@property (nonatomic) BOOL started;
@property (nonatomic) BOOL finished;
@property (nonatomic) PEXSubTaskFinishedEvent * finishEvent;

// Timestamp in milliseconds of the event occurrence.
@property (nonatomic) NSTimeInterval timestampMilli;

// Progress stage of the container task.
// May have finer granularity here. May not be used if subTaskId is enough.
// Nullable.
@property (nonatomic) NSNumber * taskStage;

// Additional information about stage progress in the subtask.
// Nullable.
@property (nonatomic) NSNumber * subTaskStage;

// Opaque type for the started/progressed event from the subTask.
// May be null, sub task may invoked some action.
// Nullable.
@property (nonatomic) PEXTaskEvent * subTaskEvent;

// Dictionary for further expansion.
// Nullable.
@property (nonatomic) NSMutableDictionary * userInfo;

- (NSString *)description;

@end