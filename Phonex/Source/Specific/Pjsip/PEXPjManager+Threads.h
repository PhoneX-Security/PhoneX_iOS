//
// Created by Dusan Klinec on 14.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPjManager.h"

@interface PEXPjManager (Threads)
/**
* Should be call to free all stored threads.
* Call on pjsua_destroy();
*/
-(void) freeThreads;

- (BOOL) threadRegistered;
- (void) registerCurrentThreadIfNotRegistered;
@end