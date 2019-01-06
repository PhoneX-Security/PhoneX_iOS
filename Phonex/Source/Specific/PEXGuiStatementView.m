//
//  PEXGuiStatementView.m
//  Phonex
//
//  Created by Matej Oravec on 16/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiStatementView.h"

@implementation PEXGuiStatementView

- (id) init
{
    self = [super initWithFontSize:PEXVal(@"dim_size_medium")
                         fontColor:PEXCol(@"light_gray_low")
                           bgColor:PEXCol(@"white_normal")];
    return self;
}

@end
