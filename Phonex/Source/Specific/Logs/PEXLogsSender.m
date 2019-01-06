//
// Created by Matej Oravec on 25/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLogsSender.h"
#import "PEXSecurityCenter.h"
#import "PEXFtUploader.h"
#import "ZipFile.h"
#import "PEXStringUtils.h"
#import "PEXGuiFileUtils.h"
#import "ZipWriteStream.h"
#import "ZipException.h"
#import "PEXObjcZipWrap.h"
#import "PEXSipUri.h"
#import "PEXLogsZipper.h"
#import "PEXFtHolder.h"
#import "PEXServiceConstants.h"
#import "PEXDhKeyHelper.h"
#import "PEXLogsUploader.h"


@interface PEXLogsSender()

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionUploadTask *uploadTask;
@property (nonatomic) NSString * fullPathToZippedLogsFile;

@end

// TODO remove zipped files after finish

@implementation PEXLogsSender  {

}

- (bool) sendLogs
{
    // TODO mutex guard?

    // START ZIPPING
    NSString * fullPathToZippedLogsFile = nil;
    PEXLogsZipper * zipper = [[PEXLogsZipper alloc] init];
    zipper.logFilesToSend = 14;

    // Log file sizes are computed before compression.
    // Average compression ratio for deflate for our log files is 9. Goal is to limit
    // size of the data package transmitted over network to reasonable size.
    zipper.maxLogFileSize = 1024l*1024l*5l*9l;
    zipper.maxLogReportSize = 1024l*1024l*5l*9l;
    const bool zipWasSuccessful = [zipper zipLogsDefaultTo:&fullPathToZippedLogsFile];

    if (!zipWasSuccessful)
        return false;

    self.fullPathToZippedLogsFile = fullPathToZippedLogsFile;
    [self startUpload];

    return true;

    // create linear file of log files not in memory.
}

#pragma sending

- (void) startUpload
{
    PEXUserPrivate * const privateData = [[PEXAppState instance] getPrivateData];

    PEXLogsUploader * const uploader = [[PEXLogsUploader alloc] init];
    uploader.user = privateData.username;
    uploader.userMessage = self.userMessage;
    uploader.filepathForLogsFile = self.fullPathToZippedLogsFile;

    /*
    WEAKSELF;
    uploader.canceller = self.canceller;
    uploader.cancelBlock = self.cancelBlock;
    uploader.progressBlock = ^(int64_t curBytes, int64_t totalBytes, int64_t totalBytesExpected) {
        [weakSelf updateProgress:weakSelf.txprogress partial:nil total:(double) totalBytes / (double) totalBytesExpected];
    };
    */

    uploader.finishBlock = ^{
        [[NSFileManager defaultManager]
                removeItemAtPath:self.fullPathToZippedLogsFile error:nil];
    };

    [uploader configureSession];
    [uploader prepareSecurity:privateData];
    [uploader prepareSession];


    NSString * const domain = [PEXSipUri getDomainFromSip:privateData.username parsed:nil];
    NSString * const url2send =
            [NSString stringWithFormat:@"%@/rest/rest/logupload", [PEXServiceConstants getDefaultRESTURL:domain]];

    [uploader uploadFilesForUser:privateData.username url:url2send];
}


@end