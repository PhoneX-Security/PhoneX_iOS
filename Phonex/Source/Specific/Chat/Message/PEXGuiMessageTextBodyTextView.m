//
// Created by Dusan Klinec on 20.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiMessageTextBodyTextView.h"
#import "UITextView+PEXPaddings.h"


@implementation PEXGuiMessageTextBodyTextView {

}
- (id)init
{
    self = [super init];

    self.scrollEnabled = NO;
    self.userInteractionEnabled = NO;

    return self;
}

- (void) padding
{
    [self setPadding:PEXVal(@"dim_size_tiny")];
}
@end