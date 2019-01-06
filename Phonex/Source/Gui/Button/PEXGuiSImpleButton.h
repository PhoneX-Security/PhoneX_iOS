//
//  PEXGuiSImpleButton.h
//  Phonex
//
//  Created by Matej Oravec on 02/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiClickableHighlightedView.h"

@interface PEXGuiSImpleButton : PEXGuiClickableHighlightedView

- (id)initWithText:(NSString * const) text fontSize:(const CGFloat) fontSize;
- (id)initWithText:(NSString * const) text;

- (void) setText: (NSString * const) text;

@end
