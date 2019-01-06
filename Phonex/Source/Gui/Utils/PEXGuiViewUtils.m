//
//  PEXGuiViewUtils.m
//  Phonex
//
//  Created by Matej Oravec on 30/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiLoginController.h"

@implementation PEXGuiViewUtils

+ (UIViewController *) showModalTransparentController
{
    UIViewController * child = [[UIViewController alloc] init];
    child.view.backgroundColor = [UIColor clearColor];

    UIViewController * const parent = [PEXGuiLoginController instance].landingController;

    [PEXGVU presentModalTransparent:child onParent:parent];

    return child;
}

+ (void) presentModalTransparent: (UIViewController * const) child onParent: (UIViewController * const) parent
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
    {
        [child setModalPresentationStyle:UIModalPresentationOverCurrentContext];
        parent.providesPresentationContextTransitionStyle = YES;
        [parent presentViewController:child animated:NO completion:nil];
    }
    else
    {
        [parent setModalPresentationStyle:UIModalPresentationCurrentContext];
        [parent presentViewController:child animated:NO completion:nil];
    }
}

+ (void) executeWithAnimations:(const bool) animated action:(void (^)(void))block
{
    //const bool previousAnimated = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:animated];
    block();
    [UIView setAnimationsEnabled:YES];
}

+ (void) executeWithoutAnimations:(void (^)(void))block
{
    // NOTE: always set the animations to YES after executions
    // if it causes problems, use "previousAnimated" and some mutex
    // because of possible race conditions ... even in the main UI thread?

    //const bool previousAnimated = [UIView areAnimationsEnabled];
    [UIView setAnimationsEnabled:NO];
    block();
    [UIView setAnimationsEnabled:YES];
}

+ (void)shakeView:(UIView * const)viewToShake
{
    const CGFloat t = 2.0;
    const CGAffineTransform translateRight  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0);
    const CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0);

    viewToShake.transform = translateLeft;

    [UIView animateWithDuration:0.07 delay:0.0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:2.0];
        viewToShake.transform = translateRight;
    } completion:^(BOOL finished) {
        if (finished) {
            // TODO UIViewAnimationOptionBeginFromCurrentStatemay crash
            [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                viewToShake.transform = CGAffineTransformIdentity;
            } completion:NULL];
        }
    }];
}

+ (CGPoint) getAbsolutePosition: (UIView *) view highestView: (UIView **) result
{
    CGFloat x = view.frame.origin.x,
            y = view.frame.origin.y;

    while (view.superview != nil)
    {
        const CGPoint superOrigin = view.superview.frame.origin;
        x += superOrigin.x;
        y += superOrigin.y;
        view = view.superview;
    }

    if (result)
        *result = view;

    return CGPointMake(x, y);
}

// SIZE

+ (void) setWidth: (UIView* const) view until: (const UIView* const) target
{
    [self setWidth:view until:target withMargin:0.0f];
}
+ (void)setWidth:(UIView *const)view until:(const UIView *const)target withMargin: (const CGFloat) margin
{
    [self setWidth:view to:target.frame.origin.x - view.frame.origin.x - margin];
}

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
    const CGFloat barHeight = PEXVal(@"status_bar_height");
    view.frame = CGRectMake(screenRect.origin.x, screenRect.origin.y + barHeight, screenRect.size.width, screenRect.size.height - barHeight);
}

+ (void) makeStatusBar: (UIView * const) view
{
    // must be copied, otherwise exception is thrown
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    view.frame = CGRectMake(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, PEXVal(@"status_bar_height"));
    view.layer.zPosition = MAXFLOAT;

    static const CGFloat statusBarAlpha = 0.85f;

    CGFloat red, green, blue, alpha;
    [view.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    view.backgroundColor = [[UIColor alloc] initWithRed:red
                                                  green:green
                                                   blue:blue
                                                  alpha:(alpha < statusBarAlpha ? alpha : statusBarAlpha)];
}

+ (void) scaleFull: (UIView * const) view
{
    const CGRect frame = view.superview.frame;
    view.frame = CGRectMake(0.0f, 0.0f,
                            frame.size.width,
                            frame.size.height);
}

+ (void)scaleFull:(UIView *const)view inMaster: (UIView * const) master {
    const CGRect frame = master.frame;
    view.frame = CGRectMake(0.0f, 0.0f,
            frame.size.width,
            frame.size.height);
}

+ (void) scaleVertically: (UIView * const) view above:(const UIView * const) lowerView
{
    [self scaleVertically:view between:0.0f and:lowerView.frame.origin.y];
}

+ (void) scaleVertically: (UIView * const) view between:(const CGFloat) yTop and:(const CGFloat) yBottom
{
    view.frame = CGRectMake(view.frame.origin.x, yTop,
                            view.frame.size.width,
                            yBottom - yTop);
}

+ (void) scaleVertically: (UIView * const ) view
{
    [self scaleVertically:view withMargin:0.0f];
}

+ (void) scaleVertically: (UIView * const ) view
                withMargin: (const CGFloat) margin
{
    const CGRect frame = view.frame;
    view.frame = CGRectMake(frame.origin.x,
                            margin,
                            view.frame.size.width,
                            view.superview.frame.size.height - (2.0f * margin));
}

+ (void) scaleVertically: (UIView * const ) view
                   below: (UIView * const ) below
              withMargin: (const CGFloat) margin
{
    [self scaleVertically:view below:below master:view.superview withMargin:margin];
}

+ (void)scaleVertically:(UIView *const)view below:(UIView *const)below master:(UIView *const)master withMargin:(const CGFloat)margin {
    const CGRect frame = view.frame;
    const CGRect bFrame = below.frame;
    const CGRect sFrame = master.frame;
    const CGFloat maxHeight = sFrame.size.height - (bFrame.origin.y - sFrame.origin.y + bFrame.size.height);
    if (maxHeight < 0.0){
        DDLogError(@"Invalid maxHeight: %0.3f", maxHeight);
        return;
    }

    view.frame = CGRectMake(
            frame.origin.x,
            frame.origin.y + margin,
            frame.size.width,
            maxHeight - (2.0f * margin));
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

+ (void) scaleHorizontally: (UIView * const ) view
                 from: (const UIView * const ) target
           leftMargin: (const CGFloat) left
          rightMargin: (const CGFloat) right
{
    const CGFloat originX = target.frame.origin.x + target.frame.size.width + left;
    view.frame = CGRectMake(originX,
                            view.frame.origin.y,
                            view.superview.frame.size.width - originX - right,
                            view.frame.size.height);
}

+ (void) scaleHorizontally: (UIView * const ) view
                        on: (const UIView * const ) superview
{
    const CGRect frame = view.frame;
    view.frame = CGRectMake(superview.frame.origin.x, frame.origin.y,
                            superview.frame.size.width,
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

+ (void) centerVertically: (UIView * const) view on: (const UIView * const) target
{
    const CGFloat diff = target.frame.size.height - view.frame.size.height;
    const CGFloat yPos = target.frame.origin.y + (diff / 2.0f);
    [self set:view y:yPos];
}

+ (void) moveAboveCenter: (UIView * const) view
{
    [self moveAboveCenter:view withMargin:0.0f];
}

+ (void) moveAboveCenter: (UIView * const) view withMargin: (const CGFloat) margin
{
    [self set:view y:((view.superview.frame.size.height - view.frame.size.height) / 2.0f) -
            (view.frame.size.height / 2.0f) - margin];
}

+ (void) moveBelowCenter: (UIView * const) view
{
    [self moveBelowCenter:view withMargin:0.0f];
}
+ (void) moveBelowCenter: (UIView * const) view withMargin: (const CGFloat) margin
{
    [self set:view y:((view.superview.frame.size.height - view.frame.size.height) / 2.0f) +
            (view.frame.size.height / 2.0f) + margin];
}

+ (void) moveUp: (UIView * const) view
               by: (const CGFloat) distance
{
    [self moveVertically:view by:-distance];
}

+ (void) moveDown: (UIView * const) view
               by: (const CGFloat) distance
{
    [self moveVertically:view by:distance];
}

+ (void) moveRight: (UIView * const) view
                by: (const CGFloat) distance
{
    [self moveHorizontally:view by:distance];
}

+ (void) moveLeft: (UIView * const) view
               by: (const CGFloat) distance
{
    [self moveHorizontally:view by:-distance];
}

+ (void) moveVertically: (UIView * const) view
                     by: (const CGFloat) distance
{
    [self set:view y:(view.frame.origin.y + distance)];
}

+ (void) moveHorizontally: (UIView * const) view
                       by: (const CGFloat) distance
{
    [self set:view x:(view.frame.origin.x + distance)];
}

+ (void) move: (UIView * const) view
      leftOf: (const UIView * const) target
{
    [self move:view leftOf:target withMargin:0.0f];
}

+ (void) move: (UIView * const) view
      leftOf: (const UIView * const) target
   withMargin: (const CGFloat) margin
{
    [self set: view x: target.frame.origin.x - margin - view.frame.size.width];
}

+ (void) move: (UIView * const) view
        rightOf: (const UIView * const) target
{
    [self move:view rightOf:target withMargin:0.0f];
}

+ (void) move: (UIView * const) view
        rightOf: (const UIView * const) target
   withMargin: (const CGFloat) margin
{
    const CGRect targetFrame = target.frame;
    [self set: view x: targetFrame.origin.x + margin + targetFrame.size.width];
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

+ (void) centerBetweenTop: (UIView * const) target
                      and: (const UIView * const) view
{
    const CGFloat yOrigin = (view.frame.origin.y / 2.0f) -
        (target.frame.size.height / 2.0f);

    [self set:target y:yOrigin];
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

+ (void) center: (UIView * const) view
             in: (const UIView * const) center
{
    const CGFloat x = center.frame.origin.x + (center.frame.size.width / 2.0f) -
    (view.frame.size.width / 2.0f);
    const CGFloat y = center.frame.origin.y + (center.frame.size.height / 2.0f) -
    (view.frame.size.height / 2.0f);

    [self setPosition:view x:x y:y];
}

+ (CGFloat) getLowerPoint: (const UIView * const) view
{
    return view.frame.origin.y + view.frame.size.height;
}

@end
