//
//  PEXGuiActionOnContactExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiActionOnContactExecutor.h"

#import "PEXGuiActionsOnContactController.h"
#import "PEXGuiDialogCloser.h"
#import "PEXDbContact.h"
#import "PEXGuiCallController.h"
#import "PEXOutgoingCall.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiChatController.h"
#import "PEXGuiContactDetailsController.h"
#import "PEXGuiActionOnContactLabelController.h"
#import "PEXGuiCallManager.h"
#import "PEXLicenceManager.h"
#import "PEXGrandSelectionManager.h"
#import "PEXGuiFileSelectNavigationController.h"
#import "PEXReport.h"
#import "PEXService.h"

@interface PEXGuiActionOnContactExecutor ()

@property (nonatomic) const PEXDbContact * contact;
@property (nonatomic) PEXGuiController * parentController;

@property (nonatomic) UIViewController * subController;

@end

@implementation PEXGuiActionOnContactExecutor

-(void) executeWithContact: (const PEXDbContact * const) contact
              parentController: (PEXGuiController * const) parentController
{
    PEXGuiActionsOnContactController * const main = [[PEXGuiActionsOnContactController alloc] init];
    PEXGuiDialogCloser * const visitor = [[PEXGuiDialogCloser alloc] initWithDialogSubcontroller:main
                                                                                        listener:nil];

    visitor.finishPrimaryBlock = ^{[self dismissWithCompletion:nil];};

    PEXGuiController * const vc =
    [[PEXGuiDialogUnaryController alloc] initWithVisitor:visitor];

    self.subController = vc;
    self.contact = contact;
    self.parentController = parentController;
    [main setListener:self];

    // PEXGuiActionOnContactLabelController * const labelController =
    // [[PEXGuiActionOnContactLabelController alloc] initWithViewController:vc title:contact.displayName];

    PEXGuiLabelController * const labelController =
    [[PEXGuiLabelController alloc] initWithViewController:vc title:contact.displayName];

    self.topController = [labelController showInWindow:parentController];
    // [labelController setListener:self];

    [super show];
}

- (void) callClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_ACTION_CALL];
    [self dismissWithCompletion:^{ [self showCall]; }];
}

- (void) showCall
{
    if ([[[PEXService instance] licenceManager] checkPermissionsAndShowGetPremiumInParent:self.parentController])
        return;

    [[PEXGuiCallManager instance] showCallOutgoing:self.contact];
}

- (void) messageClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_ACTION_MESSAGE];
    [self dismissWithCompletion:^{
        [PEXGuiChatController showChatInNavigation:self.parentController withContact:self.contact];
    }];
}
- (void) fileClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_ACTION_FILE];
    [self dismissWithCompletion:^{
        [self showSelectFile];
    }];
}

- (void) showSelectFile {
    PEXGrandSelectionManager *grandManager = [[PEXGrandSelectionManager alloc] init];

    grandManager.recipients = @[self.contact];

    PEXGuiFileSelectNavigationController *fileNavigation = [[PEXGuiFileSelectNavigationController alloc]
            initWithViewTitle:PEXStrU(@"L_choose_file")
           selectWithContacts:false
                 grandManager:grandManager];

    [fileNavigation prepareOnScreen:self.parentController];
    [fileNavigation show:self.parentController];
}

- (void) settingsClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_ACTION_SETTINGS];
    [self dismissWithCompletion:^{
        PEXGuiContactDetailsController * const controller =
        [[PEXGuiContactDetailsController alloc] initWithContact: self.contact];


        PEXGuiNavigationController * a = [[PEXGuiAppNavigationController alloc]
                                          initWithViewController:controller
                                          title:self.contact.displayName];

        [controller setNavigationParent:a];

        [a prepareOnScreen:self.parentController];
        [a show:self.parentController];
    }];
}

@end
