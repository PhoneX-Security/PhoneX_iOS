//
//  PEXGuiCallLogNotifiedTabView.m
//  Phonex
//
//  Created by Matej Oravec on 22/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCallLogNotifiedTabView.h"

@implementation PEXGuiCallLogNotifiedTabView

- (void) registerCounter
{
    [[PEXGNFC instance] registerToCallLogsAndSet:self.counter];
}

- (void) unregisterCounter
{
    [[PEXGNFC instance] unregisterForCallLogs:self.counter];
}

@end
 