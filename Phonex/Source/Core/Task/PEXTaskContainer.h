//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"
#import "PEXSystemUtils.h"
#import "PEXSubTask.h"
#import "PEXTaskFinishedEvent.h"
#import "PEXBlockThread.h"

@interface PEXTaskContainer : PEXTask <PEXTaskListener>
// Implements NSProgress conventions for this task.
@property (nonatomic) NSProgress * progress;
// Serial operation queue, executes tasks on background.
@property (nonatomic) NSOperationQueue * opqueue;
// Progress monitoring - last finished task id.
@property (atomic) int lastTaskFinishedId;
// Progress monitoring - last started task id.
@property (atomic) int lastTaskStartedId;
// Container for all tasks that need to be executed.
@property (nonatomic) NSMutableArray * tasks;
// Task container name.
@property (nonatomic) NSString * taskName;
@property (nonatomic) BOOL doRunloopWait;
@property (nonatomic) PEXBlockThread * runThread;
@property (nonatomic) BOOL prepared;
@property (nonatomic) PEXTaskFinishedEvent * finishedEvent;
@property (nonatomic) NSMutableDictionary * errorsDict;

/**
 * Initializes progress so it can be called on the thread with existing current
 * progress.
 */
-(void)prepareProgress: (int64_t) totalUnitCount;

/**
* Returns total progress unit count.
* By default, this is returns a summation of the progressUnit fields
* in SubTasks in task array.
*/
- (int64_t) getCurrentTotalProgressUnitCount;

/**
* Returns task string key. Can be used for example for progress monitoring.
* Uses parent's task key.
*/
- (NSString *) getTaskKey;

/**
 * Returns total number of the subtasks - constant.
 */
-(int) getNumSubTasks;

/**
 * Initialize tasks for execution.
 * Abstract. Should be overridden to init and add tasks to queue.
 */
-(void) prepareSubTasks;

/**
 * Starts execution of a prepared tasks.
 * Used to add all initialized tasks to queue and starts execution on them.
 */
-(void) startExecution;

/**
* Starts execution on background, avoids GCD.
*/
-(void) startOnBackground;

/**
* Starts execution on background, avoids GCD, uses own thread.
*/
-(void) startOnBackgroundThread;

/**
* Prepares for perform run.
* Initializes progress tree. If not called, will be called on perform.
* Should be called by the user before starting execution.
*/
-(void) prepareForPerform;

/**
 * Called if cancel event was detected.
 * After cancelling op queue. Callback hook.
 */
-(void) subTasksCancelled;

/**
* Returns true if this task should cancel its operation.
*/
-(BOOL) shouldCancel;

/**
* If returns true, the waiting blocking operation will finish.
* By default returns true when operation was cancelled. Can be used by
* derived classes to control cancellation process better.
*/
- (BOOL) shouldFinishOnTaskFinished: (const PEXTaskEvent *const)event;

/**
 * Waits for asynchronous jobs to get finished.
 * Responds to cancellation event form task and from progress objects.
 */
-(int) waitForSubTasks: (NSTimeInterval) timeout;

/**
 * Called when wait is finished.
 * Abstract.
 */
-(void) subTasksFinished: (int) waitResult;

/**
 * Sets s sub task to the task array with given id.
 */
-(void) setSubTask: (PEXSubTask*) task id: (uint) id;

/**
 * Get current number of tasks. Current = in this scenario, how many tasks
 * will be executed since start till end.
 */
-(int) getMaxTask;
@end