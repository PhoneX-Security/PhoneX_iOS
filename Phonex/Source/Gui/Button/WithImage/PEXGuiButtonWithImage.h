//
//  PEXGuiButtonWithImage.h
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiClickableHighlightedView.h"

@interface PEXGuiButtonWithImage : PEXGuiClickableHighlightedView

- (id)initWithImage:(UIView * const) image;

- (id)initWithImage:(UIView* const) image labelText:(NSString * const) label;

- (id)initWithImage:(UIView * const) image labelText:(NSString * const) label
           fontSize:(const CGFloat) fontSize;

@end
