//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskBlock.h"
#import "PEXTask_Protected.h"

// Add state to the class property.
@interface PEXTaskBlock () {}
@property(nonatomic) PEXTaskBlockState * state;
@end

// State implementation.
@implementation PEXTaskBlockState {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.errorOccurred = NO;
        self.cancelDetected = NO;
    }

    return self;
}

@end

// Subtask.
@implementation PEXBlockSubtask {}
- (id) initWithDel:(PEXTaskBlock *)delegate andName: (NSString *) taskName andBlock: (pex_task_block) block
  andCompleteBlock: (pex_task_block) completeBlock
{
    self = [super initWith:delegate andName:taskName];
    self.delegate = delegate;
    self.ownDelegate = delegate;
    self.state = [delegate state];
    self.block = block;
    self.completeBlock = completeBlock;
    return self;
}

-(void) subCancel {
    [super subCancel];
    self.state.cancelDetected=YES;
}

- (void)subError:(NSError *)error {
    [super subError:error];
    self.state.errorOccurred = YES;
    self.state.lastError = error;
}

- (BOOL)shouldCancel {
    BOOL shouldCancel = [super shouldCancel];
    if (shouldCancel) return YES;

    return  self.state.errorOccurred || self.state.cancelDetected;
}

- (void)subMain {
    // Derive encryption keys and load stored identity, if any.
    if (self.block != nil){
        self.block(self);
    }

    if (self.completeBlock != nil){
        self.completeBlock(self);
    }
}

@end

@implementation PEXTaskBlock {

}

+ (pex_task_block)wrapBlock:(dispatch_block_t)block {
    return ^(PEXBlockSubtask *subtask) {
        if (block!=nil){
            block();
        }
    };
}

- (instancetype)initWithName:(NSString *)name block:(pex_task_block)block {
    self = [self init];
    if (self) {
        self.taskName = name;
        self.block = block;
    }

    return self;
}

- (int)getNumSubTasks {
    return 1;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)prepareSubTasks {
    [super prepareSubTasks];

    // Construct sub-tasks.
    [self setSubTask:[[PEXBlockSubtask alloc] initWithDel:self andName:self.taskName
                                                 andBlock:self.block andCompleteBlock:self.completeBlock] id:PBT_MAIN];

    // Add dependencies to the tasks.
    // ...

    // Mark last task so we know what to wait for.
    [self.tasks[PBT_MAIN] setIsLast:YES];
}

- (void)subTasksFinished:(int)waitResult {
    [super subTasksFinished:waitResult];

    PEXTaskFinishedEvent * finResult;
    // If was cancelled - signalize cancel ended.
    if (waitResult==kWAIT_RESULT_CANCELLED){
        [self cancelEnded:NULL];
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_CANCELLED];
    } else if (self.state.errorOccurred || waitResult==kWAIT_RESULT_TIMEOUTED) {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_ERROR];
        finResult.finishError = self.state.lastError;
    } else {
        finResult = [[PEXTaskFinishedEvent alloc] initWithState: PEX_TASK_FINISHED_OK];
    }

    self.finishedEvent = finResult;
    DDLogVerbose(@"End of waiting loop, task=%@.", self.taskName);
}

- (void)subTasksCancelled {
    [super subTasksCancelled];
    DDLogVerbose(@"Jobs were cancelled!");
}


@end