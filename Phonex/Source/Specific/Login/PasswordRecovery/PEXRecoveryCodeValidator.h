//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AJWValidator;


@interface PEXRecoveryCodeValidator : NSObject
+ (NSString *) getMatchingRegex;
+ (NSString *) removeInvalidCharacters: (NSString *) code;
+ (NSString *) sanitize: (NSString *) code;
+ (BOOL) isValid: (NSString *) code;
+ (NSString *) formatCode: (NSString *) code;
+ (AJWValidator *) initValidator;
+ (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
@end