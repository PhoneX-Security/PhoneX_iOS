//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageArchiveSelectionController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiCircleView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiDetailView.h"

@interface PEXGuiMessageArchiveSelectionController ()

@property (nonatomic) NSNumber * selectedValue;
@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;

@property (nonatomic) NSArray * values;

@end

@implementation PEXGuiMessageArchiveSelectionController {

}

- (id) init
{
    self = [super init];
    self.values = @[
            // hours
            #ifdef PEX_BUILD_DEBUG
            @ (10), @(15), @(30), @(45), @(60),
            #endif
            @(30 * PEX_MINUTE_IN_SECONDS),
            @(1 * PEX_HOUR_IN_SECONDS), @(6 * PEX_HOUR_IN_SECONDS), @(12 * PEX_HOUR_IN_SECONDS),
            @(1 * PEX_DAY_IN_SECONDS), @(3 * PEX_DAY_IN_SECONDS), @(1 * PEX_WEEK_IN_SECONDS),
            @(1 * PEX_MONTH_IN_SECONDS), @(6 * PEX_MONTH_IN_SECONDS), @(1 * PEX_YEAR_IN_SECONDS)];
    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"MessageArchiveSelection";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}

- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self initValues];
    }];
}

- (void) selectValueView: (UIView * const) view
                   value: (NSNumber * const) value
{
    [self.selectorView removeFromSuperview];
    [view addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedValue = value;
}

- (void) initValues
{
    NSNumber * const current = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                                                    defaultValue:PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT];

    [self addValue:nil
           current:current
            modify:nil];

    const NSUInteger lastIndex = self.values.count;
    for (NSUInteger i = 0; i < lastIndex; ++i)
    {
        [self addValue:self.values[i]
               current:current
                modify:nil];
    }
}

- (void) addValue: (NSNumber * const) value
          current: (NSNumber * const) current
           modify: (SEL)modifier
{
    PEXGuiMenuItemView * const view =
            [[PEXGuiMenuItemView alloc] initWithImage:nil
                                            labelText:
                                                    [PEXGuiMessageArchiveSelectionController getTriggerTimeDescriptionFromSeconds:value]];

    if (modifier)
        [view performSelector:modifier];

    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    WEAKSELF;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [weakSelf selectValueView:weakView value:value];
    }];

    // both nil or equal
    if ((current == value) || ((current) && (value) && [current isEqualToNumber:value]))
    {
        [self selectValueView:weakView value:value];
    }
}

- (NSNumber *) getSelectedValue
{
    return _selectedValue;
}

+ (NSString *)getTriggerTimeDescriptionFromSeconds: (NSNumber * const)seconds
{
    return (!seconds) ?
            PEXStr(@"L_forever") :
            [PEXGuiTimeUtils getTimeDescriptionFromSeconds:seconds.unsignedLongLongValue];
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
            self.values.count * [PEXGuiDetailView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}


@end