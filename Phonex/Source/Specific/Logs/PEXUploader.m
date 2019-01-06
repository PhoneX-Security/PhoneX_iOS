//
// Created by Matej Oravec on 31/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUploader.h"
#import "PEXUploader_Protected.h"
#import "PEXCanceller.h"
#import "PEXPbRest.pb.h"
#import "USAdditions.h"
#import "PEXSOAPSSLManager.h"
#import "PEXCancelledException.h"
#import "PEXRunLoopInputStream.h"
#import "PEXMultipartUploadStream.h"
#import "PEXSystemUtils.h"
#import "PEXSOAPManager.h"
#import "PEXUserPrivate.h"
#import "PEXCodes.h"

@interface PEXUploader ()

@end

@implementation PEXUploader {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.endSignalized = NO;
        self.endSemaphore = dispatch_semaphore_create(0);
    }

    return self;
}

- (void) uploadFilesForUser: (NSString *) user url: (NSString *) url2upload {
    if (self.opQueue == nil){
        self.opQueue = [NSOperationQueue mainQueue];
    }

    self.error = nil;
    self.securityError = NO;
    self.wasCancelled = NO;
    self.responseData = [[NSMutableData alloc] init];
    self.restResponse = nil;
    self.endSignalized = NO;
    self.endSemaphore = dispatch_semaphore_create(0);

    PEXMultipartUploadStream * uploadStream = [[PEXMultipartUploadStream alloc] init];
    self.boundary = uploadStream.boundary;

    // Configure the request
    NSURL * url = [NSURL URLWithString:url2upload];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];

    // Set content type
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];

    self.updTask = [self.session uploadTaskWithStreamedRequest:request];

    // Kick-off the process.
    [self.updTask resume];
}

- (void) configureSession {
    self.sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    self.sessionConfig.timeoutIntervalForRequest = 30.0;
    self.sessionConfig.timeoutIntervalForResource = 60.0;
    self.sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    self.sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
    self.sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
}

- (void) prepareSecurity: (PEXUserPrivate *) privData{
    self.tlsManager = [[PEXSOAPSSLManager alloc] initWithPrivData:privData andUsername:privData.username];
}

- (void) prepareSession {
    if (self.opQueue == nil){
        self.opQueue = [NSOperationQueue mainQueue];
    }

    self.session = [NSURLSession sessionWithConfiguration: self.sessionConfig delegate: self delegateQueue: self.opQueue];
    self.wasCancelled = NO;
}

- (void)doCancel {
    self.wasCancelled = YES;

    // Cancel actual upload task in progress, if any.
    if (self.updTask != nil) {
        [self.updTask cancel];
    }

    [self processFinished];
}

- (void) processFinished {
    if (self.endSignalized){
        return;
    }

    DDLogVerbose(@"ProcessFinished, error=%@, total upd=%lld, bytes upd=%lld, status=%ld", _error, _uploadLength, _totalBytesSent, (long) _statusCode);

    // Let user know. Take error into consideration, status code && rest response.
    if (_finishBlock != nil){
        _finishBlock();
    }

    if (_finishBlock2 != nil){
        _finishBlock2(self);
    }

    self.endSignalized = YES;
    dispatch_semaphore_signal(self.endSemaphore);
}

- (int) uploadFilesBlockingForUser:(NSString *)user url:(NSString *)url2upload {
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
    __weak __typeof(self) weakSelf = self;

    // Perform non-blocking execution of the download task.
    [self uploadFilesForUser:user url:url2upload];

    // Wait for completion - semaphore indication.
    int waitRes =  [PEXSOAPManager waitWithCancellation:nil doneSemaphore:_endSemaphore
                                            semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                            cancelBlock:^BOOL { return [weakSelf isCancelled];}];

    // Did operation timeouted?
    if (waitRes == kWAIT_RESULT_TIMEOUTED){
        DDLogInfo(@"Download has been cancelled");
    }

    return waitRes;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    // abstract
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // abstract
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    [self URLSession:session task:nil didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DDLogDebug(@"didBecomeInvalidWithError: %@", error);
    // TODO: error.
    // https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSessionDelegate_protocol/index.html#//apple_ref/occ/intfm/NSURLSessionDelegate/URLSession:didBecomeInvalidWithError:
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    DDLogVerbose(@"URLSessionDidFinishEventsForBackgroundURLSession");
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLCredential * credential = nil;
    BOOL success = [self.tlsManager authenticateForChallenge:challenge credential:&credential];
    if (!success){
        DDLogError(@"Auth error");
        self.securityError = YES;
        self.error = [NSError errorWithDomain:PEXRuntimeSecurityException code:1 userInfo:nil];
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    } else {
        DDLogVerbose(@"Using credential for challenge %@", challenge);
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    // Progress monitoring here.
    _totalBytesSent = totalBytesSent;
    if (_progressBlock != nil){
        _progressBlock(bytesSent, totalBytesSent, totalBytesExpectedToSend < 0 ? _uploadLength : totalBytesExpectedToSend);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    // Collect received data to the data accumulator.
    [_responseData appendData:data];
}

/**
* Returns true if the local canceller signalizes a canceled state.
* @return
*/
-(BOOL) isCancelled{
    return _wasCancelled
            || (_canceller != nil && [_canceller isCancelled])
            || (_cancelBlock != nil && _cancelBlock());
}

/**
* Throws exception if operation was cancelled.
* @return
*/
-(void) checkIfCancelled {
    if ([self isCancelled]){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];
    }
}

@end