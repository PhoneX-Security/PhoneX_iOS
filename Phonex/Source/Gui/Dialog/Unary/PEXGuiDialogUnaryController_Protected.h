//
//  PEXGuiDialogUnaryController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 16/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogUnaryController.h"
#import "PEXGuiControllerDecorator_Protected.h"

#import "PEXGuiButtonDialogPrimary.h"

@class PEXGuiDialogUnaryVisitor;

@interface PEXGuiDialogUnaryController ()

@property (nonatomic) PEXGuiButton * B_primary;
@property (nonatomic) PEXGuiDialogUnaryVisitor * unaryVisitor;

@end
