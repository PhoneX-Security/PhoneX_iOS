//
//  PEXGuiSpecialPriorityManager.m
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSpecialPriorityManager.h"

#import "PEXGuiPinLockManager.h"
#import "PEXGuiCallManager.h"
#import "PEXGuiShieldManager.h"
#import "PEXGuiNoticeManager.h"

@implementation PEXGuiSpecialPriorityManager

+ (void) reorder
{
    [[PEXGuiNoticeManager instance] bringToFront];
    [[PEXGuiPinLockManager instance] bringToFront];
    [[PEXGuiCallManager instance] bringTheCallToFront];
    [[PEXGuiShieldManager instance] bringToFront];
}

+ (void) dismissAll
{
    [[PEXGuiNoticeManager instance] dismissNoticeFromOutside];
    [[PEXGuiCallManager instance] unsetCallController];
    [[PEXGuiPinLockManager instance] hidePinLock];
    [[PEXGuiShieldManager instance] hideShield];
}

@end
