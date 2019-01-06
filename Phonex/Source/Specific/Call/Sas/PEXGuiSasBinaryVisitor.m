//
//  PEXGuiSasBinaryVisitor.m
//  Phonex
//
//  Created by Matej Oravec on 05/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSasBinaryVisitor.h"
#import "PEXGuiDialogBinaryVisitor_Protected.h"

@implementation PEXGuiSasBinaryVisitor

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                         listener: (id<PEXGuiDialogUnaryListener>) listener
{
    self = [super initWithDialogSubcontroller:controller listener:listener];

    self.primaryButtonTitle = PEXStrU(@"B_approve");
    self.secondaryButtomtitle = PEXStrU(@"B_reject");

    return self;
}

@end
