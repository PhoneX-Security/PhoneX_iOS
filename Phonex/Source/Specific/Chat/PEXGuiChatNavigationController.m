//
//  PEXGuiChatNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 03/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiChatNavigationController.h"
#import "PEXGuiAppNavigationController_Protected.h"

#import "PEXGuiClickableView.h"
#import "PEXGuiImageView.h"
#import "PEXGuiCallManager.h"

#import "PEXGuiArrowDown.h"

#import "PEXGuiCircleView.h"
#import "PEXDbContact.h"
#import "PEXGuiImageView.h"

#import "PEXGuiFileController.h"
#import "PEXFilePickManager.h"
#import "PEXGuiFileSelectNavigationController.h"

#import "PEXGuiFileCategoriesController.h"
#import "PEXLicenceManager.h"
#import "PEXReport.h"
#import "PEXService.h"

@interface PEXGuiChatNavigationController ()

@property (nonatomic) UIView * I_call;
@property (nonatomic) PEXGuiClickableView * B_call;

@property (nonatomic) UIView * I_file;
@property (nonatomic) PEXGuiClickableView * B_file;

@property (nonatomic) PEXGuiChatController * chatController;

@property (nonatomic) const PEXDbContact * contact;

@end

@implementation PEXGuiChatNavigationController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"Messages";

    self.B_call = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_call];

    self.I_call = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"phone")];
    [self.B_call addSubview:self.I_call];


    self.B_file = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_file];

    self.I_file = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"file")];
    [self.B_file addSubview:self.I_file];

}

- (void) initLayout
{
    [super initLayout];

    const CGFloat padding = PEXVal(@"dim_size_large");
    const CGFloat halfPadding = padding / 2.0f;
    const CGFloat paddingWidth = padding * 1.5f;

    // status
    [PEXGVU scaleVertically:self.B_call];
    [PEXGVU setWidth:self.B_call
                  to:self.I_call.frame.size.width + paddingWidth];
    [PEXGVU moveToRight:self.B_call];

    [PEXGVU centerVertically:self.I_call];
    [PEXGVU moveToRight:self.I_call withMargin:padding];


    // file
    [PEXGVU scaleVertically:self.B_file];

    [PEXGVU setWidth:self.B_file
                  to:self.I_file.frame.size.width + padding];
    [PEXGVU move:self.B_file leftOf:self.B_call];

    [PEXGVU centerVertically:self.I_file];
    [PEXGVU moveToRight:self.I_file withMargin:halfPadding];

}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;
    [self.B_call addActionBlock:^
    {
        [PEXReport logUsrButton:PEX_EVENT_BTN_CHAT_CALL];
        if ([[[PEXService instance] licenceManager] checkPermissionsAndShowGetPremiumInParent:weakSelf])
            return;

        [[PEXGuiCallManager instance] showCallOutgoing:weakSelf.contact];
    }];

    [self.B_file addActionBlock:^
     {
         [PEXReport logUsrButton:PEX_EVENT_BTN_CHAT_FILE];
         [weakSelf showSelectFile];
     }];

    _shown = true;
}

- (void) viewDidAppear:(BOOL)animated
{
    if (self.shown)
        [PEXGNFC instance].currentChatSip = self.contact.sip;

    [super viewDidAppear:animated];
}

- (void) setShown:(bool)shown
{
    if (shown)
        [PEXGNFC instance].currentChatSip = self.contact.sip;
    else
        [[PEXGNFC instance] unsetCurrentChatSip];
    _shown = shown;
}

- (void) showSelectFile
{
    PEXGrandSelectionManager * grandManager = [[PEXGrandSelectionManager alloc] init];

    grandManager.recipients = @[self.contact];

    PEXGuiFileSelectNavigationController * fileNavigation = [[PEXGuiFileSelectNavigationController alloc]
                                                             initWithViewTitle:PEXStrU(@"L_choose_file")
                                                                 selectWithContacts:false
                                                                       grandManager:grandManager];

    fileNavigation.completionEx =
    ^{
        self.shown = true;
    };

    [fileNavigation prepareOnScreen:self];
    [fileNavigation show:self];

    self.shown = false;
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.shown = false;

    [super viewWillDisappear:animated];
}

- (id) initWithViewController: (PEXGuiController * const) controller
                      contact: (const PEXDbContact * const) contact
               chatController: (PEXGuiChatController * const) chatController
{
    self = [super initWithViewController:controller title:contact.displayName];

    self.contact = contact;

    self.chatController = chatController;

    return self;
}

- (CGFloat) rightLabelEnd
{
    return self.B_file.frame.origin.x;
    //return self.B_call.frame.origin.x;
}

@end
