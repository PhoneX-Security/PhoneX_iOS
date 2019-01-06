//
//  PEXGuiProgressController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiProgressController.h"

#import "PEXTaskEvent.h"

@interface PEXGuiProgressController ()

- (void) showTaskStarted: (const PEXTaskEvent * const) event;
- (void) showTaskEnded: (const PEXTaskEvent * const) event;
- (void) showTaskProgressed: (const PEXTaskEvent * const) event;
- (void) showTaskCancelStarted: (const PEXTaskEvent * const) event;
- (void) showTaskCancelEnded: (const PEXTaskEvent * const) event;
- (void) showTaskCancelProgressed: (const PEXTaskEvent * const) event;

- (void) setTitle: (NSString * const) title;
- (void) setProgress: (const float) progress;

@end
