//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXCaptchaValidator : NSObject
+ (NSString *) getMatchingRegex;
+ (NSString *) removeInvalidCharacters: (NSString *) code;
+ (NSString *) sanitize: (NSString *) code;
+ (BOOL) isValid: (NSString *) code;
@end