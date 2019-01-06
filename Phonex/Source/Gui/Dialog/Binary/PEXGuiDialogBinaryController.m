//
//  PEXGuiDialogBinaryController.m
//  Phonex
//
//  Created by Matej Oravec on 18/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryController.h"
#import "PEXGuiDialogBinaryController_Protected.h"

@interface PEXGuiDialogBinaryController ()

@end

@implementation PEXGuiDialogBinaryController

- (id) initWithVisitor: (PEXGuiDialogBinaryVisitor * const) visitor
{
    self = [super initWithVisitor:visitor];

    self.binaryVisitor = visitor;

    return self;
}

- (UIButton *)secondaryButton
{
    return _B_secondary;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_secondary = [[PEXGuiButtonDIalogSecondary alloc] init];
    [self.mainView addSubview:self.B_secondary];
}

- (void) initLayout
{
    [super initLayout];

    // beacuse of alias ... when cast to int ... there was shift to right
    // so we use floats in the end
    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat primaryButtonWidth = (width / 2.0f);
    const CGFloat secondaryButtonWidth = (width - primaryButtonWidth);

    [PEXGVU setWidth:self.B_primary to:primaryButtonWidth];
    [PEXGVU setWidth:self.B_secondary to:secondaryButtonWidth];

    [PEXGVU moveToBottom:self.B_secondary];
    [PEXGVU moveToRight:self.B_secondary];
    [PEXGVU moveToBottom:self.B_primary];
    [PEXGVU moveToLeft:self.B_primary];
}

@end
