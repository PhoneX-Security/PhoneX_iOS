//
// Created by Dusan Klinec on 15.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXSendRecoveryCodeTask.h"
#import "PEXRestRequester_Protected.h"
#import "PEXConnectionUtils.h"
#import "PEXServiceConstants.h"
#import "PEXSipUri.h"
#import "PEXUtils.h"

static NSString * S_SEND_CODE_REQUEST_URL_PATH = @"%@/rest/rest/recoveryCode";

@interface PEXSendRecoveryCodeTask ()
@property (nonatomic, copy) PEXRecoveryCodeSendFinished completion;
@property (nonatomic, copy) PEXRecoveryCodeSendFailed errorHandler;

@property (nonatomic) NSDictionary * resultJson;
@property (nonatomic) NSError * loadError;
@property (nonatomic) NSURLSessionDataTask * requestTask;
@end

@implementation PEXSendRecoveryCodeTask {

}

- (bool)sendRecoveryCode:(PEXRecoveryCodeSendFinished)completion
            errorHandler:(PEXRecoveryCodeSendFailed)errorHandler
{
    // Add default server part if is missing.
    if ([self.dstUser rangeOfString:@"@"].location == NSNotFound){
        self.dstUser = [NSString stringWithFormat:@"%@@phone-x.net", self.dstUser];
    }

    NSString * const domain = [PEXSipUri getDomainFromSip:self.dstUser parsed:nil];
    NSString * const url2send = [NSString stringWithFormat:S_SEND_CODE_REQUEST_URL_PATH, [PEXServiceConstants getDefaultRESTURL:domain hasCert:NO]];

    // Encode locale JSON as a parameter.
    NSURL * const url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?userName=%@&resource=%@&appVersion=%@&auxJSON=%@",
                    url2send,
                    [self encodeString:self.dstUser],
                    [self encodeString:self.dstUserResource],
                    [self encodeString:[PEXUtils serializeToJSON:[PEXUtils getAppVersion] error:nil]],
                    @""
    ]];

    WEAKSELF;
    [self defaultTrustInit];
    [self defaultQueueInit];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[self defaultConfiguration] delegate:self delegateQueue:self.delegateQueue];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"text/plain,text/html,application/xhtml+xml,application/xml,application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];

    self.requestTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf processFinished:data resp:response error:error];
    }];

    bool result = true;
    if (!self.requestTask)
    {
        result = false;
    }
    else
    {
        self.completion = completion;
        self.errorHandler = errorHandler;

        DDLogVerbose(@"Calling REST interface");
        [self.requestTask resume];
    }

    return result;
}

- (void) errorOccurred
{
    [super errorOccurred];
    if (self.errorHandler) {
        self.errorHandler();
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    @try {
        NSError *error = nil;
        self.resultJson = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                          options:0 error:&error];

        [self nilProperties];
        if (error || !self.resultJson) {
            self.loadError = error;
            [self errorOccurred];
        }
        else if (self.completion) {
            DDLogVerbose(@"Recovery code sent");

            // Deserialize important JSON data.
            NSNumber * statusCode = [PEXUtils getAsNumber:self.resultJson[@"statusCode"]];
            NSString * statusText = [PEXUtils getAsString:self.resultJson[@"statusText"]];
            NSNumber * validTo = [PEXUtils getAsNumber:self.resultJson[@"validTo"]];

            // Notify.
            if (self.completion){
                self.completion(statusCode, statusText, validTo);
            }
        }

    } @catch(NSException * ex) {
        DDLogError(@"Exception when loading products, %@", ex);
        [self errorOccurred];
    }
}

@end