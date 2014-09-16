//
//  PEXGuiControllerDecorator_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 16/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerDecorator.h"

#import "PEXGuiController_Protected.h"

@interface PEXGuiControllerDecorator ()

@property (nonatomic) PEXGuiController * subcontroller;
@property (nonatomic) UIView * finalSubview;

// boundaries for the subcontroller
- (void) subviewMaxWidth: (const CGFloat) value;
- (void) subviewMaxHeight: (const CGFloat) value;
- (void) staticWidth: (const CGFloat) value;
- (void) staticHeight: (const CGFloat) value;

// needed when showed in another decorator
- (void) setStaticSize;

@end
