//
// Created by Matej Oravec on 15/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiMessageTextBodyView.h"
#import "PEXGuiTextView_Protected.h"
#import "UITextView+PEXPaddings.h"

@implementation PEXGuiMessageTextBodyView {

}

- (id)initWithFrame: (CGRect) frame
{
    self = [super initWithFrame:frame];
    self.userInteractionEnabled = YES;
    self.backgroundColor = PEXCol(@"invisible");
    self.numberOfLines = 0;
    self.lineBreakMode = NSLineBreakByWordWrapping;

    self.linkAttributes = @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };

    self.activeLinkAttributes = @{
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName: PEXCol(@"orange_low")
    };

    return self;
}

- (void) padding
{
    [self setPadding:PEXVal(@"dim_size_tiny")];
}

@end