//
//  PEXGuiMainNavigationControllerViewController.h
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiAppLabelControllerViewController.h"
#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiMainNavigationController :
    PEXGuiAppLabelControllerViewController<PEXGuiDialogBinaryListener>

@property(nonatomic) PEXGuiController * tabController;
@end
