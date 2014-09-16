//
//  PEXGuinavigationControllerViewController.h
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerDecorator.h"

@interface PEXGuiNavigationController : PEXGuiControllerDecorator

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title;

@end
