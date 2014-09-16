//
//  PEXGuiDialogViewController.m
//  Phonex
//
//  Created by Matej Oravec on 11/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogUnaryController.h"
#import "PEXGuiDialogUnaryController_Protected.h"
#import "PEXGuiDialogUnaryController_Friend.h"

#import "PEXGuiDialogUnaryVisitor.h"
#import "PEXGuiDialogCloser.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiViewUtils.h"
#import "PEXGuiButtonDialogFirst.h"

@interface PEXGuiDialogUnaryController ()

@end

@implementation PEXGuiDialogUnaryController

- (id) initWithVisitor: (PEXGuiDialogUnaryVisitor * const) visitor
{
    self = [super initWithViewController:[visitor subcontroller]];

    self.unaryVisitor = visitor;

    return self;
}

- (UIButton *) firstButton
{
    return _B_first;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_first = [[PEXGuiButtonDialogFirst alloc] init];
    [self.mainView addSubview:self.B_first];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_first];
    [PEXGVU moveToBottom:self.B_first];

    [PEXGVU move: self.finalSubview above:self.B_first withMargin:(self.mainView.frame.size.height - self.B_first.frame.size.height - self.finalSubview.frame.size.height) / 2];
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
    [self staticHeight: [PEXGuiButtonDialogFirst height]];
}

@end
