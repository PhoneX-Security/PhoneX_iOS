//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSubTask.h"
#import "PEXCertGenParams.h"
#import "PEXSubTaskEvents.h"
#import "PEXSystemUtils.h"


@implementation PEXSubTask {

}

- (id) init {
    if (self = [super init]){
        self.parentTaskName = nil;
        self.taskName = nil;
        self.skip = NO;
        self.isLast = NO;
        self.id = -1;
        self.delegate = nil;
        self.progress = nil;
        self.error = nil;
        self.cancelDetected = NO;
        self.finishedWithError = NO;
        self.runAnyway = NO;
        self.progressUnit = 1;
    }

    return self;
}

- (id) initWith:(id <PEXTaskListener>)delegate andName: (NSString *) taskName {
    self = [self init];
    self.taskName = taskName==nil ? nil : [taskName copy];
    self.delegate = delegate;
    return self;
}

- (void)prepareProgress {
    // This creates a new progress object. Has to be called on thread that adds
    // this operation to the queue or calls start method.
    self.progress = [NSProgress progressWithTotalUnitCount: 1];
}

- (void)finishProgress {
    [self finishProgressCancelled:NO];
}

- (NSString *)getTaskKey {
    if (self.parentTaskName!=nil && self.taskName!=nil){
        return [[NSString alloc] initWithFormat:@"%@_%@", self.parentTaskName, self.taskName];
    } else if (self.taskName!=nil) {
        return [self taskName];
    } else {
        return nil;
    }
}

- (void)finishProgressCancelled:(BOOL)wasCancelled {
    NSProgress * myProgress = self == nil ? nil : self.progress;
    if (myProgress == nil) {
        return;
    }

    myProgress.completedUnitCount = myProgress.totalUnitCount;
}

- (void) subMain {
    [NSException raise:@"AbstractMethodInvocationException" format:@"Error: calling abstract method"];
}

- (void) main {
    PEXSubTaskFinishedEvent * event = [[PEXSubTaskFinishedEvent alloc] init];
    event.task = self;
    event.taskId = self.id;

    // Report task start to a delegate.
    if (self.delegate!=nil){
        [self.delegate taskStarted: event];
    }

    // Work itself.
    if (!self.runAnyway && [self shouldCancel]){
        if (self.error == nil) {
            self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
        }

        DDLogVerbose(@"Task not starting, skip || error || cancelled @ %@", self.taskName);
    } else {
        DDLogVerbose(@"<task: %@>", self.taskName);
        [self subMain];
        DDLogVerbose(@"</task: %@>", self.taskName);
    }

    // NSProgress support - default behavior.
    [self finishProgress];

    // Report progress to a delegate - parent task container.
    // Kind of simulating completionBlock.
    if (self.delegate!=nil){
        // Report result of this subtask to the delegate.
        // Task can end wither with error, then pass latest error to the
        // parent via this event. Then task can be cancelled, or finished
        // without problems.
        if (self.finishedWithError){
            event.finishState = PEX_TASK_FINISHED_ERROR;
            event.finishError = self.error;
        } else if (self.cancelDetected){
            event.finishState = PEX_TASK_FINISHED_CANCELLED;
        } else {
            event.finishState = PEX_TASK_FINISHED_OK;
        }

        [self.delegate taskEnded: event];
    }
}

- (void) subCancel {
    DDLogVerbose(@"Cancel detected @ %@", self.taskName);

    // Add cancellation error if current error is empty.
    self.cancelDetected = YES;
    if (self.error==nil){
        self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    }

    // Finish progress by default.
    [self finishProgressOnMain:YES async:NO];
}

- (void)subError:(NSError *)error {
    DDLogVerbose(@"Error detected @ %@, error=%@", self.taskName, error);

    // Add cancellation error if current error is empty.
    self.finishedWithError = YES;
    if (error!=nil){
        self.error = error;
    }

    // Finish progress by default.
    [self finishProgressOnMain:YES async:NO];
}

- (BOOL)shouldCancel {
    BOOL doCancel = [self isCancelled] || self.skip
            || (self.progress!=nil && self.progress.isCancellable && self.progress.isCancelled);

    if (doCancel) return YES;
    if (self.shouldCancelBlock != nil) {
        return self.shouldCancelBlock(self);
    }

    return NO;
}

- (void)checkCancelDoItAndThrow {
    if (![self shouldCancel]) return;
    [self subCancel];
    [PEXOperationCancelledException raise:PEXOperationCancelledExceptionString format:@"Subtask was cancelled"];
}

- (void)checkCancelAndThrow {
    if (![self shouldCancel]) return;
    [PEXOperationCancelledException raise:PEXOperationCancelledExceptionString format:@"Subtask was cancelled"];
}

- (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block {
    [PEXSystemUtils executeOnMainAsync:async block:block];
}

- (void)finishProgressOnMain: (BOOL) wasCancelled async: (BOOL) async {
    [self executeOnMain: async block: ^{
        __strong __typeof__(self) strongSelf = self;
        if (strongSelf!=nil) {
            [strongSelf finishProgressCancelled: wasCancelled];
        }
    }];
}

- (void)setProgressOnMain:(int)maxCount completedCount:(int)completedCount async: (BOOL) async{
    [self executeOnMain: async block: ^{
        __strong NSProgress * myProgress = self == nil ? nil : self.progress;
        if (myProgress == nil){
            return;
        }

        myProgress.totalUnitCount = maxCount;
        myProgress.completedUnitCount = completedCount;
    }];
}

- (void)updateProgressOnMain: (int)completedCount async: (BOOL) async{
    [self executeOnMain: async block: ^{
        __strong NSProgress * myProgress = self == nil ? nil : self.progress;
        if (myProgress == nil){
            return;
        }

        myProgress.completedUnitCount = completedCount;
    }];
}

- (void)incProgressOnMain: (int)delta async: (BOOL) async{
    [self executeOnMain: async block: ^{
        __strong NSProgress * myProgress = self == nil ? nil : self.progress;
        if (myProgress == nil){
            return;
        }

        myProgress.completedUnitCount += delta;
    }];
}

- (void)finishProgress: (BOOL) wasCancelled {
    __strong __typeof__(self) strongSelf = self;
    if (strongSelf!=nil) {
        [strongSelf finishProgressCancelled: wasCancelled];
    }
}

- (void)setProgress:(int)maxCount completedCount:(int)completedCount {
    __strong NSProgress * myProgress = self == nil ? nil : self.progress;
    if (myProgress == nil){
        return;
    }

    myProgress.totalUnitCount = maxCount;
    myProgress.completedUnitCount = completedCount;
}

- (void)updateProgress: (int)completedCount {
    __strong NSProgress * myProgress = self == nil ? nil : self.progress;
    if (myProgress == nil){
        return;
    }

    myProgress.completedUnitCount = completedCount;
}

- (void)incProgress: (int)delta {
    __strong NSProgress * myProgress = self == nil ? nil : self.progress;
    if (myProgress == nil){
        return;
    }

    myProgress.completedUnitCount += delta;
}

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskEnded:(const PEXTaskEvent *const)event {

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

@implementation PEXOperationCancelledException
@end