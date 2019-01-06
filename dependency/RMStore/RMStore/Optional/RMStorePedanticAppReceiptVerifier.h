//
// Created by Dusan Klinec on 21.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMStore.h"

@class SKPaymentTransaction;
@class RMAppReceiptIAP;
@class RMAppReceipt;

extern NSString * const RMStorePedanticAppReceiptVerificationErrorDomain;
extern const NSInteger RMStorePedanticReceiptVerificationError;
extern const NSInteger RMStorePedanticTransactionNotFoundInReceipt;

typedef void (^PEXReceiptVerifySuccessBlock)(RMAppReceiptIAP * purchase);
typedef void (^PEXReceiptVerifyFailureBlock)(NSError * error);

@interface RMStorePedanticAppReceiptVerifier : NSObject<RMStoreReceiptVerifier>
/**
 * Operation queue for receipt refresh, has to be serial.
 */
@property (nonatomic) NSOperationQueue * receiptRefreshQueue;

/**
 * Queue to perform verification / notification on after receipt refresh.
 */
@property (nonatomic) NSOperationQueue * receiptDoneQueue;

/**
 The value that will be used to validate the bundle identifier included in the app receipt. Given that it is possible to modify the app bundle in jailbroken devices, setting this value from a hardcoded string might provide better protection.
 @return The given value, or the app's bundle identifier by defult.
 */
@property (nonatomic, strong) NSString *bundleIdentifier;

/**
 The value that will be used to validate the bundle version included in the app receipt. Given that it is possible to modify the app bundle in jailbroken devices, setting this value from a hardcoded string might provide better protection.
 @return The given value, or the app's bundle version by defult.
 */
@property (nonatomic, strong) NSString *bundleVersion;

/**
 * If set to YES strict policy will be the default one when verifier protocol is called.
 * @default: NO
 */
@property (nonatomic) BOOL useStrictPolicyAsDefault;

- (instancetype)initWithReceiptRefreshQueue:(NSOperationQueue *)receiptRefreshQueue;
+ (instancetype)verifierWithReceiptRefreshQueue:(NSOperationQueue *)receiptRefreshQueue;

/**
 * Resets last receipt refresh time.
 */
- (void) resetLastReceiptRefresh;

/**
 * Synchronous receipt validation.
 * Verifies digital signature on the whole receipt, its structure.
 */
- (BOOL) receiptValidation;
- (BOOL) receiptValidation:(RMAppReceipt *)receipt;

/**
 * Synchronous transaction validation against receipt.
 * Strict form - transaction is valid only if the given product with given transaction ID is present in the receipt.
 */
- (BOOL) verify: (SKPaymentTransaction *) skTsx
         pError: (NSError **) pError
        success: (PEXReceiptVerifySuccessBlock) successBlock
        failure: (PEXReceiptVerifyFailureBlock) failureBlock;

- (BOOL) verify: (SKPaymentTransaction *) skTsx
         pError: (NSError **) pError
        receipt: (RMAppReceipt *) receipt
        success: (PEXReceiptVerifySuccessBlock) successBlock
        failure: (PEXReceiptVerifyFailureBlock) failureBlock;

- (BOOL) verify: (SKPaymentTransaction *) skTsx
        receipt: (RMAppReceipt *) receipt
        success: (void (^)()) successBlock
        failure: (PEXReceiptVerifyFailureBlock) failureBlock;

/**
 * General API for asynchronous verification.
 * If first verification fails, the receipt is refreshed and verification is tried again.
 */
- (void)verifyTransactionStrict: (SKPaymentTransaction *)skTsx
                        success: (PEXReceiptVerifySuccessBlock) successBlock
                        failure: (PEXReceiptVerifyFailureBlock) failureBlock;

/**
 * Default transaction verification for RMStore, not usign strict verification procedure.
 */
- (void)verifyTransaction: (SKPaymentTransaction *)skTsx
                  success: (void (^)()) successBlock
                  failure: (PEXReceiptVerifyFailureBlock) failureBlock;

/**
 * Thread safe API for receipt refresh. Receipt is being refreshed only in one thread.
 */
- (void)refreshReceiptOnSuccess:(RMStoreSuccessBlock)successBlock
                        failure:(RMStoreFailureBlock)failureBlock
                   forceRefresh:(BOOL) forceRefresh;
@end