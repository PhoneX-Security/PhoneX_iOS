//
//  PEXDialogUnaryDialogVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryVisitor.h"
#import "PEXGuiDialogBinaryVisitor_Protected.h"

@implementation PEXGuiDialogBinaryVisitor

- (void) setBehavior: (PEXGuiDialogBinaryController * const) dialog
{
    [super setBehavior:dialog];

    // TODO in INIT?
    self.binaryController = dialog;
    [[dialog secondButton] addTarget:self action:@selector(finishSecond)
                    forControlEvents:UIControlEventTouchUpInside];
}

- (void) finishSecond {};

@end
