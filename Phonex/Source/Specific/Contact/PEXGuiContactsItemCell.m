//
// Created by Matej Oravec on 17/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsItemCell.h"
#import "PEXGuiItemComposedView.h"

@interface PEXGuiContactsItemCell ()

- (void) initSubview;

@end

@implementation PEXGuiContactsItemCell {

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
    // NOOP
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.subview];
}

@end