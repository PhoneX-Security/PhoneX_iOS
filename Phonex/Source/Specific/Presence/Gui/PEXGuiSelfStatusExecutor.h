//
//  PEXGuiSelfStatusExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 28/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"
#import "PEXGuiDialogBinaryListener.h"

@class PEXGuiController;
@protocol PEXGuiProfileDetailClicked;


@interface PEXGuiSelfStatusExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener, PEXGuiProfileDetailClicked>

- (id) initWithParentController: (PEXGuiController * const)parent;
- (void)show;

@end
