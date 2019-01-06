//
//  PEXGuiSelectionBar_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectionBar.h"

#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiFileUtils.h"
#import "PEXFilePickManager.h"

@interface PEXGuiSelectionBar ()

@property (nonatomic) UIView * I_send;
@property (nonatomic) UIView * I_clearSelection;
@property (nonatomic) PEXGuiClassicLabel *L_primaryRestriction;
@property (nonatomic) UIView * V_disabler;

@property (nonatomic) UIColor * bgColor;

- (void) setText: (NSString * const) text forLabel: (UILabel * const) label;

@end
