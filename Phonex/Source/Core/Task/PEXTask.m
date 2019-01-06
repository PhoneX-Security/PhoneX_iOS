//
//  PEXTask.m
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTask.h"
#import "PEXTask_Protected.h"
#import "PEXTaskListener.h"

@interface PEXTask ()
{
@private
    // (volatile) others may read these attributes in future
    volatile BOOL _ended;
}

// NOTE check for cancelation after all steps in perform

@property NSMutableArray * listeners;

@end

@implementation PEXTask

- (id) init
{
    self = [super init];

    _ended = false;       // set inside
    _cancelCalled = false;  // set from outside
    _unsuccessful = false;   // set insinde at the end of cancellation

    // (1) there will be always at least one listener
    self.listeners = [[NSMutableArray alloc] initWithCapacity:1];

    return self;
}

- (void) cancel
{
    _cancelCalled = true;
}

- (BOOL) isCancelled
{
    return _cancelCalled;
}

- (void) addListener: (id<PEXTaskListener>) listener;
{
    [self.listeners addObject:listener];
}

- (void) start
{
    [self startedProtected];

    [self perform];
    if (self.completionBlock)
        self.completionBlock();

    _ended = true;
    [self endedProtected];
}

- (void) perform {/*BODY*/}

- (void) startedProtected { [self started:nil]; }
- (void) endedProtected { [self ended:nil]; }

- (void) started: (const PEXTaskEvent * const) event { for (const id<PEXTaskListener> listener in self.listeners) [listener taskStarted:event]; }
- (void) ended: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskEnded: event]; }
- (void) progressed: (const PEXTaskEvent * const) event { for (id<PEXTaskListener>listener in self.listeners) [listener taskProgressed: event]; }
- (void) cancelStarted: (const PEXTaskEvent * const) event { for (id<PEXTaskListener>listener in self.listeners) [listener taskCancelStarted: event]; }
- (void) cancelEnded: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskCancelEnded: event]; }
- (void) cancelProgressed: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskCancelProgressed: event]; }

@end
