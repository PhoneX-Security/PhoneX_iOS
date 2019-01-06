//
//  PEXGuiPinLockManager.m
//  Phonex
//
//  Created by Matej Oravec on 01/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPinLockManager.h"

#import "PEXGuiFactory.h"
#import "PEXGuiPinLockController.h"

#import "PEXGuiLoginController.h"
#import "PEXGuiMainNavigationController.h"
#import "PEXGuiSpecialPriorityManager.h"
#import "PEXGuiCallManager.h"
#import "PEXLoginHelper.h"
#import "PEXTouchId.h"
#import "PEXReport.h"

@interface PEXGuiPinLockManager ()
{
    volatile bool _elapsedTriggerTIme;
}

@property (nonatomic) NSLock * lock;
@property (nonatomic) PEXGuiPinLockController * pinLockController;

@end

@implementation PEXGuiPinLockManager

- (void) resetTrigger
{
    _elapsedTriggerTIme = false;
}

- (PEXGuiPinLockController *) showPinLockOnBecomingActive: (const uint64_t) seconds
                                               forLanding: (UIViewController * const) landing
                                                forceShow: (const bool) force;
{
    PEXGuiPinLockController * result = nil;

    [self.lock lock];

    if (landing)
    {
        if ([[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT])
        {
            if (!_elapsedTriggerTIme)
            {
                _elapsedTriggerTIme = (seconds >=
                                   ([[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                                                          defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT]));
            }

            if (_elapsedTriggerTIme)
            {
                result = [self showInternalForLanding:landing];
            }
            else
            {
                // trigger time not reached
                [self setBeyondPinLock: true];
                [[PEXGNFC instance] goingToForeground];
            }
        }
        else
        {
            if (force)
            {
                result = [self showInternalForLanding:landing];
            }
            else {

                // not logged in
                [self setBeyondPinLock:true];
                [[PEXGNFC instance] goingToForeground];
            }
        }
    }
    else if (force)
    {
        result = [self showInternalForLanding:landing];
    }

    // else not logged in or in loading (set in logout execution and launch)

    [self.lock unlock];

    return result;
}

- (PEXGuiPinLockController *) showInternalForLanding: (UIViewController * const) landing
{
    [self setBeyondPinLock: false];

    if (landing)
    {
        PEXGuiPinLockController * const pinLockController = [[PEXGuiPinLockController alloc] init];
        [pinLockController prepareOnScreen:landing];
        [pinLockController setText:[self warningText:[[PEXAppState instance] pinLockAttempts]]];
        pinLockController.pinLockListener = self;

        [pinLockController show:landing];
        self.pinLockController = pinLockController;

        if ([PEXTouchId getTouchIdStatus] == TOUCH_ID_STATUS_SET_AND_USED)
        {
            [[PEXTouchId instance] requestTouchIdWithMessageAsync:PEXStr(@"txt_touch_id_verify_to_access")
                                                        onSuccess:^{
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                [self pinLockSuccess];
                                                            });
                                                        } onFailure:nil];
        }
    }

    return self.pinLockController;
}

- (NSString *) warningText: (const int) remainingAttempts
{
    return [NSString stringWithFormat:@"%@: %d", PEXStr(@"L_remaining_attempts"), remainingAttempts];
}

// LISTENER

- (void) pinLockSet: (NSString * const) pin
{
    NSString * const preferencesPin =
            [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT];
    // possible nil pin?

    if (![pin isEqualToString:preferencesPin])
    {
        [PEXReport logUsrEvent:PEX_EVENT_PIN_FAIL];
        int attempts = [[PEXAppState instance] pinLockAttempts];
        --attempts;
        [[PEXAppState instance] setPinLockAttempts:attempts];
        if (attempts < 1)
        {
            //logout and clear credentials also from remembered database
            [PEXLoginHelper resetKeychain];

            [[PEXAppPreferences instance] setBoolPrefForKey:PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY
                                                      value:PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT];
            [[PEXGuiLoginController instance] cleanTracesForce];
            [[PEXGuiLoginController instance] performLogout];
            [self hidePinLock];
        }
        else
        {
            [self.pinLockController setText:[self warningText:attempts]];
            [self.pinLockController clear];
        }
    }
    else
    {
        [PEXReport logUsrEvent:PEX_EVENT_PIN_OK];
        [self pinLockSuccess];
    }
}

- (void) pinLockSuccess
{
    // pin input success
    [self setBeyondPinLock: true];
    [[PEXGNFC instance] goingToForeground];

    [[PEXAppState instance] resetPinLockAttempts];
    [self hidePinLock];
    _elapsedTriggerTIme = false;
}

- (void) hidePinLockForGoingToBackground
{
    if (!self.worksOutOfLogin)
        [self hidePinLock];
}

- (void) hidePinLock
{
    [self.lock lock];

    if (self.pinLockController)
    {
        [[PEXGuiLoginController instance] autologinFailedStateOff];
        [self.pinLockController dismissViewControllerAnimated:true completion:^{self.pinLockController = nil;}];
    }

    [self.lock unlock];
}

+ (PEXGuiPinLockManager *) instance
{
    static PEXGuiPinLockManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiPinLockManager alloc] init];
    });

    return instance;
}

- (id) init
{
    self = [super init];
    _elapsedTriggerTIme = false;
    return self;
}

- (void) dismissCalled { /* not needed */ }

- (void) bringToFront
{
    [self.lock lock];

    if (self.pinLockController)
    {
        [self.pinLockController.parentViewController.view bringSubviewToFront:self.pinLockController.view];
    }

    [self.lock unlock];
}

@end
