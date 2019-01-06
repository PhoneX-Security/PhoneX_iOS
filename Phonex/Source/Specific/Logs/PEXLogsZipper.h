//
// Created by Matej Oravec on 28/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXLogsZipper : NSObject
/**
 * Number of log files the log report will contain.
 * By default set to -1, meaning all log files.
 */
@property(nonatomic) NSInteger logFilesToSend;

/**
 * Maximum number of bytes for the log file.
 * If maximum is set to 50MB and log file has 250MB in size, LAST 50MBs are written to the ZIP stream,
 * since the most recent log entries are more important.
 *
 * By default set to -1, meaning there is no file size limit.
 */
@property(nonatomic) NSInteger maxLogFileSize;

/**
 * Maximum number of read bytes the whole log report can contain (before compression).
 * If set to non negative value, log sender ZIPs maxLogReportSize MBs of the most recent log entries.
 *
 * By default set to -1, meaning there is no limit.
 */
@property(nonatomic) NSInteger maxLogReportSize;
- (bool) zipLogsDefaultTo: (NSString ** const) filepathOut;


+ (bool) zipLogsDefaultTo: (NSString ** const) filepathOut;
+ (NSString *) getDestinationFolder;
- (NSArray *)getLogFilesPaths;

@end