//
//  PEXGuiSelectorButton.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectorButton.h"
#import "PEXGuiSimpleButton_Protected.h"

@implementation PEXGuiSelectorButton

- (id)initWithText:(NSString * const) text
{
    return [self initWithText:text fontSize:PEXVal(@"dim_size_medium")];
}

- (UIColor *)bgColorNormalStatic {return PEXCol(@"white_normal");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"light_orange_normal");}
- (UIColor *)bgColorDisabledStatic {return PEXCol(@"white_normal");}

@end
