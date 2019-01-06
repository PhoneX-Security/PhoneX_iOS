//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const uint64_t PEX_MINUTE_IN_SECONDS;

extern const uint64_t PEX_HOUR_IN_MINUTES;
extern const uint64_t PEX_HOUR_IN_SECONDS;

extern const uint64_t PEX_DAY_IN_HOURS;
extern const uint64_t PEX_DAY_IN_MINUTES;
extern const uint64_t PEX_DAY_IN_SECONDS;

extern const uint64_t PEX_WEEK_IN_DAYS;
extern const uint64_t PEX_WEEK_IN_HOURS;
extern const uint64_t PEX_WEEK_IN_MINUTES;
extern const uint64_t PEX_WEEK_IN_SECONDS;

// approx. average month has 29.5 days
extern const uint64_t PEX_MONTH_IN_DAYS;
extern const uint64_t PEX_MONTH_IN_HOURS;
extern const uint64_t PEX_MONTH_IN_MINUTES;
extern const uint64_t PEX_MONTH_IN_SECONDS;

extern const uint64_t PEX_YEAR_IN_MONTHS;
extern const uint64_t PEX_YEAR_IN_DAYS;
extern const uint64_t PEX_YEAR_IN_HOURS;
extern const uint64_t PEX_YEAR_IN_MINUTES;
extern const uint64_t PEX_YEAR_IN_SECONDS;

@interface PEXGuiTimeUtils : NSObject

+ (NSString *)getTimeDescriptionFromSeconds: (const uint64_t)seconds;

@end