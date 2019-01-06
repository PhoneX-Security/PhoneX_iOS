//
//  PEXGuiViewUtils.h
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiController.h"

#define PEXGVU PEXGuiViewUtils

@interface PEXGuiViewUtils : NSObject

+ (UIViewController *) showModalTransparentController;

+ (void) presentModalTransparent: (UIViewController * const) child onParent: (UIViewController * const) parent;
+ (void) executeWithoutAnimations:(void (^)(void))block;
+ (void) executeWithAnimations:(const bool) animated action:(void (^)(void))block;

+ (void)shakeView:(UIView * const)viewToShake;

+ (CGPoint) getAbsolutePosition: (UIView *) view highestView: (UIView **) result;

// SCALING

+ (void) setWidth: (UIView* const) view until: (const UIView* const) target;
+ (void) setWidth:(UIView *const)view until:(const UIView *const)target withMargin: (const CGFloat) margin;

+ (void) setSize: (UIView* const) view x: (const CGFloat) x y: (const CGFloat) y;

+ (void) setWidth: (UIView* const) view to: (const CGFloat) size;
+ (void) setHeight: (UIView* const) view to: (const CGFloat) size;

+ (void) makeFullscreenBackground:(UIView* const) view;
+ (void) makeMainbackground:(UIView * const) view;
+ (void) makeStatusBar: (UIView * const) view;

+ (void) scaleFull: (UIView * const) view;
+ (void) scaleFull: (UIView * const) view inMaster: (UIView * const) master;

+ (void) scaleVertically: (UIView * const) view above:(const UIView * const) lowerView;
+ (void) scaleVertically: (UIView * const) view between:(const CGFloat) yTop and:(const CGFloat) yBottom;

+ (void) scaleVertically: (UIView * const ) view;
+ (void) scaleVertically: (UIView * const ) view
              withMargin: (const CGFloat) margin;
+ (void) scaleVertically: (UIView * const ) view
                   below: (UIView * const ) below
              withMargin: (const CGFloat) margin;
+ (void) scaleVertically: (UIView * const ) view
                   below: (UIView * const ) below
                  master: (UIView * const ) master
              withMargin: (const CGFloat) margin;

+ (void) scaleHorizontally: (UIView *const ) view withMargin: (const CGFloat) margin;
+ (void) scaleHorizontally: (UIView * const ) view
                      from: (const UIView * const ) target
                leftMargin: (const CGFloat) left
               rightMargin: (const CGFloat) right;
+ (void) scaleHorizontally: (UIView *const ) view;

+ (void) scaleHorizontally: (UIView * const ) view
                        on: (const UIView * const ) superview;

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
+ (void) centerVertically: (UIView * const) view on: (const UIView * const) target;

+ (void) moveAboveCenter: (UIView * const) view;
+ (void) moveAboveCenter: (UIView * const) view withMargin: (const CGFloat) margin;

+ (void) moveBelowCenter: (UIView * const) view;
+ (void) moveBelowCenter: (UIView * const) view withMargin: (const CGFloat) margin;

+ (void) centerBetweenTop: (UIView * const) target
            and: (const UIView * const) view;

+ (void) moveUp: (UIView * const) view
             by: (const CGFloat) distance;

+ (void) moveDown: (UIView * const) view
               by: (const CGFloat) distance;

+ (void) moveRight: (UIView * const) view
             by: (const CGFloat) distance;

+ (void) moveLeft: (UIView * const) view
               by: (const CGFloat) distance;

+ (void) moveVertically: (UIView * const) view
                by: (const CGFloat) distance;

+ (void) moveHorizontally: (UIView * const) view
               by: (const CGFloat) distance;


+ (void) move: (UIView * const) view
       leftOf: (const UIView * const) target;

+ (void) move: (UIView * const) view
       leftOf: (const UIView * const) target
   withMargin: (const CGFloat) margin;

+ (void) move: (UIView * const) view
      rightOf: (const UIView * const) target;

+ (void) move: (UIView * const) view
      rightOf: (const UIView * const) target
   withMargin: (const CGFloat) margin;

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

+ (void) center: (UIView * const) view
             in: (const UIView * const) center;

+ (CGFloat) getLowerPoint: (const UIView * const) view;

@end
