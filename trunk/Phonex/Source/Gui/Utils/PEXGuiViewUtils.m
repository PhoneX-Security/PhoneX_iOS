//
//  PEXGuiViewUtils.m
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiViewUtils.h"

#import "PEXResValues.h"

@implementation PEXGuiViewUtils

// SIZE

+ (void) setSize: (UIView * const) view x: (const CGFloat) x y: (const CGFloat) y
{
    const CGPoint origin = view.frame.origin;
    view.frame = CGRectMake(origin.x, origin.y, x, y);
}

+ (void) setWidth: (UIView * const) view to: (const CGFloat) size
{
    [self setSize:view x:size y:view.frame.size.height];
}

+ (void) setHeight: (UIView * const) view to: (const CGFloat) size
{
    [self setSize:view x:view.frame.size.width y:size];
}

+ (void) makeFullscreenBackground:(UIView * const) view
{
    // must be copied, otherwise exception is thrown
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    view.frame = screenRect;
}

+ (void) makeMainbackground:(UIView * const) view
{
    // must be copied, otherwise exception is thrown
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    const CGFloat barHeight = PEXVal(@"L_paddingMedium");
    view.frame = CGRectMake(screenRect.origin.x, screenRect.origin.y + barHeight, screenRect.size.width, screenRect.size.height - barHeight);
}

+ (void) scaleVertically: (UIView * const) view above:(const UIView * const) lowerView
{
    [self scaleVertically:view between:0.0f and:lowerView.frame.origin.y];
}

+ (void) scaleVertically: (UIView * const) view between:(const CGFloat) yTop and:(const CGFloat) yBottom
{
    view.frame = CGRectMake(view.frame.origin.x, yTop,
                            view.frame.size.width,
                            yBottom);
}

+ (void) scaleHorizontally: (UIView * const ) view
{
    [self scaleHorizontally:view withMargin:0.0f];
}

+ (void) scaleHorizontally: (UIView * const ) view
                withMargin: (const CGFloat) margin
{
    const CGRect frame = view.frame;
    view.frame = CGRectMake(margin, frame.origin.y,
                            view.superview.frame.size.width - (2.0f * margin),
                            frame.size.height);
}

// POSITION

+ (void) moveToRight: (UIView* const) view
{
    [self moveToRight: view withMargin: 0.0f];
}

+ (void) moveToRight: (UIView* const) view
          withMargin: (const CGFloat) margin
{
    [self set: view x:view.superview.frame.size.width - margin - view.frame.size.width];
}

+ (void) moveToLeft: (UIView* const) view
{
    [self moveToLeft:view withMargin:0.0f];
}

+ (void) moveToLeft: (UIView* const) view
         withMargin: (const CGFloat) margin
{
    [self set: view x:0.0f + margin];
}

+ (void) moveToBottom: (UIView * const) view
{
    [self moveToBottom: view withMargin: 0.0f];
}

+ (void) moveToTop: (UIView * const) view
{
    [self moveToTop: view withMargin: 0.0f];
}

+ (void) moveToBottom: (UIView * const) view
           withMargin: (const CGFloat) margin
{
    [self set: view y:view.superview.frame.size.height - margin - view.frame.size.height];
}

+ (void) moveToTop: (UIView * const) view
        withMargin: (const CGFloat) margin
{
    [self set: view y: (0.0f + margin)];
}

+ (void) setPosition: (UIView * const) view x: (const CGFloat) x y: (const CGFloat) y
{
    const CGSize size = view.frame.size;
    view.frame = CGRectMake(x, y, size.width, size.height);
}

+ (void) center: (UIView * const) view
{
    [self setPosition:view x:((view.superview.frame.size.width - view.frame.size.width) / 2.0f)
                           y:((view.superview.frame.size.height - view.frame.size.height) / 2.0f)];
}

+ (void) centerHorizontally: (UIView * const) view
{
    [self set:view x:((view.superview.frame.size.width - view.frame.size.width) / 2.0f)];
}

+ (void) centerVertically: (UIView * const) view
{
    [self set:view y:((view.superview.frame.size.height - view.frame.size.height) / 2.0f)];
}

+ (void) moveDown: (UIView * const) view
               by: (const CGFloat) distance
{
    [self set:view y:(view.frame.origin.y + distance)];
}

+ (void) move: (UIView * const) view
        above: (const UIView * const) target
{
    [self move:view above:target withMargin:0.0f];
}

+ (void) move: (UIView * const) view
        above: (const UIView * const) target
   withMargin: (const CGFloat) margin
{
    [self set: view y: target.frame.origin.y - margin - view.frame.size.height];
}

+ (void) move: (UIView * const) view
        below: (const UIView * const) target
{
    [self move:view below:target withMargin:0.0f];
}


+ (void) move: (UIView * const) view
        below: (const UIView * const) target
   withMargin: (const CGFloat) margin
{
    const CGRect frame = target.frame;
    [self set: view y: frame.origin.y + margin + frame.size.height];
}

+ (void) set: (UIView * const) view
           y: (const CGFloat) y
{
    [self setPosition:view x:view.frame.origin.x y:y];
}

+ (void) set: (UIView * const) view
           x: (const CGFloat) x
{
    [self setPosition:view x:x y:view.frame.origin.y];
}

@end
