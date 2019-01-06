//
//  PEXTheme.m
//  Phonex
//
//  Created by Matej Oravec on 19/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTheme.h"
#import "PEXTheme_JustOnce.h"
#import "PEXRefDictionary.h"

static const PEXRefDictionary * s_themes;
static NSInteger s_current_theme;
static NSString * s_current_theme_name;
static const NSBundle * s_current_theme_bundle;

static UIKeyboardAppearance s_keyboardAppearance;
static UIStatusBarStyle s_statusBarStyle;
static UIActivityIndicatorViewStyle s_activityIndicatorStyle;

@implementation PEXTheme

+ (void) initTheme
{
    s_themes = [[PEXRefDictionary alloc] init];
    [s_themes setObject:@"light" forKey:@(PEX_THEME_LIGHT)];
    [s_themes setObject:@"dark" forKey:@(PEX_THEME_DARK)];

    s_current_theme = [[PEXAppPreferences instance] getIntPrefForKey:PEX_PREF_GUI_THEME_KEY
                                                        defaultValue:PEX_THEME_LIGHT];

    s_current_theme_name =
            [s_themes objectForKey:@(s_current_theme)];

    s_current_theme_bundle = [NSBundle bundleWithPath: [[[NSBundle mainBundle] resourcePath]
      stringByAppendingPathComponent:
      [NSString stringWithFormat:@"%@.bundle", s_current_theme_name]]];

    [self setSystemComponentStyles];
}

+ (void) setSystemComponentStyles
{
    switch (s_current_theme) {
        case PEX_THEME_LIGHT:
            s_keyboardAppearance = UIKeyboardAppearanceLight;
            s_statusBarStyle = UIStatusBarStyleDefault;
            s_activityIndicatorStyle = UIActivityIndicatorViewStyleGray;
            break;
        case PEX_THEME_DARK:
            s_keyboardAppearance = UIKeyboardAppearanceDark;
            s_statusBarStyle = UIStatusBarStyleLightContent;
            s_activityIndicatorStyle = UIActivityIndicatorViewStyleWhite;
            break;
    }
}

+ (const NSInteger) getCurrentTheme
{
    return s_current_theme;
}

+ (NSString *) getCurrentThemeName
{
    return s_current_theme_name;
}

+ (const NSBundle *) getCurrentThemeBundle
{
    return s_current_theme_bundle;
}

+ (const NSArray *) getThemes
{
    return [s_themes getKeys];
}

+ (NSString *) getThemeName: (const NSNumber * const) theme
{
    return [s_themes objectForKey:theme];
}

+ (NSString *) getThemeDescription: (const NSInteger) theme
{
    static NSString * const themeDescriptionSufix = @"_theme_description";
    NSString * const name = [self getThemeName:[NSNumber numberWithInteger:theme]];
    return PEXStr(([NSString stringWithFormat:@"%@%@", name, themeDescriptionSufix]));
}

+ (UIKeyboardAppearance) getKeyboardAppearance
{
    return s_keyboardAppearance;
}

+ (UIStatusBarStyle) getStatusBarStyle
{
    return s_statusBarStyle;
}

+ (UIActivityIndicatorViewStyle) getActivityIndicatorStyle
{
    return s_activityIndicatorStyle;
}

@end
