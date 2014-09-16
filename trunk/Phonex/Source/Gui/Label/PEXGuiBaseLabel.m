//
//  PEXGuiLabel.m
//  Phonex
//
//  Created by Matej Oravec on 01/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiBaseLabel.h"

#import "PEXResColors.h"

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
    return self;
}

- (id)initWithFontSize: (const CGFloat) fontSize
             fontColor: (UIColor * const) fontColor
{
    self = [self initWithFontSize:fontSize
                         fontColor:fontColor
                           bgColor:PEXCol(@"#invisible")];
    return self;
}

- (id)initWithFontSize: (const CGFloat) fontSize
{
    self = [self initWithFontSize:fontSize
                        fontColor:[UIColor blackColor]
                          bgColor:PEXCol(@"#invisible")];
    return self;
}

- (void) setStyle
{
    self.font = [UIFont systemFontOfSize: _fontSize];
    [self setTextColor:_fontColor];
    [self setBackgroundColor:_bgColor];
    [self setTextAlignment:NSTextAlignmentCenter];
}

@end
