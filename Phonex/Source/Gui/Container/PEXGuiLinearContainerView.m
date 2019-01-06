 //
//  PEXGuiContainerView.m
//  Phonex
//
//  Created by Matej Oravec on 17/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLinearContainerView.h"
#import "PEXGuiContainerView_Protected.h"
#import "PEXArrayUtils.h"

 @implementation PEXGuiLinearContainerView

- (id) init
{
    self = [super init];

    self.backgroundColor = PEXCol(@"invisible");
    self.views = [[NSMutableArray alloc] init];

    return self;
}

- (int) count
{
    return self.views.count;
}

- (NSUInteger) addView:(UIView * const) view
{
    return [self addView:view toPosition:self.views.count];
}

- (NSUInteger) addView:(UIView * const) view toPosition: (const NSUInteger) position
{
    [self addSubview:view];
    [self.views insertObject:view atIndex:position];

    [UIView animateWithDuration:PEXVal(@"dur_short") animations:^{
        [self viewAdded:view toPosition:position];
    }];

    return position;
}

- (UIView *) removeFirstView
{
    return [self removeViewAtPosition:0];
}

- (UIView *) removeLastView
{
    return [self removeViewAtPosition:(self.views.count - 1)];
}

- (UIView *) removeViewAtPosition:(const NSUInteger) index;
{
    UIView * const result = self.views[index];
    [result removeFromSuperview];
    [self.views removeObjectAtIndex:index];
    [UIView animateWithDuration:PEXVal(@"dur_short") animations:^{
    [self viewRemoved:result fromPosition: index];
    }];
    return result;
}

- (UIView *) removeView:(UIView * const) view
{
    return [self removeViewAtPosition:[self.views indexOfObject:view]];
}

- (UIView *) getViewAtIndex:(const NSUInteger) index {
    return self.views[index];
}

/*
didAddSubview:
willRemoveSubview:
*/
- (void) viewRemoved: (const UIView * const) view fromPosition: (NSUInteger) index {}

- (void) viewAdded: (UIView * const) view toPosition: (NSUInteger) index {}

// must be already there
// []
- (void) moveView: (UIView * const) view to: (const NSUInteger) position
{
    const NSUInteger index = [self.views indexOfObject:view];

    [self moveFrom:index to:position];
}


- (void) moveFrom: (const NSUInteger) from to: (const NSUInteger) to
{
    UIView * const view = self.views[from];

    if ([PEXArrayUtils moveFrom:from to:to on:self.views])
    {
        [UIView animateWithDuration:PEXVal(@"dur_short")
                         animations:^{
                             [self viewMoved:view from:from to:to];
                         }];
    }
}


- (void) viewMoved: (UIView * const) view from: (const NSUInteger) from to: (const NSUInteger) to
{}

- (void) viewResized: (UIView * const) view byDiffY: (const CGFloat) diff {}

- (void) clear
{
    [self.views removeAllObjects];
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self cleared];
}

- (void) cleared{}

@end
