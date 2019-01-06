//
// Created by Dusan Klinec on 15.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPaymentTransactionDelayedRecord.h"
#import "PEXPaymentTransactionRecord.h"


@implementation PEXPaymentTransactionDelayedRecord {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.retryCount = 0;
    }

    return self;
}


@end