//
//  PEXGuiSelectionBar.m
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSelectionBar.h"
#import "PEXGuiSelectionBar_Protected.h"

#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiFileUtils.h"
#import "PEXFilePickManager.h"

#import "PEXGuiNegCrossView.h"

@interface PEXGuiSelectionBar ()

@end

@implementation PEXGuiSelectionBar

- (id) initWithRightActionImage: (UIView * const) image
{
    self = [self init];

    // TODO better
    [self.I_send removeFromSuperview];
    self.I_send = image;
    [self.B_next addSubview:self.I_send];

    return self;
}

- (id) init
{
    self = [super init];

    self.B_next  = [[PEXGuiClickableView alloc] init];
    [self addSubview:self.B_next];
    self.I_send = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"send")];
    [self.B_next addSubview:self.I_send];

    self.B_clearSelection  = [[PEXGuiClickableView alloc] init];
    [self addSubview:self.B_clearSelection];
    self.I_clearSelection = [[PEXGuiNegCrossView alloc] initWithColor:PEXCol(@"light_gray_low")];
    [self.B_clearSelection addSubview:self.I_clearSelection];

    self.L_primaryRestriction = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                                   fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_primaryRestriction];

    self.backgroundColor = PEXCol(@"light_gray_high");
    self.bgColor = self.backgroundColor;

    self.V_disabler = [[UIView alloc] init];
    self.V_disabler.backgroundColor = PEXCol(@"light_gray_high_transparent");
    [self addSubview:self.V_disabler];

    [PEXGVU setHeight:self to: [PEXGuiSelectionBar staticHeight]];

    return self;
}


+ (CGFloat) staticHeight
{
    return 3.0f * PEXVal(@"dim_size_medium");
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    const CGFloat padding = PEXVal(@"dim_size_large");
    const CGFloat halfPadding = padding / 2.0f;
    const CGFloat paddingWidth = padding * 1.5f;

    [PEXGVU scaleVertically:self.B_next];
    [PEXGVU setWidth:self.B_next
                  to:self.I_send.frame.size.width + paddingWidth];
    [PEXGVU moveToRight:self.B_next];
    [PEXGVU centerVertically:self.I_send];
    [PEXGVU moveToRight:self.I_send withMargin:padding];

    [PEXGVU scaleVertically:self.B_clearSelection];
    [PEXGVU setWidth:self.B_clearSelection
                  to:self.I_clearSelection.frame.size.width + paddingWidth];
    [PEXGVU moveToLeft:self.B_clearSelection];
    [PEXGVU centerVertically:self.I_clearSelection];
    [PEXGVU moveToLeft:self.I_clearSelection withMargin:padding];

    [PEXGVU centerVertically:self.L_primaryRestriction];

    [PEXGVU scaleFull:self.V_disabler];
}

- (void)setPrimaryLabelText: (NSString * const) text
{
    [self setText:text forLabel:self.L_primaryRestriction];
}

- (void) setText: (NSString * const) text forLabel: (UILabel * const) label
{
    label.text = text;
    [PEXGVU centerHorizontally: label];
}

- (void) setEnabled:(const bool)enabled
{
    [self.V_disabler setHidden:enabled];
}

@end
