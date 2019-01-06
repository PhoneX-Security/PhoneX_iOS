//
//  PEXTimeUtils.m
//  Phonex
//
//  Created by Matej Oravec on 03/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXTimeUtils.h"

#include <mach/mach.h>
#include <mach/mach_time.h>
#include <unistd.h>

static const uint64_t TEN_POWER_NINE = 1000000000ULL;

uint64_t PEXGetPIDTimeInSeconds(void)
{
    return PEXGetPIDTimeInNanoseconds() / TEN_POWER_NINE;
}

// see https://developer.apple.com/library/mac/qa/qa1398/_index.html
// implemented because of absence clock_get_time/clock_gettime in Darwin
// uint64_t_max = 584,9424173325723 years
uint64_t PEXGetPIDTimeInNanoseconds(void)
{
    uint64_t        start;
    uint64_t        end;
    uint64_t        elapsed;
    uint64_t        elapsedNano;
    static mach_timebase_info_data_t    sTimebaseInfo;

    // Start the clock.

    start = mach_absolute_time();
/*
    // Call getpid. This will produce inaccurate results because
    // we're only making a single system call. For more accurate
    // results you should call getpid multiple times and average
    // the results.

    (void) getpid();

    // Stop the clock.

    end = mach_absolute_time();

    // Calculate the duration.

    elapsed = end - start;
 */

    // Convert to nanoseconds.

    // If this is the first time we've run, get the timebase.
    // We can use denom == 0 to indicate that sTimebaseInfo is
    // uninitialised because it makes no sense to have a zero
    // denominator is a fraction.

    if ( sTimebaseInfo.denom == 0 ) {
        (void) mach_timebase_info(&sTimebaseInfo);
    }

    // Do the maths. We hope that the multiplication doesn't
    // overflow; the price you pay for working in fixed point.

    elapsedNano = start/*elapsed*/ * (sTimebaseInfo.numer / sTimebaseInfo.denom);

    return elapsedNano;
}


@implementation PEXTimeUtils

+ (NSString *)timeIntervalFormatted:(NSTimeInterval)interval precision:(PEXTimeFormatPrecision)precision {
    NSMutableArray * timeArr = [[NSMutableArray alloc] initWithCapacity:6];
    NSInteger iter = (NSInteger) interval;
    BOOL negative = interval < 0;
    NSString * prefix = @"";
    if (negative){
        prefix = @"-";
        iter *= -1;
        interval *= -1.0;
    }

    // Precision rounding.
    if (precision == PEXTimeFormatPrecisionMinutes){
        interval = round(interval / 60.0) * 60.0;
    } else if (precision == PEXTimeFormatPrecisionSeconds){
        interval = round(interval);
    }

    const int millis = (int)(interval * 1000.0) % 1000;
    const int seconds = (iter % 60);
    const int minutes = (iter / 60) % 60;
    const int hours = (iter / 60 / 64) % 24;
    const int days = (iter / 60 / 60 / 24);
    if (days > 0){
        [timeArr addObject:[NSString stringWithFormat:@"%d %@", days, PEXStrP(@"txt_time_days", days)]];
    }
    if (hours > 0){
        [timeArr addObject:[NSString stringWithFormat:@"%d %@", hours, PEXStrP(@"txt_time_hours", hours)]];
    }
    if (minutes > 0){
        [timeArr addObject:[NSString stringWithFormat:@"%d %@", minutes, PEXStrP(@"txt_time_minutes", minutes)]];
    }
    if (precision == PEXTimeFormatPrecisionSeconds && seconds > 0){
        [timeArr addObject:[NSString stringWithFormat:@"%d %@", seconds, PEXStrP(@"txt_time_seconds", seconds)]];
    }
    if (precision == PEXTimeFormatPrecisionMilliseconds && millis > 0){
        [timeArr addObject:[NSString stringWithFormat:@"%d %@", millis, PEXStrP(@"txt_time_milliseconds", millis)]];
    }

    return [NSString stringWithFormat:@"%@%@", prefix, [timeArr componentsJoinedByString:@", "]];
}


@end
