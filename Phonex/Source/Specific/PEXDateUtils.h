//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO simple singleton stub

@interface PEXDateUtils : NSObject

+ (void) initInstance;
+ (PEXDateUtils *) instance;

+ (NSString *)dateToFullDateString: (NSDate * const) date;
+ (NSString *)dateToDateString: (NSDate * const) date;
+ (NSString *)dateToDateOnlyString: (NSDate * const) date;
+ (NSString *)dateToTimeString: (NSDate * const) date;

+ (BOOL)compareUneffectiveWithoutTimeComponent:(NSDate *const)first with: (NSDate * const) second;
+ (NSDate *) dateWithoutTimeComponent: (NSDate * const) date;

+ (BOOL) date: (const NSDate * const)first isOlderThan:(NSDate *) second;
+ (BOOL) date: (const NSDate * const)first isOlderThanOrEqualTo:(NSDate *) second;
+ (BOOL) date: (const NSDate * const)first isNewerThan:(NSDate *) second;
+ (BOOL) date: (const NSDate * const)first isNewerThanOrEqualTo:(NSDate *) second;

+ (dispatch_time_t) getIntervalUntilDate: (NSDate * const)eventDate;
+ (dispatch_time_t)getIntervalUntilDate:(NSDate *const)eventDate
                                  since: (NSDate * const) since;
+ (dispatch_time_t) getDispatchTimeFromTimeInterval: (NSTimeInterval) timeInterval;

+ (NSDate *) addTo:(NSDate * const)eventDate days: (const double) days;

@end