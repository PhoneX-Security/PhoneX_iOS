//
// Created by Dusan Klinec on 02.11.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXBackGroundTask : NSObject

// Properties
@property (nonatomic) NSString * name;
@property (nonatomic) dispatch_block_t expirationHandler;

// Internal state
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic) NSDate * backgroundTaskStart;

- (instancetype)initWithName:(NSString *)name expirationHandler:(dispatch_block_t)expirationHandler;
- (instancetype)initWithName:(NSString *)name;

+ (instancetype)taskWithName:(NSString *)name;
+ (instancetype)taskWithName:(NSString *)name expirationHandler:(dispatch_block_t)expirationHandler;

- (BOOL) start;
- (BOOL) start: (dispatch_block_t) expirationHandler;
- (BOOL) stop;

@end