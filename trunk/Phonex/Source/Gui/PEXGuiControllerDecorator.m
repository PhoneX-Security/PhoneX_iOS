//
//  PEXGuiControllerWithSubcontroller.m
//  Phonex
//
//  Created by Matej Oravec on 13/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerDecorator.h"
#import "PEXGuiControllerDecorator_Protected.h"

#import "PEXGuiViewUtils.h"
#import "PEXResValues.h"

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
 **/

- (id) initWithViewController: (PEXGuiController * const) controller
{
    self = [super init];

    self.subcontroller = controller;
    [self addChildViewController:controller];
    [self setStaticSize];

    return self;
}

- (void) setStaticSize
{
    [self staticWidth:PEXDefaultVal];
    [self staticHeight:PEXDefaultVal];
}

- (void) prepareOnScreen: (UIViewController * const) parent
{
    const CGRect screenRect = [[UIScreen mainScreen] bounds];
    [self setSubviewMax:screenRect.size.width and:screenRect.size.height - PEXVal(@"L_paddingMedium")];

    [self.subcontroller prepareInView:self];
    [super prepareOnScreen:parent];
}

- (void) prepareInView: (PEXGuiControllerDecorator * const) parent
{
    [self setSubviewMax:parent.subviewMaxWidth and:parent.subviewMaxHeight];

    [self.subcontroller prepareInView:self];
    [super prepareInView:parent];
}

- (void) setSubviewMax: (const CGFloat) width and: (const CGFloat) height
{
    [self subviewMaxWidth: width - [self staticWidth]];
    [self subviewMaxHeight: height - [self staticHeight]];
}

- (void) setSizeOnScreen:(UIViewController *const) parent
{

    [self placeSubView];

    [super setSizeOnScreen:parent];
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [self placeSubView];

    [PEXGVU setSize:self.mainView
                  x:_finalSubview.frame.size.width + [self staticWidth]
                  y:_finalSubview.frame.size.height + [self staticHeight]];
}

- (void) placeSubView
{
    const CGSize subviewSize = _subcontroller.mainView.frame.size;
    CGFloat newWidth = subviewSize.width;
    CGFloat newHeight = subviewSize.height;

    const BOOL higher = subviewSize.height > self.subviewMaxHeight;
    const BOOL wider = subviewSize.width > self.subviewMaxWidth;

    if (higher || wider)
    {
        UIScrollView * const scrollView = [[UIScrollView alloc] init];
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

        [scrollView addSubview:_subcontroller.mainView];
        self.finalSubview = scrollView;
    }
    else
    {
        self.finalSubview = self.subcontroller.mainView;
    }
    
    [self.mainView addSubview:_finalSubview];
}

- (CGFloat) staticWidth { return _staticWidth; }
- (CGFloat) staticHeight { return _staticHeight; }
- (CGFloat) subviewMaxWidth { return _subviewMaxWidth; }
- (CGFloat) subviewMaxHeight { return _subviewMaxHeight; }

- (void) subviewMaxWidth: (const CGFloat) value { _subviewMaxWidth = value; }
- (void) subviewMaxHeight: (const CGFloat) value { _subviewMaxHeight = value; }
- (void) staticWidth: (const CGFloat) value { _staticWidth = value; }
- (void) staticHeight: (const CGFloat) value { _staticHeight = value; }

@end
