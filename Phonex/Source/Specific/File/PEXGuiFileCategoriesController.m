//
//  PEXGuiFileCategoriesController.m
//  Phonex
//
//  Created by Matej Oravec on 13/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileCategoriesController.h"
#import "PEXGuiFileCategoriesController_Protected.h"
#import "PEXReport.h"

@implementation PEXGuiFileCategoriesController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"FileCategories";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];


    [PEXGVU executeWithoutAnimations:^{
        self.B_byPhonex = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiImageView alloc] initWithImage: PEXImg(@"save") ]
                                                          labelText:PEXStr(@"L_by_phonex")];
        [self.linearView addView:self.B_byPhonex];


        self.B_byPhotos = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiImageView alloc] initWithImage: PEXImg(@"gallery") ]
                                                          labelText:PEXStr(@"L_by_photos")];
        [self.linearView addView:self.B_byPhotos];

        self.B_newPhoto = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiImageView alloc] initWithImage: PEXImg(@"camera") ]
                                                          labelText:PEXStr(@"L_new_photo")];
        [self.linearView addView:self.B_newPhoto];

        self.B_bySelected = [[PEXGuiMenuItemView alloc] initWithImage:[[PEXGuiImageView alloc] initWithImage: PEXImg(@"check") ]
                                                          labelText:PEXStr(@"L_by_selected")];
        [self.linearView addView:self.B_bySelected];
    }];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU executeWithoutAnimations:^{
        [PEXGVU scaleFull: self.linearView];

        [PEXGVU scaleHorizontally:self.B_byPhonex];
        [PEXGVU scaleHorizontally:self.B_byPhotos];
        [PEXGVU scaleHorizontally:self.B_newPhoto];
        [PEXGVU scaleHorizontally:self.B_bySelected];
    }];
}

- (void) initBehavior
{
    [super initBehavior];

    __weak PEXGuiFileNavigationController  * const weakNavigation = self.navigation;

    [self.B_byPhonex addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_PHONEX];
        [weakNavigation showByPhonex];
    }];

    [self.B_byPhotos addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_PHOTOS];
        [weakNavigation showByPhotos];
    }];

    [self.B_newPhoto addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_NEW_PHOTO];
        [weakNavigation showNewPhoto];
    }];

    [self.B_bySelected addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_SELECTED];
        [weakNavigation showBySelected];
    }];
}

@end
