//
//  PEXResStrings.h
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

// loading localized String
#define PEXStr(str) (NSLocalizedStringFromTable(str, @"InfoPlist", nil))
#define PEXStrU(str) [NSLocalizedStringFromTable(str, @"InfoPlist", nil) uppercaseStringWithLocale:[NSLocale currentLocale]]


#define PEXUnStr(str) [PEXResStrings localizedString:(str)]

@interface PEXResStrings : NSObject

+ (NSString *) localizedString:(const NSString * const) key;

@end
