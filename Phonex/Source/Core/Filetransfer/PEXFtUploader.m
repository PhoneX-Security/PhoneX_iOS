//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtUploader.h"
#import "PEXUploader_Protected.h"

#import "USAdditions.h"
#import "PEXFtHolder.h"
#import "PEXRunLoopInputStream.h"
#import "PEXMultipartUploadStream.h"
#import "PEXPbFiletransfer.pb.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXPbRest.pb.h"
#import "PEXSOAPManager.h"
#import "PEXMergedInputStream.h"
#import "PEXUtils.h"
#import "PEXCodes.h"
#import "PEXUserPrivate.h"

NSString * PEX_FT_UPLOAD_DOMAIN = @"net.phonex.ft.upload";
const NSInteger PEX_FT_UPLOAD_UNKNOWN_RESPONSE = 1;

@interface PEXFtUploader() {}


@end

@implementation PEXFtUploader {

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    // Construct new upload stream here from available data.
    if (self.holder == nil || self.boundary == nil){
        DDLogError(@"Holder or boundary is nil");

        [task cancel];
        completionHandler(nil);
        return;
    }

    // Construct a new stream + use pre-generated boundary.
    DDLogVerbose(@"Going to construct new multipart stream");
    self.uploadStream = [[PEXMultipartUploadStream alloc] init];
    [self.uploadStream setNewBoundary:self.boundary];

    // Dumping basic parameters
    NSString * nonce2 = [_holder.nonce2 base64EncodedStringWithOptions:0];

    // Write request
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_VERSION  string:@"1"];
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_NONCE2   string:nonce2];
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_USER     string:self.user];
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_DHPUB    string:[_holder.ukeyData base64EncodedStringWithOptions:0]];
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_HASHMETA string:[_holder.fileHash[PEX_FT_META_IDX] base64EncodedStringWithOptions:0]];
    [self.uploadStream writeStringToStream:@PEX_FT_UPD_HASHPACK string:[_holder.fileHash[PEX_FT_ARCH_IDX] base64EncodedStringWithOptions:0]];

    // Was operation cancelled?
    [self checkIfCancelled];

    // Dump binary data (files) to the stream.
    PEXMultipartElement * e;

    NSUInteger metaLen = ((NSData *)_holder.filePrepRec[PEX_FT_META_IDX]).length + (NSUInteger)[PEXUtils fileSize:_holder.filePath[PEX_FT_META_IDX] error:nil];
    PEXMergedInputStream * metaInput = [[PEXMergedInputStream alloc] initWithStream:
                    [NSInputStream inputStreamWithData:_holder.filePrepRec[PEX_FT_META_IDX]]
                   :[NSInputStream inputStreamWithFileAtPath:_holder.filePath[PEX_FT_META_IDX]]];
    [metaInput open];

    e = [[PEXMultipartElement alloc] initWithName:@PEX_FT_UPD_METAFILE filename:@"meta" boundary:self.boundary stream: metaInput streamLength: metaLen];
    [self.uploadStream addPart:e];

    NSUInteger archLen = ((NSData *)_holder.filePrepRec[PEX_FT_ARCH_IDX]).length + (NSUInteger)[PEXUtils fileSize:_holder.filePath[PEX_FT_ARCH_IDX] error:nil];
    PEXMergedInputStream * archInput = [[PEXMergedInputStream alloc] initWithStream:
                    [NSInputStream inputStreamWithData:_holder.filePrepRec[PEX_FT_ARCH_IDX]]
                   :[NSInputStream inputStreamWithFileAtPath:_holder.filePath[PEX_FT_ARCH_IDX]]];
    [archInput open];

    e = [[PEXMultipartElement alloc] initWithName:@PEX_FT_UPD_PACKFILE filename:@"pack" boundary:self.boundary stream: archInput streamLength: archLen];
    [self.uploadStream addPart:e];

    // Total length of the upload stream for progress monitoring.
    self.uploadLength = [self.uploadStream length];

    // Pass our stream to the upload function.
    DDLogVerbose(@"Going to pass new upload stream, length=%lld, metaLen=%lu, archLen=%lu", self.uploadLength, (unsigned long)metaLen, (unsigned long)archLen);
    completionHandler(self.uploadStream);
}

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
            self.error = [NSError errorWithDomain:PEX_FT_UPLOAD_DOMAIN code:PEX_FT_UPLOAD_UNKNOWN_RESPONSE userInfo:nil];
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
            self.error = [NSError errorWithDomain:PEX_FT_UPLOAD_DOMAIN code:PEX_FT_UPLOAD_UNKNOWN_RESPONSE userInfo:@{PEXExtraException : e}];
        }
    }

    [self processFinished];
}

@end