//
// Created by Matej Oravec on 30/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPackageCell.h"
#import "PEXGuiPackageView.h"

@interface PEXGuiPackageCell ()

@property (nonatomic) PEXGuiPackageView * subview;

@end

@implementation PEXGuiPackageCell {

}
- (UIView *) getSubview
{
    return self.subview;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.subview = [[PEXGuiPackageView alloc] init];
    [self.contentView addSubview:self.subview];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.subview];
}



@end