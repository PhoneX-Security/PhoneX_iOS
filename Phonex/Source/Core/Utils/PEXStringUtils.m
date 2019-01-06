//
//  PEXStringUtils.m
//  Phonex
//
//  Created by Matej Oravec on 06/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXStringUtils.h"

@implementation PEXStringUtils

+ (bool) isEmpty: (NSString * const) textString
{
    if (textString == nil || [textString isKindOfClass:[NSNull class]]) return YES;
    return ([[self trimWhiteSpaces:textString] isEqualToString:@""]);
}

+ (NSString *) trimWhiteSpaces: (NSString * const) text
{
    if (![text isKindOfClass:[NSString class]]){
        return nil;
    }

    return [text stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceCharacterSet]];
}

+ (bool) string: (NSString * const) str hasLengthAtLeast: (const NSUInteger) length
{
    const NSUInteger passLength = [self trimWhiteSpaces:str].length;
    return (passLength >= length);
}

+ (bool) containsAtLeastOneDigit: (NSString * const) str
{
    return ([str rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]].location
            != NSNotFound);
}

+ (bool)contains:(NSString *)haystack needle:(NSString *)needle {
    if (haystack == nil){
        return NO;
    }

    return [haystack rangeOfString:needle].location != NSNotFound;
}

+ (bool)containsIc:(NSString *)haystack needle:(NSString *)needle {
    if (haystack == nil){
        return NO;
    }

    NSString * haystackLow = [haystack lowercaseString];
    NSString * needleLow = [needle lowercaseString];
    return [self contains:haystackLow needle:needleLow];
}

+ (bool) startsWith: (NSString *) string prefix: (NSString *) prefix {
    if (string == nil){
        return NO;
    }

    return [string rangeOfString:prefix].location == 0;
}

+ (NSString *) capitaliseFirstLetter: (NSString * const) text
{
    return (text && text.length) ?
    [NSString stringWithFormat:@"%@%@",[[text substringToIndex:1] uppercaseString],[text substringFromIndex:1] ] :
            text;
}
@end
