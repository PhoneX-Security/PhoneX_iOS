//
//  PEXGuiChatNavigationController.h
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiAppNavigationController.h"

#import "PEXGuiChatController.h"

@interface PEXGuiChatNavigationController : PEXGuiAppNavigationController

@property (nonatomic) bool shown;

- (id) initWithViewController: (PEXGuiController * const) controller
                      contact: (const PEXDbContact * const) contact
               chatController: (PEXGuiChatController * const) chatController;

@end
