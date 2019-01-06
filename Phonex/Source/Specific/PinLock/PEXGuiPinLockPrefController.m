//
//  PEXGuiPinLockPrefController.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPinLockPrefController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiDetailView.h"
#import "PEXGuiSelectorButton.h"
#import "PEXGuiLinearScalingView.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiCircleView.h"
#import "PEXGuiMenuLine.h"

#import "PEXGuiSetPinExecutor.h"
#import "PEXGuiChoosePinLockTriggerTimeExecutor.h"

#import "PEXGuiButtonDialogPrimary.h"
#import "PEXGuiButtonDIalogSecondary.h"
#import "PEXGuiTimeUtils.h"
#import "PEXReport.h"

@interface PEXGuiPinLockPrefController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;

@property (nonatomic) PEXGuiButton * B_enable;
@property (nonatomic) PEXGuiButton * B_disable;
@property (nonatomic) PEXGuiLinearScalingView * setViews;

@property (nonatomic) PEXGuiDetailView * B_pinLockTriggerTime;
@property (nonatomic) NSLock * lock;

@end

@implementation PEXGuiPinLockPrefController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"PinLockPreferences";

    [PEXGVU executeWithoutAnimations:^{

        self.linearView = [[PEXGuiLinearScrollingView alloc] init];
        [self.mainView addSubview:self.linearView];

        self.setViews = [[PEXGuiLinearScalingView alloc] init];
        [PEXGVU setHeight:self.setViews to:[PEXGuiButtonDialogPrimary height]];
        [self.linearView addView:self.setViews];

        self.B_enable = [[PEXGuiButtonDialogPrimary alloc] init];
        [self.setViews addView:self.B_enable];

        self.B_disable = [[PEXGuiButtonDIalogSecondary alloc] init];
        [self.setViews addView:self.B_disable];

        self.B_pinLockTriggerTime = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.B_pinLockTriggerTime];

    }];
}

- (void) initContent
{
    [super initContent];

//    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
//    self.setViews.backgroundColor = PEXCol(@"light_gray_high");
    [self.B_pinLockTriggerTime setName:PEXStrU(@"L_pin_lock_trigger_time")];
}

+ (NSString *) getTriggerTimeDescription: (const int)seconds
{
    return (seconds == 0) ?
            PEXStr(@"L_immediatelly") :
            [PEXGuiTimeUtils getTimeDescriptionFromSeconds:seconds];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.setViews];
    [PEXGVU scaleVertically:self.B_enable];
    [PEXGVU scaleVertically:self.B_disable];
    [PEXGVU scaleHorizontally:self.B_pinLockTriggerTime];

    [self.setViews layoutSubviews];
}

- (void) enablePinLock:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_PIN_LOCK_ENABLE];
    PEXGuiSetPinExecutor * const executor = [[PEXGuiSetPinExecutor alloc] initWithParentController:self];
    [executor show];
}

- (void) initBehavior
{
    [super initBehavior];

    __weak PEXGuiPinLockPrefController * const weakSelf = self;
    [self.B_disable addTarget:self action:@selector(disablePinLock:)forControlEvents:UIControlEventTouchUpInside];
    [self.B_enable addTarget:self action:@selector(enablePinLock:) forControlEvents:UIControlEventTouchUpInside];


    [self.B_pinLockTriggerTime addActionBlock:^{
        PEXGuiChoosePinLockTriggerTimeExecutor * const executor =
            [[PEXGuiChoosePinLockTriggerTimeExecutor alloc] initWithParentController:weakSelf];
        [executor show];
    }];
}

- (void) initState
{
    [super initState];

    self.lock = [[NSLock alloc] init];

    [self.lock lock];

    [[PEXAppPreferences instance] addListener:self];
    [self loadPinLock];

    [self.lock unlock];
}

- (void) disablePinLock:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_PIN_LOCK_DISABLE];
    [[PEXUserAppPreferences instance] setStringPrefForKey: PEX_PREF_PIN_LOCK_PIN_KEY
                                                value:nil];
    [[PEXUserAppPreferences instance] setBoolPrefForKey: PEX_PREF_USE_TOUCH_ID_KEY
                                                    value:false];

    [self loadPinLock];
}

- (void) preferenceChangedForKey:(NSString *const)key
{
    [self.lock lock];
    if ([key isEqualToString:[PEXUserAppPreferences userKeyFor:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY ]] ||
            [key isEqualToString:[PEXUserAppPreferences userKeyFor:PEX_PREF_PIN_LOCK_PIN_KEY]])
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadPinLock];
        });
    }
    [self.lock unlock];
}

- (void) loadPinLock
{
    NSString * const pin = [[PEXUserAppPreferences instance] getStringPrefForKey: PEX_PREF_PIN_LOCK_PIN_KEY
                                                                defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT];

    if (pin)
    {
        [self.B_disable setEnabled:true];
        [self.B_disable setTitle:PEXStrU(@"L_disable") forState:UIControlStateNormal];
        [self.B_enable setTitle:PEXStrU(@"L_change") forState:UIControlStateNormal];
    }
    else
    {
        [self.B_disable setEnabled:false];
        [self.B_disable setTitle:PEXStrU(@"L_disabled") forState:UIControlStateNormal];
        [self.B_enable setTitle:PEXStrU(@"L_enable") forState:UIControlStateNormal];
    }

    [self.B_pinLockTriggerTime setValue:[PEXGuiPinLockPrefController getTriggerTimeDescription:
        [[PEXUserAppPreferences instance] getIntPrefForKey: PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                          defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT]]];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.lock lock];

    [[PEXAppPreferences instance] removeListener:self];

    [self.lock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

@end
