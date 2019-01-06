//
//  PEXGuiControllerWithSubcontroller.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerDecorator.h"
#import "PEXGuiControllerDecorator_Protected.h"
#import "PEXGuiClickableScrollView.h"
#import "UIViewController+PEXRelayout.h"


@interface PEXGuiControllerDecorator ()

@end

@implementation PEXGuiControllerDecorator

/**
 0. initWithViewController:
    0a. init
    0b. "assign controller" + addChildViewController
 
 2. prepareInView / prepareOnScreen
 
    setSubviewMax
    controller showInView

    2a. postInit
        2aa. initMasterView
        2ab. initGuiComponents
        2ac. initContent
        2ad. initBehavior
 
    2b. recalculateOnScreen / recalculateInView
        2ba. setSizeInView / makeFullscreenBackground
        2bb. initLayout
        2vc. initState
 **/

- (id) initWithViewController: (PEXGuiController * const) controller
{
    self = [self init];

    [self addChildViewController:controller];

    [self finishInit];

    return self;
}

- (id) initWithViewControllers: (NSArray * const) controllers
{
    self = [self init];

    for (id controller in controllers)
        [self addChildViewController:controller];

    [self finishInit];

    return self;
}

- (void) finishInit
{
    [self setStaticSize];
}

- (PEXGuiController *) subcontroller
{
    return self.childViewControllers[0];
}

- (void) setStaticSize
{
    [self staticWidth:PEXDefaultVal];
    [self staticHeight:PEXDefaultVal];
}

- (void) prepareOnScreen: (PEXGuiController * const) parent
{
    self.fullscreener = self;

    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    [self setSubviewMax:screenRect.size.width and:screenRect.size.height - PEXVal(@"status_bar_height")];

    // overtype
    for (PEXGuiController * const c in self.childViewControllers)
        [c prepareInView:self];

    [super prepareOnScreen:parent];
}

- (void) prepareInView: (PEXGuiControllerDecorator * const) parent
{
    self.fullscreener = ([[parent class] isSubclassOfClass:[PEXGuiController class]] ? parent.fullscreener : parent);

    [self setSubviewMax:parent.subviewMaxWidth and:parent.subviewMaxHeight];

    // overtype
    for (PEXGuiController * const c in self.childViewControllers)
        [c prepareInView:self];
    
    [super prepareInView:parent];
}

- (void) setSubviewMax: (const CGFloat) width and: (const CGFloat) height
{
    [self subviewMaxWidth: width - [self staticWidth]];
    [self subviewMaxHeight: height - [self staticHeight]];
}

- (void) setSizeOnScreen:(UIViewController *const) parent
{
    [self placeSubViews];

    [super setSizeOnScreen:parent];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [self placeSubViews];

    const CGSize subviewSize = ((UIViewController*)self.childViewControllers[0]).view.frame.size;

    [PEXGVU setSize:self.mainView
                  x:subviewSize.width + [self staticWidth]
                  y:subviewSize.height + [self staticHeight]];
}

- (void) placeSubViews
{
    for (NSUInteger i = 0; i < self.childViewControllers.count; ++i)
    {
        // overtype
        [self placeSubcontroller:self.childViewControllers[i]];
    }
}

- (void) positionSubcontrollersView: (UIView * const) subview
{
    // not implemented
}


- (void) placeSubcontroller: (PEXGuiController * const) subcontroller
{
    // TODO move this commented code to PEXGuiController setSizeInView or after ... if needed
    /*
    const CGSize subviewSize = subcontroller.mainView.frame.size;
    CGFloat newWidth = subviewSize.width;
    CGFloat newHeight = subviewSize.height;

    const BOOL higher = subviewSize.height > self.subviewMaxHeight;
    const BOOL wider = subviewSize.width > self.subviewMaxWidth;

    UIView * final = nil;
    if (higher || wider)
    {
        UIScrollView * const scrollView = [[PEXGuiClickableScrollView alloc] init];
        scrollView.scrollEnabled = YES;
        [scrollView setUserInteractionEnabled:YES];

        if (wider)
        {
            newWidth = [self subviewMaxWidth];
            scrollView.showsHorizontalScrollIndicator = YES;
        }

        if (higher)
        {
            newHeight = [self subviewMaxHeight];
            scrollView.showsVerticalScrollIndicator = YES;
        }

        scrollView.contentSize = subviewSize;
        [PEXGVU setSize:scrollView x:newWidth y:newHeight];

        [scrollView addSubview:subcontroller.mainView];
        final = scrollView;
    }
    else
    {
        final = subcontroller.mainView;
    }*/

    [subcontroller addSelfAsChildIfNotAdded:self];
    [self positionSubcontrollersView: subcontroller.mainView];
}

- (CGFloat) staticWidth { return _staticWidth; }
- (CGFloat) staticHeight { return _staticHeight; }
- (CGFloat) subviewMaxWidth { return _subviewMaxWidth; }
- (CGFloat) subviewMaxHeight { return _subviewMaxHeight; }

- (void) subviewMaxWidth: (const CGFloat) value { _subviewMaxWidth = value; }
- (void) subviewMaxHeight: (const CGFloat) value { _subviewMaxHeight = value; }
- (void) staticWidth: (const CGFloat) value { _staticWidth = value; }
- (void) staticHeight: (const CGFloat) value { _staticHeight = value; }

- (BOOL)relayout {
    // overtype
    for (PEXGuiController * const c in self.childViewControllers)
        [c relayout];

    return [super relayout];
}

- (void) reloadOnScreen: (PEXGuiController * const) parent
{
    self.fullscreener = self;

    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    [self setSubviewMax:screenRect.size.width and:screenRect.size.height - PEXVal(@"status_bar_height")];

    // overtype
    for (PEXGuiController * const c in self.childViewControllers)
        [c reloadInView:self];

    [super reloadOnScreen:parent];
}

- (void) reloadInView: (PEXGuiControllerDecorator * const) parent
{
    self.fullscreener = ([[parent class] isSubclassOfClass:[PEXGuiController class]] ? parent.fullscreener : parent);

    [self setSubviewMax:parent.subviewMaxWidth and:parent.subviewMaxHeight];

    // overtype
    for (PEXGuiController * const c in self.childViewControllers)
        [c reloadInView:self];

    [super reloadInView:parent];
}


@end
