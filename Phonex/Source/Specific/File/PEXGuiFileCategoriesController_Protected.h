//
//  PEXGuiFileCategoriesController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 13/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileCategoriesController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiMenuItemView.h"
#import "PEXGuiImageView.h"

@interface PEXGuiFileCategoriesController ()

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiMenuItemView * B_byPhonex;
@property (nonatomic) PEXGuiMenuItemView * B_byPhotos;
@property (nonatomic) PEXGuiMenuItemView *B_bySelected;
@property (nonatomic) PEXGuiMenuItemView *B_newPhoto;

@end