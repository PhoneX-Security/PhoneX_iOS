//
//  PEXTask_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTask.h"

@class PEXTaskEvent;

@interface PEXTask ()
{
    @protected
    volatile BOOL _unsuccessful;
    volatile BOOL _cancelCalled;
}


- (void) perform;

- (void) startedProtected;
- (void) endedProtected;

// NOT FOR OVERRIDING

- (void) started: (const PEXTaskEvent * const) event;
- (void) ended: (const PEXTaskEvent * const) event;
- (void) progressed: (const PEXTaskEvent * const) event; // call within perform
- (void) cancelStarted: (const PEXTaskEvent * const) event; // call within perform
- (void) cancelEnded: (const PEXTaskEvent * const) event; // call within perform
- (void) cancelProgressed: (const PEXTaskEvent * const) event; // call within perform

@end
