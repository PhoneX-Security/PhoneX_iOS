//
//  PEXGuiPoint.m
//  Phonex
//
//  Created by Matej Oravec on 18/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiPoint.h"

@implementation PEXGuiPoint

- (id) initWithColor: (UIColor * const) color
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 1.0f, 1.0f)];

    [self setBackgroundColor:color];

    return self;
}

@end
