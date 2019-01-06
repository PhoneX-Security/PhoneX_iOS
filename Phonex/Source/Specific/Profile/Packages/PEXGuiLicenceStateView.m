//
// Created by Matej Oravec on 25/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiLicenceStateView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiReadOnlyTextView.h"

@interface PEXGuiLicenceStateView ()

@property (nonatomic) PEXGuiReadOnlyTextView * TV_validity;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_calls;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_messages;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_support;

//@property (nonatomic) PEXGuiClassicLabel * B_seeDetails;

@end

@implementation PEXGuiLicenceStateView {

}

- (id) init
{
    self = [super init];

    self.TV_validity = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_validity setScrollEnabled:false];
    [self addSubview:self.TV_validity];

    self.TV_calls = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_calls setScrollEnabled:false];
    [self addSubview:self.TV_calls];

    self.TV_messages = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_messages setScrollEnabled:false];
    [self addSubview:self.TV_messages];

    self.TV_support = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_support setScrollEnabled:false];
    [self addSubview:self.TV_support];

    return self;
}

- (void) dataWasSet
{
    [PEXGVU scaleHorizontally:self.TV_validity];
    [self.TV_validity sizeToFit];
    [PEXGVU moveToTop:self.TV_validity];

    [PEXGVU scaleHorizontally:self.TV_calls];
    [self.TV_calls sizeToFit];
    [PEXGVU move:self.TV_calls below:self.TV_validity];

    [PEXGVU scaleHorizontally:self.TV_messages];
    [self.TV_messages sizeToFit];
    [PEXGVU move:self.TV_messages below:self.TV_calls];

    [PEXGVU scaleHorizontally:self.TV_support];
    [self.TV_support sizeToFit];
    [PEXGVU move:self.TV_support below:self.TV_messages];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self dataWasSet];
}


@end