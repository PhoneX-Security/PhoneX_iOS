//
//  PEXGuiDialogProgressCanceller.h
//  Phonex
//
//  Created by Matej Oravec on 30/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiDialogUnaryVisitor.h"

#import "PEXTaskListener.h"


@class PEXTask;

@interface PEXGuiDialogProgressCanceller : PEXGuiDialogUnaryVisitor<PEXTaskListener>

@property (nonatomic, copy) void (^howToDismiss)(void);

- (id) initWithController: (PEXGuiController * const) controller;

- (void) setTheTask: (PEXTask * const) task;

@end
