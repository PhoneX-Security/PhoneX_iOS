//
//  PEXTheme.h
//  Phonex
//
//  Created by Matej Oravec on 19/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum PEXThemeEnum : NSInteger PEXThemeEnum;
enum PEXThemeEnum : NSInteger {
    PEX_THEME_LIGHT = 0,
    PEX_THEME_DARK,
    PEX_THEME_FIRST = PEX_THEME_LIGHT,
    PEX_THEME_LAST = PEX_THEME_DARK
};

@interface PEXTheme : NSObject

+ (const NSInteger) getCurrentTheme;
+ (NSString *) getCurrentThemeName;
+ (const NSBundle *) getCurrentThemeBundle;
+ (const NSArray *) getThemes;
+ (NSString *) getThemeName: (const NSNumber * const) theme;
+ (NSString *) getThemeDescription: (const NSInteger) theme;
+ (UIKeyboardAppearance) getKeyboardAppearance;
+ (UIStatusBarStyle) getStatusBarStyle;
+ (UIActivityIndicatorViewStyle) getActivityIndicatorStyle;

@end
