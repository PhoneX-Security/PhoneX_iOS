//
//  PEXGuiButtonMain.m
//  Phonex
//
//  Created by Matej Oravec on 11/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonMain.h"
#import "PEXGuiButton_Protected.h"

#import "PEXResColors.h"

@implementation PEXGuiButtonMain

- (UIColor *) textColorNormal { return PEXCol(@"whiteHigh"); }
- (UIColor *) textColorHighlight { return PEXCol(@"blackLow"); }
- (UIColor *) bgColorNormal { return PEXCol(@"orangeHigh"); }
- (UIColor *) bgColorHighlight { return PEXCol(@"orangeNormal"); }

@end
