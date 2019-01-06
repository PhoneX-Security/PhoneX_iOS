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

@property (nonatomic, assign) bool showProgressBar;

- (id) initWithTask: (PEXTask * const) task;
- (void)setTheTask: (PEXTask * const) task;

@end
