//
//  PEXDialogUnaryDialogVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogUnaryVisitor.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"
#import "PEXGuiDialogUnaryListener.h"
#import "PEXReport.h"

@interface PEXGuiDialogUnaryVisitor ()

@end

@implementation PEXGuiDialogUnaryVisitor

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
{
    self = [super init];

    self.subcontroller = controller;
    self.primaryButtonTitle = PEXStrU(@"B_ok");

    return self;
}

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                         listener: (id<PEXGuiDialogUnaryListener>) listener
{
    self = [self initWithDialogSubcontroller:controller];

    self.unaryListener = listener;

    return self;
}

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                    primaryAction: (PEXDialogActionListenerBlock) primaryAction
{
    self = [self initWithDialogSubcontroller:controller];

    self.onPrimaryActionClick = primaryAction;

    return self;
}

- (void) setBehavior: (PEXGuiDialogUnaryController * const) dialog
{
    self.dialog = dialog;

    [[dialog primaryButton] addTarget:self action:@selector(finishPrimary)
                   forControlEvents:UIControlEventTouchUpInside];
}

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog
{
    [[dialog primaryButton] setTitle:self.primaryButtonTitle forState:UIControlStateNormal];
};

- (void) finishPrimary
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CLOSE];
    if (self.unaryListener)
    {
        [self.unaryListener primaryButtonClicked];
    }

    if (self.onPrimaryActionClick){
        self.onPrimaryActionClick(self.dialog);
    }
};

@end
