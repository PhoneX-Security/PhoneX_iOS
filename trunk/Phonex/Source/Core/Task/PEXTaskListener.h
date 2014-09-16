//
//  PEXTaskListener.h
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXTaskEvent;

@protocol PEXTaskListener<NSObject>

- (void) taskStarted: (const PEXTaskEvent * const) event;
- (void) taskEnded: (const PEXTaskEvent * const) event;
- (void) taskProgressed: (const PEXTaskEvent * const) event;
- (void) taskCancelStarted: (const PEXTaskEvent * const) event;
- (void) taskCancelEnded: (const PEXTaskEvent * const) event;
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event;

@end
