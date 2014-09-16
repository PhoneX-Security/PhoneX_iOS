//
//  PEXTask.h
//  Phonex
//
//  Created by Matej Oravec on 25/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXTaskListener;

// linear lock free task
@interface PEXTask : NSObject

- (void) start;
- (void) cancel;
// not thread safe
- (void) addListener: (id<PEXTaskListener>) listener;

@end
