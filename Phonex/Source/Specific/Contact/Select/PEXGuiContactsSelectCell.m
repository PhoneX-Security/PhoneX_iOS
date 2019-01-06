//
// Created by Matej Oravec on 18/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsSelectCell.h"
#import "PEXGuiSelectableContactsItemView.h"
#import "PEXGuiItemComposedView.h"


@implementation PEXGuiContactsSelectCell {

}

- (void) initSubview
{
    PEXGuiSelectableContactsItemView * contactView = [[PEXGuiSelectableContactsItemView alloc] init];
    [contactView initGui];
    self.subview = contactView;

}

@end