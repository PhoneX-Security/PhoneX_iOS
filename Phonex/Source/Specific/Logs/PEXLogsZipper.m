//
// Created by Matej Oravec on 28/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLogsZipper.h"
#import "PEXObjcZipWrap.h"
#import "PEXStringUtils.h"
#import "PEXSecurityCenter.h"
#import "ZipWriteStream.h"

@implementation PEXLogsZipper {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.logFilesToSend = -1;
        self.maxLogReportSize = -1;
        self.maxLogFileSize = -1;
    }

    return self;
}

#pragma zipping

+ (bool) zipLogsDefaultTo: (NSString ** const) filepathOut{
    PEXLogsZipper * zipper = [[PEXLogsZipper alloc] init];
    return [zipper zipLogsDefaultTo:filepathOut];
}

- (bool) zipLogsDefaultTo: (NSString ** const) filepathOut
{
    NSArray * const logFilesPaths = [self getLogFilesPaths];
    if (!logFilesPaths)
        return false;

    return [self zipFiles:logFilesPaths
                       to:[PEXLogsZipper getDestinationFolder]
        withFilePlainName:@"zippedLogs"
              filepathOut:filepathOut];
}

+ (NSString *) getDestinationFolder
{
    return [NSString stringWithFormat:@"%@/logsToSend",
                    [PEXSecurityCenter getDefaultDocsDirectory:nil createIfNonexistent: YES]];
}

- (NSArray *)getLogFilesPaths
{
    NSString * const logsFolder = [PEXSecurityCenter getLogDirGeneral];
    if (!logsFolder)
    {
        DDLogWarn(@"Logs path is nil");
        return nil;
    }

    NSFileManager * const fileManager = [NSFileManager defaultManager];

    NSError * error;
    NSArray * const directoryContent = [fileManager contentsOfDirectoryAtPath:logsFolder error:&error];

    if (error)
    {
        DDLogWarn(@"Unable to get contents of logs folder: %@", error.description);
        return nil;
    }

    NSMutableArray * const result = [[NSMutableArray alloc] init];
    for (const id filename in directoryContent)
    {
        [result addObject:[logsFolder stringByAppendingPathComponent:filename]];
    }

    // Sort the array on names in DESCending order so the newest log file is first.
    // Used in the report size-capping.
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: nil ascending: NO selector:@selector(caseInsensitiveCompare:)];
    NSMutableArray * sortedResult = [NSMutableArray arrayWithArray: [result sortedArrayUsingDescriptors: @[sortOrder]]];

    // If a limit on a number of log files is set, sort the array and keep only TOP x.
    const NSUInteger arrSize = [sortedResult count];
    if (self.logFilesToSend >= 0 && self.logFilesToSend < arrSize){
        NSRange range = NSMakeRange((NSUInteger) self.logFilesToSend, arrSize - self.logFilesToSend);
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
        [sortedResult removeObjectsAtIndexes:indexes];
    }

    return sortedResult;
}

- (bool) zipFiles: (NSArray * const) filepaths
               to: (NSString * const) outputFolder
withFilePlainName: (NSString * const) outputFilePlainName
      filepathOut: (NSString ** const) filepathOut

{
    if (!outputFolder || [PEXStringUtils isEmpty:outputFolder] ||
            !outputFilePlainName || [PEXStringUtils isEmpty:outputFilePlainName])
    {
        DDLogWarn(@"invariant conditions not met");
        return false;
    }


    NSString * filepath;
    if (![self prepareOutputPathForFolder: outputFolder
                                     filePlainName: outputFilePlainName
                                       filepathOut: &filepath])
    {
        DDLogWarn(@"preparation of output path for zipped logs failed");
        return false;
    }

    if (![self zipThatNigga:filepaths to:filepath])
    {
        DDLogWarn(@"Zipping of log files failed");
        return false;
    }

    *filepathOut = filepath;

    return true;
}

- (bool) zipThatNigga: (NSArray * const) filepaths to: (NSString * const) outputFilepath
{
    bool result = true;

    ZipFile * const zipFile = [PEXObjcZipWrap createZipFile:outputFilepath];

    if (!zipFile)
    {
        result = false;
    }
    else {
        // Number of files processed so far.
        NSInteger numFilesProcessed = 0;
        // Number of bytes read so far, in total.
        size_t numBytesSoFar = 0;
        NSFileManager const * const fmgr = [NSFileManager defaultManager];

        const NSUInteger bufferSize = 65535;
        NSMutableData * readBuffData = [NSMutableData dataWithLength:bufferSize];

        // Sort order of the items in filepaths is important here as we may limit number of MB sent
        // and the most recent logs are more important than old ones.
        for (const id filepath in filepaths) {
            if (self.logFilesToSend > 0 && numFilesProcessed >= self.logFilesToSend){
                break;
            }

            @autoreleasepool {
                const unsigned long long fileSize = [[fmgr attributesOfItemAtPath:filepath error:nil] fileSize];
                unsigned long long fileOffset = 0;

                // If total byte limit is in place, seek start of the reading.
                if (self.maxLogReportSize >= 0) {
                    long long bytesRemaining = self.maxLogReportSize - numBytesSoFar;
                    if (bytesRemaining <= 0) {
                        DDLogVerbose(@"Log report reached threshold, no more bytes will be added");
                        break;
                    }

                    // If we can write less bytes from the limit that is the overall file size, set file offset
                    // so the limit is filled up with most recent records.
                    if (bytesRemaining < fileSize) {
                        fileOffset = fileSize - bytesRemaining;
                    }
                }

                // If per file byte limit is in place, seek start of the reading.
                if (self.maxLogFileSize >= 0 && self.maxLogFileSize < fileSize) {
                    fileOffset = MAX(fileOffset, fileSize - self.maxLogFileSize);
                }

                DDLogVerbose(@"Processing log file %@, size=%lld (%lld) MB, offset: %lld", [filepath lastPathComponent], fileSize, fileSize / 1024ul / 1024ul, fileOffset);
                FILE *fd = NULL;
                ZipWriteStream *stream = nil;
                @try {
                    fd = fopen([filepath UTF8String], "r");
                    if (fd == NULL) {
                        [NSException raise:@"logSendException" format:@"Could not open file %@", filepath];
                    }

                    // Seek on positive offset.
                    if (fileOffset > 0 && fseek(fd, (long) fileOffset, SEEK_SET) < 0) {
                        [NSException raise:@"logSendException" format:@"Seek was not successful for file %@", filepath];
                    }

                    // Add a new file entry to the ZIP file, obtaining writing stream to write file data into.
                    stream = [PEXObjcZipWrap createZipStreamForFile:zipFile destinationFilename:[filepath lastPathComponent]];
                    if (!stream) {
                        result = false;
                        break;
                    }

                    // Read file in chunks, writing to ZIP stream.
                    size_t len = 0;
                    while (result) {
                        len = fread([readBuffData mutableBytes], 1, bufferSize, fd);

                        // EOF / error?
                        if (len == 0) {
                            break;
                        }

                        [readBuffData setLength:len];
                        if (![PEXObjcZipWrap writeData:readBuffData toZipStream:stream]) {
                            stream = nil;
                            result = false;

                            [NSException raise:@"logSendException" format:@"Could not write stream data from %@", filepath];
                        }

                        // MutableData length needs to be restored back to normal.
                        [readBuffData setLength:bufferSize];
                        numBytesSoFar += len;
                    }

                    numFilesProcessed += 1;
                } @catch (NSException *e) {
                    DDLogError(@"Exception in processing log file %@, exc: %@", filepath, e);

                } @finally {
                    if (fd != NULL) {
                        fclose(fd);
                    }

                    // Close the stream, if any. If error occurs, stop processing.
                    if (stream != nil && ![PEXObjcZipWrap finishZipStream:stream]) {
                        DDLogError(@"Could not finish ZIP stream");
                        result = false;
                        break;
                    }
                }
            }
        }

        if (![PEXObjcZipWrap closeZipFile:zipFile]) {
            DDLogError(@"Could not close a ZIP file");
            result = false;
        }
    }

    return result;
}

- (bool) prepareOutputPathForFolder: (NSString * const) folder
                      filePlainName: (NSString * const) filePlainName
                        filepathOut: (NSString ** const) filepathOut
{
    NSFileManager * const fileManager = [NSFileManager defaultManager];


    NSArray * const directoryContent = [fileManager contentsOfDirectoryAtPath:folder error:nil];

    if (![fileManager fileExistsAtPath:folder])
    {
        if (![fileManager createDirectoryAtPath:folder
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil])
        {
            DDLogWarn(@"unable to create missing destination directory for zipped logs");
            return false;
        }
    }

    int orderNumber = 0;
    NSString * filepath = nil;

    do
    {
        filepath = [folder stringByAppendingFormat:@"/%@-%d.tmp", filePlainName, orderNumber++];
    }
    while ([fileManager fileExistsAtPath:filepath]);

    if (!filepath)
    {
        DDLogWarn(@"filepath for zipped logs could not be constructed");
        return false;
    }

    *filepathOut = filepath;

    return true;
}

@end