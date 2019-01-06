//
//  PEXGuiButtonWithImageCall.m
//  Phonex
//
//  Created by Matej Oravec on 06/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiCallButtonView.h"

@implementation PEXGuiCallButtonView

// TODO make it static with dispatch_once
- (UIColor *) bgColorNormalStatic {return PEXCol(@"light_gray_high");}
- (UIColor *) bgColorHighlightStatic {return PEXCol(@"light_gray_normal");}

@end
