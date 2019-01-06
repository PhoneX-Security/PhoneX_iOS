//
//  PEXGuiDetailView.m
//  Phonex
//
//  Created by Matej Oravec on 12/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiDetailView.h"
#import "PEXGuiRowItemView_Protected.h"

#import "PEXGuiClassicLabel.h"

@interface PEXGuiDetailView ()

@property (nonatomic ) PEXGuiBaseLabel * L_name;
@property (nonatomic ) PEXGuiBaseLabel * L_value;

@end

@implementation PEXGuiDetailView

- (id) init
{
    self = [super init];

    self.L_value = [[PEXGuiClassicLabel alloc]
                    initWithFontSize:PEXVal(@"dim_size_medium")];
    [self addSubview:self.L_value];

    self.L_name = [[PEXGuiClassicLabel alloc]
                   initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_name];

    return self;
}

- (void) setName: (NSString * const) name
{
    self.L_name.text = name;
}

- (void) setValue: (NSString * const) value
{
    self.L_value.text = value;
}

- (void) setValue: (NSString * const) value fontColor: (UIColor *) fontColor
{
    self.L_value.text = value;
    if (fontColor != nil) {
        self.L_value.textColor = fontColor;
    }
}

- (void) multiLineValue: (BOOL) multiline {
    self.L_value.numberOfLines = multiline ? 0 : 1;
}

- (void) setAttributedValue: (NSAttributedString *) attributedValue {
    self.L_value.attributedText = attributedValue;
    [self.L_value sizeToFit];
}

- (void) highlightValue
{
    self.L_value.textColor = PEXCol(@"orange_normal");
}

- (void) dehighlightValue
{
    self.L_value.textColor = PEXCol(@"black_normal");
}

- (void) setEnabledLook:(const bool)enabled {
    [super setEnabled:enabled];
    self.L_value.textColor = enabled ? PEXCol(@"black_normal") : PEXCol(@"light_gray_normal");
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU moveAboveCenter:self.L_name];
    //[PEXGVU moveToLeft:self.L_name withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU scaleHorizontally:self.L_name withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveBelowCenter:self.L_value];
    //[PEXGVU moveToLeft:self.L_value withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU scaleHorizontally:self.L_value withMargin:PEXVal(@"dim_size_large")];
    if (self.L_value.numberOfLines == 0 || self.L_value.numberOfLines > 1) {
        [self.L_value sizeToFit];
    }
}

- (UIColor *) bgColorDisabledStatic { return [self bgColorNormalStatic];}

@end
