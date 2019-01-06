//
// Created by Dusan Klinec on 24.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXRegex : NSObject
+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string error: (NSError **) pError;

+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string isCaseSensitive: (BOOL) isCaseSensitive
                                               error: (NSError **) pError;
+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string
                                     isCaseSensitive: (BOOL) isCaseSensitive isWholeWords: (BOOL) isWholeWords
                                               error: (NSError **) pError;
+ (NSString *) getStringAtRange: (NSString *) input range: (NSRange) range;
@end