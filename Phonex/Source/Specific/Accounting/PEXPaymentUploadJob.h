//
// Created by Dusan Klinec on 18.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXUploader.h"
#import "PEXPaymentUploadManager.h"

@class SKPaymentTransaction;
@class RMAppReceiptIAP;
@class PEXMultipartUploadStream;
@class PEXPaymentTransactionRecord;

@interface PEXPaymentUploadJob : NSObject
/**
 * Request related parameters.
 */
@property (nonatomic) NSString * user;
@property (nonatomic) NSString * guuid;
@property (nonatomic) NSString * tsxId;
@property (nonatomic) BOOL isReceiptReUpload;
@property (nonatomic) SKPaymentTransaction * transaction;
@property (nonatomic) RMAppReceiptIAP *purchase;
@property (nonatomic) NSString * receipt64;
@property (nonatomic) NSObject * recLock;
@property (nonatomic) PEXPaymentTransactionRecord * tsxRec;

@property (nonatomic) NSInteger retryCount;
@property (nonatomic) NSInteger currentRetry;

/**
 * Success / failure blocks
 */
@property (nonatomic, copy) PEXPaymentUploadFinishBlock finishBlock;

/**
 * Upload task internals.
 */
@property (nonatomic) NSURLSessionUploadTask * uploadTask;
@property (nonatomic) PEXMultipartUploadStream * uploadStream;
@property (nonatomic) NSString * boundary;
@property (nonatomic) NSMutableData * responseData;
@property(nonatomic) int64_t uploadLength;

/**
 * Upload result task.
 */
@property(nonatomic) NSInteger statusCode;
@property(nonatomic) BOOL securityError;
@property(nonatomic) NSError * error;
@property (nonatomic) NSString * jsonResponse;

- (instancetype)initWithUser:(NSString *)user guuid:(NSString *)guuid transaction:(SKPaymentTransaction *)transaction purchase:(RMAppReceiptIAP *)purchase receipt64:(NSString *)receipt64;

+ (instancetype)jobWithUser:(NSString *)user guuid:(NSString *)guuid transaction:(SKPaymentTransaction *)transaction purchase:(RMAppReceiptIAP *)purchase receipt64:(NSString *)receipt64;


@end