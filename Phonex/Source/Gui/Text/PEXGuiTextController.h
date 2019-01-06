//
//  PEXGuiTextController.h
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"

@interface PEXGuiTextController : PEXGuiController

- (id) initWithText: (NSString * const) text;
- (id) initWithAttributedText: (NSAttributedString * const) text;

@end
