//
//  PEXGuiCallBaseViewController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 05/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//



@interface PEXGuiDialogUnaryVisitor ()

@property (nonatomic, weak) PEXGuiDialogUnaryController * dialog;
@property (nonatomic, weak) PEXGuiController * subcontroller;

- (void) firstButtonAction;

@end