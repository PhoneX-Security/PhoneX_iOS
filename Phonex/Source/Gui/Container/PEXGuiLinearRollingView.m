//
//  PEXGuiLinearRollingView.m
//  Phonex
//
//  Created by Matej Oravec on 17/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLinearRollingView.h"
#import "PEXGuiContainerView_Protected.h"

@implementation PEXGuiLinearRollingView

- (void) viewAdded: (UIView * const) view toPosition: (NSUInteger) index
{
    const CGFloat addedViewHeight = view.frame.size.height;
    const CGFloat selfNewHeight = self.frame.size.height + addedViewHeight;
    [PEXGVU setHeight:self to:selfNewHeight];

    // the added view is already in the array
    if (index > 0) {
        [PEXGVU move:view below:self.views[index - 1]];
    }
    else {
        [PEXGVU moveToTop:view];
    }

    for (NSUInteger pos = index + 1; pos < self.views.count; ++pos)
    {
        [PEXGVU moveDown:self.views[pos] by:addedViewHeight];
    }
}

- (void) viewRemoved: (const UIView * const) view fromPosition: (NSUInteger) index
{
    const CGFloat viewHeight = view.frame.size.height;

    for (NSUInteger pos = index; pos < self.views.count; ++pos)
    {
        [PEXGVU moveUp:self.views[pos] by:viewHeight];
    }

    [PEXGVU setHeight:self to:self.frame.size.height - viewHeight];
}

- (void) viewMoved: (UIView * const) view from: (const NSUInteger) from to: (const NSUInteger) to
{
    // not called when to == from
    const CGFloat viewHeight = view.frame.size.height;
    // to up
    if (from > to)
    {
        if (to > 0)
        {
            [PEXGVU move:view below:self.views[to - 1]];
        }
        else
        {
            [PEXGVU moveToTop:view];
        }

        for (NSUInteger i = to + 1; i < from + 1; ++i)
        {
            [PEXGVU moveDown:self.views[i] by:viewHeight];
        }
    }
    // lower / the same
    else
    {
        NSUInteger toMoveOthers = to - 1;

        if (to < self.views.count)
        {
            [PEXGVU move:view above:self.views[to]];
        }
        else
        {
            [PEXGVU moveToBottom:view];
        }

        for (NSUInteger i = from ; i < toMoveOthers; ++i)
        {
            [PEXGVU moveUp:self.views[i] by:viewHeight];
        }
    }
}

// diff > 0 -> bigger
// diff < 0 -> smaller
- (void) viewResized: (UIView * const) view byDiffY: (const CGFloat) diff
{
    if (diff == 0)
        return;

    NSUInteger index = [self.views indexOfObject:view];

    if (index == NSNotFound)
        return;

    [PEXGVU setHeight:self to:self.frame.size.height + diff];

    const NSUInteger count = self.views.count;
    for (++index; index < count; ++index)
    {
        [PEXGVU moveVertically:self.views[index] by:diff];
    }
}

- (void) cleared
{
    [PEXGVU setHeight:self to:0.0f];
}

@end
