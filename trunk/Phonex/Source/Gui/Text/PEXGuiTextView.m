//
//  PEXGuiTextView.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiTextView.h"

#import "PEXGuiViewUtils.h"
#import "PEXResColors.h"
#import "PEXResValues.h"

@implementation PEXGuiTextView

- (id)init
{
    self = [super init];

    self.font = [UIFont systemFontOfSize:PEXVal(@"fontSizeMedium")];
    self.backgroundColor = PEXCol(@"whiteHigh");
    self.textColor = PEXCol(@"blackLow");
    const CGFloat padding = PEXVal(@"contentMarginSmall");
    self.textContainerInset = UIEdgeInsetsMake(padding, padding, padding, padding);
    self.editable = NO;
    [self resignFirstResponder];
    self.scrollEnabled = NO;
    [self setUserInteractionEnabled:NO];

    return self;
}

@end
