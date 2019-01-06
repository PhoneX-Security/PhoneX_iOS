//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiUnaryDialogExecutor.h"
#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiBinaryDialogExecutor : PEXGuiUnaryDialogExecutor<PEXGuiDialogBinaryListener>

@property (nonatomic) NSString * secondaryButtonText;
@property (nonatomic, copy) void (^secondaryAction)(void);

@end