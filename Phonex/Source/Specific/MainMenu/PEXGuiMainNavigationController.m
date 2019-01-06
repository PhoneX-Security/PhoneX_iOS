//
//  PEXGuiMainNavigationControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiMainNavigationController.h"
#import "PEXGuiLabelController_Protected.h"

#import "PEXGuiClickableView.h"
#import "PEXGuiArrowBack.h"
#import "PEXGuiFactory.h"
#import "PEXDatabase.h"
#import "PEXService.h"

#import "PEXGuiPinLockManager.h"
#import "PEXGuiCallManager.h"

#import "PEXGuiImageView.h"

#import "PEXGuiShieldManager.h"
#import "PEXDbAppContentProvider.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiShieldManager.h"

#import "PEXGuiLoginController.h"

#import "PEXGuiFileCategoriesController.h"
#import "PEXGuiFileSelectNavigationController.h"
#import "PEXReport.h"

@interface PEXGuiMainNavigationController ()

@property (nonatomic) PEXGuiImageView * I_files;
@property (nonatomic) PEXGuiClickableView * B_files;

@property (nonatomic) PEXGuiController * showedController;

@end

@implementation PEXGuiMainNavigationController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"MainNavigation";

    self.B_files = [[PEXGuiClickableView alloc] init];
    [self.V_background addSubview:self.B_files];

    self.I_files = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"file")];
    [self.B_files addSubview:self.I_files];

}

- (void) initLayout
{
    [super initLayout];

    const CGFloat padding = PEXVal(@"dim_size_large");

    [PEXGVU scaleVertically:self.B_files];
    [PEXGVU moveToLeft:self.B_files];
    [PEXGVU setWidth:self.B_files
                  to:self.I_files.frame.size.width + 1.5f * padding];
    [PEXGVU centerVertically:self.I_files];
    [PEXGVU moveToLeft:self.I_files withMargin:padding];
}

- (CGFloat) leftLabelEnd
{
    return self.B_files.frame.origin.x + self.B_files.frame.size.width;
    //return self.B_logout.frame.origin.x + self.B_logout.frame.size.width;
}

- (void) initBehavior
{
    [super initBehavior];

    __weak PEXGuiMainNavigationController * const weakSelf = self;
    [self.B_files addActionBlock:^{[weakSelf showSelectFile];}];
}

- (void) showSelectFile
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_MAIN_FILE];
    PEXGrandSelectionManager * grandManager = [[PEXGrandSelectionManager alloc] init];

    PEXGuiFileSelectNavigationController* fileNavigation = [[PEXGuiFileSelectNavigationController alloc]
                                                             initWithViewTitle:PEXStrU(@"L_choose_file")
                                                            selectWithContacts:true
                                                            grandManager:grandManager];

    [fileNavigation prepareOnScreen:self];
    [fileNavigation show:self];
}

- (void) secondaryButtonClicked
{

}

- (void) primaryButtonClicked
{

}

- (void)viewDidReveal {
    if (self.tabController != nil){
        [self.tabController viewDidReveal];
        return;
    }

    [super viewDidReveal];
}


@end
