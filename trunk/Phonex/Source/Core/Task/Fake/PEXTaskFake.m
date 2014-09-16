//
//  PEXTaskFake.m
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTaskFake.h"
#import "PEXTaskFake_Protected.h"

#import "PEXTaskFakeEvents.h"

@implementation PEXTaskFake

- (void) perform
{
    for (volatile int i = 1; i < 10; ++i)
    {
        if ([self isCancelled])
        {
            [self performCancel];
            break;
        }

        /*
        if (i == 5)
        {
            [self cancel];
        }*/

        [NSThread sleepForTimeInterval:1.0];
        [self progressed:[[PEXTaskFakeEventProgress alloc] initWithProgress:(i / 9.0f)]];
    }
}

- (void) startedProtected
{
    [super startedProtected];
}

- (void) endedProtected
{
    [super endedProtected];
}

- (void) performCancel
{
    [self cancelStarted:nil];
    [NSThread sleepForTimeInterval:1.0];

    [self cancelProgressed:nil];

    [NSThread sleepForTimeInterval:1.0];
    _unsuccessful = true;
    [self cancelEnded:nil];
}

@end
