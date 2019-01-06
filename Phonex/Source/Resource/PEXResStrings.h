//
//  PEXResStrings.h
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXStringUtils.h"

typedef enum PEXPlural : NSInteger {
    PEX_PLURAL_ZERO,
    PEX_PLURAL_ONE,
    PEX_PLURAL_TWO,
    PEX_PLURAL_FEW,
    PEX_PLURAL_MANY,
    PEX_PLURAL_OTHER
}PEXPlural;

// loading localized String
#define PEXStr(str) [PEXResStrings string:(str)]
#define PEXStrP(str,q) [PEXResStrings pluralTolerantKey:(str) quantity:(q)]
#define PEXStrU(str) [PEXStringUtils capitaliseFirstLetter: [PEXResStrings string:(str)]]

#define _PEXStr PEXResStrings

#define PEX_LANGUAGE_SYSTEM @"auto"

@interface PEXResStrings : NSObject

+ (NSString *) getCurrentAppLanguage;
+ (NSString *) string:(NSString * const) key;
+ (const NSArray *) getLanguages;
+ (NSString *) getLanguageDescription: (NSString * const) languageString;

+ (NSString *) pluralTolerantKey:(NSString * const) key quantity: (double) quantity;
+ (NSString *) pluralKey:(NSString * const) key quantity: (double) quantity;
+ (NSString *) pluralKey:(NSString * const) key quantity: (double) quantity language: (NSString *) language;

+ (NSString *) getPluralStringKey:(NSString * const) key quantity: (double) quantity language: (NSString *) language;
+ (NSString *) getPluralStringKey:(NSString * const) key form: (PEXPlural) form language: (NSString *) language;
+ (PEXPlural) getPluralForm: (double) quantity language: (NSString *) language;
@end
