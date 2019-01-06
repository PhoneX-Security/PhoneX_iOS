//
// Created by Dusan Klinec on 15.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLicenseLoader.h"
#import "PEXRestRequester_Protected.h"

#import "PEXConnectionUtils.h"
#import "PEXPackageDeserializer.h"
#import "PEXPaymentManager.h"
#import "PEXPackage.h"
#import "PEXUtils.h"

static NSString * S_LICENSE_REQUEST_URL_PATH = @"api/auth/products/list-from-licenses";

@interface PEXLicenseLoader ()

@property (nonatomic, copy) PEXLicenseLoadFinished completion;
@property (nonatomic, copy) PEXLicenseLoadFailed errorHandler;
@property (nonatomic) NSArray * requestIds;

@property (nonatomic) NSDictionary * resultJson;
@property (nonatomic) NSMutableDictionary * licenses;
@property (nonatomic) NSError * loadError;
@property (nonatomic) NSURLSessionDataTask * requestTask;
@end

@implementation PEXLicenseLoader {

}

- (bool) loadItemsCompletion: (NSArray *) licenseIds
                  completion: (PEXLicenseLoadFinished)completion
                errorHandler: (PEXLicenseLoadFailed)errorHandler
{
    self.licenses = [[NSMutableDictionary alloc] init];
    NSString * const urlString = [PEXConnectionUtils systemUrlClientCrtWithPath:S_LICENSE_REQUEST_URL_PATH];

    // If request body is empty, exit immediately.
    if (licenseIds == nil || [licenseIds count] == 0){
        if (completion) {
            completion(self.licenses);
        }
        return NO;
    }

    // Encode locale JSON as a parameter.
    NSString * locales = [[PEXUtils getPreferredLanguages] componentsJoinedByString:@","];
    NSURL * const url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?ids=%@&locales=%@",
                                                                        urlString,
                                                                        [self encodeString:[licenseIds componentsJoinedByString:@","]],
                                                                        [self encodeString:locales]]];

    WEAKSELF;
    [self defaultTrustInit];
    [self defaultQueueInit];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[self defaultConfiguration] delegate:self delegateQueue:self.delegateQueue];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
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
        self.requestIds = licenseIds;

        DDLogVerbose(@"Starting to load license data from lic server");
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

        } else if (self.completion) {
            DDLogVerbose(@"License data loaded");

            // Re-key, NSNumber should be the key.
            for(id key in self.resultJson){
                NSNumber * numKey = [PEXUtils getAsNumber:key];
                NSDictionary * val = self.resultJson[key];
                if (numKey == nil){
                    DDLogError(@"License key id is nil, %@", key);
                    continue;
                }

                self.licenses[numKey] = val;
            }

            self.completion(self.licenses);
        }

    } @catch(NSException * ex) {
        DDLogError(@"Exception when loading products, %@", ex);
        [self errorOccurred];
    }
}

@end