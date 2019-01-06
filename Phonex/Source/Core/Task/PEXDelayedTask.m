//
// Created by Matej Oravec on 02/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDelayedTask.h"
#import "PEXTask_Protected.h"

@interface PEXDelayedTask ()
{
@private
    dispatch_time_t _eventTime;
}

@property (atomic) dispatch_semaphore_t semaphore;

@property (atomic) dispatch_semaphore_t instanceSaver;

@end

@implementation PEXDelayedTask {

}

- (id)initWithEventTime: (const dispatch_time_t)eventTime
{
    self = [super init];

    _eventTime = eventTime;
    self.semaphore = dispatch_semaphore_create(0);
    self.instanceSaver = dispatch_semaphore_create(0);

    return self;
}

- (void)cancel
{
    [super cancel];

    dispatch_semaphore_signal(self.semaphore);
    //dispatch_semaphore_wait(self.instanceSaver, DISPATCH_TIME_FOREVER);
}

- (void)start
{
    // wait until cancellation or timeout
    dispatch_semaphore_wait(self.semaphore, _eventTime);

    if ([self isCancelled])
    {
        //dispatch_semaphore_signal(self.instanceSaver);
        return;
    }

    [super start];
}

@end