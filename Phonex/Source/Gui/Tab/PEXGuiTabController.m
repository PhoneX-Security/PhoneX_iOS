//
//  PEXGuiTabController.m
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiTabController.h"
#import "PEXGuiTabController_Protected.h"

#import "PEXGuiTabContainer.h"
#import "PEXGuiTabView.h"
#import "PEXGuiPoint.h"

#import "PEXRefDictionary.h"

#import "PEXGuiClickInterface.h"

@interface PEXGuiTabController ()
{
    NSUInteger _currentPosition;
}

@property (nonatomic) PEXRefDictionary * viewsAndControllers;
@property (nonatomic) const NSArray * tabContainers;
@property (nonatomic) UIView * tabBg;
@property (nonatomic) UIView * tabSelector;
@property (nonatomic) PEXGuiClickableView * selectedTab;

@end

@implementation PEXGuiTabController

- (id) initWithTabViews: (const NSArray * const) tabContainers;
{
    NSMutableArray * const controllers = [[NSMutableArray alloc] init];
    for (PEXGuiTabContainer * const tc in tabContainers)
    {
        [controllers addObject:tc.tabController];
    }

    self = [super initWithViewControllers:controllers];

    self.viewsAndControllers = [[PEXRefDictionary alloc] init];
    self.tabContainers = tabContainers;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.tabBg = [[UIView alloc] init];
    [self.mainView addSubview: self.tabBg];

    self.tabViews = [[PEXGuiLinearScalingView alloc] init];
    [self.tabBg addSubview:self.tabViews];

    self.tabSelector = [[PEXGuiPoint alloc] initWithColor: PEXCol(@"orange_normal")];
    [self.tabViews addSubview:self.tabSelector];

}

- (void) initContent
{
    [super initContent];

    _currentPosition = 0;
    self.tabBg.backgroundColor = PEXCol(@"light_gray_high");

    for (const PEXGuiTabContainer * const container in self.tabContainers)
    {
        PEXGuiClickableView * const view = container.tabView;

        [PEXGVU setHeight:view to:PEXVal(@"tab_height")];
        [self.tabViews addView:view];

        [self.viewsAndControllers setObject:container.tabController forKey:view];

        __weak PEXGuiClickableView * const weakView = view;
        __weak PEXGuiTabController * const weakSelf = self;
        [weakView addActionBlock:^{ [weakSelf selectView:weakView]; }];
    }

    [self.tabViews bringSubviewToFront:self.tabSelector];
}

- (void) selectViewWithoutConsequence: (PEXGuiClickableView * const) view
{
    [self selectView:view withConsequence:false];
}

- (void) selectView: (PEXGuiClickableView * const) view
{
    [self selectView:view withConsequence:true];
}

- (void) selectView: (PEXGuiClickableView * const) view
    withConsequence: (const bool) withConsequence
{
    const NSUInteger index = [[self.viewsAndControllers getKeys] indexOfObject:view];

    [UIView animateWithDuration:PEXVal(@"dur_shorter")
                     animations:^{
                         // select tab
                         self.tabSelector.frame = CGRectMake(view.frame.origin.x, self.tabSelector.frame.origin.y, view.frame.size.width, self.tabSelector.frame.size.height);
                         if (self.selectedTab)
                             [self.selectedTab setEnabled:true];
                         [view setEnabled:false];
                         self.selectedTab = view;

                         //swipe to controller view
                         // all others than selected must be hidden for safety
                         // it causes some glitches otherwise (e.g. loading indicator after login in navigation bar)
                         for (int i = 0; i < self.childViewControllers.count; ++i)
                         {
                             UIView * const b = ((UIViewController*)self.childViewControllers[i]).view;
                             if (i == index)
                             {
                                 b.alpha = 1.0f;
                                 [b.superview bringSubviewToFront:b];
                             }
                             else
                             {
                                 b.alpha = 0.0f;
                             }
                         }
                         const NSUInteger previousPosition = _currentPosition;
                         _currentPosition = index;
                         if (withConsequence && self.tabSelected)
                             self.tabSelected(previousPosition, index);
                     }];
}

- (void) initBehavior
{
    [super initBehavior];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.tabBg];
    [PEXGVU setHeight:self.tabBg to: PEXVal(@"tab_height")];
    [PEXGVU moveToBottom:self.tabBg];

    [PEXGVU scaleHorizontally:self.tabViews];
    [PEXGVU setHeight:self.tabViews to: PEXVal(@"tab_height")];
    [PEXGVU moveToBottom:self.tabViews];

    [PEXGVU setHeight:self.tabSelector to:PEXVal(@"tab_selector_height")];
    [PEXGVU setPosition:self.tabSelector
                      x:self.tabViews.frame.origin.x
                      y:self.tabViews.frame.origin.y - 1.0f];
}

- (void) initState
{
    [super initState];

    // TODO maybe more effective? (its caled twice)
    [self.tabViews layoutSubviews];
    [self selectViewWithoutConsequence:[self.viewsAndControllers getKeys][0]];
}

- (void) setStaticSize
{
    [self staticWidth: 0.0f];
    [self staticHeight: PEXVal(@"tab_height")];
}

- (void)viewDidReveal {
    if (self.tabDidReveal)
        self.tabDidReveal(_currentPosition);
}

@end
