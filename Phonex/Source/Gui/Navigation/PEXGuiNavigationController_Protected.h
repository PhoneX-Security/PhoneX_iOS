//
//  PEXGuinavigationControllerViewController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 07/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiNavigationController.h"
#import "PEXGuiLabelController_Protected.h"

#import "PEXGuiArrowBack.h"

@interface PEXGuiNavigationController ()

@property (nonatomic) PEXGuiArrowBack * B_back;
@property (nonatomic) PEXGuiClickableView * B_backClickWrapper;

- (void) goBack;

@end
