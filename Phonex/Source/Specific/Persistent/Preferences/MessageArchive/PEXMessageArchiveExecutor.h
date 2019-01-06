//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"

#import "PEXGuiDialogBinaryListener.h"

@interface PEXMessageArchiveExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener>

- (id) initWithParentController: (PEXGuiController * const)parent;

@end