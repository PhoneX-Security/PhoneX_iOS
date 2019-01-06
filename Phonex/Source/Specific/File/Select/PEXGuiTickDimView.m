//
//  PEXGuiTickDimView.m
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiTickDimView.h"

#import "PEXGuiTick.h"

@interface PEXGuiTickDimView ()

@property (nonatomic) PEXGuiTick * V_tick;

@end

@implementation PEXGuiTickDimView


- (id) init
{
    self = [super init];

    self.backgroundColor = PEXCol(@"dim");

    self.V_tick = [[PEXGuiTick alloc] initWithColor:PEXCol(@"orange_normal")];
    [self addSubview: self.V_tick];

    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU setSize:self.V_tick x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU center:self.V_tick];
}

@end
