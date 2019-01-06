//
//  PEXGuiFileNavigationController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileNavigationController.h"
#import "PEXGuiAppNavigationController_Protected.h"

#import "PEXGuiFileByPhotosController.h"
#import "PEXGuiFileByPhonexController.h"

@interface PEXGuiFileNavigationController ()

@property (nonatomic) PEXGuiFileController * showedCategoryController;

- (void) showCategory: (PEXGuiFileController * const) fileController;


@end