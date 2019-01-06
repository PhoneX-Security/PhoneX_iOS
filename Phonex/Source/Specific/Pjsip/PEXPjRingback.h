//
// Created by Dusan Klinec on 09.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "pexpj.h"
#import "PEXPjTone.h"

@class PEXPjConfig;

/**
* Class handling ringback tone when dialing a number.
* Stores own configuration. Should be singleton in the stack.
*/
@interface PEXPjRingback : PEXPjTone
+ (instancetype)ringbackWithConfig:(PEXPjConfig *)config;
@end