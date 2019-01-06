//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskEventWrapper.h"


@implementation PEXTaskEventWrapper {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.startedBlock=nil;
        self.cancelEndedBlock=nil;
        self.cancelProgressedBlock=nil;
        self.cancelStartedBlock=nil;
        self.endedBlock=nil;
        self.progressedBlock=nil;
    }

    return self;
}

- (instancetype)initWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock {
    self = [self init];
    if (self) {
        self.endedBlock = endedBlock;
    }

    return self;
}

- (instancetype)initWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                      startedBlock:(void (^)(PEXTaskEvent const *const))startedBlock {
    self = [self init];
    if (self) {
        self.endedBlock = endedBlock;
        self.startedBlock = startedBlock;
    }

    return self;
}

- (instancetype)initWithStartedBlock:(void (^)(PEXTaskEvent const *const))startedBlock
                          endedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                     progressedBlock:(void (^)(PEXTaskEvent const *const))progressedBlock
                  cancelStartedBlock:(void (^)(PEXTaskEvent const *const))cancelStartedBlock
                    cancelEndedBlock:(void (^)(PEXTaskEvent const *const))cancelEndedBlock
               cancelProgressedBlock:(void (^)(PEXTaskEvent const *const))cancelProgressedBlock
{
    self = [self init];
    if (self) {
        self.startedBlock = startedBlock;
        self.endedBlock = endedBlock;
        self.progressedBlock = progressedBlock;
        self.cancelStartedBlock = cancelStartedBlock;
        self.cancelEndedBlock = cancelEndedBlock;
        self.cancelProgressedBlock = cancelProgressedBlock;
    }

    return self;
}

+ (instancetype)wrapperWithStartedBlock:(void (^)(PEXTaskEvent const *const))startedBlock
                             endedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                        progressedBlock:(void (^)(PEXTaskEvent const *const))progressedBlock
                     cancelStartedBlock:(void (^)(PEXTaskEvent const *const))cancelStartedBlock
                       cancelEndedBlock:(void (^)(PEXTaskEvent const *const))cancelEndedBlock
                  cancelProgressedBlock:(void (^)(PEXTaskEvent const *const))cancelProgressedBlock {
    return [[self alloc] initWithStartedBlock:startedBlock endedBlock:endedBlock progressedBlock:progressedBlock cancelStartedBlock:cancelStartedBlock cancelEndedBlock:cancelEndedBlock cancelProgressedBlock:cancelProgressedBlock];
}

+ (instancetype)wrapperWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock
                         startedBlock:(void (^)(PEXTaskEvent const *const))startedBlock {
    return [[self alloc] initWithEndedBlock:endedBlock startedBlock:startedBlock];
}


+ (instancetype)wrapperWithEndedBlock:(void (^)(PEXTaskEvent const *const))endedBlock {
    return [[self alloc] initWithEndedBlock:endedBlock];
}

- (void)taskStarted:(const PEXTaskEvent *const)event {
    if (self.startedBlock!=nil){
        self.startedBlock(event);
    }
}

- (void)taskEnded:(const PEXTaskEvent *const)event {
    if (self.endedBlock!=nil){
        self.endedBlock(event);
    }
}

- (void)taskProgressed:(const PEXTaskEvent *const)event {
    if (self.progressedBlock!=nil){
        self.progressedBlock(event);
    }
}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {
    if (self.cancelStartedBlock!=nil){
        self.cancelStartedBlock(event);
    }
}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {
    if (self.cancelEndedBlock!=nil){
        self.cancelEndedBlock(event);
    }
}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {
    if (self.cancelProgressedBlock!=nil){
        self.cancelProgressedBlock(event);
    }
}

@end