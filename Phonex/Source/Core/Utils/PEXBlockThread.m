//
// Created by Dusan Klinec on 04.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXBlockThread.h"

@interface PEXBlockThread () {}
@end

@implementation PEXBlockThread {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.block = nil;
        self.completionBlock = nil;
    }

    return self;
}

- (instancetype)initWithBlock:(dispatch_block_t)block {
    self = [self init];
    if (self) {
        self.block = block;
    }

    return self;
}

+ (instancetype)threadWithBlock:(dispatch_block_t)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(dispatch_block_t)block completionBlock:(dispatch_block_t)completionBlock {
    self = [super init];
    if (self) {
        self.block = block;
        self.completionBlock = completionBlock;
    }

    return self;
}

+ (instancetype)threadWithBlock:(dispatch_block_t)block completionBlock:(dispatch_block_t)completionBlock {
    return [[self alloc] initWithBlock:block completionBlock:completionBlock];
}

/**
* This is invoked when main thread is started.
*/
- (void)main {
    @autoreleasepool {
        if (self.block != nil) {
            self.block();
        }

        if (self.completionBlock != nil) {
            self.completionBlock();
        }
    }
}

@end