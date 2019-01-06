//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskContainer.h"
#import "PEXSubTask.h"
#import "PEXTask_Protected.h"
#import "PEXSubTaskEvents.h"
#import "PEXTaskContainerEvents.h"
#import "PEXBlockThread.h"
#import "PEXUtils.h"

// Private part of the PEXCertGenTask
@interface PEXTaskContainer ()  {
    // Semaphore for waiting for tasks to finish.
    dispatch_semaphore_t _semFinished;
}
@end

@implementation PEXTaskContainer
- (int)getNumSubTasks {
    return _tasks == nil ? 0 : (int)_tasks.count;
}

- (int)getMaxTask {
    return [self getNumSubTasks];
}

- (void)setSubTask:(PEXSubTask *)task id:(uint)id1 {
    if (task==nil){
        DDLogError(@"Task is nil");
        return;
    }

    [task setId:id1];
    [_tasks insertObject:task atIndex:id1];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.prepared = NO;

        // Initialize custom operation queue for particular purpose - certgen.
        self.opqueue = [[NSOperationQueue alloc] init];

        // Reset task array
        self.tasks = [[NSMutableArray alloc] init];

        // Initialize finished semaphore.
        _semFinished = dispatch_semaphore_create(0);

        // Default finish event is nil.
        self.finishedEvent = nil;
        self.doRunloopWait = YES;
        self.lastTaskStartedId = -1;
        self.lastTaskFinishedId = -1;
        self.runThread = nil;
        self.errorsDict = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (int64_t) getCurrentTotalProgressUnitCount {
    int64_t acc = 0;
    if (_tasks == nil) {
        return acc;
    }

    int numtasks = [self getMaxTask];
    if (numtasks > _tasks.count){
        numtasks = _tasks.count;
    }

    for(int idtask = 0; idtask < numtasks; ++idtask) {
        if (_tasks[idtask] == NULL) {
            continue;
        }

        acc += [_tasks[idtask] progressUnit];
    }

    return acc;
}

- (void) prepareForPerform {
    if (self.prepared){
        DDLogWarn(@"Already prepared");
        return;
    }

    // Remove all errors from previous invocations.
    [self.errorsDict removeAllObjects];

    // Construct sub-tasks.
    [self prepareSubTasks];

    // Initialize progress.
    int numtasks = [self getMaxTask];
    int64_t totalProgressUnitCount = [self getCurrentTotalProgressUnitCount];
    [self prepareProgress: totalProgressUnitCount];

    // Update number of tasks for progress.
    self.progress.totalUnitCount = totalProgressUnitCount;

    // Add tasks to the queue - starts execution of a task.
    int idtask = 0;
    if (numtasks > _tasks.count){
        numtasks = _tasks.count;
    }

    for(; idtask < numtasks; idtask++){
        if (_tasks[idtask]==NULL) {
            continue;
        }

        // Become current progress, Subtask should now register its progress.
        [self.progress becomeCurrentWithPendingUnitCount: [_tasks[idtask] progressUnit]];

        // Initialize child's NSProgress in this thread so it is connected to our NSPogress.
        [_tasks[idtask] prepareProgress];

        // Resign current progress from main.
        [self.progress resignCurrent];
    }

    self.prepared=YES;
}

- (void) perform {
    // Prepare of not already.
    if (!self.prepared){
        [self prepareForPerform];
    }

    // Add tasks to queue for execution.
    // Starts task execution.
    [self startExecution];

    // Wait for cancellation - semaphore indication.
    // Tasks are running on a newly created background queue, thus main operation has
    // to wait until it is finished. Meanwhile, cancellation is checked, progress
    // can be updated and so on...
    int waitResult = [self waitForSubTasks:-1];

    [self subTasksFinished:waitResult];
    DDLogVerbose(@"End of waiting loop");

    [super perform];
}

- (void)prepareSubTasks {

}

- (void)subTasksCancelled {

}

- (BOOL)shouldCancel {
    return [self isCancelled] || (self.progress!=nil && self.progress.isCancellable && self.progress.isCancelled);
}

- (void)subTasksFinished:(int)waitResult {

}

- (void)startExecution {
    int numtasks = [self getMaxTask];
    [_opqueue setSuspended:YES];

    DDLogVerbose(@"Going to start %d tasks for %@, curOps=%d, maxOps=%d, qname=%@, suspended=%d", numtasks, self.taskName,
            (int)_opqueue.operationCount, (int)_opqueue.maxConcurrentOperationCount, _opqueue.name,
            _opqueue.isSuspended);

    // Add tasks to the queue - starts execution of a task.
    int idtask = 0;
    if (numtasks > _tasks.count){
        numtasks = _tasks.count;
    }

    for(; idtask < numtasks; idtask++){
        if (_tasks[idtask]==NULL) {
            continue;
        }

        // Add task to the queue.
        [_opqueue addOperation:_tasks[idtask]];
    }

    // Start execution now.
    [_opqueue setSuspended:NO];

    [self started:nil];
    DDLogVerbose(@"Execution started for task: %@, susp=%d, curOps=%d,%d", self.taskName, _opqueue.isSuspended,
            (int)_opqueue.operationCount, (int)_opqueue.operations.count);
}

- (void)startOnBackground {
    [self performSelectorInBackground:@selector(start) withObject:nil];
}

- (void)startOnBackgroundThread {
    __weak PEXTaskContainer * weakSelf = self;
    self.runThread = [PEXBlockThread threadWithBlock:^{
        DDLogVerbose(@"<start_on_background_thread id=%@>", weakSelf.taskName);
        [weakSelf start];
        DDLogVerbose(@"</start_on_background_thread id=%@>", weakSelf.taskName);
    }];

    [self.runThread start];
}

- (int)waitForSubTasks: (NSTimeInterval) timeout {
    // Wait for cancellation - semaphore indication.
    // Tasks are running on a newly created background queue, thus main operation has
    // to wait until it is finished. Meanwhile, cancellation is checked, progress
    // can be updated and so on...
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 25ull * 1000000ull);
    NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];

    BOOL alreadyCancelled = NO;
    for(;[loopUntil timeIntervalSinceNow] > 0;){
        int64_t semResult = dispatch_semaphore_wait(_semFinished, tdeadline);
        if (semResult==0){
            DDLogVerbose(@"Main semaphore signalize, quitting");
            break;
        }

        if (_doRunloopWait) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        // If cancelled - cancel the whole queue.
        // Still has to wait on semaphore signaling.
        if (alreadyCancelled == NO && [self shouldCancel]){
            DDLogVerbose(@"Job is cancelled");

            // Do not repeat this cancellation check.
            alreadyCancelled = YES;

            // Call cancelAllOperations.
            [self.opqueue cancelAllOperations];

            // Notify
            [self subTasksCancelled];

            // Progress monitoring to parent.
            [self cancelStarted:NULL];
        }
    }

    if (alreadyCancelled) return kWAIT_RESULT_CANCELLED;                    // Cancelled.
    if ([loopUntil timeIntervalSinceNow]<=0) return kWAIT_RESULT_TIMEOUTED; // Timeouted.
    return kWAIT_RESULT_FINISHED;
}

- (void)prepareProgress:(int64_t)totalUnitCount {
    // Initialize a new progress.
    if (totalUnitCount<=0) {
        self.progress = [[NSProgress alloc] initWithParent:[NSProgress currentProgress] userInfo:nil];
    } else {
        self.progress = [NSProgress progressWithTotalUnitCount:totalUnitCount];
    }
}

- (NSString *)getTaskKey {
    return self.taskName;
}

- (void) startedProtected {
    [super startedProtected];
}

- (void) endedProtected {
    [self ended:self.finishedEvent];
}

- (void) performCancel
{
    //_result = PEX_LOGIN_TASK_CANCELLED;
    DDLogVerbose(@"Cancelling");

    // TODO: implement proper cancellation.


    [self cancelStarted:nil];
    [NSThread sleepForTimeInterval:1.0];

    [self cancelProgressed:nil];

    [NSThread sleepForTimeInterval:1.0];
    _unsuccessful = true;
    [self cancelEnded:nil];
}

- (BOOL) shouldFinishOnTaskFinished: (const PEXTaskEvent *const)event{
    return [self shouldCancel];
}

- (void)taskStarted:(const PEXTaskEvent *const)event {
    if (event==nil){
        DDLogError(@"Event is nil, not compatible");
        return;
    }

    const PEXSubTaskFinishedEvent * const finishedEvent = (const PEXSubTaskFinishedEvent * const) event;
    int id = [finishedEvent taskId];
    DDLogVerbose(@"Task started, id=%d, task=%@", id, self.taskName);

    // Progress monitoring.
    int lastTask = self.lastTaskStartedId;
    if (lastTask < id) {
        self.lastTaskStartedId = id;
    }

    // Send taskProgress to the parent listener.
    // This supports very basic progress monitoring for parent controller.
    // It sees the task that started its execution. Started event
    // is just a special case of progressed event here, for simplicity.
    PEXTaskProgressedEvent * evt = [[PEXTaskProgressedEvent alloc] init];
    evt.timestampMilli = [[NSDate date] timeIntervalSince1970];
    evt.started = YES;
    evt.container = self;
    evt.subTask = self.tasks[id];
    evt.subTaskId = id;
    [self progressed:evt];

    // TODO: Add localized description to the progress?
    // New task was started, this is the newest from the parallel task.
    // Maybe use getTaskKey to identify progress string from resources.
    // Parent can set final progress by harvesting child progress data.
}

- (void)taskEnded:(const PEXTaskEvent *const)event {
    if (event==nil){
        DDLogError(@"Event is nil, not compatible");
        return;
    }

    PEXSubTaskFinishedEvent * finishedEvent = (PEXSubTaskFinishedEvent *) event;
    int id = [finishedEvent taskId];
    DDLogVerbose(@"Tasks finished: %d", id);

    // Progress monitoring.
    int lastTask = self.lastTaskFinishedId;
    if (lastTask < id){
        self.lastTaskFinishedId = id;
    }

    // Send taskProgress to the parent listener.
    // This supports very basic progress monitoring for parent controller.
    // It sees the task that started its execution. Finished event
    // is just a special case of progressed event here, for simplicity.
    PEXTaskProgressedEvent * evt = [[PEXTaskProgressedEvent alloc] init];
    evt.timestampMilli = [[NSDate date] timeIntervalSince1970];
    evt.finished = YES;
    evt.finishEvent = finishedEvent;
    evt.container = self;
    evt.subTask = self.tasks[id];
    evt.subTaskId = id;

    // Task can harvest error from subtask.
    if ([finishedEvent finishState] != PEX_TASK_FINISHED_OK){
        DDLogVerbose(@"Task finished with error or cancelled. State=%d, error=%@", [finishedEvent finishState], [finishedEvent finishError]);

        // If there is some finish error, store it to the dictionary for given subtask.
        if (finishedEvent.finishState == PEX_TASK_FINISHED_ERROR && finishedEvent.finishError != nil){
            __weak PEXTaskContainer * weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.errorsDict[@(id)] = finishedEvent.finishError;
            });
        }
    }

    [self progressed:evt];

    // Final task - signalize finished process.
    PEXSubTask * curTask = _tasks[id];
    if ((curTask!=nil && [curTask isLast]) || [self shouldFinishOnTaskFinished:event]){
        DDLogVerbose(@"Tasks finished, signaling semaphore");
        dispatch_semaphore_signal(_semFinished);
    }
}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}


@end