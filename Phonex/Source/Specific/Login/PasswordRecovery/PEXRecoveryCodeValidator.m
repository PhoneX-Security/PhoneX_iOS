//
// Created by Dusan Klinec on 16.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXRecoveryCodeValidator.h"
#import "AJWValidator.h"
#import "PEXProductCodeValidator.h"

/**
 * Recovery code has the same form as a product code.
 */
@implementation PEXRecoveryCodeValidator {

}

+ (NSString *)getMatchingRegex {
    return [PEXProductCodeValidator getMatchingRegex];
}

+ (NSString *)removeInvalidCharacters:(NSString *)code {
    return [PEXProductCodeValidator removeInvalidCharacters:code];
}

+ (NSString *)sanitize:(NSString *)code {
    // Recovery code is case sensitive
    NSString * s = [self removeInvalidCharacters:code];
    return [s substringToIndex:MIN(9, s.length)];
}

+ (BOOL)isValid:(NSString *)code {
    return [PEXProductCodeValidator isValid:code];
}

+ (NSString *)formatCode:(NSString *)code {
    // Drop all illegal characters
    NSString *text = [self sanitize:code];

    // Add dashes
    NSMutableArray *parts = [NSMutableArray array];
    int counter = 0;
    while (text.length > 0) {
        [parts addObject:[text substringToIndex:MIN(3, text.length)]];
        if (text.length > 3) {
            text = [text substringFromIndex:3];
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
    return [PEXProductCodeValidator initValidator];
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