//
//  PEXDialogUnaryDialogVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryVisitor.h"
#import "PEXGuiDialogBinaryVisitor_Protected.h"
#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiDialogBinaryVisitor ()

@property (nonatomic) id<PEXGuiDialogBinaryListener> binaryListener;

@end

@implementation PEXGuiDialogBinaryVisitor


- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                         listener: (id<PEXGuiDialogUnaryListener>) listener
{
    self = [super initWithDialogSubcontroller:controller listener:listener];

    self.secondaryButtomtitle = PEXStrU(@"B_cancel");
    self.binaryListener = (id <PEXGuiDialogBinaryListener>) self.unaryListener;

    return self;
}

- (void) setBehavior: (PEXGuiDialogUnaryController * const) dialog
{
    [super setBehavior:dialog];

    self.binaryDialog = (PEXGuiDialogBinaryController *)dialog;
    [[(PEXGuiDialogBinaryController *)dialog secondaryButton] addTarget:self action:@selector(finishSecond)
                    forControlEvents:UIControlEventTouchUpInside];
}

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog
{
    [super setContent:dialog];

    [[(PEXGuiDialogBinaryController *)dialog secondaryButton]
            setTitle:self.secondaryButtomtitle forState:UIControlStateNormal];
};

- (void) finishSecond
{
    if (self.binaryListener)
    {
        [self.binaryListener secondaryButtonClicked];
    }

    if (self.onSecondaryActionClick){
        self.onSecondaryActionClick(self.binaryDialog);
    }
};

@end
