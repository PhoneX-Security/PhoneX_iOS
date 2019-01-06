//
//  PEXGuiShieldView.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiShieldView.h"

#import "PEXGuiImageView.h"

@interface PEXGuiShieldView ()

@property (nonatomic) PEXGuiImageView * I_appLogo;

@end

@implementation PEXGuiShieldView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.backgroundColor = PEXCol(@"white_normal");
    self.I_appLogo = [[PEXGuiImageView alloc] init];
    [self addSubview: self.I_appLogo];
    [self.I_appLogo setImage:PEXImg(@"logo_large")];

    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU center:self.I_appLogo];
}

@end
