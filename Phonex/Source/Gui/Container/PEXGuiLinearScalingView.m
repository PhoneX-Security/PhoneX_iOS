//
//  PEXGuiButtonRowControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLinearScalingView.h"
#import "PEXGuiContainerView_Protected.h"

@interface PEXGuiLinearScalingView ()
{
    @private
    CGFloat _gapSize;
}
@end

@implementation PEXGuiLinearScalingView

- (id) init
{
    return [self initWithGapSize:0.0f];
}

- (id) initWithGapSize: (const CGFloat) gapSize
{
    self = [super init];
    _gapSize = gapSize;
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    const int viewsCount = (int)self.views.count;
    if (viewsCount > 0)
    {
        // TODO rounding
        const CGFloat subviewWidth = (self.frame.size.width - (_gapSize * (viewsCount - 1))) / viewsCount;

        CGFloat originX = 0.0f;
        for (UIView * const view in self.views)
        {
            view.frame = CGRectMake(originX, 0.0f, subviewWidth, self.frame.size.height);
            originX += subviewWidth + _gapSize;
        }
    }
}

@end
