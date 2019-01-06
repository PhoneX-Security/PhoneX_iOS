//
//  PEXGuiContactsItemComposed.m
//  Phonex
//
//  Created by Matej Oravec on 02/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiItemComposedView.h"

#import "PEXGuiContactsItemView.h"
#import "PEXGuiDeleteItemView.h"

#import "PEXGuiHorizontalPanRecognizerHelper.h"

#import "PEXGuiStaticDimmer.h"
#import "PEXGuiImageView.h"

@interface PEXGuiItemComposedView ()

@property (nonatomic) UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>* view;
@property (nonatomic) PEXGuiDeleteItemView * deleteView;
@property (nonatomic) PEXGuiHorizontalPanRecognizerHelper * panner;

@end

@implementation PEXGuiItemComposedView

- (id) initWithView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer> *) view;
{
    self = [super init];

    [self applyView:view];

    return self;
}

- (void) applyView: (UIView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer> *) view
{
    self.backgroundColor = PEXCol(@"invisible");

    self.view = view;
    [self addSubview:view];
    self.deleteView = [[PEXGuiDeleteItemView alloc] initWithImage:
                       [[PEXGuiImageView alloc]
                        initWithImage:PEXImg(@"trash_strong")]
                                                        labelText:nil];
    [self insertSubview:self.deleteView belowSubview:self.view];

    [PEXGVU setHeight:self to:[self staticHeight]];

    self.panner = [[PEXGuiHorizontalPanRecognizerHelper alloc] initWithView:self.view
                                                                     maxPan:[self staticHeight]];
}

- (void) reset
{
    [self.panner reset];
}

- (UIView *) getView
{
    return self.view;
}

- (PEXGuiDeleteItemView *) getDeleteView
{
    return self.deleteView;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleHorizontally:self.view];

    [PEXGVU scaleVertically: self.deleteView];
    [PEXGVU setWidth:self.deleteView to:[self staticHeight]];
    [PEXGVU moveToRight:self.deleteView];
}

- (CGFloat) staticHeight
{
    return [self.view staticHeight];
}

@end
