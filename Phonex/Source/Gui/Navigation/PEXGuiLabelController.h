//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiControllerDecorator.h"


@interface PEXGuiLabelController : PEXGuiControllerDecorator

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title;

- (void) setLabelText: (NSString * const) text;

@end