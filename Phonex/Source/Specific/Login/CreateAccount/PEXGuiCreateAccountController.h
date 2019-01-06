//
// Created by Matej Oravec on 19/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiCheckBox.h"
#import "PEXGuiProgressController.h"
#import "PEXCreateAccountExecutor.h"


@interface PEXGuiCreateAccountController : PEXGuiController<PEXNewAccountCreatedListener>

@property (nonatomic) id<PEXNewAccountCreatedListener> listener;

- (void) reloadCaptcha;

@end