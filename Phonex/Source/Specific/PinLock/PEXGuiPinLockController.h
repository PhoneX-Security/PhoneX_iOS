//
//  PEXGuiPinLockController.h
//  Phonex
//
//  Created by Matej Oravec on 01/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiLooseController.h"

@protocol PEXPinLockListener

- (void) pinLockSet: (NSString * const) pin;
- (void) dismissCalled;

@end

@interface PEXGuiPinLockController : PEXGuiLooseController

@property (nonatomic) id<PEXPinLockListener> pinLockListener;

- (id) initWithDismissButton;

- (void) setText: (NSString * const) text;
- (void) clear;

@end
