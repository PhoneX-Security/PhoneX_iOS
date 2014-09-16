//
//  PEXGuiDialogBinaryController.m
//  Phonex
//
//  Created by Matej Oravec on 18/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogBinaryController.h"
#import "PEXGuiDialogBinaryController_Friend.h"
#import "PEXGuiDialogBinaryController_Protected.h"

#import "PEXGuiDialogBinaryVisitor.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiDialogBinaryController ()

@end

@implementation PEXGuiDialogBinaryController

- (id) initWithVisitor: (PEXGuiDialogBinaryVisitor * const) visitor
{
    self = [super initWithVisitor:visitor];

    self.binaryVisitor = visitor;

    return self;
}

- (UIButton *) secondButton
{
    return _B_second;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_second = [[PEXGuiButtonDialogFirst alloc] init];
    [self.mainView addSubview:self.B_second];
}

- (void) initLayout
{
    // TODO make it better
    [super initLayout];

    const CGFloat buttonWidth = (self.mainView.frame.size.width / 2.0f) - 1.0f;
    [PEXGVU setWidth:self.B_first to:buttonWidth];
    [PEXGVU setWidth:self.B_second to:buttonWidth];

    [PEXGVU moveToBottom:self.B_first];
    [PEXGVU moveToBottom:self.B_second];
    [PEXGVU moveToRight:self.B_second];
}

@end
