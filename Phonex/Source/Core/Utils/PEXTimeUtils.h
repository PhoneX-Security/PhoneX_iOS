//
//  PEXTimeUtils.h
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

uint64_t PEXGetPIDTimeInNanoseconds(void);
uint64_t PEXGetPIDTimeInSeconds(void);

typedef enum PEXTimeFormatPrecision{
    PEXTimeFormatPrecisionMilliseconds = 0,
    PEXTimeFormatPrecisionSeconds = 1,
    PEXTimeFormatPrecisionMinutes = 2
} PEXTimeFormatPrecision;

@interface PEXTimeUtils : NSObject
+(NSString *) timeIntervalFormatted: (NSTimeInterval) interval precision: (PEXTimeFormatPrecision) precision;
@end
