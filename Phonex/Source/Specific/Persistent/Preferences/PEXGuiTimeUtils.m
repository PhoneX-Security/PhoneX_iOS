//
// Created by Matej Oravec on 30/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiTimeUtils.h"

const uint64_t PEX_MINUTE_IN_SECONDS = 60LL;

const uint64_t PEX_HOUR_IN_MINUTES = 60LL;
const uint64_t PEX_HOUR_IN_SECONDS = PEX_MINUTE_IN_SECONDS * PEX_HOUR_IN_MINUTES;

const uint64_t PEX_DAY_IN_HOURS =    24LL;
const uint64_t PEX_DAY_IN_MINUTES =  PEX_DAY_IN_HOURS * PEX_HOUR_IN_MINUTES;
const uint64_t PEX_DAY_IN_SECONDS =  PEX_DAY_IN_MINUTES * PEX_MINUTE_IN_SECONDS;

const uint64_t PEX_WEEK_IN_DAYS =    7LL;
const uint64_t PEX_WEEK_IN_HOURS =   PEX_WEEK_IN_DAYS * PEX_DAY_IN_HOURS;
const uint64_t PEX_WEEK_IN_MINUTES = PEX_WEEK_IN_HOURS * PEX_HOUR_IN_MINUTES;
const uint64_t PEX_WEEK_IN_SECONDS = PEX_WEEK_IN_MINUTES * PEX_MINUTE_IN_SECONDS;

// approx. average month has 29.5 days ... better sooner than later :)
// NOT VERY PRECISE
const uint64_t PEX_MONTH_IN_DAYS =    29LL;
const uint64_t PEX_MONTH_IN_HOURS =   PEX_MONTH_IN_DAYS * PEX_DAY_IN_HOURS;
const uint64_t PEX_MONTH_IN_MINUTES = PEX_MONTH_IN_HOURS * PEX_HOUR_IN_MINUTES;
const uint64_t PEX_MONTH_IN_SECONDS = PEX_MONTH_IN_MINUTES * PEX_MINUTE_IN_SECONDS;

const uint64_t PEX_YEAR_IN_MONTHS = 12LL;
const uint64_t PEX_YEAR_IN_DAYS = 365LL;
const uint64_t PEX_YEAR_IN_HOURS = PEX_YEAR_IN_DAYS * PEX_DAY_IN_HOURS;
const uint64_t PEX_YEAR_IN_MINUTES = PEX_YEAR_IN_HOURS * PEX_HOUR_IN_MINUTES;
const uint64_t PEX_YEAR_IN_SECONDS = PEX_YEAR_IN_MINUTES * PEX_MINUTE_IN_SECONDS;

const uint64_t PEX_COUNT_FOR_MORE_THAN_FOUR = 5;

@implementation PEXGuiTimeUtils {

}

+ (NSString *)getTimeDescriptionFromSeconds: (const uint64_t)seconds
{
    NSString * units;

    int64_t value = seconds;
    if (value < PEX_MINUTE_IN_SECONDS) {
        units = (value == 1) ? PEXStr(@"L_second") :
                (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_seconds") : PEXStr(@"L_seconds_more_than_four");
    }
    else {
        value /= PEX_MINUTE_IN_SECONDS;
        if (value < PEX_HOUR_IN_MINUTES) {
            units = (value == 1) ? PEXStr(@"L_minute") :
                    (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_minutes") : PEXStr(@"L_minutes_more_than_four");
        }
        else {
            value /= PEX_HOUR_IN_MINUTES;
            if (value < PEX_DAY_IN_HOURS) {
                units = (value == 1) ? PEXStr(@"L_hour") :
                        (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_hours") : PEXStr(@"L_hours_more_than_four");
            }
            else {
                value /= PEX_DAY_IN_HOURS;
                if (value < PEX_MONTH_IN_DAYS) {
                    units = (value == 1) ? PEXStr(@"L_day") :
                            (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_days") : PEXStr(@"L_days_more_than_four");
                }
                else {
                    value /= PEX_MONTH_IN_DAYS;
                    if (value < PEX_YEAR_IN_MONTHS) {
                        units = (value == 1) ? PEXStr(@"L_month") :
                                (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_months") : PEXStr(@"L_months_more_than_four");
                    }
                    else {
                        value /= PEX_YEAR_IN_MONTHS;
                        units = (value == 1) ? PEXStr(@"L_year") :
                                (value < PEX_COUNT_FOR_MORE_THAN_FOUR) ? PEXStr(@"L_years") : PEXStr(@"L_years_more_than_four");
                    }
                }
            }
        }
    }

    return [NSString stringWithFormat:@"%llu %@", value, units];
}

@end