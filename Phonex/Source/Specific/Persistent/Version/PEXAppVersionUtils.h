//
// Created by Matej Oravec on 25/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXAppVersionUtils : NSObject

+ (NSString *)fullVersionStringToShow;
+ (NSString *)fullVersionString;

+ (uint64_t)fullVersionStringToCode: (NSString *)fullVersionString;
+ (NSString *)codeToFullVersionString: (const uint64_t) versionCode;

+ (NSString *) bundleIdentifier;
+ (NSString *) buildString;
+ (NSString *) versionString;
@end