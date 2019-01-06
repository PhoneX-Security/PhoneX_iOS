//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

// Maximum number of concurrently running RSA threads in the RSA key gen manager.
#define PEX_MAX_RSA_KEYGEN_THREADS 1

@class PEXCertGenKeyGenTaskThread;

/**
* Manager for generating RSA keys, holds RSA key gen tasks
* so only a few RSA keys are generated at time.
*
* TODO: refactor to behave like generator pool.
*/
@interface PEXCertKeyGeneratorManager : NSObject {}
@property (nonatomic) dispatch_semaphore_t genSemaphore;

+ (PEXCertKeyGeneratorManager *) instance;

/**
* Creates a new generator thread if current state allows it.
* Once thread has finished, it is removed from manager object.
*
* Returns nil if no thread can be assigned from pool after waitTime
* passed.
*/
- (PEXCertGenKeyGenTaskThread *)getNewGenerator: (dispatch_time_t) waitTime;

/**
* Wait method for obtaining a generator from pool.
*/
- (int) getNewGeneratorWithWait: (dispatch_time_t)semWaitTime timeout:(NSTimeInterval)timeout
                      doRunLoop:(BOOL)doRunLoop
                         result:(PEXCertGenKeyGenTaskThread**) pThread
                    cancelBlock:(BOOL (^)())cancelBlock;
@end
