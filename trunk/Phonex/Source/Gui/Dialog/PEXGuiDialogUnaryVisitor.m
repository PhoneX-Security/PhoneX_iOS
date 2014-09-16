//
//  PEXDialogUnaryDialogVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogUnaryVisitor.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"

@interface PEXGuiDialogUnaryVisitor ()

@end

@implementation PEXGuiDialogUnaryVisitor

- (id) initWithController: (PEXGuiController *) controller
{
    self = [super init];

    self.subcontroller = controller;

    return self;
}

- (void) setBehavior: (PEXGuiDialogUnaryController * const) dialog
{
    // TODO set in INIT?
    self.dialog = dialog;
    [[dialog firstButton] addTarget:self action:@selector(firstButtonAction)
                   forControlEvents:UIControlEventTouchUpInside];
}

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog {};

- (void) firstButtonAction {};

@end
