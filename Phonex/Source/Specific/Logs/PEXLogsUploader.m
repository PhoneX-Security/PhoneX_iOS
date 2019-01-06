//
// Created by Matej Oravec on 31/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLogsUploader.h"
#import "PEXUploader_Protected.h"
#import "PEXRunLoopInputStream.h"

#import "PEXMultipartUploadStream.h"
#import "PEXUtils.h"
#import "PEXMergedInputStream.h"
#import "USAdditions.h"
#import "PEXPbRest.pb.h"


#define PEX_LOGS_UPLOAD_VERSION "version"
#define PEX_LOGS_UPLOAD_RESOURCE        "resource"
#define PEX_LOGS_UPLOAD_APPVERSION      "appVersion"
#define PEX_LOGS_UPLOAD_MESSAGE         "message"
#define PEX_LOGS_UPLOAD_AUXJSON         "auxJSON"
#define PEX_LOGS_UPLOAD_LOGFILE         "logfile"

NSString * PEX_LOGS_UPLOAD_DOMAIN = @"net.phonex.logs";
const NSInteger PEX_LOGS_UPLOAD_UNKNOWN_RESPONSE = 1;

@interface PEXLogsUploader ()

@end


@implementation PEXLogsUploader {

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    // Construct new upload stream here from available data.
    if (self.boundary == nil) {
        DDLogError(@"Boundary is nil");
        [task cancel];
        completionHandler(nil);
        return;
    }

    // Construct a new stream + use pre-generated boundary.
    DDLogVerbose(@"Going to construct new multipart stream");
    self.uploadStream = [[PEXMultipartUploadStream alloc] init];
    [self.uploadStream setNewBoundary:self.boundary];

    // Write request
    [self.uploadStream writeStringToStream:@PEX_LOGS_UPLOAD_VERSION    string:@"1"];
    [self.uploadStream writeStringToStream:@PEX_LOGS_UPLOAD_RESOURCE   string:@""];
    NSDictionary * const auxJsonDict = @{@"appVersion" : [PEXUtils getAppVersion]};
    [self.uploadStream writeStringToStream:@PEX_LOGS_UPLOAD_APPVERSION string:[PEXUtils serializeToJSON:auxJsonDict error:nil]];
    [self.uploadStream writeStringToStream:@PEX_LOGS_UPLOAD_MESSAGE    string:self.userMessage ? self.userMessage : @""];
    [self.uploadStream writeStringToStream:@PEX_LOGS_UPLOAD_AUXJSON    string:@""];

    // Was operation cancelled?
    [self checkIfCancelled];

    // Dump binary data (files) to the stream.
    PEXMultipartElement * e;

    const NSUInteger archLen = (NSUInteger) [PEXUtils fileSize:self.filepathForLogsFile error:nil];
    PEXMergedInputStream * const archInput = [[PEXMergedInputStream alloc]
            initWithStream:[NSInputStream inputStreamWithFileAtPath:self.filepathForLogsFile]];

    [archInput open];

    e = [[PEXMultipartElement alloc] initWithName:@PEX_LOGS_UPLOAD_LOGFILE filename:[self.filepathForLogsFile lastPathComponent]
                                         boundary:self.boundary
                                           stream: archInput
                                     streamLength: archLen];
    [self.uploadStream addPart:e];

    // Total length of the upload stream for progress monitoring.
    self.uploadLength = [self.uploadStream length];

    // Pass our stream to the upload function.
    DDLogVerbose(@"Going to pass new upload stream, length=%lld, archLen=%lu", self.uploadLength, (unsigned long)archLen);
    completionHandler(self.uploadStream);
}


// TODO unite with PEXFtUploader code? only diff in error codes and domain so far
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DDLogVerbose(@"Task did complete with error=%@", error);
    if (error != nil){
        self.error = error;
        [self processFinished];
        return;
    }

    NSUInteger dataLen = [self.responseData length];

    // If response is too short, it is suspicious.
    if (dataLen < 4){
        self.statusCode = 500;
        if (self.error == nil){
            self.error = [NSError errorWithDomain:PEX_LOGS_UPLOAD_DOMAIN code:PEX_LOGS_UPLOAD_UNKNOWN_RESPONSE userInfo:nil];
        }

        [self processFinished];
        return;
    }

    NSHTTPURLResponse * resp = (NSHTTPURLResponse *) [self.updTask response];
    self.statusCode = resp.statusCode;
    self.expectedContentLength = resp.expectedContentLength;

    // Take last _expectedContentLength bytes and parse response.
    NSData  * respData = self.responseData;
    NSData  * respDataPrefix = [self.responseData subdataWithRange:NSMakeRange(0, 4)];
    NSData  * httpData = [@"HTTP" dataUsingEncoding:NSASCIIStringEncoding];

    // HTTP detection.
    if ([httpData isEqualToData:respDataPrefix]){
        DDLogVerbose(@"Response data do start with HTTP");

        // Find \r\n as a separator
        NSData * rn = [@"\r\n" dataUsingEncoding:NSASCIIStringEncoding];
        NSRange range = [respData rangeOfData:rn options:0 range:NSMakeRange(0, [respData length])];
        if (range.location != NSNotFound && (range.length + range.location) < dataLen){
            NSUInteger fromIdx = range.length + range.location;
            DDLogVerbose(@"Removing HTTP response header from index: %lu", (unsigned long) fromIdx);
            respData = [respData subdataWithRange:NSMakeRange(fromIdx, dataLen - fromIdx)];
        }
    }

    @try {
        NSString * str = [[NSString alloc] initWithData:respData encoding:NSASCIIStringEncoding];
        NSData * bdecoded = [NSData dataWithBase64EncodedString:str];
        self.restResponse = [PEXPbRESTUploadPost parseFromData:bdecoded];
    } @catch(NSException * e){
        DDLogError(@"Exception in parsing response, exception=%@", e);
        if (self.error == nil){
            self.error = [NSError errorWithDomain:PEX_LOGS_UPLOAD_DOMAIN
                                             code:PEX_LOGS_UPLOAD_UNKNOWN_RESPONSE userInfo:@{PEXExtraException : e}];
        }
    }

    [self processFinished];
}

@end