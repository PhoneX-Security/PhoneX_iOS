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

    volatile BOOL _cancelCalled;
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

    _ended = true;
    [self endedProtected];
}

- (void) perform {/*BODY*/}

- (void) startedProtected { [self started:nil]; }
- (void) endedProtected { [self ended:nil]; }

- (void) started: (const PEXTaskEvent * const) event { for (const id<PEXTaskListener> listener in self.listeners) [listener taskStarted:nil]; }
- (void) ended: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskEnded: event]; }
- (void) progressed: (const PEXTaskEvent * const) event { for (id<PEXTaskListener>listener in self.listeners) [listener taskProgressed: event]; } // set within perform
- (void) cancelStarted: (const PEXTaskEvent * const) event { for (id<PEXTaskListener>listener in self.listeners) [listener taskCancelStarted: event]; } // set within perform
- (void) cancelEnded: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskCancelEnded: event]; } // set within perform
- (void) cancelProgressed: (const PEXTaskEvent * const) event { for (id<PEXTaskListener> listener in self.listeners) [listener taskCancelProgressed: event]; } // set within perform

@end
