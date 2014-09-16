//
//  PEXGuiProgressBar.m
//  Phonex
//
//  Created by Matej Oravec on 29/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiProgressBar.h"

#import "PEXResColors.h"

@implementation PEXGuiProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.progressViewStyle = UIProgressViewStyleDefault;
    [self setProgressing];

    return self;
}

- (void) setProgressing
{
    self.progressTintColor = PEXCol(@"orangeHigh");
    self.trackTintColor = PEXCol(@"grayHigh");
}

- (void) setCancelling;
{
    self.progressTintColor = PEXCol(@"orangeLow");
    self.trackTintColor = PEXCol(@")grayLow");
}

@end
