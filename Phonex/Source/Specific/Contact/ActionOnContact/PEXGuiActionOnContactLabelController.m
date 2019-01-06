//
//  PEXGuiActionOnContactNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 08/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiActionOnContactLabelController.h"
#import "PEXGuiLabelController_Protected.h"

#import "PEXGuiClickableView.h"
#import "PEXGuiImageView.h"

@interface PEXGuiActionOnContactLabelController ()

@property (nonatomic) id<PEXGuiActionOnContactListener> listener;

@property (nonatomic) UIView * B_details;
@property (nonatomic) PEXGuiClickableView * B_detailsClickWrapper;

@end

@implementation PEXGuiActionOnContactLabelController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_detailsClickWrapper = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_detailsClickWrapper];
    self.B_details = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"settings")];;
    [self.B_detailsClickWrapper addSubview:self.B_details];
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat padding = PEXVal(@"dim_size_large");

    [PEXGVU scaleVertically:self.B_detailsClickWrapper];
    [PEXGVU setWidth:self.B_detailsClickWrapper
                  to:self.B_details.frame.size.width + padding * 1.5];
    [PEXGVU moveToRight:self.B_detailsClickWrapper];
    [PEXGVU centerVertically:self.B_details];
    [PEXGVU moveToRight:self.B_details withMargin:padding];
}

- (void) initBehavior
{
    [super initBehavior];

    __weak PEXGuiActionOnContactLabelController * const weakSelf = self;
    [self.B_detailsClickWrapper addActionBlock:^{
        [weakSelf.listener settingsClicked];
    }];
}

- (CGFloat) rightLabelEnd
{
    return self.B_detailsClickWrapper.frame.origin.x;
}

- (void) setListener: (id<PEXGuiActionOnContactListener>) listener
{
    _listener = listener;
}

@end
