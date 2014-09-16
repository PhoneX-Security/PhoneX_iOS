//
//  PEXGuiWindowWithTitleController.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiWindowController.h"

@interface PEXGuiWindowWithTitleController : PEXGuiWindowController

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title;

@end
