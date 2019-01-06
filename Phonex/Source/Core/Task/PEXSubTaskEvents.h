//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"
#import "PEXSubTask.h"
#import "PEXTaskFinishedEvent.h"

@interface PEXSubTaskFinishedEvent : PEXTaskFinishedEvent
@property (nonatomic) int taskId;
@property (nonatomic, weak) PEXSubTask * task;

- (NSString *)description;
@end
