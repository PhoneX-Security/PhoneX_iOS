//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskContainerEvents.h"


@implementation PEXTaskProgressedEvent

- (instancetype)init {
    self = [super init];
    if (self) {
        self.taskStage = nil;
        self.subTaskStage = nil;
        self.subTask = nil;
        self.subTaskEvent = nil;
        self.subTaskId = -1;
        self.userInfo = nil;
        self.container = nil;
        self.started = NO;
        self.finished = NO;
        self.finishEvent = nil;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.container=%@", self.container];
    [description appendFormat:@", self.subTask=%@", self.subTask];
    [description appendFormat:@", self.subTaskId=%i", self.subTaskId];
    [description appendFormat:@", self.started=%d", self.started];
    [description appendFormat:@", self.finished=%d", self.finished];
    [description appendFormat:@", self.taskStage=%@", self.taskStage];
    [description appendFormat:@", self.subTaskStage=%@", self.subTaskStage];
    [description appendFormat:@", self.subTaskEvent=%@", self.subTaskEvent];
    [description appendFormat:@", self.userInfo=%@", self.userInfo];
    [description appendString:@">"];
    return description;
}

- (double)cost {
    // This is for min heap (ASC), we want the most recent event to be displayed, thus bigger is better (DESC).
    return self.timestampMilli * (-1.0);
}


@end