//
//  PEXTask.h
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

// linear lock free task
@interface PEXTask : NSObject

@property (nonatomic, copy) void (^completionBlock)(void);

- (void) start;
- (void) cancel;
// not thread safe
- (void) addListener: (id<PEXTaskListener>) listener;
- (BOOL) isCancelled;

@end
