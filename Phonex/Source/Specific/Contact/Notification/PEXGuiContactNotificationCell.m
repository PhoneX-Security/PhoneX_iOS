//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactNotificationCell.h"
#import "PEXGuiContactNotificationView.h"
#import "PEXGuiItemComposedView.h"

@interface PEXGuiContactNotificationCell ()

- (void) initSubview;

@end

@implementation PEXGuiContactNotificationCell {

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
    PEXGuiContactNotificationView *view = [[PEXGuiContactNotificationView alloc] init];
    [view initGui];
    self.subview = [[PEXGuiItemComposedView alloc] initWithView:view];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.subview];
}

@end