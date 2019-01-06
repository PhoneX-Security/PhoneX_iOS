//
//  PEXGuiActionOnContactNavigationController.h
//  Phonex
//
//  Created by Matej Oravec on 08/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLabelController.h"

#import "PEXGuiActionOnContactListener.h"

@interface PEXGuiActionOnContactLabelController : PEXGuiLabelController

- (void) setListener: (id<PEXGuiActionOnContactListener>) listener;

@end
