//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertKeyGeneratorManager.h"
#import "PEXCertGenKeyGenTaskThread.h"
#import "PEXSystemUtils.h"

@interface PEXCertKeyGeneratorManager () {}

// Weak so parent holds the reference.
// Has to be weak because semaphore gets signalled on ARC release
// in case task was not started or finished.
@property (nonatomic, weak) PEXCertGenKeyGenTaskThread * thread;
@end

@implementation PEXCertKeyGeneratorManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.genSemaphore = dispatch_semaphore_create(PEX_MAX_RSA_KEYGEN_THREADS);
        if (PEX_MAX_RSA_KEYGEN_THREADS > 1) {
            DDLogError(@"ERROR: More than one generating thread is not yet supported");
        }
    }

    return self;
}


+ (PEXCertKeyGeneratorManager *)instance {
    static PEXCertKeyGeneratorManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (PEXCertGenKeyGenTaskThread *)getNewGenerator: (dispatch_time_t) waitTime {
    // Check if it is possible to create a new generator - try to lock a semaphore.
    int64_t semResult = dispatch_semaphore_wait(self.genSemaphore, waitTime);
    if (semResult != 0){
        // Semaphore was not acquired,
        return nil;
    }

    PEXCertGenKeyGenTaskThread * thread = [[PEXCertGenKeyGenTaskThread alloc] init];
    self.thread = thread;

    // Thread will signalize completion to the manager thread.
    // Warning: thread has to be started. Otherwise it wont be called.
    thread.managerDoneSemaphore = self.genSemaphore;
    return thread;
}

- (int) getNewGeneratorWithWait: (dispatch_time_t)semWaitTime timeout:(NSTimeInterval)timeout
                      doRunLoop:(BOOL)doRunLoop
                         result:(PEXCertGenKeyGenTaskThread**) pThread
                      cancelBlock:(BOOL (^)())cancelBlock
{
    if (pThread == NULL){
        DDLogError(@"Phtread is null. No place to put result to.");
        return kWAIT_RESULT_FINISHED;
    }

    NSDate *loopUntil = timeout < 0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
    for(;[loopUntil timeIntervalSinceNow] > 0;){
        // In this call we wait for self.genSemaphore.
        PEXCertGenKeyGenTaskThread * thread = [self getNewGenerator:semWaitTime];
        if (thread != nil){
            (*pThread) = thread;
            return kWAIT_RESULT_FINISHED;
        }

        if (doRunLoop){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        // If cancelled - cancel the whole queue.
        // Still has to wait on semaphore signaling.
        if (cancelBlock != nil && cancelBlock()){
            // Cancellation = 1;
            return kWAIT_RESULT_CANCELLED;
        }
    }

    // Loop apparently timeouted.
    return kWAIT_RESULT_TIMEOUTED;
}

@end