//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXProductCodeValidator.h"
#import "AJWValidator+Private.h"
#import "AJWValidatorRegularExpressionRule.h"
#import "PEXRegex.h"

#define CODE_REGEX @"(^[A-Za-z0-9]{3}\\-[A-Za-z0-9]{3}\\-[A-Za-z0-9]{3}$)|(^[A-Za-z0-9]{3}[A-Za-z0-9]{3}[A-Za-z0-9]{3}$)"
#define CODE_REGEX_PART_EXCL @"[^A-Za-z0-9]"
#define CODE_PART_LEN 3
#define CODE_SEGMENT_COUNT 3

@implementation PEXProductCodeValidator {

}
+ (NSString *)getMatchingRegex {
    return CODE_REGEX;
}

+ (NSString *)removeInvalidCharacters:(NSString *)code {
    NSMutableString *s = [code mutableCopy];
    NSRegularExpression *expr = [NSRegularExpression regularExpressionWithPattern:CODE_REGEX_PART_EXCL options:0 error:NULL];
    [expr replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""];
    return s;
}

+ (NSString *)sanitize:(NSString *)code {
    NSString * s = [self removeInvalidCharacters:code];
    return [[s substringToIndex:MIN(CODE_PART_LEN * CODE_SEGMENT_COUNT, s.length)] lowercaseString];
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

+ (NSString *)formatCode:(NSString *)code {
    // Drop all illegal characters
    NSString *text = [self sanitize:code];

    // Add dashes
    NSMutableArray *parts = [NSMutableArray array];
    int counter = 0;
    while (text.length > 0) {
        [parts addObject:[text substringToIndex:MIN(CODE_PART_LEN, text.length)]];
        if (text.length > CODE_PART_LEN) {
            text = [text substringFromIndex:CODE_PART_LEN];
        } else {
            text = @"";
        }
        counter ++;
    }

    if ([parts count] > 0) {
        text = parts[0];
        [parts removeObjectAtIndex:0];
        for (NSString *part in parts) {
            text = [text stringByAppendingString:@"-"];
            text = [text stringByAppendingString:part];
        }
    }

    return text;
}

+ (AJWValidator *)initValidator {
    AJWValidatorRegularExpressionRule *rule =
            [[AJWValidatorRegularExpressionRule alloc] initWithType:AJWValidatorRuleTypeCustom
                                                     invalidMessage:PEXStr(@"txt_product_code_not_valid")
                                                            pattern:[self getMatchingRegex]];

    AJWValidator * validator = [AJWValidator validatorWithType:AJWValidatorTypeString];
    [validator addValidationRule:rule];

    return validator;
}

+ (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    string = [self sanitize:string];
    if (range.location == 11
            || (textField.text.length >= 11 && range.length == 0)
            || string.length + textField.text.length - range.length > 11 )
    {
        return NO;
    }

    UITextRange* selRange = textField.selectedTextRange;
    UITextPosition *currentPosition = selRange.start;
    NSInteger pos = [textField offsetFromPosition:textField.beginningOfDocument toPosition:currentPosition];
    if (range.length != 0) { //deleting
        if (range.location == 3 || range.location == 7) { //deleting a dash
            if (range.length == 1) {
                range.location--;
                pos-=2;
            }
            else {
                pos++;
            }
        }
        else {
            if (range.length > 1) {
                NSString* selectedRange = [textField.text substringWithRange:range];
                NSString* hyphenless = [selectedRange stringByReplacingOccurrencesOfString:@"-" withString:@""];
                NSInteger diff = selectedRange.length - hyphenless.length;
                pos += diff;
            }
            pos --;
        }
    }

    NSMutableString* changedString = [NSMutableString stringWithString:[[textField.text stringByReplacingCharactersInRange:range withString:string] stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    if (changedString.length >= 3) {
        [changedString insertString:@"-" atIndex:3];
        if (pos == 2 && range.length == 0) {
            pos++;
        }
    }
    if (changedString.length >= 7) {
        [changedString insertString:@"-" atIndex:7];
        if (pos == 6 && range.length == 0) {
            pos++;
        }
    }
    pos += string.length;

    textField.text = changedString;
    if (pos > changedString.length) {
        pos = changedString.length;
    }
    currentPosition = [textField positionFromPosition:textField.beginningOfDocument offset:pos];

    [textField setSelectedTextRange:[textField textRangeFromPosition:currentPosition toPosition:currentPosition]];
    return NO;
}

@end