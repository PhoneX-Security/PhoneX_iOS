//
// Created by Matej Oravec on 04/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXLogsUtils : NSObject

+ (void) removeAllTooOldLogsAsyncAll;
+ (void) removeAllTooOldLogsAsyncOlderThanDay;
+ (void) removeAllTooOldLogsAsyncOlderThan: (const int64_t) seconds;

@end