//
//  PEXGuiFileNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileNavigationController.h"
#import "PEXGuiFileNavigationController_Protected.h"

#import "PEXGuiFileByPhotosController.h"
#import "PEXGuiFileByPhonexController.h"
#import "PEXGuiFileBySelection.h"

@interface PEXGuiFileNavigationController ()

@end

@implementation PEXGuiFileNavigationController

- (void) showByPhotos
{
    [self showCategory:[[PEXGuiFileByPhotosController alloc] init]];
}

- (void) showByPhonex
{
    [self showCategory:[[PEXGuiFileByPhonexController alloc] init]];
}

- (void) showBySelected
{
    [self showCategory:[[PEXGuiFileBySelection alloc] init]];
}

- (void) showNewPhoto
{
    [self showCategory:[[PEXGuiFileBySelection alloc] init]];
}

- (void) showCategory: (PEXGuiFileController * const) fileController
{
    [fileController prepareInView:self];
    [self placeSubcontroller:fileController];
    self.showedCategoryController = fileController;
}

@end
