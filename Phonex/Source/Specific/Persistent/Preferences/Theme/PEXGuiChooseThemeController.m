//
//  PEXGuiChooseThemeController.m
//  Phonex
//
//  Created by Matej Oravec on 20/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiChooseThemeController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXResStrings.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiControllerDecorator.h"
#import "PEXGuiCircleView.h"

@interface PEXGuiChooseThemeController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;
@property (nonatomic) NSInteger selectedStatus;

@end

@implementation PEXGuiChooseThemeController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ThemeChooser";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}


- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) selectPreferenceView: (UIView * const) themeView
                   theme: (const NSNumber * const) theme
{
    [self.selectorView removeFromSuperview];
    [themeView addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selectedStatus = theme.integerValue;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self initLanguages];
    }];
}

- (void) initLanguages
{
    const NSNumber * const currentTheme =
        @([[PEXAppPreferences instance] getIntPrefForKey:PEX_PREF_GUI_THEME_KEY
                                      defaultValue:PEX_THEME_LIGHT]);

    const NSArray * const themes = [PEXTheme getThemes];
    const NSUInteger lastIndex = themes.count - 1;
    for (NSUInteger i = 0; i < lastIndex + 1; ++i)
    {
        [self addTheme:themes[i]
              currentTheme:currentTheme];
    }
}

- (void) addTheme: (const NSNumber * const) theme
     currentTheme: (const NSNumber * const) currentTheme
{
    PEXGuiDetailView * const view = [[PEXGuiDetailView alloc] init];

    [view setName:[PEXTheme getThemeName:theme]];
    [view setValue:[PEXTheme getThemeDescription:theme.integerValue]];
    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    __weak const PEXGuiChooseThemeController * const weakSelf = self;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [weakSelf selectPreferenceView:weakView theme:theme];
    }];

    if ([currentTheme isEqualToNumber:theme])
    {
        [self selectPreferenceView:view theme:theme];
    }
}


- (NSInteger) getSelectedStatus
{
    return self.selectedStatus;
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
    (PEX_THEME_LAST + 1) * [PEXGuiDetailView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                x:[parent subviewMaxWidth]
                y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}

@end
