//
//  PEXGuiCentricButtonView.m
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiCentricButtonView.h"
#import "PEXGuiCentricButtonView_Protected.h"

@implementation PEXGuiCentricButtonView


- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU center:self.imageView];
    // TODO magic
    if (self.labelView.text.length > 0)
    {
        self.labelView.lineBreakMode = NSLineBreakByWordWrapping;
        self.labelView.numberOfLines = 0;
        self.labelView.textAlignment = NSTextAlignmentCenter;

        [PEXGVU setWidth:self.labelView to: self.frame.size.width];
        [PEXGVU moveUp:self.imageView by:[self getMoveSizeImage]];
        [PEXGVU move:self.labelView below:self.imageView withMargin:[self getMoveSizeLabel]];

        [self.labelView sizeToFit];

        [PEXGVU centerHorizontally:self.labelView];
    }
}

- (CGFloat) getMoveSizeImage
{
    return PEXVal(@"dim_size_small");
}

- (CGFloat) getMoveSizeLabel
{
    return PEXVal(@"dim_size_small");
}

@end
