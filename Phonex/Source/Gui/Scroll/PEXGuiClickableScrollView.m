//
// Created by Matej Oravec on 18/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiClickableScrollView.h"


@implementation PEXGuiClickableScrollView {

}

- (id) init
{
    self = [super init];

    self.delaysContentTouches = NO;
    self.scrollEnabled = YES;
    [self setUserInteractionEnabled:YES];

    return self;
}


- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return YES;
}

@end