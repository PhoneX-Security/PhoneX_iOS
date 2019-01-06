//
//  PEXGuiChoosePinLockTriggerTimeController.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiChoosePinLockTriggerTimeController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiCircleView.h"

#import "PEXGuiMenuItemView.h"
#import "PEXGuiPinLockPrefController.h"
#import "PEXGuiTimeUtils.h"

@interface PEXGuiChoosePinLockTriggerTimeController ()
{
    int _selectedValue;
}
@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;

@end

@implementation PEXGuiChoosePinLockTriggerTimeController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ChoosePinLockTriggerTime";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}

- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) selectValueView: (UIView * const) view
                   value: (const int) value
{
    [self.selectorView removeFromSuperview];
    [view addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    _selectedValue = value;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self initValues];
    }];
}

- (void) initValues
{
    const int current = (int) [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                                                    defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT];
    const NSArray * const values = @[
            // seconds
            @0, @5, @10, @15, @20, @25, @30, @35, @40, @45, @50, @55,
            // minutes
            @(PEX_MINUTE_IN_SECONDS), @(PEX_MINUTE_IN_SECONDS * 5),
            @(PEX_MINUTE_IN_SECONDS * 10), @(PEX_MINUTE_IN_SECONDS * 15),
            @(PEX_MINUTE_IN_SECONDS * 20), @(PEX_MINUTE_IN_SECONDS * 25),
            @(PEX_MINUTE_IN_SECONDS * 30), @(PEX_MINUTE_IN_SECONDS * 35),
            @(PEX_MINUTE_IN_SECONDS * 40), @(PEX_MINUTE_IN_SECONDS * 45),
            @(PEX_MINUTE_IN_SECONDS * 55), @(PEX_HOUR_IN_SECONDS)];

    const NSUInteger lastIndex = values.count;
    for (NSUInteger i = 0; i < lastIndex; ++i)
    {
        [self addValue:(int)((NSNumber *)values[i]).integerValue
               current:current
                   modify:nil];
    }
}

- (void) addValue: (const int) value
          current: (const int) current
           modify: (SEL) selectorOnLanguageView
{
    PEXGuiMenuItemView * const view =
        [[PEXGuiMenuItemView alloc] initWithImage:nil
                                        labelText:[PEXGuiPinLockPrefController getTriggerTimeDescription:value]];

    if (selectorOnLanguageView)
        [view performSelector:selectorOnLanguageView];

    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    __weak const PEXGuiChoosePinLockTriggerTimeController * const weakSelf = self;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [weakSelf selectValueView:weakView value:value];
    }];

    if (current == value)
    {
        [self selectValueView:weakView value:value];
    }
}

- (int) getSelectedValue
{
    return _selectedValue;
}

@end
