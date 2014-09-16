//
//  PEXGuiClassicLabel.m
//  Phonex
//
//  Created by Matej Oravec on 09/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiClassicLabel.h"

#import "PEXResColors.h"
#import "PEXResValues.h"

@implementation PEXGuiClassicLabel

- (void) setText:(NSString *)text
{
    [super setText: text];
    [self resize];
}


- (void) resize
{
    [self sizeToFit];
}

@end
