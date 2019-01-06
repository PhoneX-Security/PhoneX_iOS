//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "PEXGuiBusyInputFullscreenController.h"
#import "PEXTaskListener.h"


@interface PEXGuiAddContactWithUsernameController : PEXGuiBusyInputFullscreenController<PEXTaskListener>

@property (nonatomic) NSString * preparedUsername;

@end