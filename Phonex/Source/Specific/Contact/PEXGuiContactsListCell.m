//
// Created by Matej Oravec on 18/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsListCell.h"
#import "PEXGuiItemComposedView.h"
#import "PEXGuiContactsItemView.h"


@implementation PEXGuiContactsListCell {

}

- (void) initSubview
{
    PEXGuiContactsItemView * contactView = [[PEXGuiContactsItemView alloc] init];
    [contactView initGui];
    self.subview = [[PEXGuiItemComposedView alloc] initWithView:contactView];

}

@end