//
// Created by Dusan Klinec on 12.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiLoginController;


@interface PEXGuiForgottenPasswordController : PEXGuiController
@property (nonatomic) NSString * preFilledRecoveryCode;
@property (nonatomic, weak) PEXGuiLoginController * loginController;

-(void) fillInCode: (NSString *) code;
@end