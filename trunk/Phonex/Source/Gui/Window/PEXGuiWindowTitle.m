//
//  PEXGuiDialogTitile.m
//  Phonex
//
//  Created by Matej Oravec on 11/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiWindowTitle.h"
#import "PEXPaddingLabel_Protected.h"

#import "PEXResColors.h"
#import "PEXResValues.h"

@implementation PEXGuiWindowTitle

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
