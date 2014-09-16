//
//  PEXGuiViewUtils.h
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PEXGVU PEXGuiViewUtils

@interface PEXGuiViewUtils : NSObject

// SCALING

+ (void) setSize: (UIView* const) view x: (const CGFloat) x y: (const CGFloat) y;

+ (void) setWidth: (UIView* const) view to: (const CGFloat) size;
+ (void) setHeight: (UIView* const) view to: (const CGFloat) size;

+ (void) makeFullscreenBackground:(UIView* const) view;
+ (void) makeMainbackground:(UIView * const) view;

+ (void) scaleVertically: (UIView * const) view above:(const UIView * const) lowerView;
+ (void) scaleVertically: (UIView * const) view between:(const CGFloat) yTop and:(const CGFloat) yBottom;

+ (void) scaleHorizontally: (UIView *const ) view withMargin: (const CGFloat) margin;
+ (void) scaleHorizontally: (UIView *const ) view;

// POSITIONING RELATIVE TO SUPERVIEW

+ (void) moveToRight: (UIView* const) view;

+ (void) moveToRight: (UIView* const) view
        withMargin: (const CGFloat) margin;

+ (void) moveToLeft: (UIView* const) view;

+ (void) moveToLeft: (UIView* const) view
          withMargin: (const CGFloat) margin;

+ (void) moveToTop: (UIView* const) view;

+ (void) moveToTop: (UIView* const) view
        withMargin: (const CGFloat) margin;

+ (void) moveToBottom: (UIView* const) view;

+ (void) moveToBottom: (UIView* const) view
           withMargin: (const CGFloat) margin;

+ (void) setPosition: (UIView* const) view x: (const CGFloat) x y: (const CGFloat) y;

+ (void) center: (UIView * const) view;
+ (void) centerHorizontally: (UIView * const) view;
+ (void) centerVertically: (UIView * const) view;

+ (void) moveDown: (UIView * const) view
               by: (const CGFloat) distance;

+ (void) move: (UIView * const) view
        above: (const UIView * const) target;
+ (void) move: (UIView * const) view
        above: (const UIView * const) target
  withMargin: (const CGFloat) margin;

+ (void) move: (UIView * const) view
        below: (const UIView * const) target;
+ (void) move: (UIView * const) view
        below: (const UIView * const) target
  withMargin: (const CGFloat) margin;

+ (void) set: (UIView * const) view
           y: (const CGFloat) y;

+ (void) set: (UIView * const) view
           x: (const CGFloat) x;

@end
