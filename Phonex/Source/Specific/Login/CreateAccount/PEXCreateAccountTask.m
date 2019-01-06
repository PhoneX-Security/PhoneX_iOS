//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCreateAccountTask.h"
#import "PEXTask_Protected.h"
#import "PEXStringUtils.h"
#import "PEXCreateAccountHolder.h"
#import "PEXConnectionUtils.h"
#import "PEXOpenUDID.h"
#import "PEXMessageDigest.h"
#import "PEXRestRequester.h"

static NSString * const S_CREATE_TRIAL_ACCOUNT_URL_PATH = @"account/trial";
static NSString * const S_CREATE_PRODUCT_ACCOUNT_URL_PATH = @"account/business-account";
static NSString * const S_REQUEST_VERSION_STRING = @"1";

@interface PEXCreateAccountTask ()
{
@private
    int _httpResponseCode;
}

@property (nonatomic) NSMutableData * receivedData;

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) PEXRestRequester * requester;
@property (nonatomic) NSURLSessionUploadTask * requestTask;

@end

@implementation PEXCreateAccountTask {

}

- (int)httpResponseCode
{
    return _httpResponseCode;
}

- (void)perform
{
    [super perform];

    [self makeRequest];
}

- (void) makeRequest
{
    self.semaphore = dispatch_semaphore_create(0);
    [self prepareRequest];

    if (!self.requestTask)
    {
        self.result = PEX_CREATE_ACCOUNT_CONNECTION_ERROR;
    }
    else
    {
        [self.requestTask resume];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    }

    self.semaphore = nil;
}

-(void) prepareRequest {
    self.requester = [[PEXRestRequester alloc] init];

    NSURL * const requestUrl = [NSURL URLWithString:[PEXConnectionUtils systemUrlWithPath:
            (self.createAccountInfo.productCode ?
                    S_CREATE_PRODUCT_ACCOUNT_URL_PATH :
                    S_CREATE_TRIAL_ACCOUNT_URL_PATH)]];

    WEAKSELF;
    [self.requester defaultTrustInit];
    [self.requester defaultQueueInit];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[self.requester defaultConfiguration]
                                                          delegate:self.requester
                                                     delegateQueue:self.requester.delegateQueue];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:requestUrl];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    // Build body.
    NSString * openUdidHexSha256;
    NSString * const openUdid = [PEXOpenUDID value];
    if (openUdid) {
        NSData * const data = [PEXMessageDigest sha256Message:openUdid];
        if (data) {
            openUdidHexSha256 = [PEXMessageDigest bytes2hex:data];
        }
    }

    NSURLConnection * result;
    if (!openUdidHexSha256) {
        self.result = PEX_CREATE_ACCOUNT_REQUEST_DATA_ERROR;

    } else {
        NSMutableDictionary *postDict = [[NSMutableDictionary alloc] init];
        postDict[@"captcha"] = self.createAccountInfo.captcha;
        postDict[@"imei"] = openUdidHexSha256;
        postDict[@"username"] = self.createAccountInfo.username;
        postDict[@"version"] = S_REQUEST_VERSION_STRING;

        if (self.createAccountInfo.productCode)
            postDict[@"bcode"] = self.createAccountInfo.productCode;

        NSData *const postData = [PEXConnectionUtils encodeDictionaryToHttpParameters:postDict];

        [request setHTTPBody:postData];

        self.requestTask = [session uploadTaskWithRequest:request
                                                 fromData:postData
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            [weakSelf onPostFinished:data response:response error:error];
                                        }];
    }
}

- (void)onPostFinished:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    DDLogVerbose(@"ProcessFinished, response=%@, error=%@", response, error);
    if (error != nil){
        [self connection:nil didFailWithError:error];
        return;
    }

    // Check the code, get data.
    const NSHTTPURLResponse * const httpResponse = (NSHTTPURLResponse*)response;
    _httpResponseCode = [httpResponse statusCode];
    if ((_httpResponseCode != 200) && (_httpResponseCode != 201)) {
        self.result = PEX_CREATE_ACCOUNT_REQUEST_ERROR;
        [self dispatchFinishConnection];
        return;
    }

    self.receivedData = [data mutableCopy];
    [self connectionDidFinishLoading:nil];
}

- (void)dispatchFinishConnection
{
    dispatch_semaphore_signal(self.semaphore);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [PEXConnectionUtils connection:connection didFailWithError:error];

    self.receivedData = nil;
    [self dispatchFinishConnection];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!self.receivedData)
    {
        self.result = PEX_CREATE_ACCOUNT_RESPONSE_DATA_ERROR;
    }
    else
    {
        NSError *error;

        NSDictionary *const jsonData = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&error];
        self.receivedData = nil;

        if (error || !jsonData)
        {
            self.result = PEX_CREATE_ACCOUNT_RESPONSE_DATA_ERROR;
        }
        else
        {
            self.result = PEX_CREATE_ACCOUNT_SUCCESSFUL_RESPONSE;
            _jsonResult = jsonData;
        }
    }

    [self dispatchFinishConnection];
}


@end