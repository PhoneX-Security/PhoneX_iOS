//
//  PEXGuiBroadcastNavigationControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiBroadcastNavigationController.h"
#import "PEXGuiAppNavigationController_Protected.h"

#import "PEXGuiClickableView.h"
#import "PEXGrandSelectionManager.h"
#import "PEXGuiMessageComposerController.h"
#import "PEXContactSelectManager.h"
#import "PEXGuiContactsSelectController.h"
#import "PEXGuiSelectContactsNavigationController.h"
#import "PEXGuiImageView.h"

#import "PEXStringUtils.h"
#import "PEXMessageUtils.h"
#import "PEXReport.h"

@interface PEXGuiBroadcastNavigationController ()

@property (nonatomic) UIView * I_contacts;
@property (nonatomic) PEXGuiClickableView * B_contacts;

@property (nonatomic) PEXGrandSelectionManager * grandManager;
@property (nonatomic) PEXGuiMessageComposerController * composerController;

@end

@implementation PEXGuiBroadcastNavigationController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_contacts = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_contacts];

    self.I_contacts = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"contact_book")];
    [self.B_contacts addSubview:self.I_contacts];
}

- (void) initLayout
{
    [super initLayout];

    const CGFloat padding = PEXVal(@"dim_size_large");
    const CGFloat halfPadding = padding / 2.0f;
    const CGFloat paddingWidth = padding * 1.5f;

    // status
    [PEXGVU scaleVertically:self.B_contacts];
    [PEXGVU setWidth:self.B_contacts
                  to:self.I_contacts.frame.size.width + paddingWidth];
    [PEXGVU moveToRight:self.B_contacts];

    [PEXGVU centerVertically:self.I_contacts];
    [PEXGVU moveToRight:self.I_contacts withMargin:padding];
}

- (void) initBehavior
{
    [super initBehavior];

    WEAKSELF;

    [self.B_contacts addActionBlock:^
     {
         [PEXReport logUsrButton:PEX_EVENT_BTN_BCAST_CONTACTS];
         [weakSelf showSelectContacts];
     }];
}

- (void) showSelectContacts
{
    NSString * const text = [self.composerController getComposedText];
    
    if (![PEXMessageUtils isSendeable:text])
    {
        [self.composerController warningFlash];
        return;
    }

    self.grandManager.messageText = [self.composerController getComposedText];

    // show contacts:
    PEXContactSelectManager * const manager = [[PEXContactSelectManager alloc] init];

    PEXGuiContactsSelectController * const contactListController =
    [[PEXGuiContactsSelectController alloc] initWithManager:manager];

    PEXGuiSelectContactsNavigationController * const contactSelectNavgation =
    [[PEXGuiSelectContactsNavigationController alloc] initWithViewController:contactListController title:PEXStrU(@"L_select_contacts") manager:manager
                                                                grandManager:self.grandManager];

    [contactSelectNavgation prepareOnScreen:self];
    [contactSelectNavgation show:self];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.grandManager removeController:self];
    self.grandManager = nil;

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (id) initWithViewController: (PEXGuiController * const) controller
           composerController: (PEXGuiMessageComposerController * const) composerController
                 grandManager: (PEXGrandSelectionManager * const) grandManager;
{
    self = [super initWithViewController:controller title:PEXStrU(@"L_compose_message")];

    self.grandManager = grandManager;
    [self.grandManager addController:self];

    self.composerController = composerController;

    return self;
}

- (void)initState
{
    [super initState];

    [self.composerController setComposedText:self.grandManager.messageText];
}


- (CGFloat) rightLabelEnd
{
    return self.B_contacts.frame.origin.x;
}

@end
