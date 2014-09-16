//
//  PEXVC_UnaryDialog.m
//  Phonex
//
//  Created by Matej Oravec on 27/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiWindowController.h"
#import "PEXGuiWindowController_Protected.h"

#import "PEXGuiWindowMainView.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiWindowBackgroundView.h"

#import "PEXGuiViewUtils.h"
#import "PEXResValues.h"

@interface PEXGuiWindowController ()

@end

@implementation PEXGuiWindowController

- (void) setStaticSize
{
    [self staticWidth: 2.0f * PEXVal(@"contentMarginLarge")];
    [self staticHeight: 2.0f * PEXVal(@"contentMarginLarge")];
}

- (UIView *) getMainView
{
    return [[PEXGuiWindowMainView alloc] init];
}

- (UIView *) getBackgroundView
{
    return [[PEXGuiWindowBackgroundView alloc] init];
}

- (void) initLayout
{
    [super initLayout];
    
    [PEXGVU center:self.finalSubview];
}

// MAINTENANCE

- (void) show:(UIViewController * const) parent
{
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    parent.modalPresentationStyle = UIModalPresentationCurrentContext;
    // MODAL CROSS DISOLVE BUG FIX
    self.view.alpha = 0.0f;
    [parent presentViewController:self animated:NO completion:nil];
    [UIView beginAnimations: nil context: nil];
    self.view.alpha = 1.0f;
    [UIView commitAnimations];
}

@end
