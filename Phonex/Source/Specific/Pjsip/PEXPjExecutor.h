//
// Created by Dusan Klinec on 31.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXPjJobEntry : NSObject
@property (nonatomic) NSString * name;
@property (nonatomic, strong) dispatch_block_t block;
@property (nonatomic, strong) dispatch_semaphore_t finishSemaphore;
@property (nonatomic) volatile BOOL isFinished;
@property (nonatomic) volatile BOOL isCancelled;
@property (nonatomic) BOOL async;
@end

@interface PEXPjExecutor : NSObject
- (void) startExecutor: (dispatch_queue_t) jobQueue;
- (void) stopExecutor;
- (BOOL) isRunning;
- (void) addJobAsync: (BOOL) async name: (NSString *) name block: (dispatch_block_t) block;

@end