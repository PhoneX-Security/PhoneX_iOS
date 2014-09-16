//
//  PEXDialogCloser.m
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogCloser.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"

#import "PEXGuiDialogUnaryController.h"

@interface PEXGuiDialogCloser ()

@end

@implementation PEXGuiDialogCloser

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog
{
    [[dialog firstButton] setTitle:(PEXStrU(@"close")) forState:UIControlStateNormal];
}

- (void) firstButtonAction
{
    [self.dialog dismissViewControllerAnimated:YES completion:nil];
}

@end
