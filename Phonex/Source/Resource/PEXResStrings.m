//
//  PEXResStrings.m
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXResStrings.h"

#import "PEXRefDictionary.h"
#import "PEXUtils.h"

static const NSMutableDictionary * s_strings;
static const PEXRefDictionary * s_languages;
static NSString * s_currentAppLanguage;

@implementation PEXResStrings

+ (NSString *) getCurrentAppLanguage
{
    return s_currentAppLanguage;
}

+ (void) initStrings
{
    // for each language there must be
    // localized string (language descriptor)
    // localized string file
    NSString * const languageDescriptionSufix = @"_language_description";
    const NSArray * languages = @[PEX_LANGUAGE_SYSTEM, @"en", @"de", @"sk", @"cs", @"pl", @"ru-RU"];
    s_languages = [[PEXRefDictionary alloc] init];
    for (NSString * const language in languages)
    {
        [s_languages setObject:[NSString stringWithFormat:@"%@%@", language,
                                    languageDescriptionSufix]
                        forKey:language];
    }

    // set language
    s_currentAppLanguage = [[PEXAppPreferences instance]
            getStringPrefForKey:PEX_PREF_APPLICATION_LANGUAGE_KEY defaultValue:PEX_LANGUAGE_SYSTEM];

    s_strings = [NSMutableDictionary dictionaryWithContentsOfFile:
        ([s_currentAppLanguage isEqualToString:PEX_LANGUAGE_SYSTEM] ?
                 [self loadBySystem] :
                 [self loadByChoise])];

    // load unlocalized strings
    [s_strings addEntriesFromDictionary:
     [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                 pathForResource:@"Unlocalized"
                                                 ofType:@"strings"]]];
}

+ (NSString *) loadByChoise
{
    return [[[NSBundle mainBundle] pathForResource:s_currentAppLanguage
                                            ofType:@"lproj"]
             stringByAppendingPathComponent:@"InfoPlist.strings"];
}

+ (NSString *) loadBySystem

{
    return [[NSBundle mainBundle] pathForResource:@"InfoPlist"
                                           ofType:@"strings"];
}

+ (NSString *) string:(NSString * const) key
{
    NSString * const result = [s_strings objectForKey:key];
    return (result ? result : key);
}

+ (NSString *) pluralTolerantKey:(NSString * const) key quantity: (double) quantity
{
    NSString * lang = [PEXUtils getPreferredLanguages][0];
    PEXPlural form = [self getPluralForm:quantity language:lang];
    NSString * pluralKey = [self getPluralStringKey:key form:form language:lang];
    NSString * result = [s_strings objectForKey:pluralKey];

    if (result == nil){
        DDLogWarn(@"String plural form not found for key: %@", pluralKey);
        NSString * pluralKey2 = [self getPluralStringKey:key form:PEX_PLURAL_OTHER language:lang];
        result = [s_strings objectForKey:pluralKey2];
        return result == nil ? pluralKey : result;
    }

    return result;
}

+ (NSString *) pluralKey:(NSString * const) key quantity: (double) quantity
{
    return [self pluralKey:key quantity:quantity language:[PEXUtils getPreferredLanguages][0]];
}

+ (NSString *) pluralKey:(NSString * const) key quantity: (double) quantity language: (NSString *) language
{
    return [self string:[self getPluralStringKey:key quantity:quantity language:language]];
}

+ (NSString *) getPluralStringKey:(NSString * const) key quantity: (double) quantity language: (NSString *) language {
    PEXPlural pluralForm = [self getPluralForm:quantity language:language];
    return [self getPluralStringKey:key form:pluralForm language:language];
}

+ (NSString *) getPluralStringKey:(NSString * const) key form: (PEXPlural) form language: (NSString *) language{
    NSString * pluralSuffix = nil;

    switch (form){
        case PEX_PLURAL_ZERO:
            pluralSuffix = @"_plurals_zero";
            break;

        case PEX_PLURAL_ONE:
            pluralSuffix = @"_plurals_one";
            break;

        case PEX_PLURAL_TWO:
            pluralSuffix = @"_plurals_two";
            break;

        case PEX_PLURAL_FEW:
            pluralSuffix = @"_plurals_few";
            break;

        case PEX_PLURAL_MANY:
            pluralSuffix = @"_plurals_many";
            break;

        case PEX_PLURAL_OTHER:
            pluralSuffix = @"_plurals_other";
            break;
    }

    return [NSString stringWithFormat:@"%@%@", key, pluralSuffix];
}

+ (PEXPlural) getPluralForm: (double) quantity language: (NSString *) language {
    const double decimalPart = quantity - floor(quantity);
    const BOOL isInteger = decimalPart == 0;

    // http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
    if ([@"en" isEqualToString:language]){
        return quantity == 1 && isInteger ? PEX_PLURAL_ONE : PEX_PLURAL_OTHER;

    } else if ([@"de" isEqualToString:language]){
        return quantity == 1 && isInteger ? PEX_PLURAL_ONE : PEX_PLURAL_OTHER;

    } else if ([@"sk" isEqualToString:language]){
        if (quantity == 1 && isInteger){
            return PEX_PLURAL_ONE;

        } else if (quantity >= 2 && quantity <=4 && isInteger){
            return PEX_PLURAL_FEW;

        } else if (!isInteger){
            return PEX_PLURAL_MANY;

        } else {
            return PEX_PLURAL_OTHER;

        }

    } else if ([@"cs" isEqualToString:language]){
        if (quantity == 1 && isInteger){
            return PEX_PLURAL_ONE;

        } else if (quantity >= 2 && quantity <=4 && isInteger){
            return PEX_PLURAL_FEW;

        } else if (!isInteger){
            return PEX_PLURAL_MANY;

        } else {
            return PEX_PLURAL_OTHER;

        }

    } else if ([@"pl" isEqualToString:language]){
        const int mod10 = (int)quantity % 10;
        const int mod100 = (int)quantity % 100;

        if (quantity == 1 && isInteger){
            return PEX_PLURAL_ONE;

        } else if (isInteger
                && mod10 >= 2 && mod10 <= 4
                && !(mod100 >= 12 && mod100 <= 14)){
            return PEX_PLURAL_FEW;

        } else if (isInteger
                && (  (mod10 >= 0 && mod10 <= 1)
                   || ((mod10 >= 5 && mod10 <=9) && (mod100 >= 12 && mod100 <=14 )))){
            return PEX_PLURAL_MANY;

        } else {
            return PEX_PLURAL_OTHER;

        }

    } else if ([@"ru-RU" isEqualToString:language]){
        const int mod10 = (int)quantity % 10;
        const int mod100 = (int)quantity % 100;

        if (isInteger && mod10 == 1 && mod100 != 11){
            return PEX_PLURAL_ONE;

        } else if (isInteger
                && mod10 >= 2 && mod10 <= 4
                && !(mod100 >= 12 && mod100 <= 14)){
            return PEX_PLURAL_FEW;

        } else if (isInteger
                && (  (mod10 == 0)
                || ((mod10 >= 5 && mod10 <=9) && (mod100 >= 12 && mod100 <=14 )))){
            return PEX_PLURAL_MANY;

        } else {
            return PEX_PLURAL_OTHER;

        }
    }

    return PEX_PLURAL_OTHER;
}

+ (const NSArray *) getLanguages
{
    return [s_languages getKeys];
}


+ (NSString *) getLanguageDescription: (NSString * const) languageString
{
    return PEXStr([s_languages objectForKey:languageString]);
}

@end
