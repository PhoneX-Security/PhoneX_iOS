//
// Created by Matej Oravec on 28/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageTextOnlyCell.h"
#import "PEXGuiMessageCell_Protected.h"

#import "PEXGuiMessageTextOnlyView.h"

@implementation PEXGuiMessageTextOnlyCell {

}
- (void) initSubview
{
    self.subview = [[PEXGuiMessageTextOnlyView alloc] init];
    [self.subview initGuiStuff];
}

@end