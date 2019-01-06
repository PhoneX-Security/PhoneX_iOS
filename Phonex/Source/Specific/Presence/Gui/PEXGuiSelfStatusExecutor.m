//
//  PEXGuiSelfStatusExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 28/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiSelfStatusExecutor.h"

#import "PEXGuiSelfStatusControllerViewController.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiFactory.h"
#import "PEXGuiTextController.h"

#import "PEXGuiPresenceCenter.h"
#import "PEXGuiDialogBinaryVisitor.h"
#import "PEXGuiPresenceLabelController.h"
#import "PEXGuiProfileController.h"
#import "PEXReport.h"

@interface PEXGuiSelfStatusExecutor ()

@property (nonatomic) PEXGuiController * parent;
@property (nonatomic) PEXGuiSelfStatusControllerViewController *controller;

@end

@implementation PEXGuiSelfStatusExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void)show
{
    self.controller = [[PEXGuiSelfStatusControllerViewController alloc] init];

    PEXGuiDialogBinaryVisitor * const visitor = [[PEXGuiDialogBinaryVisitor alloc] initWithDialogSubcontroller:self.controller
                                                                                                      listener:self];
    PEXGuiController * const dialog = [[PEXGuiDialogBinaryController alloc] initWithVisitor:visitor];
    /*
    PEXGuiPresenceLabelController* a = [[PEXGuiPresenceLabelController alloc]
                                 initWithViewController:dialog
                                 title:PEXStrU(@"L_choose_presence_status")];

                                 //[dialog   setListener:self];
                                 */

    PEXGuiLabelController * a = [[PEXGuiLabelController alloc] initWithViewController:dialog
                             title:PEXStrU(@"L_choose_presence_status")];

    self.topController = [a showInWindow:self.parent];

    [super show];
}

- (void)secondaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CHANGE_STATUS_CANCEL];
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CHANGE_STATUS_CONFIRM];
    [[PEXGuiPresenceCenter instance] setCurrentWantedPresenceAsync:
            [self.controller getSelected]];
    [self dismissWithCompletion:nil];
}

- (void) clicked
{
    [self dismissWithCompletion:^{
    [PEXGAU showInNavigation:[[PEXGuiProfileController alloc] init]
                          in:self.parent
                       title:PEXStrU(@"L_my_profile")];
    }];
}

@end