//
//  PEXGuiNavigationLabel.m
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiNavigationLabel.h"
#import "PEXPaddingLabel_Protected.h"

@implementation PEXGuiNavigationLabel

- (id) init
{
    self = [super initWithFontColor:PEXCol(@"blackLow") bgColor:PEXCol(@"grayLow")];

    return self;
}

- (CGFloat) fontSize
{
    return PEXVal(@"fontSizeMedium");
}

- (CGFloat) padding
{
    return PEXVal(@"L_paddingMedium");
}

// TODO make it better
+ (CGFloat) height
{
    return PEXVal(@"fontSizeMedium") + (2.0f * PEXVal(@"L_paddingMedium"));
}

@end
