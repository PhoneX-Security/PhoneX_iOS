//
//  PEXStringUtils.h
//  Phonex
//
//  Created by Matej Oravec on 06/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXStringUtils : NSObject

+ (bool) isEmpty: (NSString * const) textString;
+ (NSString *) trimWhiteSpaces: (NSString * const) text;
+ (bool) string: (NSString * const) str hasLengthAtLeast: (const NSUInteger) length;
+ (bool) containsAtLeastOneDigit: (NSString * const) str;
+ (bool) contains: (NSString *) haystack needle: (NSString *) needle;
+ (bool) containsIc: (NSString *) haystack needle: (NSString *) needle;
+ (bool) startsWith: (NSString *) string prefix: (NSString *) prefix;

+ (NSString *) capitaliseFirstLetter: (NSString * const) text;
@end
