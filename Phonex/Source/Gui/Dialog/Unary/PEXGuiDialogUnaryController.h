//
//  PEXGuiDialogViewController.h
//  Phonex
//
//  Created by Matej Oravec on 11/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiControllerDecorator.h"

@class PEXGuiDialogUnaryVisitor;

@interface PEXGuiDialogUnaryController : PEXGuiControllerDecorator

- (id) initWithVisitor: (PEXGuiDialogUnaryVisitor * const) visitor;

@end
