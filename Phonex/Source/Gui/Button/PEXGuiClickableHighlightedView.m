//
//  PEXGuiClickableView.m
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiClickableHighlightedView.h"

@implementation PEXGuiClickableHighlightedView

// MAINTENANCE

-(id) init
{
    self = [super init];

    [self setStateNormal];

    return self;
}

-(void) setStateNormal
{
    [self setState:[self bgColorNormalStatic]];
}

-(void) setStateHighlight
{
    [self setState:[self bgColorHighlightStatic]];
}

-(void) setStateDisabled
{
    [self setState:[self bgColorDisabledStatic]];
}

-(void) setState: (UIColor * const) bgColor
{
    [self setBackgroundColor:bgColor];
}

- (void) setEnabled: (const bool) enabled
{
    [super setEnabled:enabled];

    if (enabled)
    {
        [self animateNormal];
    }
    else
    {
        [self animateDisabled];
    }
}

- (UIColor *)bgColorNormalStatic {return PEXCol(@"white_normal");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"light_orange_normal");}
- (UIColor *)bgColorDisabledStatic {return nil;}

#include "AnimationOnClickStub.h"

@end
