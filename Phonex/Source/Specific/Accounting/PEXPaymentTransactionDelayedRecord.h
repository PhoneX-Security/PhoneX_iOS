//
// Created by Dusan Klinec on 15.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMStore.h"

@class SKPaymentTransaction;
@class PEXPaymentTransactionRecord;


@interface PEXPaymentTransactionDelayedRecord : NSObject
@property(nonatomic) SKPaymentTransaction * transaction;
@property(nonatomic, copy) RMSKPaymentTransactionFinishBlock finishBlock;
@property(nonatomic) NSInteger retryCount;

@property(nonatomic) PEXPaymentTransactionRecord * tsxRec;
@end