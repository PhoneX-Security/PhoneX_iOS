//
// Created by Dusan Klinec on 18.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPaymentUploadManager.h"
#import "PEXSOAPSSLManager.h"
#import "PEXCanceller.h"
#import "PEXSOAPManager.h"
#import "PEXUtils.h"
#import "PEXMultipartUploadStream.h"
#import "PEXPaymentUploadJob.h"
#import "PEXConcurrentHashMap.h"
#import "RMAppReceipt.h"
#import "PEXPaymentManager.h"
#import "PEXConnectionUtils.h"

#define PEX_TSX_UPLOAD_REQUEST "request"
NSString * PEX_TSX_UPLOAD_DOMAIN = @"PEXTransactionUpload";

@interface PEXPaymentUploadManager() {}

/**
 * Individual upload tasks are stored here.
 * NSURLSessionTask -> PEXPaymentUploadJob.
 */
@property (nonatomic) NSMutableDictionary * updTasks;
@property (nonatomic) NSObject * updLock;

/**
 * Transaction id -> PEXPaymentUploadJob.
 */
@property (nonatomic) NSMutableDictionary * tsxMap;


@end

@implementation PEXPaymentUploadManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configureSession];
        self.updTasks = [[NSMutableDictionary alloc] init];
        self.updLock = [[NSObject alloc] init];
        self.tsxMap = [[NSMutableDictionary alloc] init];

        self.securityError = NO;
        self.error = nil;

        self.opQueue = [[NSOperationQueue alloc] init];
        self.opQueue.name = @"updTasksQueue";
        self.opQueue.maxConcurrentOperationCount = 1;
    }

    return self;
}

/**
 * Method for acquiring a job for the given task
 */
-(PEXPaymentUploadJob *) getJobForTask: (NSURLSessionTask *) task {
    @synchronized (_updLock) {
        PEXPaymentUploadJob * job = _updTasks[task];
        return job;
    }
}

- (void) configureSession {
    self.sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    self.sessionConfig.timeoutIntervalForRequest = 45.0;
    self.sessionConfig.timeoutIntervalForResource = 60.0;
    self.sessionConfig.HTTPMaximumConnectionsPerHost = 3;
    self.sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol1;
    self.sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
}

- (void) prepareSecurity: (PEXUserPrivate *) privData{
    self.tlsManager = [[PEXSOAPSSLManager alloc] initWithPrivData:privData andUsername:privData.username];
}

- (void) prepareSession {
    if (self.opQueue == nil){
        self.opQueue = [NSOperationQueue mainQueue];
    }

    self.session = [NSURLSession sessionWithConfiguration:self.sessionConfig delegate:self delegateQueue:self.opQueue];
    self.wasCancelled = NO;
}

- (void)doCancel {
//    self.wasCancelled = YES;
//
//    // Cancel actual upload task in progress, if any.
//    if (self.updTask != nil) {
//        [self.updTask cancel];
//    }
//
//    [self processFinished];
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

/**
 * Default client & server cert auth code.
 */
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

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    PEXPaymentUploadJob * job = [self getJobForTask:dataTask];
    if (job == nil){
        DDLogError(@"Could not find job for the task");
        return;
    }

    // Collect received data to the data accumulator.
    @synchronized (job.recLock) {
        [job.responseData appendData:data];
    }
}

- (void)addUploadJob:(PEXPaymentUploadJob *)job {
    PEXMultipartUploadStream * uploadStream = [[PEXMultipartUploadStream alloc] init];
    job.boundary = uploadStream.boundary;
    [job.responseData setLength:0];

    // Configure the request
    NSMutableURLRequest * request = [self buildRequest:job];
    job.uploadTask = [self.session uploadTaskWithStreamedRequest:request];

    // Add to local dictionaries.
    @synchronized (_updLock) {
        _updTasks[job.uploadTask] = job;
        _tsxMap[job.tsxId] = job;
    }

    // Kick-off the process.
    DDLogVerbose(@"Going to kick-off new upload for tsxId: %@, retry: %d", job.tsxId, (int) job.currentRetry);
    [job.uploadTask resume];
}

-(NSMutableURLRequest *) buildRequest: (PEXPaymentUploadJob *)job {
    NSURL * url = [NSURL URLWithString:[PEXConnectionUtils systemUrlClientCrtWithPath:@"api/auth/purchase/appstore/payment-verif"]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];

    // Set content type
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", job.boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    return request;
}

- (void) finishJob: (PEXPaymentUploadJob *) job {
    // Finish block
    if (job.error == nil){
        job.statusCode = 200;
    }

    if (job.finishBlock){
        job.finishBlock(job, job.jsonResponse, job.error);
    }

    // Remove from dictionary.
    NSString * uploadTsxId = [PEXPaymentManager getUploadTsxId:job.transaction];
    DDLogVerbose(@"Going to remove upload job for tsxId: %@, uodTsxId: %@", job.tsxId, uploadTsxId);
    @synchronized (_updLock) {
        [_updTasks removeObjectForKey:job.uploadTask];
        [_tsxMap removeObjectForKey:job.tsxId];
    }
}

- (void) onJobFailed: (PEXPaymentUploadJob *) job withError: (NSError *) error {
    job.currentRetry += 1;

    // If retry count is too high, declare it officially as failed.
    if (job.retryCount < job.currentRetry){
        DDLogError(@"Upload job failed %@, retryCount: %d, current: %d",
                job.tsxId, (int)job.retryCount, (int)job.currentRetry);

        job.error = error;
        [self finishJob:job];
        return;
    }

    // Retry count - re-add the job.
    @synchronized (_updLock) {
        [_updTasks removeObjectForKey:job.uploadTask];
    }

    [self addUploadJob:job];
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler {
    // Construct new upload stream here from available data.
    PEXPaymentUploadJob * job = [self getJobForTask:task];
    if (job == nil){
        DDLogError(@"Could not find job for the task");
        completionHandler(nil);
        return;
    }

    // Collect received data to the data accumulator.
    @synchronized (job.recLock) {
        if (job.boundary == nil) {
            DDLogError(@"Boundary is nil");
            [task cancel];
            completionHandler(nil);
            return;
        }

        // Construct a new stream + use pre-generated boundary.
        DDLogVerbose(@"Going to construct new multipart stream %p", self);
        job.uploadStream = [[PEXMultipartUploadStream alloc] init];
        [job.uploadStream setNewBoundary:job.boundary];

        // Build JSON request.
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *transaction = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *product = [[NSMutableDictionary alloc] init];

        // Main body
        [PEXUtils addIfNonNil:info key:@"p"
                        value:@"apple"];
        [PEXUtils addIfNonNil:info key:@"appVersion"
                        value:[PEXUtils getAppVersion]];
        [PEXUtils addIfNonNil:info key:@"guuid"
                        value:job.guuid];
        [PEXUtils addIfNonNil:info key:@"receiptReupload"
                        value:@(job.isReceiptReUpload)];
        [PEXUtils addIfNonNil:info key:@"transaction"
                        value:transaction];
        [PEXUtils addIfNonNil:info key:@"product"
                        value:product];
        [PEXUtils addIfNonNil:info key:@"receipt"
                        value:job.receipt64];

        // Transaction
        [PEXUtils addIfNonNil:transaction key:@"transactionId"
                        value:job.transaction.transactionIdentifier];
        [PEXUtils addIfNonNil:transaction key:@"originalTransactionId"
                        value:job.transaction.originalTransaction.transactionIdentifier];
        [PEXUtils addIfNonNil:transaction key:@"originalTransactionDate"
                         date:job.transaction.originalTransaction.transactionDate];
        [PEXUtils addIfNonNil:transaction key:@"transactionDate"
                         date:job.transaction.transactionDate];
        [PEXUtils addIfNonNil:transaction key:@"transactionRestored"
                        value:@(job.transaction.transactionState == SKPaymentTransactionStateRestored)];

        // Product
        [PEXUtils addIfNonNil:product key:@"productId"
                        value:job.purchase.productIdentifier];
        [PEXUtils addIfNonNil:product key:@"tsxId"
                        value:job.purchase.transactionIdentifier];
        [PEXUtils addIfNonNil:product key:@"originalTsxId"
                        value:job.purchase.originalTransactionIdentifier];
        [PEXUtils addIfNonNil:product key:@"quantity"
                        value:@(job.purchase.quantity)];
        [PEXUtils addIfNonNil:product key:@"cancellationDate"
                         date:job.purchase.cancellationDate];
        [PEXUtils addIfNonNil:product key:@"purchaseDate"
                         date:job.purchase.purchaseDate];
        [PEXUtils addIfNonNil:product key:@"subscriptionExpirationDate"
                         date:job.purchase.subscriptionExpirationDate];
        [PEXUtils addIfNonNil:product key:@"originalPurchaseDate"
                         date:job.purchase.originalPurchaseDate];

        // Write request
        NSError *err = nil;
        NSString *json = [PEXUtils serializeToJSON:@{@"payment" : info} error:&err];
        if (json == nil || err != nil) {
            job.error = err;
            if (job.error == nil) {
                job.error = [NSError errorWithDomain:PEX_TSX_UPLOAD_DOMAIN code:2 userInfo:nil];
            }

            DDLogError(@"Error in JSON request body buiding: %@ for tsxId: %@", err, job.tsxId);
            [self finishJob:job];
            return;
        }

        [job.uploadStream writeStringToStream:@PEX_TSX_UPLOAD_REQUEST string:json];
        DDLogVerbose(@"JSON request for tsxId: %@, json: %@", job.tsxId, json);

        // Total length of the upload stream for progress monitoring.
        job.uploadLength = [job.uploadStream length];

        // Pass our stream to the upload function.
        completionHandler(job.uploadStream);
    }
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    DDLogVerbose(@"Task did complete with error=%@", error);
    PEXPaymentUploadJob * job = [self getJobForTask:task];
    if (job == nil){
        DDLogError(@"Could not find job for the task");
        return;
    }

    @synchronized (job.recLock) {
        // Error path.
        if (error != nil){
            [self onJobFailed:job withError:error];
            return;
        }

        const NSUInteger dataLen = [job.responseData length];

        // If response is too short, it is suspicious.
        if (dataLen < 4){
            job.statusCode = 500;
            [self onJobFailed:job withError:[NSError errorWithDomain:PEX_TSX_UPLOAD_DOMAIN code:1 userInfo:nil]];
            return;
        }

        NSHTTPURLResponse * resp = (NSHTTPURLResponse *) [job.uploadTask response];
        job.statusCode = resp.statusCode;

        // Take last _expectedContentLength bytes and parse response.
        NSData  * respData = job.responseData;
        NSData  * respDataPrefix = [job.responseData subdataWithRange:NSMakeRange(0, 4)];
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
            job.jsonResponse = str;

        } @catch(NSException * e){
            DDLogError(@"Exception in parsing response, exception=%@", e);
            if (job.error == nil){
                job.error = [NSError errorWithDomain:PEX_TSX_UPLOAD_DOMAIN
                                                 code:1 userInfo:@{PEXExtraException : e}];
            }
        }

        [self finishJob:job];
    }
}

@end