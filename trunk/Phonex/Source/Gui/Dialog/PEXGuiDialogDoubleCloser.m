//
//  PEXGuiDialogDoubleCloser.m
//  Phonex
//
//  Created by Matej Oravec on 18/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogDoubleCloser.h"

#import "PEXGuiDialogBinaryController_Friend.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiDialogDoubleCloser ()

@property (nonatomic, weak) PEXGuiDialogBinaryController * binaryController;

- (void) firstButtonAction;

@end

@implementation PEXGuiDialogDoubleCloser

- (void) setContent: (PEXGuiDialogBinaryController * const) dialog
{
    [[dialog firstButton] setTitle:(PEXStrU(@"close")) forState:UIControlStateNormal];
    [[dialog secondButton] setTitle:(PEXStrU(@"close")) forState:UIControlStateNormal];
}

- (void) finishSecond
{
    [self firstButtonAction];
}

- (void) firstButtonAction
{
    [self.binaryController dismissViewControllerAnimated:YES completion:nil];
}

@end
