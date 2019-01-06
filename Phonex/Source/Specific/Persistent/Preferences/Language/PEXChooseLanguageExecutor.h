//
//  PEXChooseLanguageExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 14/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"
#import "PEXGuiDialogBinaryListener.h"

@class PEXGuiController;

@interface PEXChooseLanguageExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener>

- (id) initWithParentController: (PEXGuiController * const)parent;

@end
