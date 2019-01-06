//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMuteNotificationController.h"
#import "PEXGuiChooseLanguageController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"

#import "PEXResStrings.h"
#import "PEXGuiDetailView.h"

#import "PEXGuiControllerDecorator.h"

#import "PEXGuiCircleView.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiMenuItemView.h"

@interface PEXGuiMuteNotificationController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;
@property (nonatomic) NSNumber * selectedPeriod;
@property (nonatomic) NSArray * values;

@end

@implementation PEXGuiMuteNotificationController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.values = @[
                @(0),
#ifdef PEX_BUILD_DEBUG
                @(30l*1000ll), @(60l*1000ll),
#endif
                @(30ll * PEX_MINUTE_IN_SECONDS*1000ll),
                @(1ll * PEX_HOUR_IN_SECONDS*1000ll),
                @(4ll * PEX_HOUR_IN_SECONDS*1000ll),
                @(8ll * PEX_HOUR_IN_SECONDS*1000ll),
                @(12ll * PEX_HOUR_IN_SECONDS*1000ll),
                @(24ll * PEX_HOUR_IN_SECONDS*1000ll),
                @(2ll * PEX_DAY_IN_SECONDS*1000ll),
                @(25ll * PEX_YEAR_IN_SECONDS*1000ll)
        ];
    }

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ChooseMuteUntil";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}

- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) selectMutePeriodView: (UIView * const) periodView
                       period: (NSNumber * const) period
{
    [self.selectorView removeFromSuperview];
    [periodView addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedPeriod = period;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self preparePeriods];
    }];
}

- (void)preparePeriods
{
    NSNumber * const currentPeriod = [[PEXUserAppPreferences instance]
            getNumberPrefForKey:self.prefKey defaultValue:@(0)];

    NSNumber * selectedPeriod = nil;
    const NSUInteger lastIndex = self.values.count;
    const NSTimeInterval selectedMilli = currentPeriod == nil ? 0 : [currentPeriod doubleValue];
    const NSTimeInterval curTimeMilli = [[NSDate date] timeIntervalSince1970] * 1000.0;

    for (NSUInteger i = 0; i < lastIndex; ++i) {
        NSTimeInterval timeBoundCur = curTimeMilli + [self.values[i] doubleValue];

        if (i == 0 && selectedMilli <= timeBoundCur){
            selectedPeriod = self.values[i];
            break;
        }

        if (i == lastIndex-1 && selectedMilli >= timeBoundCur){
            selectedPeriod = self.values[i];
            break;
        }

        if (i < lastIndex-1) {
            NSTimeInterval timeBoundNext = curTimeMilli + [self.values[i+1] doubleValue];
            NSTimeInterval timeBoundHalf = (timeBoundNext + timeBoundCur)/2;
            if (selectedMilli < timeBoundCur || selectedMilli > timeBoundNext){
                continue;
            }

            if (selectedMilli <= timeBoundHalf){
                selectedPeriod = self.values[i];
            } else {
                selectedPeriod = self.values[i+1];
            }

            break;
        }
    }

    for (NSUInteger i = 0; i < lastIndex; ++i) {
        [self addPeriod:self.values[i]
          currentPeriod:selectedPeriod
                 modify:nil];
    }
}

+ (NSString *)getTimeDescriptionFromSeconds: (NSNumber * const)seconds
{
    long long secs = [seconds longLongValue];
    if (secs <= 0){
        return PEXStr(@"L_mute_disabled");
    } else if (secs >= 2ll*PEX_YEAR_IN_SECONDS){
        return PEXStr(@"L_until_enabled");
    }

    return [PEXGuiTimeUtils getTimeDescriptionFromSeconds:seconds.unsignedLongLongValue];
}

- (void) addPeriod: (NSNumber * const) period
     currentPeriod: (NSNumber * const) current
            modify: (SEL) selectorOnLanguageView
{
    PEXGuiMenuItemView * const view =
            [[PEXGuiMenuItemView alloc] initWithImage:nil
                                            labelText: [PEXGuiMuteNotificationController getTimeDescriptionFromSeconds:@([period longLongValue]/1000)]];

    if (selectorOnLanguageView) {
        [view performSelector:selectorOnLanguageView];
    }

    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    WEAKSELF;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [weakSelf selectMutePeriodView:weakView period:period];
    }];

    if (period == nil || [period longLongValue] == 0){
        [weakSelf selectMutePeriodView:weakView period:period];
    }

    // both nil or equal
    if ((current == period) || ((current) && (period) && [current isEqualToNumber:period]))
    {
        [weakSelf selectMutePeriodView:weakView period:period];
    }
}

- (NSNumber *)getSelectedPeriod {
    return self.selectedPeriod;
}

- (void) initBehavior
{
    [super initBehavior];
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
            [_PEXStr getLanguages].count * [PEXGuiDetailView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}

@end
