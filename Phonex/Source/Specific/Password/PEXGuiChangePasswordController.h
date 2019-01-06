//
//  PEXGuiChangePassword.h
//  Phonex
//
//  Created by Matej Oravec on 09/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiBusyInputController.h"

@interface PEXGuiChangePasswordController : PEXGuiBusyInputController

- (NSString *) oldPassword;
- (NSString *) newPassword;
- (NSString *) newPasswordRepeated;

@end
