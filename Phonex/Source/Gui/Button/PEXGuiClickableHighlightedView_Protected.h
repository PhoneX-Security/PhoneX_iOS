//
//  PEXGuiClickableHighlightedView_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiClickableHighlightedView.h"
#import "PEXGuiClickableView_Protected.h"

@interface PEXGuiClickableHighlightedView ()

-(void) setStateNormal;
-(void) setStateHighlight;
-(void) setStateDisabled;
-(void) setState: (UIColor * const) bgColor;

- (UIColor *)bgColorNormalStatic;
- (UIColor *)bgColorHighlightStatic;
- (UIColor *)bgColorDisabledStatic;

@end

