//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertRefreshTaskState.h"
#import "hr.h"

@implementation PEXCertRefreshTaskState
- (instancetype)init {
    self = [super init];
    if (self) {
        self.callProgress = nil;
        self.requests = @[];
        self.responses = [[NSMutableDictionary alloc] init];
        self.overallTaskState = PEX_TASK_FINISHED_NA;
        self.soapTaskFinishState = PEX_TASK_FINISHED_NA;
        self.soapTaskError = nil;
    }

    return self;
}

@end