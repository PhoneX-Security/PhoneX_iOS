//
//  PEXGuiControllerWithSubcontroller.h
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiControllerDecorator : PEXGuiController
{
    @private
    CGFloat _subviewMaxWidth;
    CGFloat _subviewMaxHeight;
    CGFloat _staticWidth;
    CGFloat _staticHeight;
}

- (id) initWithViewController: (PEXGuiController * const) controller;

- (CGFloat) subviewMaxWidth;
- (CGFloat) subviewMaxHeight;
- (CGFloat) staticWidth;
- (CGFloat) staticHeight;

@end
