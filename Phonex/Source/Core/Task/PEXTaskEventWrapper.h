//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

/**
 * Useful for wrapping blocks and redirecting task events into them.
 */
@interface PEXTaskEventWrapper : NSObject <PEXTaskListener>
@property(nonatomic, copy) void (^startedBlock)(const PEXTaskEvent *const);
@property(nonatomic, copy) void (^endedBlock)(const PEXTaskEvent *const);
@property(nonatomic, copy) void (^progressedBlock)(const PEXTaskEvent *const);
@property(nonatomic, copy) void (^cancelStartedBlock)(const PEXTaskEvent *const);
@property(nonatomic, copy) void (^cancelEndedBlock)(const PEXTaskEvent *const);
@property(nonatomic, copy) void (^cancelProgressedBlock)(const PEXTaskEvent *const);

- (instancetype)initWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock;
+ (instancetype)wrapperWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock;

- (instancetype)initWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                      startedBlock:(void (^)(PEXTaskEvent const *const))startedBlock;
+ (instancetype)wrapperWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                         startedBlock:(void (^)(PEXTaskEvent const *const))startedBlock;

- (instancetype)initWithStartedBlock:(void (^)(PEXTaskEvent const *const))startedBlock
                          endedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                     progressedBlock:(void (^)(PEXTaskEvent const *const))progressedBlock
                  cancelStartedBlock:(void (^)(PEXTaskEvent const *const))cancelStartedBlock
                    cancelEndedBlock:(void (^)(PEXTaskEvent const *const))cancelEndedBlock
               cancelProgressedBlock:(void (^)(PEXTaskEvent const *const))cancelProgressedBlock;

+ (instancetype)wrapperWithStartedBlock:(void (^)(PEXTaskEvent const *const))startedBlock
                             endedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                        progressedBlock:(void (^)(PEXTaskEvent const *const))progressedBlock
                     cancelStartedBlock:(void (^)(PEXTaskEvent const *const))cancelStartedBlock
                       cancelEndedBlock:(void (^)(PEXTaskEvent const *const))cancelEndedBlock
                  cancelProgressedBlock:(void (^)(PEXTaskEvent const *const))cancelProgressedBlock;
@end