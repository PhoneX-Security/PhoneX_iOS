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
#import "PEXGuiWindowBackgroundView.h"

#import "PEXUnmanagedObjectHolder.h"

#import "PEXGuiOutlineView.h"
#import "UIViewController+PEXRelayout.h"


@interface PEXGuiWindowController ()

@property (nonatomic) UIView * outlineView;

@end

@implementation PEXGuiWindowController

- (void) setStaticSize
{
    [self staticWidth: 2.0f * PEXVal(@"dim_size_large")];
    [self staticHeight: 2.0f * PEXVal(@"dim_size_large")];
}

- (UIView *) getMainView
{
    return [[PEXGuiWindowMainView alloc] init];
}

- (UIView *)getBackgroundView
{
    return [[PEXGuiWindowBackgroundView alloc] init];
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.outlineView = [[PEXGuiOutlineView alloc] init];
    [self.mainView addSubview:self.outlineView];
}

- (void) initLayout
{
    [super initLayout];

    UIView * const subcontrollerView = ((UIViewController*)self.childViewControllers[0]).view;

    [PEXGVU center:subcontrollerView];

    const CGRect frame = subcontrollerView.frame;
    self.outlineView.frame = CGRectMake(frame.origin.x - 1.0f,
                                     frame.origin.y - 1.0f,
                                     frame.size.width + 2.0f,
                                     frame.size.height + 2.0f);

    [self.mainView bringSubviewToFront:subcontrollerView];
}

// MAINTENANCE


// TODO Is not prepared for IN VIEW situation yet ... only fullscreen
- (void) show:(UIViewController * const) parent {
    [self show:parent animated:YES];
}

- (void) show:(UIViewController * const) parent animated: (const bool) animated {
    if (animated) {
        self.view.alpha = 0.0f;
    }

    [self addSelfAsChildIfNotAdded:([[parent class] isSubclassOfClass:[PEXGuiController class]] ? ((PEXGuiController*) parent).fullscreener : parent)];
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        self.view.alpha = 1.0f;
        [UIView commitAnimations];
    }
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self dismissWithCompletion:completion animation:^{
        self.view.alpha = 0.0f;
    }];
}

- (BOOL)relayoutHierarchy {
    // Stop relayouting, new window, boundary.
    [self relayout];
    return YES;
}

- (BOOL)relayout {
    UIViewController * ctl = self.parentViewController;
    if (ctl != nil && [ctl isKindOfClass:[PEXGuiController class]]){
        [self reloadOnScreen:ctl];
        [self show:ctl animated:NO];
    }

    [super relayout];
    return NO;
}

@end
