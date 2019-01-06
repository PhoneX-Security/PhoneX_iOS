//
// Created by Dusan Klinec on 23.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXJsonFetchOperation.h"
#import "PEXService.h"
#import "NSError+PEX.h"
#import "PEXCanceller.h"
#import "PEXCancelledException.h"
#import "PEXSOAPManager.h"
#import "PEXSOAPSSLManager.h"

NSString        * PEXFetchErrorDomain           = @"PEXFetchErrorDomain";
const NSInteger   PEXFetchGenericError          = 6001;
const NSInteger   PEXFetchNotConnectedError     = 6002;
const NSInteger   PEXFetchInvalidResponseError  = 6003;
const NSInteger   PEXFetchCancelledError        = 6004;
const NSInteger   PEXFetchTimedOutError         = 6005;

@interface PEXJsonFetchOperation () {
    BOOL          _wasCancelled;
    PEXService  * _svc;
}

@property(nonatomic) NSError * opError;
@property(nonatomic) BOOL interruptedDueToConnectionError;
@property(nonatomic) BOOL endSignalized;
@property(nonatomic) dispatch_semaphore_t endSemaphore;
@property(nonatomic) NSDictionary * response;
@property(nonatomic) NSURLSessionUploadTask * requestTask;
@property(nonatomic) NSOperationQueue * delegateQueue;
@end

@implementation PEXJsonFetchOperation {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.blockingOp = YES;
    }

    return self;
}


/**
* Main entry point for this task.
*/
-(void) main {
    @try {
        [self runInternal];
    } @catch(NSException * e){
        DDLogError(@"Exception in certificate refresh. Exception=%@", e);
        if (_opError == nil){
            _opError = [NSError errorWithDomain:PEXFetchErrorDomain code:PEXFetchGenericError userInfo:@{PEXExtraException : e}];
        }
    }
}

- (void)runInternal {
    _wasCancelled = NO;
    self.tlsManager = [[PEXSOAPSSLManager alloc] initWithPrivData:self.privData];
    self.tlsManager.supportClientAuth = NO;

    self.endSignalized = NO;
    self.endSemaphore = dispatch_semaphore_create(0);
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
    __weak __typeof(self) weakSelf = self;

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders: @{@"Accept": @"application/json"}];
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;

    self.delegateQueue = [[NSOperationQueue alloc] init];

    // 1
    NSURL *url = [NSURL URLWithString:_url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:self.delegateQueue];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];

    NSString * params = [self parseParams:_params];
    [request setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];

    // 3
    NSError * error   = nil;

    // 4
    self.requestTask = [session uploadTaskWithRequest:request fromData:[params dataUsingEncoding:NSUTF8StringEncoding]
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *rerror)
        {
            [weakSelf processFinished:data resp:response error:rerror];
        }];

    // 5
    [self.requestTask resume];

    // If this is configured as blocking operation, do wait for finish.
    if (self.blockingOp) {
        // Wait for completion - semaphore indication.
        int waitRes = [PEXSOAPManager waitWithCancellation:nil doneSemaphore:_endSemaphore
                                               semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                               cancelBlock:^BOOL {
                                                   return [weakSelf isCancelled];
                                               }];

        // Did operation timeouted?
        if (waitRes == kWAIT_RESULT_TIMEOUTED) {
            DDLogDebug(@"Fetch timed out");
            [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchTimedOutError userInfo:nil];
        } else if (waitRes == kWAIT_RESULT_CANCELLED && _opError == nil){
            DDLogDebug(@"Fetch cancelled");
            [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchCancelledError userInfo:nil];
        }
    }
}

- (void) processFinished: (NSData *) data resp: (NSURLResponse *) response error: (NSError *) rerror {
    if (self.endSignalized){
        return;
    }

    self.opError = rerror;
    DDLogVerbose(@"ProcessFinished, error=%@", _opError);

    NSError * jsonError = nil;
    // Only Ok error codes are accepted as good.
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
    if (httpResp.statusCode / 100 != 2) {
        DDLogError(@"HTTP status code is not OK: %ld", (long)httpResp.statusCode);
        [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchInvalidResponseError userInfo:nil];
        goto end;
    }

    // Parse JSON data.
    self.response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
    if (jsonError != nil) {
        DDLogError(@"Error parsing JSON data: %@", jsonError);
        [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchInvalidResponseError userInfo:nil];
        goto end;
    }

end:
    self.endSignalized = YES;
    dispatch_semaphore_signal(self.endSemaphore);

    if (self.finishBlock != nil){
        self.finishBlock();
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DDLogVerbose(@"didBecomeInvalidWithError: %@", error);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    [self URLSession:session task:nil didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    NSURLCredential * credential = nil;
    BOOL success = [self.tlsManager authenticateForChallenge:challenge credential:&credential];
    if (!success){
        DDLogError(@"Auth error");
        self.opError = [NSError errorWithDomain:PEXRuntimeSecurityException code:1 userInfo:nil];
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    } else {
        DDLogVerbose(@"Using credential");
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

-(NSString *) parseParams: (NSDictionary *) dict {
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    for(NSString * key in dict){
        NSString * val = dict[key];

        [arr addObject:[NSString stringWithFormat:@"%@=%@", [self encodeString:key], [self encodeString:val]]];
    }

    return [arr componentsJoinedByString:@"&"];
}

-(NSString *) encodeString: (NSString *) str {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(
            NULL,
            (__bridge CFStringRef)str,
            NULL,
            (CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
            kCFStringEncodingUTF8 );
}

/**
* Put this error on the top of the error stack, leaving tail of the error chain in the EXTRA.
*/
-(void) chainErrorWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict {
    _opError = [NSError errorWithDomain:domain code:code userInfo:dict subError:_opError];
}

/**
* Returns true if the local canceller signalizes a canceled state.
* @return
*/
-(BOOL) wasCancelled{
    return _wasCancelled || [self isCancelled] || (self.canceller != nil && [self.canceller isCancelled]);
}

/**
* Throws exception if operation was cancelled.
* @return
*/
-(void) checkIfCancelled {
    if ([self wasCancelled]){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Operation cancelled"];
    }
}

/**
* Check if connectivity is OK.
* if not, exception is thrown.
*/
-(void) checkIfConnected {
    _interruptedDueToConnectionError |= ![_svc isConnectivityWorking];
    if (_interruptedDueToConnectionError){
        [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchNotConnectedError userInfo:nil];
        [NSException raise:PEXNotConnectedExceptionString format:@"Not connected"];
    }
}

- (void)doCancel {
    _wasCancelled = YES;
    [self chainErrorWithDomain:PEXFetchErrorDomain code:PEXFetchCancelledError userInfo:nil];
    [self.requestTask cancel];
    [self cancel];
}
@end