//
// Created by Dusan Klinec on 18.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPaymentUploadJob.h"
#import "RMAppReceipt.h"
#import "PEXMultipartUploadStream.h"
#import "PEXPaymentTransactionRecord.h"


@implementation PEXPaymentUploadJob {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.responseData = [[NSMutableData alloc] init];
        self.recLock = [[NSObject alloc] init];
        self.securityError = NO;
        self.isReceiptReUpload = NO;
        self.retryCount = 0;
        self.currentRetry = 0;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user guuid:(NSString *)guuid transaction:(SKPaymentTransaction *)transaction purchase:(RMAppReceiptIAP *)purchase receipt64:(NSString *)receipt64 {
    self = [self init];
    if (self) {
        self.user = user;
        self.guuid = guuid;
        self.transaction = transaction;
        self.purchase = purchase;
        self.receipt64 = receipt64;
    }

    return self;
}

+ (instancetype)jobWithUser:(NSString *)user guuid:(NSString *)guuid transaction:(SKPaymentTransaction *)transaction purchase:(RMAppReceiptIAP *)purchase receipt64:(NSString *)receipt64 {
    return [[self alloc] initWithUser:user guuid:guuid transaction:transaction purchase:purchase receipt64:receipt64];
}


@end