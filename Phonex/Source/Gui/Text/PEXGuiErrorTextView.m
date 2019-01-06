//
// Created by Matej Oravec on 31/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiErrorTextView.h"


@implementation PEXGuiErrorTextView {

}

- (id)init
{
    self = [super init];

    self.font = [UIFont systemFontOfSize:PEXVal(@"dim_size_medium")];
    self.backgroundColor = PEXCol(@"invisible");
    self.textColor = PEXCol(@"red_normal");

    self.editable = NO;
    [self resignFirstResponder];
    self.scrollEnabled = NO;
    [self setUserInteractionEnabled:YES];

    return self;
}

- (void)sizeToFit
{
    [super sizeToFit];

    [self.textContainer setSize:self.frame.size];
}

@end