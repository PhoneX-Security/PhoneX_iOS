//
//  PEXGuiMoveToTrashView.m
//  Phonex
//
//  Created by Matej Oravec on 02/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiDeleteItemView.h"
#import "PEXGuiCentricButtonView_Protected.h"

@implementation PEXGuiDeleteItemView

// TODO make it static with dispatch_once
- (UIColor *) bgColorNormalStatic {return PEXCol(@"red_normal");}
- (UIColor *) bgColorHighlightStatic {return PEXCol(@"red_low");}
- (UIColor *) bgColorDisabledStatic { return PEXCol(@"light_gray_high");}

@end
