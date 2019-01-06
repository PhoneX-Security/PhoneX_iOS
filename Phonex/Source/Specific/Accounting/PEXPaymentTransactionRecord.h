//
// Created by Dusan Klinec on 16.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@class SKPaymentTransaction;

/**
 * Holder passed to the success/finish callbacks.
 */
@interface PEXPaymentTransactionRecord : NSObject
@property (nonatomic, readonly) SKPaymentTransaction * transaction;
@property (nonatomic) SKPaymentQueue * queue;
@property (nonatomic) NSError * error;
@property (nonatomic) BOOL isRmTransaction;
@property (nonatomic) BOOL receiptRefreshed;
@property (nonatomic) BOOL verificationError;

// Redundant, for copying sake.
@property (nonatomic, readonly) NSString * transactionId;
@property (nonatomic, readonly) NSDate * transactionDate;
@property (nonatomic, readonly) SKPaymentTransactionState transactionState;
@property (nonatomic, copy, readonly) NSString *productIdentifier;
@property (nonatomic, readonly) NSInteger quantity NS_AVAILABLE_IOS(3_0);

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction;
+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction;

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue;
+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue;

- (instancetype)initWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue error:(NSError *)error;

- (NSString *)description;
+ (instancetype)recordWithTransaction:(SKPaymentTransaction *)transaction queue:(SKPaymentQueue *)queue error:(NSError *)error;

@end
