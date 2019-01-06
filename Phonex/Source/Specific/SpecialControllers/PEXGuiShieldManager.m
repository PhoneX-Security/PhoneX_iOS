//
//  PEXGuiSpecialControllersManager.m
//  Phonex
//
//  Created by Matej Oravec on 02/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiShieldManager.h"

#import "PEXGuiBackgroundView.h"

#import "PEXGuiShieldView.h"

#import "PEXGuiLoginController.h"

@interface PEXGuiShieldManager ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) UIView * shieldView;

@property (nonatomic) NSMutableArray * victims;

@end

@implementation PEXGuiShieldManager

- (void) addVictim: (UIViewController * const) victim
{
    [self.lock lock];
    [self.victims addObject:victim];
    [self.lock unlock];
}

- (void) removeVictim: (UIViewController * const) victim
{
    [self.lock lock];
    [self.victims removeObject:victim];
    [self.lock unlock];
}

- (id) init
{
    self = [super init];

    self.victims = [[NSMutableArray alloc] init];

    return self;
}


- (void) showShield
{
    [self.lock lock];

    if (!self.shieldView) {

        // dismiss all victims but let them stay!
        [self preDismissVictims];

        UIViewController *landing = [PEXGuiLoginController instance].landingController;

        if (landing) {
            UIView *const shield = [[PEXGuiShieldView alloc] init];
            [PEXGVU makeFullscreenBackground:shield];

            [landing.view.window insertSubview:shield
                                  aboveSubview:landing.view];
            [landing.view bringSubviewToFront:shield];
            self.shieldView = shield;
        }
    }
    
    [self.lock unlock];
}

- (void) preDismissVictims
{
    const NSUInteger count = self.victims.count;
    for (NSUInteger i = count; i > 0; --i) {
        [self.victims[i - 1] dismissViewControllerAnimated:true completion:nil];
    }
}

- (void) postDismissVictims
{
    // they need to be killed for the second time
    // try to dismiss victims and kill them
    const NSUInteger count = self.victims.count;
    for (NSUInteger i = 0; i < count; ++i)
    {
        [self.victims[i] dismissViewControllerAnimated:true completion:nil];
        [self.victims removeObjectAtIndex:i];
    }
}

- (void) dimissVictims
{
    [self preDismissVictims];
    [self postDismissVictims];
}

// just a helper ... locks not needed
- (void) bringToFront
{
    // showing only when logged in
    UIViewController * landing = [PEXGuiLoginController instance].landingController;

    if (landing && self.shieldView)
    {
        [landing.parentViewController.view bringSubviewToFront:self.shieldView];
    }
}

- (void) hideShield
{
    [self.lock lock];

    if (self.shieldView)
    {
        [self postDismissVictims];

        [self.shieldView removeFromSuperview];
        self.shieldView = nil;
    }

    [self.lock unlock];
}

+ (PEXGuiShieldManager *) instance
{
    static PEXGuiShieldManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiShieldManager alloc] init];
    });

    return instance;
}

@end
