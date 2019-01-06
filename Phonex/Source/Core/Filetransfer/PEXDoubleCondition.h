//
// Created by Dusan Klinec on 27.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* Single mutex lock and two condition variables tied to the same mutex.
* Used in bound-buffer producer-consumer problem.
*/
@interface PEXDoubleCondition : NSObject<NSLocking>
- (void) lock;
- (BOOL) tryLock;
- (void) unlock;
- (void) wait: (int) idx;
- (BOOL) wait: (int) idx untilDate: (NSDate *) date;
- (void) signal: (int) idx;
- (void) broadcast: (int) idx;
@end