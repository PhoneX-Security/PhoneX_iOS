//
//  PEXGuiActivityIndicatorView.m
//  Phonex
//
//  Created by Matej Oravec on 18/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiActivityIndicatorView.h"

@implementation PEXGuiActivityIndicatorView

- (id) init
{
    self = [super initWithActivityIndicatorStyle:[PEXTheme getActivityIndicatorStyle]];
    return self;
}

@end
