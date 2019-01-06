//
// Created by Dusan Klinec on 31.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjExecutor.h"
#import "PEXConcurrentRingQueue.h"

@interface PEXPjExecutor() {
    // Concurrent job queue.
    PEXConcurrentRingQueue *_jobQueue;

    // PJSIP worker thread.
    NSThread *_pjThread;

    // Condition to signalize availability.
    NSCondition *_pjThreadCond;

    // Singaling variable to stop thread from running.
    volatile BOOL _pjThreadRunning;
}
@end

@implementation PEXPjExecutor {

}

- (void) startExecutor: (dispatch_queue_t) jobQueue {
    _pjThreadRunning = YES;
    _jobQueue = [[PEXConcurrentRingQueue alloc] initWithQueue:jobQueue capacity:32];
    _pjThreadCond = [[NSCondition alloc] init];

    _pjThread = [[NSThread alloc] initWithTarget:self selector:@selector(pjThreadMain:) object:nil];
    [_pjThread start];
}

- (void) stopExecutor {
    // Signalize stop so thread finishes ASAP.
    // Note that if current job is being executed it may take a while to really quit.
    [_pjThreadCond lock];
    _pjThreadRunning = NO;
    [_pjThreadCond signal];
    [_pjThreadCond unlock];
    DDLogVerbose(@"Stop executor signaled");
}

- (BOOL) isRunning {
    return _pjThreadRunning;
}

- (void)dealloc {
    [self stopExecutor];
}

- (void) addJobAsync: (BOOL) async name: (NSString *) name block: (dispatch_block_t) block {
    if (!_pjThreadRunning){
        DDLogError(@"Executor is not running!");
        return;
    }

    PEXPjJobEntry * job = [[PEXPjJobEntry alloc] init];
    job.isFinished = NO;
    job.isCancelled = NO;
    job.async = async;
    job.block = block;
    job.name = name;
    job.finishSemaphore = nil;

    if (!async) {
        job.finishSemaphore = dispatch_semaphore_create(0);
    }

    // Insert a new job to the queue and signal insertion to the worker thread.
    [_pjThreadCond lock];
    [_jobQueue pushBack:job async:NO];
    [_pjThreadCond signal];
    [_pjThreadCond unlock];

    if (!async){
        dispatch_semaphore_wait(job.finishSemaphore, DISPATCH_TIME_FOREVER);
    }
}

- (void)pjThreadMain:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"pjWork"];
        DDLogDebug(@"PJExecutor thread started");

        // Work loop.
        while(_pjThreadRunning){ @autoreleasepool {
            PEXPjJobEntry * job = nil;
            BOOL signaled = NO;

            // Maximum wait time in condition wait is x seconds so we dont deadlock (soft deadlock).
            NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow: 3.000];

            // <critical_section> monitor queue, poll one job from queue.
            [_pjThreadCond lock];
            {
                // If queue is empty, wait for insertion signal.
                if ([_jobQueue isEmpty]) {
                    // Wait signaling, note mutex is atomically unlocked while waiting.
                    // CPU cycles are saved here since thread blocks while waiting for new jobs.
                    signaled = [_pjThreadCond waitUntilDate:timeoutDate];
                }

                // Check job queue again.
                job = [_jobQueue popFront];
            }
            [_pjThreadCond unlock];
            // </critical_section>

            // If signaling ended with command to quit.
            if (!_pjThreadRunning){
                break;
            }

            // Job may be nil. If is, continue with waiting.
            if (job == nil || job.isCancelled){
                continue;
            }

            // Execute block here, in try-catch to protect executor from fails.
            @try {
                job.block();
            } @catch(NSException * e){
                DDLogError(@"Job execution exception=%@", e);
            }

            // Job is finished. If async, signalize semaphore.
            job.isFinished = YES;
            if (!job.async && job.finishSemaphore != nil){
                dispatch_semaphore_signal(job.finishSemaphore);
            }
        }}

        DDLogDebug(@"PJExecutor thread stopped");
    }
}

@end

@implementation PEXPjJobEntry
@end
