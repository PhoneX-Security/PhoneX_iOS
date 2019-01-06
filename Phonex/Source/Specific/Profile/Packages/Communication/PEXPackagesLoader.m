//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPackagesLoader.h"
#import "PEXRestRequester_Protected.h"

#import "PEXConnectionUtils.h"
#import "PEXPackageDeserializer.h"
#import "PEXPaymentManager.h"
#import "PEXPackage.h"
#import "PEXUtils.h"

static NSString * S_PRODUCTS_REQUEST_URL_PATH = @"api/auth/products/available";

@interface PEXPackagesLoader ()

@property (nonatomic, copy) PEXProductsLoadFinished completion;
@property (nonatomic, copy) PEXProductsLoadFailed errorHandler;

@property (nonatomic) NSDictionary * resultJson;
@property (nonatomic) NSMutableDictionary * products;
@property (nonatomic) NSError * loadError;
@property (nonatomic) NSURLSessionDataTask * requestTask;
@end

@implementation PEXPackagesLoader {

}

- (bool) loadItemsCompletion: (PEXProductsLoadFinished)completion
                errorHandler: (PEXProductsLoadFailed)errorHandler
{
    self.products = [[NSMutableDictionary alloc] init];
    NSString * const urlString = [PEXConnectionUtils systemUrlClientCrtWithPath:S_PRODUCTS_REQUEST_URL_PATH];

    // Encode locale JSON as a parameter.
    NSString * locales = [[PEXUtils getPreferredLanguages] componentsJoinedByString:@","];
    NSURL * const url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?locales=%@",
                    urlString,
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

        DDLogVerbose(@"Starting to load package data from lic server");
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
            DDLogVerbose(@"Product data loaded, loading apple product info");
            NSArray *products = [PEXPackageDeserializer getPackagesFromJson:self.resultJson];

            NSInteger sortOrder = 0;
            for (PEXPackage *product in products) {
                if (product == nil || product.appleProductId == nil) {
                    DDLogError(@"Product not valid: %@", product);
                    continue;
                }

                product.sortOrder = sortOrder++;
                self.products[product.appleProductId] = product;
            }

            [self loadAppleProductInfo];
        }

    } @catch(NSException * ex) {
        DDLogError(@"Exception when loading products, %@", ex);
        [self errorOccurred];
    }
}

- (void) loadAppleProductInfo {
    if ([self.products count] == 0){
        if (self.completion){
            self.completion(self.products);
        }
        return;
    }

    PEXPaymentManager * pmgr = [PEXPaymentManager instance];
    NSMutableArray * appleProductIds = [[NSMutableArray alloc] init];
    for(PEXPackage * pkg in [self.products allValues]){
        [appleProductIds addObject:pkg.appleProductId];
    }

    WEAKSELF;
    RMSKProductsRequestSuccessBlock successBlock = ^(NSArray *products, NSArray *invalidIdentifiers) {
        DDLogVerbose(@"Products loaded");
        [weakSelf onAppleProductsLoaded:products invalidIdentifiers:invalidIdentifiers];
    };

    RMSKProductsRequestFailureBlock failureBlock = ^(NSError *error) {
        DDLogError(@"Could not load products, error: %@", error);
        weakSelf.loadError = error;
        [weakSelf errorOccurred];
    };

    // Request more info from apple.
    [pmgr getProductInfo:appleProductIds
            successBlock:successBlock
            failureBlock:failureBlock];
}

- (void) onAppleProductsLoaded: (NSArray *) products invalidIdentifiers: (NSArray *) invalidIdentifiers {
    DDLogVerbose(@"Apple product info loaded");
    for (NSString *invalidIdentifier in invalidIdentifiers) {
        DDLogError(@"Invalid product identifier: %@", invalidIdentifier);
        [self.products removeObjectForKey: invalidIdentifier];
    }

    // Process valid products, add localized title, price and the whole object.
    for(SKProduct * prod in products){
        DDLogVerbose(@"Product: %@, id: %@, title: %@", prod, prod.productIdentifier, prod.localizedTitle);
        PEXPackage * pkg = self.products[prod.productIdentifier];
        if (pkg == nil){
            DDLogError(@"Package was not found for product id: %@", prod.productIdentifier);
            continue;
        }

        pkg.localizedPrice = [RMStore localizedPriceOfProduct:prod];
        pkg.product = prod;
    }

    self.completion(self.products);
}

@end