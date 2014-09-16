//
//  PEXGuinavigationControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiNavigationController.h"
#import "PEXGuinavigationController_Protected.h"

#import "PEXGuiNavigationLabel.h"
#import "PEXGuiBackgroundNavigationView.h"
#import "PEXGuiImageClickableView.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiNavigationController ()

@property (nonatomic) NSString * title;
@property (nonatomic) PEXGuiNavigationLabel * L_title;
@property (nonatomic) PEXGuiImageClickableView * I_back;

@end

@implementation PEXGuiNavigationController

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title
{
    self = [super initWithViewController:controller];

    self.title = title;

    return self;
}

- (UIView *) getBackgroundView
{
    return [[PEXGuiBackgroundNavigationView alloc] init];
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.L_title = [[PEXGuiNavigationLabel alloc] init];
    [self.mainView addSubview:self.L_title];

    self.I_back = [[PEXGuiImageClickableView alloc] init];
    [self.L_title addSubview:self.I_back];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.L_title];
    [PEXGVU moveToTop:self.L_title];

    [PEXGVU move: self.finalSubview below:self.L_title];

    [PEXGVU centerVertically:self.I_back];
    [PEXGVU moveToLeft:self.I_back withMargin:PEXVal(@"contentMarginLarge")];
}

- (void) initContent
{
    [super initContent];

    [self.I_back setImage:[UIImage imageNamed:@"log32.png"]];
}

- (void) initBehavior
{
    [super initBehavior];

    // Needs to be set because then the subviews do not respond ...
    // probably set on NO by default
    self.L_title.userInteractionEnabled = YES;

    [self.I_back addAction:self action:@selector(goBack)];
}

- (void) setStaticSize
{
    [self staticWidth: 0.0f];
    [self staticHeight: [PEXGuiNavigationLabel height]];
}

- (void) goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
