//
//  PEXGuiButtonDIalogSecondary.m
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonDIalogSecondary.h"
#import "PEXGuiButton_Protected.h"

@implementation PEXGuiButtonDIalogSecondary

- (UIColor *) bgColorNormalStatic { return PEXCol(@"white_normal"); }
- (UIColor *) bgColorHighlightStatic { return PEXCol(@"light_orange_normal"); }
- (UIColor *) textLabelColor { return PEXCol(@"orange_normal"); }

- (void) setStyle
{
    [super setStyle];

    self.layer.borderColor = [PEXCol(@"orange_normal") CGColor];
    self.layer.borderWidth = PEXVal(@"line_width_small");
}

@end
