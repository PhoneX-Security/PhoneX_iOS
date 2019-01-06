//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXRestRequester.h"
#import "PEXRestRequester_Protected.h"

#import "PEXConnectionUtils.h"
#import "PEXSOAPSSLManager.h"


@implementation PEXRestRequester {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegateQueue = [NSOperationQueue mainQueue];
    }

    return self;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self nilProperties];
}

- (void) nilProperties
{
    self.connection = nil;
    self.receivedData = nil;
}

- (void) errorOccurred
{
    [self nilProperties];
}

- (NSArray *) satisfactoryCodes
{
    return @[@(200)];
}

- (bool) codeSatisfies: (const int) code
{
    return [[self satisfactoryCodes] containsObject:@(code)];
}

-(NSString *) encodeString: (NSString *) str {
    return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(
            NULL,
            (__bridge CFStringRef)str,
            NULL,
            (CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
            kCFStringEncodingUTF8 );
}

// ---------------------------------------------
#pragma mark - NSURLConnection code
// ---------------------------------------------

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    const int code = [PEXConnectionUtils connection:connection didReceiveResponse:response];

    if (![self codeSatisfies:code])
    {
        [self errorOccurred];
    }
    else
    {
        self.receivedData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [PEXConnectionUtils connection:connection didFailWithError:error];

    [self errorOccurred];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [PEXConnectionUtils connection:connection canAuthenticateAgainstProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [PEXConnectionUtils connection:connection didReceiveAuthenticationChallenge:challenge];
}

// ---------------------------------------------
#pragma mark - NSURLSession code
// ---------------------------------------------

- (void) processFinished: (NSData *) data resp: (NSURLResponse *) response error: (NSError *) rerror {
    self.opError = rerror;
    DDLogVerbose(@"ProcessFinished, response=%@, error=%@", response, self.opError);

    // Check the code, get data.
    const NSHTTPURLResponse * const httpResponse = (NSHTTPURLResponse*)response;
    const int code = [httpResponse statusCode];
    if (![self codeSatisfies:code]){
        [self errorOccurred];
        return;
    }

    self.receivedData = [data mutableCopy];
    [self connectionDidFinishLoading:nil];
}

- (void) defaultTrustInit {
    self.tlsManager = [[PEXSOAPSSLManager alloc] initWithPrivData:[[PEXAppState instance] getPrivateData]];
}

- (void)defaultQueueInit {
    self.delegateQueue = [[NSOperationQueue alloc] init];
    self.delegateQueue.maxConcurrentOperationCount = 1;
}

- (NSURLSessionConfiguration *) defaultConfiguration {
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders: @{@"Accept": @"application/json,text/html,application/xhtml+xml,application/xml"}];
    sessionConfig.timeoutIntervalForRequest = 45.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 3;
    sessionConfig.TLSMinimumSupportedProtocol = kTLSProtocol12;
    sessionConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    return sessionConfig;
}

// ---------------------------------------------
#pragma mark - NSURLSession delegate
// ---------------------------------------------

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    DDLogError(@"didBecomeInvalidWithError: %@", error);
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

@end