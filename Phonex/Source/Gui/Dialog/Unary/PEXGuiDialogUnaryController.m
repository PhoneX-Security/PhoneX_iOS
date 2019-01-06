//
//  PEXGuiDialogViewController.m
//  Phonex
//
//  Created by Matej Oravec on 11/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogUnaryController.h"
#import "PEXGuiDialogUnaryController_Protected.h"

#import "PEXGuiDialogUnaryVisitor.h"
#import "PEXGuiBackgroundView.h"

#import "PEXGuiDialogBackground.h"

@interface PEXGuiDialogUnaryController ()

@end

@implementation PEXGuiDialogUnaryController

- (id) initWithVisitor: (PEXGuiDialogUnaryVisitor * const) visitor
{
    self = [super initWithViewController:[visitor subcontroller]];

    self.unaryVisitor = visitor;

    return self;
}

- (UIView *) getMainView
{
    return [[PEXGuiDialogBackground alloc] init];
}

- (UIView *)getBackgroundView
{
    return [[PEXGuiDialogBackground alloc] init];
}

- (UIButton *)primaryButton
{
    return _B_primary;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_primary = [[PEXGuiButtonDialogPrimary alloc] init];
    [self.mainView addSubview:self.B_primary];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_primary];
    [PEXGVU moveToBottom:self.B_primary];

    [PEXGVU move: ((UIViewController*)self.childViewControllers[0]).view above:self.B_primary /*withMargin:1.0f*/];
}

- (void) initContent
{
    [super initContent];

    [_unaryVisitor setContent:self];
}

- (void) initBehavior
{
    [super initBehavior];
    
    [_unaryVisitor setBehavior:self];
}

- (void) setStaticSize
{
    [self staticWidth: 0.0f];
    [self staticHeight: [PEXGuiButtonDialogPrimary height] /*+ 1.0f*/];
}

@end
