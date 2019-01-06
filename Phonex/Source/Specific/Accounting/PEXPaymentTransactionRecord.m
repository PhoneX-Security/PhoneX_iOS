//
// Created by Dusan Klinec on 16.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPaymentTransactionRecord.h"

@interface PEXPaymentTransactionRecord () {

}

@property (nonatomic) SKPaymentTransaction * transaction;

@property (nonatomic) NSString * transactionId;
@property (nonatomic) NSDate * transactionDate;
@property (nonatomic) SKPaymentTransactionState transactionState;
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic) NSInteger quantity NS_AVAILABLE_IOS(3_0);

@end

@implementation PEXPaymentTransactionRecord {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.error = nil;
        self.queue = nil;
        self.receiptRefreshed = NO;
        self.verificationError = NO;
        self.isRmTransaction = YES;
    }

    return self;
}

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction {
    self = [self init];
    if (self) {
        self.transaction = transaction;
        [self applyTransaction];
    }

    return self;
}

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    self = [self init];
    if (self) {
        self.transaction = transaction;
        self.queue = queue;
        [self applyTransaction];
    }

    return self;
}

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue error:(NSError *)error {
    self = [self init];
    if (self) {
        self.transaction = transaction;
        self.queue = queue;
        self.error = error;
        [self applyTransaction];
    }

    return self;
}

+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue error:(NSError *)error {
    return [[self alloc] initWithTransaction:transaction queue:queue error:error];
}


+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue {
    return [[self alloc] initWithTransaction:transaction queue:queue];
}


+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction {
    return [[self alloc] initWithTransaction:transaction];
}

- (void) applyTransaction {
    if (self.transaction == nil){
        return;
    }

    self.transactionId = self.transaction.transactionIdentifier;
    self.transactionDate = self.transaction.transactionDate;
    self.transactionState = self.transaction.transactionState;
    self.transactionId = self.transaction.transactionIdentifier;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.error=%@", self.error];
    [description appendFormat:@", self.transaction=%@", self.transaction];
    [description appendFormat:@", self.queue=%@", self.queue];
    [description appendFormat:@", self.isRmTransaction=%d", self.isRmTransaction];
    [description appendFormat:@", self.receiptRefreshed=%d", self.receiptRefreshed];
    [description appendFormat:@", self.verificationError=%d", self.verificationError];
    [description appendFormat:@", self.transactionId=%@", self.transactionId];
    [description appendFormat:@", self.transactionDate=%@", self.transactionDate];
    [description appendFormat:@", self.transactionState=%ld", (long)self.transactionState];
    [description appendFormat:@", self.productIdentifier=%@", self.productIdentifier];
    [description appendFormat:@", self.quantity=%li", (long)self.quantity];
    [description appendString:@">"];
    return description;
}


@end