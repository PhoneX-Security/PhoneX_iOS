//
// Created by Matej Oravec on 08/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiCallLogCell.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiCallLogItemView.h"

@interface PEXGuiCallLogCell()

@property (nonatomic) PEXGuiItemComposedView * subview;

@end

@implementation PEXGuiCallLogCell {

}

- (UIView *) getSubview
{
    return self.subview;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    [self initSubview];
    [self.contentView addSubview:self.subview];
    self.backgroundColor = PEXCol(@"white_normal");

    return self;
}

- (void) initSubview
{
    PEXGuiCallLogItemView * V_callLog = [[PEXGuiCallLogItemView alloc] init];
    [V_callLog initGuiStuff];
    PEXGuiItemComposedView * const composed = [[PEXGuiItemComposedView alloc] initWithView: V_callLog];
    self.subview = composed;

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [PEXGVU scaleFull:self.subview];
}


@end