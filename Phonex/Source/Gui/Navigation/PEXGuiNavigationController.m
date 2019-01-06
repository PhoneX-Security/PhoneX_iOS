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
#import "PEXGuiPoint.h"
#import "PEXGuiMenuLine.h"

#import "PEXGuiCallsController.h"
#import "PEXGuiCallManager.h"
#import "PEXReport.h"


@interface PEXGuiNavigationController ()

@end

@implementation PEXGuiNavigationController


- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_backClickWrapper = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_backClickWrapper];

    self.B_back = [[PEXGuiArrowBack alloc] initWithColor:PEXCol(@"light_gray_low")];
    [self.B_backClickWrapper addSubview:self.B_back];

}

- (void) initLayout
{
    [super initLayout];

    const CGFloat leftPadding = PEXVal(@"dim_size_large");

    [PEXGVU scaleVertically:self.B_backClickWrapper];
    [PEXGVU moveToLeft:self.B_backClickWrapper];
    [PEXGVU setWidth:self.B_backClickWrapper to:self.B_back.frame.size.width + 2 * leftPadding];

    [PEXGVU centerVertically:self.B_back];
    [PEXGVU moveToLeft:self.B_back withMargin:leftPadding];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_backClickWrapper addAction:self action:@selector(goBackWrap)];
}

- (void) goBackWrap
{
    [self goBack];
}

- (void) goBack
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_NAVIGATION_BACK];
    [self dismissViewControllerAnimated:true completion:nil];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismissWithCompletion:completion animation:^{
        [PEXGVU set: self.view x:[[UIScreen mainScreen] bounds].size.width];
    }];
}

// TODO Is not prepared for IN VIEW situation yet ... only fullscreen
- (void) show:(UIViewController * const) parent
{
    [PEXGVU set: self.view x:[[UIScreen mainScreen] bounds].size.width];

    [self addSelfAsChildIfNotAdded:([[parent class] isSubclassOfClass:[PEXGuiController class]] ?
            ((PEXGuiController*) parent).fullscreener :
            parent)];

    [UIView beginAnimations: nil context: nil];
    [PEXGVU set: self.view x:0.0f];
    [UIView commitAnimations];
}

- (CGFloat) leftLabelEnd
{
    return self.B_backClickWrapper.frame.origin.x + self.B_backClickWrapper.frame.size.width;
}

@end
