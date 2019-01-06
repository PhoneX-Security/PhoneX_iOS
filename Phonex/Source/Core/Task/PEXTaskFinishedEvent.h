//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"

typedef enum PEX_TASK_FINIHED_STATE {
    PEX_TASK_FINISHED_NA=0,
    PEX_TASK_FINISHED_OK=1,
    PEX_TASK_FINISHED_CANCELLED=2,
    PEX_TASK_FINISHED_ERROR=3
}PEX_TASK_FINIHED_STATE;

@interface PEXTaskFinishedEvent : PEXTaskEvent

/**
 * Eventual finish state the task finished with.
 * Can be either OK, cancelled or finished with error.
 */
@property (nonatomic) PEX_TASK_FINIHED_STATE finishState;

/**
 * In case the task finished with error, this may contain
 * additional useful information about error itself.
 */
@property (nonatomic) NSError * finishError;

- (id) initWithState: (PEX_TASK_FINIHED_STATE) state;
- (BOOL) didFinishOK;
- (BOOL) didFinishCancelled;
- (BOOL) didFinishWithError;
- (NSString *)description;
@end