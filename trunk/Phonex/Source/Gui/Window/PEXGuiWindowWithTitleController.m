//
//  PEXGuiWindowWithTitleController.m
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiWindowWithTitleController.h"
#import "PEXGuiWindowWithTitleController_Protected.h"

#import "PEXGuiWindowTitle.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiWindowWithTitleController ()

@property (nonatomic) NSString * title;
@property (nonatomic) PEXGuiWindowTitle * L_title;

@end

@implementation PEXGuiWindowWithTitleController

- (id) initWithViewController: (PEXGuiController * const) controller
{
    return [self initWithViewController:controller title:PEXDefaultStr];
}

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title
{
    self = [super initWithViewController:controller];

    self.title = title;

    return self;
}

- (void) setStaticSize
{
    [super setStaticSize];

    [self staticHeight:[self staticHeight] + [PEXGuiWindowTitle height]];
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.L_title = [[PEXGuiWindowTitle alloc] init];
    [self.mainView addSubview:self.L_title];
}

- (void) initContent
{
    [super initContent];

    self.L_title.text = self.title;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU moveDown:self.finalSubview by:([PEXGuiWindowTitle height] / 2.0f)];

    [PEXGVU scaleHorizontally:self.L_title];
    [PEXGVU setWidth:self.L_title to:self.finalSubview.frame.size.width];
    [PEXGVU centerHorizontally:self.L_title];
    [PEXGVU move:self.L_title above:self.finalSubview];
}

@end
