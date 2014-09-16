//
//  PEXResStrings.m
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXResStrings_JustOnce.h"

static const NSDictionary * s_unlocalizedStrings;

@implementation PEXResStrings

+ (NSString *) localizedString:(const NSString * const) key
{
    return [s_unlocalizedStrings objectForKey:key];
}

+ (void) initUnlocalizedStrings
{
    s_unlocalizedStrings =
    [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                pathForResource:@"Unlocalized"
                                                ofType:@"strings"]];
}

+ (void) initLanguage
{
    // set language
    [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:@"en", nil] forKey:@"AppleLanguages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
