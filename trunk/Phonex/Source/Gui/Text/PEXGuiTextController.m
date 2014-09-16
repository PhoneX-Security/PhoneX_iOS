//
//  PEXGuiTextController.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiTextController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiTextView.h"
#import "PEXGuiControllerDecorator.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiTextController ()

@property (nonatomic) NSString * text;
@property (nonatomic) PEXGuiTextView * blackLow;

@end

@implementation PEXGuiTextController

- (id) init
{
    return [self initWithText:PEXDefaultStr];
}

- (id) initWithText: (NSString * const) text
{
    self = [super init];

    self.text = text;

    return self;
}

- (UIView *) getMainView
{
    return [[PEXGuiTextView alloc] init];
}

- (void) initGuiComponents
{
    self.blackLow = (PEXGuiTextView *) self.mainView;
}

- (void) initContent
{
    [self.blackLow setText:self.text];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    // blackLow == mainView
    [PEXGVU setWidth:self.blackLow to:[parent subviewMaxWidth]];
    [self.blackLow sizeToFit];
}

@end
