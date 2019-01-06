//
//  PEXGuiMessageBreakerView.m
//  Phonex
//
//  Created by Matej Oravec on 30/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiMessageBreakerView.h"

#import "PEXGuiMessageBreakerLine.h"
#import "PEXPaddingLabel.h"
#import "PEXGuiBreakerLabelView.h"

@interface PEXGuiMessageBreakerView ()

@property (nonatomic) PEXGuiMessageBreakerLine * leftLine;
@property (nonatomic) PEXGuiMessageBreakerLine * rightLine;
@property (nonatomic) PEXGuiBreakerLabelView * messageLabel;

@end


@implementation PEXGuiMessageBreakerView

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    [self initGuiStuff];

    return self;
}

- (void) initGuiStuff
{
    self.leftLine = [[PEXGuiMessageBreakerLine alloc] init];
    [self addSubview:self.leftLine];

    self.rightLine = [[PEXGuiMessageBreakerLine alloc] init];
    [self addSubview:self.rightLine];

    self.messageLabel = [[PEXGuiBreakerLabelView alloc]
                         initWithFontColor:PEXCol(@"black_normal")
                         bgColor:PEXCol(@"light_gray_high")];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.messageLabel];
}

- (void) setText: (NSString * const)text
{
    self.messageLabel.text = text;

    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    const CGFloat margin = PEXVal(@"dim_size_large");

    // TEXTLABEL
    const CGSize messageLabelSize = self.messageLabel.frame.size;
    [PEXGVU setHeight:self to:[PEXGuiMessageBreakerView staticHeight]];
    [PEXGVU center:self.messageLabel];

    // LINES
    const CGFloat widthForLine = ((self.frame.size.width -
            messageLabelSize.width) / 2.0f) - (2.0f * margin);
    [PEXGVU setWidth:self.rightLine to:widthForLine];
    [PEXGVU setWidth:self.leftLine to:widthForLine];
    [PEXGVU centerVertically: self.rightLine];
    [PEXGVU centerVertically: self.leftLine];
    [PEXGVU moveToRight: self.rightLine withMargin:margin];
    [PEXGVU moveToLeft: self.leftLine withMargin:margin];
}

+ (CGFloat) staticHeight
{
    return [PEXGuiBreakerLabelView height] + (2.0f * PEXVal(@"dim_size_tiny_small"));
}

@end
