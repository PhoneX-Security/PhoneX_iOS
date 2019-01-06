//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiRowItemView.h"
#import "PEXGuiRowItemView_Protected.h"

#import "PEXGuiPoint.h"
#import "PEXGuiMenuLine.h"

@implementation PEXGuiRowItemView {

}

- (id)init
{
    self = [super init];

    [self setStateNormal];
    [self setHeight];

    return self;
}

- (void) setHeight
{
    [PEXGVU setHeight:self to: [self staticHeight]];
}

- (CGFloat) staticHeight
{
    return [PEXGuiRowItemView staticHeight];
}

+ (CGFloat) staticHeight
{
    return [PEXResValues getItemHeight];
}


- (UIColor *) bgColorNormalStatic {return PEXCol(@"white_normal");}
- (UIColor *) bgColorHighlightStatic {return PEXCol(@"light_orange_normal");}
- (UIColor *) bgColorDisabledStatic { return PEXCol(@"light_gray_high");}

@end