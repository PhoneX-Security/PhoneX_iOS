//
// Created by Dusan Klinec on 04.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtDownloader.h"
#import "PEXSOAPSSLManager.h"
#import "PEXUtils.h"
#import "PEXSecurityCenter.h"
#import "PEXCanceller.h"
#import "PEXFtHolder.h"
#import "PEXSOAPManager.h"
#import "PEXCancelledException.h"

@interface PEXFtDownloader() {}
@property(nonatomic) NSURLSessionConfiguration * sessionConfig;
@property(nonatomic) NSURLSession * session;
@property(nonatomic) PEXSOAPSSLManager * tlsManager;
@property(nonatomic) NSURLSessionDownloadTask * dwnTask;
@property(nonatomic) NSOperationQueue * opQueue;
@property(nonatomic) BOOL wasCancelled;

@property(nonatomic) BOOL securityError;
@property(nonatomic) NSError * error;

@property(nonatomic) int64_t downloadLength;
@property(nonatomic) int64_t totalBytesReceived;
@property(nonatomic) NSNumber * rangeFromVal;
@property(nonatomic) NSNumber * reqTimeout;
@property(nonatomic) NSNumber * resTimeout;

@property(nonatomic) BOOL endSignalized;
@property(nonatomic) dispatch_semaphore_t endSemaphore;
@end

@implementation PEXFtDownloader {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _endSignalized = NO;
        _endSemaphore = dispatch_semaphore_create(0);
        _rangeFromVal = nil;
    }

    return self;
}

- (void) configureSession {
    _sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    _sessionConfig.timeoutIntervalForRequest  = _reqTimeout != nil ? [_reqTimeout doubleValue] : 30.0;
    _sessionConfig.timeoutIntervalForResource = _resTimeout != nil ? [_resTimeout doubleValue] : 60.0;
    _sessionConfig.HTTPMaximumConnectionsPerHost = 3;
    _sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
    _sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
}

- (void) prepareSecurity: (PEXUserPrivate *) privData{
    _tlsManager = [[PEXSOAPSSLManager alloc] initWithPrivData:privData andUsername:privData.username];
}

- (void) prepareSession {
    if (_opQueue == nil){
        _opQueue = [NSOperationQueue mainQueue];
    }

    _session = [NSURLSession sessionWithConfiguration: _sessionConfig delegate: self delegateQueue: _opQueue];
    _wasCancelled = NO;
}

- (void)doCancel {
    _wasCancelled = YES;

    // Cancel actual upload task in progress, if any.
    if (_dwnTask != nil) {
        [_dwnTask cancel];
    }

    [self processFinished];
}

-(void) downloadFile: (NSString *) urlStr {
    _endSignalized = NO;
    _error = nil;
    _securityError = NO;
    _endSemaphore = dispatch_semaphore_create(0);

    // Configure the request;
    NSURL * url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    if (_rangeFromVal != nil){
        [request setValue:[NSString stringWithFormat:@"bytes=%ld-", [_rangeFromVal longValue]] forHTTPHeaderField:@"Range"];
        DDLogVerbose(@"Continued download, start from: %@", _rangeFromVal);
    }

    _dwnTask = [_session downloadTaskWithRequest: request];
    [_dwnTask resume];
}

-(int) downloadFileBlocking: (NSString *) urlStr {
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
    __weak __typeof(self) weakSelf = self;

    // Perform non-blocking execution of the download task.
    [self downloadFile:urlStr];

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

- (void) processFinished {
    if (_endSignalized){
        return;
    }

    DDLogVerbose(@"ProcessFinished, error=%@, total downLength=%lld, bytes totalBytesReceived=%lld", _error, _downloadLength, _totalBytesReceived);

    // Let user know. Take error into consideration, status code && rest response.
    if (_finishBlock != nil){
        _finishBlock();
    }

    _endSignalized = YES;
    dispatch_semaphore_signal(_endSemaphore);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DDLogVerbose(@"didBecomeInvalidWithError: %@", error);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    [self URLSession:session task:nil didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {

}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    DDLogVerbose(@"Session %@ download task %@ finished downloading to UR %@", session, downloadTask, location);

    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    // Delete destination file right now so it does not exist for file manager to move here new one.
    [PEXUtils removeFile:_destinationFile];

    NSURL *destinationURL = [NSURL fileURLWithPath:_destinationFile];
    if ([fileManager moveItemAtURL:location toURL:destinationURL error: &err]) {
        DDLogVerbose(@"File stored to: %@", destinationURL);

    } else {
        // Handle the error.
        DDLogError(@"Downloaded file cannot be moved to desired file, error=%@", err);
        _error = err;
        [self processFinished];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // Progress monitoring here.
    _totalBytesReceived = totalBytesWritten;
    if (_progressBlock != nil){
        _progressBlock(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    // Progress after resume.
    DDLogVerbose(@"Progress after resume: %lld", fileOffset);
    _totalBytesReceived = fileOffset;
    if (_progressBlock != nil){
        _progressBlock(fileOffset, fileOffset, expectedTotalBytes);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLCredential * credential = nil;
    BOOL success = [_tlsManager authenticateForChallenge:challenge credential:&credential];
    if (!success){
        DDLogError(@"Auth error");
        _securityError = YES;
        _error = [NSError errorWithDomain:PEXRuntimeSecurityException code:1 userInfo:nil];
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    } else {
        DDLogVerbose(@"Using credential");
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse * resp = (NSHTTPURLResponse *) [_dwnTask response];
    _statusCode = resp.statusCode;

    DDLogVerbose(@"Task did complete with error=%@, response=%@, status code: %ld", error, resp, (long)_statusCode);
    if (error != nil){
        _error = error;
        [self processFinished];
        return;
    }

    [self processFinished];
}

- (void) setRangeFrom:(NSUInteger)rangeBytes {
    _rangeFromVal = @(rangeBytes);
}

- (void)setTimeouts:(NSNumber *)reqTimeout resTimeout:(NSNumber *)resTimeout {
    _reqTimeout = reqTimeout;
    _resTimeout = resTimeout;
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