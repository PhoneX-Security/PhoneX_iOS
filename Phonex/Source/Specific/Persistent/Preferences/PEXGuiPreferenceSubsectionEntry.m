//
// Created by Dusan Klinec on 13.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPreferenceSubsectionEntry.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiImageView.h"
#import "PEXGuiArrowNext.h"

@interface PEXGuiPreferenceSubsectionEntry()
{

}

@property (nonatomic) UILabel * L_description;
@property (nonatomic) PEXGuiArrowNext * I_nextImage;
@property (nonatomic) PEXGuiClickableView * B_clicker;

@end

@implementation PEXGuiPreferenceSubsectionEntry {

}

- (id) init
{
    self = [super init];

    self.L_description = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    [self addSubview:self.L_description];

    self.I_nextImage = [[PEXGuiArrowNext alloc] initWithColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.I_nextImage];

    self.B_clicker = [[PEXGuiClickableView alloc] init];
    [self addSubview:self.B_clicker];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.L_description];
    [PEXGVU moveToLeft: self.L_description withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU setSize:self.I_nextImage x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU centerVertically:self.I_nextImage];
    [PEXGVU moveToRight: self.I_nextImage withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleFull: self.B_clicker];
    [self bringSubviewToFront:self.B_clicker];
}

- (void) setLabel: (NSString * const) label
{
    self.L_description.text = label;
}

@end