//
// Created by Matej Oravec on 29/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageSeenView.h"

#import "PEXGuiClassicLabel.h"

@interface PEXGuiMessageSeenView ()

@property (nonatomic) PEXGuiClassicLabel * L_seen;

@end


@implementation PEXGuiMessageSeenView {

}

- (id)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    self.L_seen = [[PEXGuiClassicLabel alloc]
            initWithFontSize:[PEXGuiMessageSeenView staticHeight]
                   fontColor:PEXCol(@"light_gray_low")];

    [self addSubview:self.L_seen];

    return self;
}

- (void) setDate: (const NSDate * const) date
{
    self.L_seen.text = [NSString stringWithFormat:@"%@ %@", PEXStr(@"L_seen"), [PEXDateUtils dateToTimeString:date]];

    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU moveToRight:self.L_seen withMargin: PEXVal(@"dim_size_large")];
}

+ (CGFloat) staticHeight
{
    return PEXVal(@"dim_size_small_medium");
}

@end