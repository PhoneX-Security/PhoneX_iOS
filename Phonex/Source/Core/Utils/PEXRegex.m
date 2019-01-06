//
// Created by Dusan Klinec on 24.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXRegex.h"


@implementation PEXRegex {

}

+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string error: (NSError **) pError
{
    return [self regularExpressionWithString:string isCaseSensitive:YES isWholeWords:NO error:pError];
}

+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string isCaseSensitive: (BOOL) isCaseSensitive
                                               error: (NSError **) pError
{
    return [self regularExpressionWithString:string isCaseSensitive:isCaseSensitive isWholeWords:NO error:pError];
}

+ (NSRegularExpression *)regularExpressionWithString:(NSString *)string
                                     isCaseSensitive: (BOOL) isCaseSensitive isWholeWords: (BOOL) isWholeWords
                                               error: (NSError **) pError
{
    NSRegularExpressionOptions regexOptions = isCaseSensitive ? 0 : NSRegularExpressionCaseInsensitive;

    NSString *placeholder = isWholeWords ? @"\\b%@\\b" : @"%@";
    NSString *pattern = [NSString stringWithFormat:placeholder, string];

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:regexOptions error:pError];
    return regex;
}

+ (NSString *)getStringAtRange:(NSString *)input range:(NSRange)range {
    // Nothing to look for / not found range.
    if (input == nil || range.location == NSNotFound){
        return nil;
    }

    // Out of range, warning.
    if (input.length < (range.location+range.length)){
        DDLogError(@"Out of range!");
        return nil;
    }

    return [input substringWithRange:range];
}

@end