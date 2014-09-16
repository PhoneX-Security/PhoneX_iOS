//
//  PEXGuiController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 05/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiController ()

@property (nonatomic) UIView * mainView;

- (UIView *) getMainView;
- (UIView *) getBackgroundView;
- (void) initMasterViewOnScreen;
- (void) initMasterViewInView;

- (void) postInit;
- (void) initGuiComponents;
- (void) initBehavior;
- (void) initContent;

- (void) recalculateOnScreen: (UIViewController * const) parent;
- (void) recalculateInView: (PEXGuiControllerDecorator * const) parent;

- (void) setSizeOnScreen: (UIViewController * const) parent;
- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent;

- (void) initLayout;

@end
