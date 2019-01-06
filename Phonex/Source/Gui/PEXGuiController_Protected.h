//
//  PEXGuiController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 05/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"

#define PEXStdKeyboardAnimation @"StdKeyboardAnimation"

@interface PEXGuiController ()
{
    bool _shownByModal;
}

// reference to the nearest fullscreen controller
@property (nonatomic, weak) UIViewController * fullscreener;

@property (nonatomic) UIView * mainView;
@property (nonatomic) UIView * statusBarView;

- (UIView *) getMainView;
- (UIView *)getBackgroundView;
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
- (void) initState;

- (CGFloat) getKeyboardOffset;

- (void) slideToHide: (NSNotification * const)notification;
- (void) youDidEndEditing;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void) animateSlide: (const CGFloat) y
          accordingTo: (const NSNotification * const) notification;

-(CGFloat) getTopKeyboardPoint;

@end
