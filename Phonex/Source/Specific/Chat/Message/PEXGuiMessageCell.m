//
// Created by Matej Oravec on 24/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageCell.h"
#import "PEXGuiMessageCell_Protected.h"

@implementation PEXGuiMessageCell {

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
    // NOOP
}

- (PEXGuiMessageView *) getSubview
{
    return self.subview;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.subview];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.subview prepareForReuse];
}


@end