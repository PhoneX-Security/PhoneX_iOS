//
//  PEXGuiChoosePinLockTriggerTimeExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"

#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiChoosePinLockTriggerTimeExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener>

- (id) initWithParentController: (PEXGuiController * const)parent;

@end
