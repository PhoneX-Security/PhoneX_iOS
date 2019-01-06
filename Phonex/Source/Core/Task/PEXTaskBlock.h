//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskContainer.h"

@class PEXTaskBlock;
@class PEXBlockSubtask;

/**
* Type of a block to be executed.
* Specific type is defined so block can control cancellation, error and progress of the subtask
*/
typedef void (^pex_task_block)(PEXBlockSubtask * subtask);

/**
* ID of the block tasks.
*/
typedef enum PEXBlockTaskID : NSInteger {
    PBT_MAIN=0,
    PBT_MAX
} PEXBlockTaskID;

/**
* State for the block task.
*/
@interface PEXTaskBlockState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic, readwrite) NSError * lastError;
@end

/**
* Subtask parent - has internal state.
*/
@interface PEXBlockSubtask : PEXSubTask { }
@property (nonatomic, weak) pex_task_block block;
@property (nonatomic, weak) pex_task_block completeBlock;
@property (nonatomic, weak) PEXTaskBlockState * state;
@property (nonatomic, weak) PEXTaskBlock * ownDelegate;

- (id) initWithDel:(PEXTaskBlock *)delegate andName: (NSString *) taskName andBlock: (pex_task_block) block
  andCompleteBlock: (pex_task_block) completeBlock;
@end

/**
* Task container designated to store only one subtask.
*/
@interface PEXTaskBlock : PEXTaskContainer
@property(nonatomic, copy) pex_task_block block;
@property(nonatomic, copy) pex_task_block completeBlock;

/**
* Create a required block from ordinary no parameter block.
*/
+(pex_task_block) wrapBlock:(dispatch_block_t)block;

-(instancetype) initWithName: (NSString *) name block: (pex_task_block) block;
@end