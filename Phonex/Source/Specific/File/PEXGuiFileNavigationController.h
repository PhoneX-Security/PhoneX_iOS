//
//  PEXGuiFileNavigationController.h
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiAppNavigationController.h"
#import "PEXGuiFileController.h"

@interface PEXGuiFileNavigationController : PEXGuiAppNavigationController

- (void) showByPhonex;
- (void) showByPhotos;
- (void) showBySelected;
- (void) showNewPhoto;


@end
