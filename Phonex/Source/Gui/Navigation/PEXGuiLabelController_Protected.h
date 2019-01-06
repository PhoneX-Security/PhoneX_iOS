//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLabelController.h"
#import "PEXGuiControllerDecorator_Protected.h"
#import "PEXGuiClassicLabel.h"

@class PEXGuiNavigationLabel;
@class PEXGuiClickableView;

@interface PEXGuiLabelController ()

@property (nonatomic) UIView * V_background;
@property (nonatomic) PEXGuiClassicLabel * L_title;

@property (nonatomic) PEXGuiClickableView * B_profileWrapper;

- (CGFloat) leftLabelEnd;
- (CGFloat) rightLabelEnd;

@end