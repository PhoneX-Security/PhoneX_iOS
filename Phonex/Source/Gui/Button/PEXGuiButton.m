//
//  PEXGuiButton.m
//  Phonex
//
//  Created by Matej Oravec on 31/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButton.h"
#import "PEXGuiButton_Protected.h"

@interface PEXGuiButton ()

@end

@implementation PEXGuiButton

- (id)init
{
    self = [super init];

    [self setStyle];

    return self;
}

// TODO save values of sizes and color and use them instead of always lookinp up using the key
+ (CGFloat) fontSize
{
    return PEXVal(@"dim_size_medium");
}

+ (CGFloat) padding
{
    return PEXVal(@"dim_size_medium");
}

+ (CGFloat) height
{
    return [self fontSize] + (2.0f * [self padding]);
}

- (void) setStyle
{
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self setBackgroundColor:[self bgColorNormalStatic]];
    self.titleLabel.font = [UIFont boldSystemFontOfSize: [PEXGuiButton fontSize]];
    [self setTitleColor:[self textLabelColor] forState:UIControlStateNormal];
    // width is set by a controller
    [PEXGVU setSize: self x: PEXDefaultVal y: [PEXGuiButton fontSize] + (2.0f * [PEXGuiButton padding])];
}

// MAINTENANCE

-(void) setStateHighlight
{
    [self setState:[self bgColorHighlightStatic]];
}

-(void) setStateNormal
{
    [self setState:self.isEnabled ? [self bgColorNormalStatic] : [self bgColorDisabledStatic]];
}

-(void) setState: (UIColor * const) bgColor
{
    [self setBackgroundColor:bgColor];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];

    [self setStateNormal];
}

- (UIColor *) bgColorNormalStatic {return nil;}
- (UIColor *) bgColorHighlightStatic {return nil;}
- (UIColor *) bgColorDisabledStatic { return PEXCol(@"light_gray_high");}
- (UIColor *) textLabelColor { return PEXCol(@"white_normal"); }

#include "AnimationOnClickStub.h"

@end
