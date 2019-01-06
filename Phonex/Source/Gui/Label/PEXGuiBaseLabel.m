//
//  PEXGuiLabel.m
//  Phonex
//
//  Created by Matej Oravec on 01/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiBaseLabel.h"

@interface PEXGuiBaseLabel ()

@property (nonatomic) UIColor * fontColor;
@property (nonatomic) UIColor * bgColor;

@end

@implementation PEXGuiBaseLabel

- (id)initWithFontSize: (const CGFloat) fontSize
             fontColor: (UIColor * const) fontColor
               bgColor: (UIColor * const) bgColor;
{
    self = [super init];
    self.fontSize = fontSize;
    self.fontColor = fontColor;
    self.bgColor = bgColor;

    [self setStyle];
    self.text = PEXDefaultStr;

    [self sizeToFit];
    return self;
}

- (id)initWithFontSize: (const CGFloat) fontSize
             fontColor: (UIColor * const) fontColor
{
    self = [self initWithFontSize:fontSize
                         fontColor:fontColor
                           bgColor:PEXCol(@"invisible")];
    return self;
}

- (id)initWithFontSize: (const CGFloat) fontSize
{
    self = [self initWithFontSize:fontSize
                        fontColor:PEXCol(@"black_normal")
                          bgColor:PEXCol(@"invisible")];
    return self;
}

- (id) init
{
    self = [self initWithFontSize:PEXVal(@"dim_size_medium")
                        fontColor:PEXCol(@"black_normal")
                          bgColor:PEXCol(@"invisible")];
    return self;
}

- (void) setStyle
{
    self.font = [UIFont systemFontOfSize: _fontSize];
    [self setTextColor:_fontColor];
    [self setBackgroundColor:_bgColor];
    self.textAlignment = NSTextAlignmentLeft;
}

- (void)sizeToFitMaxWidth: (NSNumber *) maxWidth maxHeight: (NSNumber *) maxHeight {
    [super sizeToFit];

    if (maxHeight != nil && self.frame.size.height > [maxHeight floatValue]){
        [PEXGVU setHeight:self to:[maxHeight floatValue]];
    }

    if (maxWidth != nil && self.frame.size.width > [maxWidth floatValue]){
        [PEXGVU setWidth:self to:[maxWidth floatValue]];
    }
}

@end
