//
// Created by Matej Oravec on 16/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiBreakerLabelView.h"


@implementation PEXGuiBreakerLabelView {

}

- (CGFloat) fontSize
{
    return PEXVal(@"dim_size_small_medium");
}

- (CGFloat) padding
{
    return PEXVal(@"dim_size_tiny");
}

+ (CGFloat) height
{
    return PEXVal(@"dim_size_medium") + (2.0f * PEXVal(@"dim_size_tiny"));
}

@end