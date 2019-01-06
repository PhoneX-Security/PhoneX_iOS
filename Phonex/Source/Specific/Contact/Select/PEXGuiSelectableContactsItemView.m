//
//  PEXGuiSelectableContactsItemView.m
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectableContactsItemView.h"
#import "PEXGuiContactsItemView_Protected.h"

#import "PEXGuiTickDimView.h"
#import "PEXGuiTick.h"

@interface PEXGuiSelectableContactsItemView ()

@property (nonatomic) PEXGuiTickDimView * V_tick;

@end

@implementation PEXGuiSelectableContactsItemView

- (void) initGui
{
    [super initGui];

    self.V_tick = [[PEXGuiTickDimView alloc] init];
    [self addSubview:self.V_tick];

    self.isSelected = false;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleVertically:self.V_tick];
    [PEXGVU setWidth:self.V_tick to:self.aliasView.frame.origin.x];
}


- (void) setIsSelected:(bool)isSelected
{
    _isSelected = isSelected;
    [self.V_tick setHidden: !isSelected];
}

@end
