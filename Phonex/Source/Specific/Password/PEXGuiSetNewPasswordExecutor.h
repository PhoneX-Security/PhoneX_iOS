//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"
#import "PEXGuiDialogUnaryListener.h"

@protocol PEXPasswordListener;
@class PEXGuiController;


@interface PEXGuiSetNewPasswordExecutor : PEXGuiExecutor<PEXGuiDialogUnaryListener>

- (id) initWithParentController: (PEXGuiController * const)parent
                       listener: (id<PEXPasswordListener>) listener;

// Shows the dialog
- (void)showGetChangePassword;

@end