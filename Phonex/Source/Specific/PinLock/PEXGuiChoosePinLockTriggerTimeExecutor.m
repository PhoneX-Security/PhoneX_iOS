//
//  PEXGuiChoosePinLockTriggerTimeExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiChoosePinLockTriggerTimeExecutor.h"

#import "PEXGuiChoosePinLockTriggerTimeController.h"
#import "PEXUnmanagedObjectHolder.h"

@interface PEXGuiChoosePinLockTriggerTimeExecutor ()

@property (nonatomic) PEXGuiController * parent;
@property (nonatomic) PEXGuiChoosePinLockTriggerTimeController * controller;

@end


@implementation PEXGuiChoosePinLockTriggerTimeExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void)show
{
    self.controller = [[PEXGuiChoosePinLockTriggerTimeController alloc] init];
    self.topController = [self.controller showInWindowWithTitle:self.parent
                                                   title:PEXStrU(@"L_pin_lock_trigger_time")
                                      withBinaryListener:self];
    [super show];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self.parent viewDidReveal];
    [super dismissWithCompletion:completion];
}

- (void)secondaryButtonClicked
{
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                                 value:[self.controller getSelectedValue]];

    [self dismissWithCompletion:nil];
}

@end
