//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiRowItemViewWithImage.h"
#import "PEXGuiRowItemViewWithImage_Protected.h"

#import "PEXGuiImageView.h"


@implementation PEXGuiRowItemViewWithImage {

}

- (id)initWithImage:(UIView * const) image
{
    self = [super init];

    self.imageView = image;
    [self addSubview:self.imageView];

    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.imageView];

    [PEXGVU moveToLeft:self.imageView
            withMargin:([self staticHeight] - self.imageView.frame.size.width) / 2];
}

@end