//
//  PEXGuiMessageDetailController.h
//  Phonex
//
//  Created by Matej Oravec on 20/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"

@class PEXMessageModel;

@interface PEXGuiMessageDetailController : PEXGuiController

- (id) initWithMessage: (const PEXMessageModel * const) message;

@end
