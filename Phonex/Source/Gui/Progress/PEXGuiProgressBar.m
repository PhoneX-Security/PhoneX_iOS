//
//  PEXGuiProgressBar.m
//  Phonex
//
//  Created by Matej Oravec on 29/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiProgressBar.h"

@implementation PEXGuiProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.trackTintColor = PEXCol(@"light_gray_high");
    self.progressViewStyle = UIProgressViewStyleDefault;
    [self setProgressing];

    return self;
}

- (void) setProgressing
{
    self.progressTintColor = PEXCol(@"orange_normal");
}

- (void) setCancelling;
{
    self.progressTintColor = PEXCol(@"black_normal");
}

@end
