//
//  TitleAttributes.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#ifndef Phonex_TitleAttributes_h
#define Phonex_TitleAttributes_h

- (id) init
{
    self = [super initWithFontColor:PEXCol(@"light_gray_low") bgColor:PEXCol(@"invisible")];

    return self;
}

- (CGFloat) fontSize
{
    return PEXVal(@"dim_size_medium");
}

- (CGFloat) padding
{
    return PEXVal(@"dim_size_medium");
}

// TODO make it better statically
+ (CGFloat) height
{
    return PEXVal(@"dim_size_medium") + (2.0f * PEXVal(@"dim_size_medium"));
}

#endif
