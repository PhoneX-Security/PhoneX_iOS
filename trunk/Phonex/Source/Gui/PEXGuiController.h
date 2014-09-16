//
//  PEXGuiCustomViewController.h
//  Phonex
//
//  Created by Matej Oravec on 28/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PEXGuiControllerDecorator;

@interface PEXGuiController : UIViewController<UITextFieldDelegate>

- (void) prepareOnScreen: (UIViewController * const) parent;
- (void) prepareInView: (PEXGuiControllerDecorator * const) parent;
- (void) show:(UIViewController * const) parent;

@end
