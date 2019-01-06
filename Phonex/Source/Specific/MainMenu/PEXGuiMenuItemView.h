//
//  PEXGuiMainMenuItem.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonWithImage.h"
#import "PEXGuiRowItemView.h"
#import "PEXGuiRowItemViewWithImage.h"

@interface PEXGuiMenuItemView : PEXGuiRowItemViewWithImage

- (id)initWithImage:(UIView * const) image labelText:(NSString * const) label;

- (void) setLabelText: (NSString * const) text;

- (void) highlighted;
- (void) normal;

@end
