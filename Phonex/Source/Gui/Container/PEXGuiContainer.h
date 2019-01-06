//
// Created by Matej Oravec on 30/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXGuiLinearContainer <NSObject>

// TODO implement addSubviewBatch

- (NSUInteger) addView:(UIView * const) view;
- (NSUInteger) addView:(UIView * const) view toPosition: (const NSUInteger) position;

- (void) viewAdded: (UIView * const) view toPosition: (const NSUInteger) index;

- (UIView *) removeFirstView;
- (UIView *) removeLastView;
- (UIView *) removeViewAtPosition:(const NSUInteger) index;
- (UIView *) removeView:(UIView * const) view;

- (void) viewRemoved: (const UIView * const) view fromPosition: (const NSUInteger) index;

// the view must be already there
- (void) moveView: (UIView * const) view to: (const NSUInteger) to;
- (void) moveFrom: (const NSUInteger) from to: (const NSUInteger) to;
- (void) viewMoved: (UIView * const) view from: (const NSUInteger) from to: (const NSUInteger) to;

- (void) viewResized: (UIView * const) view byDiffY: (const CGFloat) diff;

- (void) clear;
- (void) cleared;

- (int) count;

@end