//
//  PEXGuiButtonRowControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiViewRow.h"
#import "PEXGuiController_Protected.h"

@interface PEXGuiViewRow ()

@property (nonatomic) NSMutableArray * views;

@end

@implementation PEXGuiViewRow

- (id) init
{
    self = [super init];

    self.views = [[NSMutableArray alloc] init];

    return self;
}

- (void) addView:(UIView * const) view
{
    [self.views addObject:view];
    [self addSubview:view];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    // TODO rounding
    const int viewsCount = self.views.count;
    const CGFloat gapSize = 1.0f;
    const CGFloat subviewWidth = (self.frame.size.width - (gapSize * (viewsCount - 1))) / viewsCount;

    CGFloat originX = 0.0f;
    for (UIView * const view in self.views)
    {
        view.frame = CGRectMake(originX, 0.0f, subviewWidth, self.frame.size.height);
        originX += subviewWidth + gapSize;
    }
}

@end
