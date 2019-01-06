//
//  PEXGuiContextMenuViewController.m
//  Phonex
//
//  Created by Matej Oravec on 05/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContextMenuViewController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiContextItemHolder.h"
#import "PEXGuiImageView.h"

@interface PEXGuiContextMenuViewController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXRefDictionary * actionsAndPresentations;

@end

@implementation PEXGuiContextMenuViewController

- (id) initWithActionsAndPresentations: (PEXRefDictionary * const) actionsAndPresentations
{
    self = [super init];

    self.actionsAndPresentations = actionsAndPresentations;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];
}

- (void) initState
{
    [super initState];

    [self initContextActions];
}

- (void) initContextActions
{
    const NSUInteger count = self.actionsAndPresentations.count;
    NSArray * const actions = [self.actionsAndPresentations getKeys];
    NSArray * const presentations = [self.actionsAndPresentations getObjects];
    for (NSUInteger i = 0; i < count; ++i)
    {
        const PEXGuiContextItemHolder * const itemHolder = [presentations objectAtIndex:i];
        PEXGuiMenuItemView * const itemView = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiImageView alloc]
                initWithImage:itemHolder.icon]
                                                                              labelText:itemHolder.text];

        void (^action)(void) = [actions objectAtIndex:i];
        [itemView addActionBlock:^{
            [self.fullscreener dismissViewControllerAnimated:true completion:action];
        }];

        [PEXGVU executeWithoutAnimations:^{
            [self.linearView addView:itemView];
            [PEXGVU scaleHorizontally:itemView];
        }];
    }
}

- (void) setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    // TODO GARBAGE
    const CGFloat contentHeight =
    (self.actionsAndPresentations.count) * [PEXGuiMenuItemView staticHeight];

    const CGFloat maxHeight = [parent subviewMaxHeight];
    [PEXGVU setSize:self.mainView
                  x:[parent subviewMaxWidth]
                  y:((contentHeight > maxHeight) ? maxHeight : contentHeight)];
}

@end
