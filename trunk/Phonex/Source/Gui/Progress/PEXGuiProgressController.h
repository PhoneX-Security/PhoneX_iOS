//
//  PEXGuiProgressController.h
//  Phonex
//
//  Created by Matej Oravec on 26/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiController.h"

#import "PEXTaskListener.h"

@class PEXTask;

@interface PEXGuiProgressController : PEXGuiController<PEXTaskListener>

- (id) initWithTask: (PEXTask * const) task;

@end
