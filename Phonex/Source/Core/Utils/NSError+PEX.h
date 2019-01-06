//
// Created by Dusan Klinec on 11.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (PEX)

/**
* If subError is non-nil, it is added with PEXExtraError key to the userInfo dictionary.
* New dictionary is returned.
*/
+(NSDictionary *) chainSubError: (NSDictionary *) userInfo sub: (NSError *) subError;

/**
* Constructs new error with defined subError. Chains only if suberror is non-nil.
*/
+ (NSError *) errorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict subError:(NSError *)subError;

/**
* Chains subError under error.
* Warning, since NSError is not mutable, this just extracts some information about error, may lose something.
* Original error is placed under separate key.
*/
+ (NSError *) errorWithError: (NSError *) error subError: (NSError *) subError;

/**
* Adds specified userdata to the error's user data.
*/
+ (NSError *) addUserDataToError: (NSError *) err userData: (NSDictionary *) toAdd;

@end