//
// Created by Matej Oravec on 02/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"


@interface PEXDelayedTask : PEXTask

- (id)initWithEventTime: (const dispatch_time_t)eventTime;

@end