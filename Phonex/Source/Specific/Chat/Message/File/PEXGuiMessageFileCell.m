//
// Created by Matej Oravec on 28/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageFileCell.h"
#import "PEXGuiMessageCell_Protected.h"

#import "PEXGuiMessageFileView.h"

@implementation PEXGuiMessageFileCell {

}

- (void) initSubview
{
    self.subview = [[PEXGuiMessageFileView alloc] init];
    [self.subview initGuiStuff];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // because we scroll from bottom to top
    [PEXGVU moveToBottom:self.subview];
}

@end