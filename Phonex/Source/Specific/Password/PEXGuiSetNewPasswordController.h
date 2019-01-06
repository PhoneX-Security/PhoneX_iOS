//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiController.h"


@interface PEXGuiSetNewPasswordController : PEXGuiController

- (NSString *) getNewPassword;
- (NSString *) getRepeatedNewPassword;

- (void) setErrorText: (NSString * const) text;

@end