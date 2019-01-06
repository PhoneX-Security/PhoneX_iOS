//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXCaptchaValidator.h"
#import "PEXRegex.h"


@implementation PEXCaptchaValidator {

}

+ (NSString *)getMatchingRegex {
    return @"[A-Za-z0-9\\-_]+";
}

+ (NSString *)removeInvalidCharacters:(NSString *)code {
    NSMutableString *s = [code mutableCopy];
    NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:@"[^A-Za-z0-9_\\-]" options:0 error:NULL];
    [expr replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""];
    return s;
}

+ (NSString *)sanitize:(NSString *)code {
    NSString * s = [self removeInvalidCharacters:code];
    return [s substringToIndex:MIN(16, s.length)];
}

+ (BOOL)isValid:(NSString *)code {
    bool result = false;

    if (code && (code.length > 0))
    {
        NSRegularExpression *const regex =
                [PEXRegex regularExpressionWithString:[self getMatchingRegex] isCaseSensitive:NO error:nil];
        const NSRange matchRange =
                [regex rangeOfFirstMatchInString:code options:NSMatchingReportProgress range:NSMakeRange(0, code.length)];

        result = (matchRange.location != NSNotFound);
    }

    return result;
}


@end