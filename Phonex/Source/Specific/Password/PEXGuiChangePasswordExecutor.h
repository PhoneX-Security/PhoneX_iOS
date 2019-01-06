//
//  PEXGuiChangePasswordExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"

#import "PEXGuiDialogBinaryListener.h"
#import "PEXTaskListener.h"

@class PEXGuiChangePasswordController;

@interface PEXGuiChangePasswordExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener, PEXTaskListener>

@property (nonatomic) PEXGuiChangePasswordController *showedController;

- (id) initWithParentController: (PEXGuiController * const)parent;
- (void) topControllerShowed: (PEXGuiController * const) topController;

@end
