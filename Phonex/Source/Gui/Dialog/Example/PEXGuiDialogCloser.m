//
//  PEXDialogCloser.m
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogCloser.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"
#import "PEXReport.h"

@interface PEXGuiDialogCloser ()

@end

@implementation PEXGuiDialogCloser

- (id)initWithDialogSubcontroller:(PEXGuiController *const)controller listener:(id <PEXGuiDialogUnaryListener>)listener
{
    self = [super initWithDialogSubcontroller:controller listener:listener];

    self.primaryButtonTitle = PEXStrU(@"B_close");

    return self;
}


- (void) finishPrimary
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CLOSE];
    if (self.finishPrimaryBlock)
        self.finishPrimaryBlock();
}

@end
