//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"


/**
* NSOperation extension.
* Designed to be used as a sub-task in PEXTaskContainer.
*
* Supports progress monitoring via NSProgress. prepareProgress has
* to be called from the same thread where parent NSProgress was selected
* as current.
*
* Cancellation is supported via NSOperation cancel and NSProgress cancel.
*/
@interface PEXSubTask : NSOperation <PEXTaskListener> { }
@property (nonatomic) NSString * parentTaskName;

/**
 * Unique string identifier of this task. Used in logs, may be used for loading
 * localized progress strings related to this task.
 */
@property (nonatomic) NSString * taskName;

/**
 * Progress used for monitoring in the subtask.
 * Manipulated in prepareProgress, finishProgress and other helper methods.
 */
@property (nonatomic) NSProgress * progress;

/**
* Number of progress units for this subTask. By default set to 1, but can change
* to reflect a fact that some subtasks takes longer than others.
* Progress unit total count in container task is derived by summing over all subtasks on this field.
*/
@property (nonatomic) NSInteger progressUnit;

/**
 * In case of an error this may contain additional helper information.
 */
@property (nonatomic) NSError * error;

/**
 * Unique numeric identifier of the task. It must correspond to an index
 * in the tasks array. Parent know this task under this id.
 */
@property (nonatomic) int id;

/**
 * Flag says if this task was cancelled.
 */
@property (nonatomic) BOOL cancelDetected;

/**
 * Flag says if this task finished with error.
 */
@property (nonatomic) BOOL finishedWithError;

/**
 * Controlling flag. If set to true, the main execution body is skipped.
 */
@property (nonatomic) BOOL skip;

/**
 * Flag signaling this task is the last in the tasks array.
 * After this task finishes, parent can stop waiting for finishing.
 * Sets and controlls parent.
 */
@property (nonatomic) BOOL isLast;

/**
 * Delegate for task progress monitoring.
 * Receives progress updates, namely {taskStarted, taskFinished}.
 */
@property (nonatomic, weak) id <PEXTaskListener> delegate;

/**
* If set to true, this task will run in spite of cancel was detected.
* Helpful for cancellation task workflow.
*/
@property (nonatomic) BOOL runAnyway;

/**
 * Constructor, providing delegate and task name.
 */
- (id) initWith:(id <PEXTaskListener>)delegate andName: (NSString *) taskName;

/**
* This creates a new progress object. Has to be called on thread that adds
* this operation to the queue or calls start method, i.e., thread that set
* parent NSProgress as current.
*/
- (void) prepareProgress;

/**
 * Sets current progress as finished.
 */
- (void) finishProgress;
- (void) finishProgressCancelled: (BOOL) wasCancelled;

/**
 * Returns task string key. Can be used for example for progress monitoring.
 * Uses parent's task key.
 */
- (NSString *) getTaskKey;

/**
 * Performs internal maintenance, called on cancel detected event by user code.
 * Progress is finished, cancelDetected set to true.
 */
- (void) subCancel;

/**
 * Performs internal maintenance called on error by user code. Only valid if finishedWithError==YES.
 * Progress is finished, finishedWithError set to true, error set to object if not nil.
 */
-(void) subError: (NSError *) error;

/**
 * Abstract. Main worker method.
 * Has to be overridden by subclass.
 */
- (void) subMain;

/**
 * Cancellation block.
 * If not nil, this block is called to determine another cancellation signal status, when
 * shouldCancel method is called. If block returns true, shouldCancel returns true.
*/
@property (nonatomic, copy) BOOL (^shouldCancelBlock)(const PEXSubTask * const task);

/**
 * Main method for cancel detection, designed to be used by user application code to react to cancellation.
 * Takes skip and progress cancellation into account. Subclass can inherit and extend this cancel detection.
 * Includes shouldCancelBlock if is not nil.
 */
- (BOOL) shouldCancel;

/**
* Checks cancellation condition.
* If cancellation was triggered (calls shouldCancel), subCancel is called and cancellation exception is thrown.
*/
- (void) checkCancelDoItAndThrow;

/**
* Checks cancellation condition.
* If cancellation was triggered (calls shouldCancel), cancellation exception is thrown.
*/
- (void) checkCancelAndThrow;

/**
 * Ensures the given block will be executed on main thread.
 */
- (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block;

/**
 * Finishes the progress on main thread. Sets completedUnitCount to totalUnitCount.
 */
- (void) finishProgressOnMain: (BOOL) wasCancelled async: (BOOL) async;

/**
 * Sets progress object on the main thread.
 */
- (void) setProgressOnMain: (int) maxCount completedCount: (int) completedCount async: (BOOL) async;

/**
 * Set completedUnitCount of progress object on the main thread.
 */
- (void) updateProgressOnMain: (int) completedCount async: (BOOL) async;

/**
 * Increments completedUnitCount of progress object by given delta.
 */
- (void) incProgressOnMain: (int) delta async: (BOOL) async;

- (void)finishProgress: (BOOL) wasCancelled;
- (void)setProgress:(int)maxCount completedCount:(int)completedCount;
- (void)updateProgress: (int)completedCount;
- (void)incProgress: (int)delta;
@end

@interface PEXOperationCancelledException : NSException
@end