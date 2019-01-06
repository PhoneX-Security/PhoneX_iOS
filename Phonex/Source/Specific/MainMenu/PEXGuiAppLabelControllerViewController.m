//
//  PEXGuiAppLabelControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiAppLabelControllerViewController.h"
#import "PEXGuiLabelController_Protected.h"

#import "PEXGuiCrossView.h"
#import "PEXGuiClickableView.h"
#import "PEXGuiPreferencesController.h"
#import "PEXGuiImageView.h"
#import "PEXGuiPresenceView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiSelfStatusExecutor.h"

#import "PEXGuiPresenceCenter.h"
#import "PEXGuiCallsController.h"
#import "PEXReport.h"

@interface PEXGuiAppLabelControllerViewController ()

@property (nonatomic) UIView * B_preferencesView;
@property (nonatomic) PEXGuiClickableView * B_preferencesViewClickWrapper;

@property (nonatomic) PEXGuiPresenceView * B_statusView;
@property (nonatomic) PEXGuiClickableView * B_profileWrapper;
@property (nonatomic) PEXGuiActivityIndicatorView * statusActivityView;
@property (nonatomic) PEXGuiImageView * profileView;

@property (nonatomic) NSLock * lock;

@end

@implementation PEXGuiAppLabelControllerViewController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_preferencesViewClickWrapper = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_preferencesViewClickWrapper];
    self.B_preferencesView = [[PEXGuiImageView alloc]
                              initWithImage:PEXImg(@"settings")];
    [self.B_preferencesViewClickWrapper addSubview:self.B_preferencesView];

    self.B_profileWrapper = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_profileWrapper];

    self.profileView = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"contact")];
    [self.B_profileWrapper addSubview:self.profileView];

    self.B_statusView = [[PEXGuiPresenceView alloc] initWithDiameter:PEXVal(@"dim_size_small")];
    [self.profileView addSubview:self.B_statusView];

    self.statusActivityView = [[PEXGuiActivityIndicatorView alloc] init];
    [self.B_profileWrapper addSubview:self.statusActivityView];
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat padding = PEXVal(@"dim_size_large");
    const CGFloat halfPadding = padding / 2.0f;
    const CGFloat paddingWidth = padding * 1.5f;

    // preferences
    [PEXGVU scaleVertically:self.B_preferencesViewClickWrapper];
    [PEXGVU setWidth:self.B_preferencesViewClickWrapper
                  to:self.B_preferencesView.frame.size.width + paddingWidth];
    [PEXGVU moveToRight:self.B_preferencesViewClickWrapper];
    [PEXGVU centerVertically:self.B_preferencesView];
    [PEXGVU moveToRight:self.B_preferencesView withMargin:padding];

    // status
    [PEXGVU scaleVertically:self.B_profileWrapper];
    [PEXGVU setWidth:self.B_profileWrapper
                  to:self.profileView.frame.size.width + padding];
    [PEXGVU move:self.B_profileWrapper leftOf:self.B_preferencesViewClickWrapper];
    [PEXGVU centerVertically:self.profileView];
    [PEXGVU moveToRight:self.profileView withMargin:halfPadding];
    [PEXGVU moveToLeft:self.B_statusView];
    [PEXGVU moveToTop:self.B_statusView];

    [PEXGVU center:self.statusActivityView];
}

- (void) initState
{
    [super initState];

    self.lock = [[NSLock alloc] init];

    [[PEXGuiPresenceCenter instance] addListenerAsync:self];
    [self.B_statusView setStatus:[[PEXGuiPresenceCenter instance]currentWantedPresence]];
}

- (void) presencePreset: (const PEX_GUI_PRESENCE) presetPresence
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lock lock];
        [self.B_statusView setStatus:[[PEXGuiPresenceCenter instance]currentWantedPresence]];
        [self.statusActivityView startAnimating];
        self.statusActivityView.hidden = false;
        [self.lock unlock];
    });
}
- (void) presenceSet: (const PEX_GUI_PRESENCE) setPresence
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.lock lock];
        // get actual presence status
        [self.B_statusView setStatus:[[PEXGuiPresenceCenter instance]currentWantedPresence]];
        [self.statusActivityView stopAnimating];
        self.statusActivityView.hidden = true;
        [self.lock unlock];
    });
}

- (void) presenceProcessing
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.lock lock];
        [self.statusActivityView startAnimating];
        self.statusActivityView.hidden = false;
        [self.lock unlock];
    });
}

- (CGFloat) rightLabelEnd
{
    return self.B_profileWrapper.frame.origin.x;
}

- (void) initBehavior
{
    [super initBehavior];

    [self.B_preferencesViewClickWrapper addAction:self action:@selector(showPreferences:)];
    [self.B_profileWrapper addAction:self action:@selector(showChoosePresence:)];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.lock lock];
    [[PEXGuiPresenceCenter instance] removeListener:self];
    [self.lock unlock];

    [super dismissViewControllerAnimated:flag
                              completion:completion];
}

- (IBAction) showPreferences: (id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_SHOW_PREFERENCES];
    [PEXGAU showInNavigation:[[PEXGuiPreferencesController alloc] init]
                          in:self
                       title:PEXStrU(@"menu_preferences")];
}

- (IBAction) showChoosePresence: (id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CHOOSE_PRESENCE];
    [[[PEXGuiSelfStatusExecutor alloc] initWithParentController:self] show];
}

@end
