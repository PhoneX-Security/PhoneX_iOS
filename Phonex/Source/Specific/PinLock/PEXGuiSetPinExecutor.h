//
//  PEXGuiSetPinExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"

#import "PEXGuiPinLockController.h"

@interface PEXGuiSetPinExecutor : PEXGuiExecutor<PEXPinLockListener>

- (id) initWithParentController: (PEXGuiController * const)parent;
- (void)show;

@end
