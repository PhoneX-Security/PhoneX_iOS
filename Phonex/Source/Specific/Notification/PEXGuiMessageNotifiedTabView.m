//
//  PEXGuiMessageNotifiedTabView.m
//  Phonex
//
//  Created by Matej Oravec on 22/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiMessageNotifiedTabView.h"

@implementation PEXGuiMessageNotifiedTabView

- (void) registerCounter
{
    [[PEXGNFC instance] registerToMessagesAndSet:self.counter];
}

- (void) unregisterCounter
{
    [[PEXGNFC instance] unregisterForMessages:self.counter];
}

@end
