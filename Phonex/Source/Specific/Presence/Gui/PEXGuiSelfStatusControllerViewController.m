//
//  PEXGuiSelfStatusControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 28/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiSelfStatusControllerViewController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiControllerDecorator.h"
#import "PEXGuiCircleView.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiPresenceView.h"
#import "PEXGuiMenuItemView.h"

#import "PEXGuiPresenceCenter.h"
#import "PEXReport.h"

@interface PEXGuiSelfStatusControllerViewController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiCircleView * selectorView;
@property (nonatomic) NSInteger selected;

@end

@implementation PEXGuiSelfStatusControllerViewController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"SelfStatus";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    self.selectorView = [[PEXGuiCircleView alloc] init];
}


- (void) initContent
{
    [super initContent];

    self.selectorView.backgroundColor = PEXCol(@"orange_normal");
}

- (void) selectView: (UIView * const) view
                   item: (const NSNumber * const) itemId
{
    [self.selectorView removeFromSuperview];
    [view addSubview:self.selectorView];
    [PEXGVU centerVertically:self.selectorView];
    [PEXGVU moveToRight:self.selectorView withMargin:PEXVal(@"dim_size_large")];
    self.selected= itemId.integerValue;
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        [self initItems];
    }];
}

- (NSNumber *) getCurrentItem
{
    return [NSNumber numberWithInteger:
            [[PEXGuiPresenceCenter instance] currentWantedPresence]];
}

- (void) initItems
{
    const NSNumber * const currentItem = [self getCurrentItem];
    for (NSUInteger i = PEX_GUI_PRESENCE_FIRST; i < PEX_GUI_PRESENCE_LAST + 1; ++i)
    {
        [self addItem:[NSNumber numberWithInteger:i]
          currentItem:currentItem
                modify:nil];
    }
}

- (void) addItem: (const NSNumber * const) itemId
     currentItem: (const NSNumber * const) currentItem
          modify: (SEL) selectorOnView
{
    PEXGuiPresenceView * const image = [[PEXGuiPresenceView alloc] init];
    [image setStatus: [itemId integerValue]];
    NSString * label = nil;

    switch ([itemId integerValue])
    {
        case PEX_GUI_PRESENCE_ONLINE: label = PEXStr(@"L_online"); break;
        case PEX_GUI_PRESENCE_AWAY: label = PEXStr(@"L_away"); break;
        case PEX_GUI_PRESENCE_OFFLINE: label = PEXStr(@"L_invisible"); break;
    }

    PEXGuiMenuItemView * const view = [[PEXGuiMenuItemView alloc] initWithImage:image labelText:label];
    if (selectorOnView)
        [view performSelector:selectorOnView];

    [self.linearView addView:view];
    [PEXGVU scaleHorizontally:view];

    __weak const PEXGuiSelfStatusControllerViewController * const weakSelf = self;
    __weak UIView * const weakView = view;
    [view addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_PRESENCE_STATUS];
        [weakSelf selectView:weakView item:itemId];;
    }];

    if ([currentItem isEqualToNumber:itemId])
    {
        [self selectView:view item:itemId];
    }
}

- (NSInteger) getSelected
{
    return self.selected;
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
    (PEX_GUI_PRESENCE_LAST + 1) * [PEXGuiMenuItemView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}

@end