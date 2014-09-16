//
//  PEXTaskFakeEventProgress.m
//  Phonex
//
//  Created by Matej Oravec on 30/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTaskFakeEvents.h"

@implementation PEXTaskFakeEventProgress

- (id) initWithProgress: (const float) progress
{
    self = [super init];
    _progress = progress;
    return self;
}

- (float) progress { return _progress; }

@end

@implementation PEXTaskFakeEventEnd

- (id) initWithSuccess: (const BOOL) success
{
    self = [super init];
    _success = success;
    return self;
}

- (float) success { return _success; }

@end
