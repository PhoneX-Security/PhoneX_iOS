//
// Created by Dusan Klinec on 04.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXBlockThread : NSThread
@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic, copy) dispatch_block_t completionBlock;

- (instancetype)initWithBlock:(dispatch_block_t)block;
- (instancetype)initWithBlock:(dispatch_block_t)block completionBlock:(dispatch_block_t)completionBlock;

+ (instancetype)threadWithBlock:(dispatch_block_t)block completionBlock:(dispatch_block_t)completionBlock;
+ (instancetype)threadWithBlock:(dispatch_block_t)block;

@end