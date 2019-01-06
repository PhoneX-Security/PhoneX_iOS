//
// Created by Matej Oravec on 09/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiChatCell.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiChatItemView.h"

@interface PEXGuiChatCell()

@property (nonatomic) PEXGuiItemComposedView * subview;

@end

@implementation PEXGuiChatCell {

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
    PEXGuiChatItemView * V_chat = [[PEXGuiChatItemView alloc] init];
    [V_chat initGuiStuff];
    PEXGuiItemComposedView * const composed = [[PEXGuiItemComposedView alloc] initWithView: V_chat];
    self.subview = composed;

}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [PEXGVU scaleFull:self.subview];
}

@end