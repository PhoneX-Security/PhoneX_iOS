//
//  PEXResDimensions.m
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXResValues.h"

static const NSDictionary * s_values;

@implementation PEXResValues

+ (CGFloat) value:(const NSString * const) key
{
    return [[s_values objectForKey:key] floatValue];
}

+ (void) initValues
{
    s_values =
    [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                pathForResource:@"portrait"
                                                ofType:@"plist"]];
}

@end
