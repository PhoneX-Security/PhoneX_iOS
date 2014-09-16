//
//  PEXGuiBackgroundView.m
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiBackgroundView.h"

#import "PEXResColors.h"

@implementation PEXGuiBackgroundView

- (id)init
{
    self = [super init];

    [self setBackgroundColor:PEXCol([self getColorKey])];

    return self;
}

- (NSString *) getColorKey
{
    return @"whiteHigh";
}

@end
