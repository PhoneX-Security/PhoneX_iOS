//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#include <time.h>
#import "PEXGuiTimeUtils.h"

@interface PEXDateUtils ()

@property (nonatomic) NSDateFormatter * fullDateTimeFormatter;
@property (nonatomic) NSDateFormatter * dateFormatter;
@property (nonatomic) NSDateFormatter * dateOnlyFormatter;
@property (nonatomic) NSDateFormatter * timeFormatter;

@end

@implementation PEXDateUtils {

}

+ (void) initInstance
{
    [PEXDateUtils instance];
}

+ (PEXDateUtils *) instance
{
    static PEXDateUtils * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXDateUtils alloc] init];
    });

    return instance;
}


- (id)init
{
    self = [super init];

    self.fullDateTimeFormatter = [[NSDateFormatter alloc] init];
    [self.fullDateTimeFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy-MM-dd"];

    self.dateOnlyFormatter = [[NSDateFormatter alloc] init];
    [self.dateOnlyFormatter setDateFormat:@"MM-dd"];

    self.timeFormatter = [[NSDateFormatter alloc] init];
    [self.timeFormatter setDateFormat:@"HH:mm"];

    return self;
}

+ (NSString *)dateToFullDateString: (NSDate * const) date
{
    return [[self instance].fullDateTimeFormatter stringFromDate:date];
}

+ (NSString *)dateToDateString: (NSDate * const) date
{
    return [[self instance].dateFormatter stringFromDate:date];
}

+ (NSString *)dateToDateOnlyString: (NSDate * const) date
{
    return [[self instance].dateOnlyFormatter stringFromDate:date];
}

+ (NSString *)dateToTimeString: (NSDate * const) date
{
    return [[self instance].timeFormatter stringFromDate:date];
}

// returns true if equal to day
+ (BOOL)compareUneffectiveWithoutTimeComponent:(NSDate *const)first with: (NSDate * const) second
{
    ///

    NSDate * const firstWTC = [self dateWithoutTimeComponent:first];
    NSDate * const secondWTC = [self dateWithoutTimeComponent:second];

    NSComparisonResult comparison = [firstWTC compare:secondWTC];

    return comparison == NSOrderedSame;


    ///

    /*
    const NSCalendar * const calendar = [NSCalendar currentCalendar];

    NSDate * date1 = [first copy];
    NSDate * date2 = [second copy];

    [calendar rangeOfUnit:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit startDate:&date1 interval:NULL forDate:date1];
    [calendar rangeOfUnit:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit startDate:&date2 interval:NULL forDate:date2];

    NSUInteger day1 = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSEraCalendarUnit forDate:date1];
    NSUInteger day2 = [calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSEraCalendarUnit forDate:date2];

    return (day1 == day2);
    */
}

+ (NSDate *) dateWithoutTimeComponent: (NSDate * const) date
{
    const NSCalendar * const calendar = [NSCalendar currentCalendar];

    NSDateComponents * const dateComponents =
            [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];

    return [calendar dateFromComponents:dateComponents];
}

+ (BOOL) date: (const NSDate * const)first isOlderThan:(NSDate *) second
{
    return ([first compare:second] == NSOrderedAscending);
}

+ (BOOL) date: (const NSDate * const)first isOlderThanOrEqualTo:(NSDate *) second
{
    NSComparisonResult comparisonResult = [first compare:second];
    return ((comparisonResult == NSOrderedAscending) || (comparisonResult == NSOrderedSame));
}

+ (BOOL) date: (const NSDate * const)first isNewerThan:(NSDate *) second
{
    NSComparisonResult comparisonResult = [first compare:second];
    return (comparisonResult == NSOrderedDescending);
}

+ (BOOL) date: (const NSDate * const)first isNewerThanOrEqualTo:(NSDate *) second
{
    NSComparisonResult comparisonResult = [first compare:second];
    return ((comparisonResult == NSOrderedDescending) || (comparisonResult == NSOrderedSame));
}

+ (dispatch_time_t) getIntervalUntilDate: (NSDate * const)eventDate
{
    return [self getIntervalUntilDate:eventDate since:[NSDate date]];
}

+ (dispatch_time_t)getIntervalUntilDate:(NSDate *const)eventDate
                                  since: (NSDate * const) since
{
    // nstimeinterval is in seconds
    const double timeIntervalSinceNow = [eventDate timeIntervalSinceDate:since];
    const dispatch_time_t timeDelayInNanoSeconds = (timeIntervalSinceNow > 0.01) ?
            dispatch_time(DISPATCH_TIME_NOW, ((uint64_t)timeIntervalSinceNow) * NSEC_PER_SEC) :
            DISPATCH_TIME_NOW;

    return timeDelayInNanoSeconds;
}

+ (dispatch_time_t) getDispatchTimeFromTimeInterval: (NSTimeInterval) timeInterval {
    const dispatch_time_t timeDelayInNanoSeconds = (timeInterval > 0.001) ?
            dispatch_time(DISPATCH_TIME_NOW, ((uint64_t)timeInterval) * NSEC_PER_SEC) :
            DISPATCH_TIME_NOW;

    return timeDelayInNanoSeconds;
}

+ (NSDate *) addTo:(NSDate * const)eventDate days: (const double) days
{
    return [eventDate dateByAddingTimeInterval:(days * PEX_DAY_IN_SECONDS)];
}

////////
//
// http:blog.soff.es/how-to-drastically-improve-your-app-with-an-afternoon-and-instruments/
//
////////
+ (NSDate *)dateFromISO8601String:(NSString * const)string {
    if (!string) {
        return nil;
    }

    struct tm tm;
    time_t t;

    strptime([string cStringUsingEncoding:NSUTF8StringEncoding], "%Y-%m-%dT%H:%M:%S%z", &tm);
    tm.tm_isdst = -1;
    t = mktime(&tm);

    return [NSDate dateWithTimeIntervalSince1970:t + [[NSTimeZone localTimeZone] secondsFromGMT]];
}

+ (NSString *)ISO8601String: (NSDate * const) date
{
    return [self ISO8601String:date format:"%Y-%m-%dT%H:%M:%S%z"];
}

+ (NSString *)ISO8601StringDateOnly: (NSDate * const) date
{
    return [self ISO8601String:date format:"%Y-%m-%dT"];
}

+ (NSString *)ISO8601StringTimeOnly: (NSDate * const) date
{
    return [self ISO8601String:date format:"%H:%M:%S%z"];
}

+ (NSString *)ISO8601String: (NSDate * const) date format: (const char * const) format
{
    struct tm *timeinfo;
    char buffer[80];

    time_t rawtime = [date timeIntervalSince1970] - [[NSTimeZone localTimeZone] secondsFromGMT];
    timeinfo = localtime(&rawtime);

    strftime(buffer, 80, format, timeinfo);

    return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end