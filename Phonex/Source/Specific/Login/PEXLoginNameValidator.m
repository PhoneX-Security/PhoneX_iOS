//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXLoginNameValidator.h"
#import "AJWValidator+Private.h"
#import "AJWValidatorRegularExpressionRule.h"
#import "PEXRegex.h"

#define LOGIN_REGEX_DOMAIN @"(^[_A-Za-z0-9\\.\\-]+($|(@[A-Za-z0-9\\-_]+(\\.[A-Za-z0-9\\-_]+)*(\\.[A-Za-z‌​_0-9]{2,})$)))"
#define LOGIN_REGEX_NODOMAIN @"(^[_A-Za-z0-9\\.\\-]+$)"
#define LOGIN_REGEX_PART_EXCL @"[^_A-Za-z0-9\\.\\-]"
#define LOGIN_REGEX_PART_WITH_DOMAIN_EXCL @"[^_A-Za-z0-9\\.\\-@]"

@implementation PEXLoginNameValidator {

}

+ (NSString *) getMatchingRegexWithDomain: (BOOL) withDomain {
    return withDomain ? LOGIN_REGEX_DOMAIN : LOGIN_REGEX_NODOMAIN;
}

+ (NSString *) removeInvalidCharactersFromLogin: (NSString *) login allowDomain: (BOOL) allowDomain {
    NSString *text = login;
    NSMutableString *s = [text mutableCopy];
    NSString * regex = allowDomain ? LOGIN_REGEX_PART_WITH_DOMAIN_EXCL : LOGIN_REGEX_PART_EXCL;
    NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern: regex options:0 error:NULL];
    [expr replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""];
    return s;
}

+ (NSString *)sanitize:(NSString *)login allowDomain:(BOOL)allowDomain {
    NSString * s = [self removeInvalidCharactersFromLogin:login allowDomain:allowDomain];
    return [s substringToIndex:MIN(64, s.length)];
}

+ (BOOL) isUsernameValid: (NSString *) username allowDomain: (BOOL) allowDomain {
    bool result = false;

    if (username && (username.length > 0))
    {
        NSRegularExpression *const regex =
                [PEXRegex regularExpressionWithString:[self getMatchingRegexWithDomain:allowDomain] isCaseSensitive:NO error:nil];
        const NSRange matchRange =
                [regex rangeOfFirstMatchInString:username options:NSMatchingReportProgress range:NSMakeRange(0, username.length)];

        result = (matchRange.location != NSNotFound);
    }

    return result;
}

+ (AJWValidator *) initValidatorWithDomain: (BOOL) withDomain {
    AJWValidatorRegularExpressionRule *ruleLogin =
            [[AJWValidatorRegularExpressionRule alloc] initWithType:AJWValidatorRuleTypeEmail
                                                     invalidMessage:PEXStr(@"txt_login_name_not_valid")
                                                            pattern:[self getMatchingRegexWithDomain:withDomain]];

    AJWValidator * validator = [AJWValidator validatorWithType:AJWValidatorTypeString];
    [validator addValidationRule:ruleLogin];

    return validator;
}



@end