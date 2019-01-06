//
// Created by Dusan Klinec on 30.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "PEXDDLogFormatter.h"

#define PEX_DDLOG_QUEUE_SIZE 20
#define PEX_DDLOG_QUEUE_FMT "%.*s%s"

#define PEX_DDLOG_FILE_NAME_SIZE 24
#define PEX_DDLOG_FILE_NAME_FMT "%.*s%s"

#define PEX_DDLOG_FILE_NAME_SIZE_P1 ((PEX_DDLOG_FILE_NAME_SIZE-3)/2)
#define PEX_DDLOG_FILE_NAME_SIZE_P2 ( PEX_DDLOG_FILE_NAME_SIZE-3-PEX_DDLOG_FILE_NAME_SIZE_P1)
#define PEX_DDLOG_FILE_NAME_EL_FMT "%.*s...%s"

#define PEX_DDLOG_FNAME_SIZE 50
#define PEX_DDLOG_FNAME_FMT "%.*s%s"

#define PEX_DDLOG_FNAME_SIZE_P1 ((PEX_DDLOG_FNAME_SIZE-3)/2)
#define PEX_DDLOG_FNAME_SIZE_P2 ( PEX_DDLOG_FNAME_SIZE-3-PEX_DDLOG_FNAME_SIZE_P1)
#define PEX_DDLOG_FNAME_EL_FMT "%.*s...%s"

#define PEX_DDLOG_THREAD_SIZE 4

// Used to padd strings when needed
#define PEX_DDLOG_PADDING_STRING "                                                                                                      "

static PEXDDLogFormatter *sharedInstance;

@interface PEXDDLogFormatter () {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end

// Documentation: https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/CustomFormatters.md
@implementation PEXDDLogFormatter {

}

+ (instancetype)sharedInstance {
    static dispatch_once_t PEXDDLogFormatterOnceToken;

    dispatch_once(&PEXDDLogFormatterOnceToken, ^{
        sharedInstance = [[PEXDDLogFormatter alloc] init];
    });

    return sharedInstance;
}

- (NSString *)stringFromDate:(NSDate *)date
{
    static NSString * dateFormatString = @"yyyy/MM/dd HH:mm:ss:SSS";
    int32_t loggerCount = OSAtomicAdd32(0, &atomicLoggerCount);

    if (loggerCount <= 1) {
        // Single-threaded mode.
        if (threadUnsafeDateFormatter == nil) {
            threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
            [threadUnsafeDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [threadUnsafeDateFormatter setDateFormat:dateFormatString];
        }

        return [threadUnsafeDateFormatter stringFromDate:date];

    } else {
        // Multi-threaded mode.
        // NSDateFormatter is NOT thread-safe.
        NSString *key = @"MyCustomFormatter_NSDateFormatter";
        NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
        NSDateFormatter *dateFormatter = threadDictionary[key];

        // If there is no date formatter, create a new one.
        if (dateFormatter == nil) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
            [dateFormatter setDateFormat:dateFormatString];
            threadDictionary[key] = dateFormatter;
        }

        return [dateFormatter stringFromDate:date];
    }
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->_flag)
    {
        case DDLogFlagError    : logLevel = @"E"; break;
        case DDLogFlagWarning  : logLevel = @"W"; break;
        case DDLogFlagInfo     : logLevel = @"I"; break;
        case DDLogFlagDebug    : logLevel = @"D"; break;
        default                : logLevel = @"V"; break;
    }

    // Normalize queue label to last PEX_DDLOG_QUEUE_SIZE characters.
    NSString * queueLabel = [PEXDDLogFormatter normalizeString:logMessage->_queueLabel len:PEX_DDLOG_QUEUE_SIZE];

    // Normalize file name.
    NSString * filename = [PEXDDLogFormatter normalizeString:logMessage->_fileName len:PEX_DDLOG_FILE_NAME_SIZE];

    // Normalize function name to PEX_DDLOG_FNAME_SIZE. Use middle ellipsis.
    NSString * fname = [PEXDDLogFormatter normalizeString:logMessage->_function len:PEX_DDLOG_FNAME_SIZE];

    // Thread name.
    NSString * threadName = [PEXDDLogFormatter normalizeString:logMessage->_threadName len:PEX_DDLOG_THREAD_SIZE];

    NSString *dateAndTime = [self stringFromDate:(logMessage->_timestamp)];
    return [NSString stringWithFormat:@"%@ %@ | %@:%@ | [%@ : %@:%04lu] %@",
            logLevel, dateAndTime, threadName, queueLabel, filename,
            fname, (unsigned long)logMessage->_line, logMessage->_message];
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
    OSAtomicIncrement32(&atomicLoggerCount);
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
    OSAtomicDecrement32(&atomicLoggerCount);
}

+ (NSString *)normalizeString:(NSString *)input len:(unsigned)length {
    NSString * output = nil;
    if (input != nil){
        NSUInteger len = [input length];
        if (len > length){
            output = [input substringFromIndex:len-length];

        } else if (len == length) {
            output = input;

        } else {
            output = [NSString stringWithFormat:@"%.*s%@",
                                                    (int)(length-len), PEX_DDLOG_PADDING_STRING,
                                                    input];
        }
    }

    return output;
}


@end