//
// Created by Matej Oravec on 04/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLogsUtils.h"
#import "PEXLogsZipper.h"
#import "PEXGuiTimeUtils.h"


@implementation PEXLogsUtils {

}

+ (void) removeAllTooOldLogsAsyncAll
{
    [self removeAllTooOldLogsAsyncOlderThan: 0LL];
}

+ (void) removeAllTooOldLogsAsyncOlderThanDay
{
    [self removeAllTooOldLogsAsyncOlderThan:PEX_DAY_IN_SECONDS];
}

+ (void) removeAllTooOldLogsAsyncOlderThan: (const int64_t) seconds
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("logs_deleter_queue", nil);
    });

    // Code to delete images older than two days.

    dispatch_async(queue, ^{
        NSString * const pathToZippedLogsFolder = [PEXLogsZipper getDestinationFolder];
        NSFileManager * const fileManager = [[NSFileManager alloc] init];
        NSDirectoryEnumerator * const en = [fileManager enumeratorAtPath:pathToZippedLogsFolder];

        NSString * file;
        while (file = [en nextObject])
        {
            DDLogVerbose(@"File To Delete : %@",file);
            NSError *error = nil;
            NSString * const filepath = [pathToZippedLogsFolder stringByAppendingPathComponent: file];

            if (seconds == 0LL)
            {
                [[NSFileManager defaultManager]
                        removeItemAtPath:[pathToZippedLogsFolder stringByAppendingPathComponent:file] error:&error];
            }
            else
            {
                NSDate * const creationDate =[[fileManager attributesOfItemAtPath:filepath error:nil] fileCreationDate];
                NSDate * const date =[[NSDate date] dateByAddingTimeInterval: -seconds];

                if ([PEXDateUtils date:creationDate isOlderThan:date])
                {
                    [[NSFileManager defaultManager]
                            removeItemAtPath:[pathToZippedLogsFolder stringByAppendingPathComponent:file] error:&error];
                }
            }
        }
    });
}

@end