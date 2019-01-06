//
//  PEXGuiSetPinExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSetPinExecutor.h"

@interface PEXGuiSetPinExecutor ()
{
    bool _secondStage;
}

@property (nonatomic) PEXGuiController * parent;
@property (nonatomic) PEXGuiPinLockController * controller;

@property (nonatomic) NSString * firstPin;

@end

@implementation PEXGuiSetPinExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;
    _secondStage = false;

    return self;
}

- (void)show
{
    PEXGuiPinLockController * const pinLockController = [[PEXGuiPinLockController alloc] initWithDismissButton];
    [pinLockController prepareOnScreen:self.parent];
    [pinLockController setText:PEXStr(@"L_set_pin")];
    pinLockController.pinLockListener = self;
    [pinLockController show:self.parent];

    self.topController = self.controller = pinLockController;

    [super show];
}

- (void) pinLockSet: (NSString * const) pin
{
    if (!_secondStage)
    {
        self.firstPin = pin;

        [self.controller clear];
        [self.controller setText:PEXStr(@"L_set_pin_repeat")];
        _secondStage = true;
    }
    else
    {
        if (![pin isEqualToString:self.firstPin])
        {
            [self.controller clear];
            [self.controller setText:PEXStr(@"L_set_pin_must_be_equal")];
        }
        else
        {
            [[PEXUserAppPreferences instance] setStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY value:pin];
            [self dismissCalled];
        }
    }
}

- (void) dismissCalled
{
    [self dismissWithCompletion:nil];
}

@end
