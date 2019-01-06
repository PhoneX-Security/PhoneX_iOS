//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AJWValidator;

@interface PEXLoginNameValidator : NSObject
+ (NSString *) getMatchingRegexWithDomain: (BOOL) withDomain;
+ (NSString *) removeInvalidCharactersFromLogin: (NSString *) login allowDomain: (BOOL) allowDomain;
+ (NSString *) sanitize: (NSString *) login allowDomain: (BOOL) allowDomain;
+ (BOOL) isUsernameValid: (NSString *) username allowDomain: (BOOL) allowDomain;
+ (AJWValidator *) initValidatorWithDomain: (BOOL) withDomain;
@end