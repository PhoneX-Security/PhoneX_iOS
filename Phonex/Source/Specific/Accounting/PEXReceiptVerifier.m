//
// Created by Dusan Klinec on 21.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXReceiptVerifier.h"
#import "RMAppReceipt.h"
#import "RMStoreTransaction.h"
#import "PEXPaymentManager.h"
#import "PEXUtils.h"
#import "PEXReceipt.h"
#import "PEXPaymentTransactionRecord.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXSOAPManager.h"
#import "PEXBase.h"

#ifndef WEAKSELF
#  define WEAKSELF __weak __typeof(self) weakSelf = self
#endif

// ---------------------------------------------
#pragma mark - PEXReceiptRefreshTask
// ---------------------------------------------

@interface PEXReceiptRefreshTask : NSOperation
@property(nonatomic, weak) PEXReceiptVerifier * verif;

@property(nonatomic) BOOL force;
@property(nonatomic) SKPaymentTransaction * tsx;
@property(nonatomic, copy) RMStoreSuccessBlock successBlock;
@property(nonatomic, copy) RMStoreFailureBlock failureBlock;
@property(nonatomic) dispatch_semaphore_t semaphore;
-(void) main;
@end

// ---------------------------------------------
#pragma mark - PEXReceiptVerifier()
// ---------------------------------------------

@interface PEXReceiptVerifier() {}
@property (nonatomic) NSDate * lastReceiptRefresh;
@end

// ---------------------------------------------
#pragma mark - PEXReceiptVerifier implementation
// ---------------------------------------------

@implementation PEXReceiptVerifier {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.useStrictPolicyAsDefault = NO;
        self.receiptCachingTime = 60;
    }

    return self;
}

- (instancetype)initWithReceiptRefreshQueue:(NSOperationQueue *)receiptRefreshQueue {
    self = [self init];
    if (self) {
        self.receiptRefreshQueue = receiptRefreshQueue;
    }

    return self;
}

+ (instancetype)verifierWithReceiptRefreshQueue:(NSOperationQueue *)receiptRefreshQueue {
    return [[self alloc] initWithReceiptRefreshQueue:receiptRefreshQueue];
}

-(void) lazyInitQueue {
    if (self.receiptDoneQueue != nil && self.receiptRefreshQueue != nil){
        return;
    }

    @synchronized (self) {
        if (self.receiptRefreshQueue == nil){
            self.receiptRefreshQueue = [[NSOperationQueue alloc] init];
            self.receiptRefreshQueue.maxConcurrentOperationCount = 1;
            self.receiptRefreshQueue.name = @"receiptRefresh";
        }

        if (self.receiptDoneQueue == nil){
            self.receiptDoneQueue = [[NSOperationQueue alloc] init];
            self.receiptDoneQueue.maxConcurrentOperationCount = 1;
            self.receiptDoneQueue.name = @"receiptDone";
        }
    }
}

-(void) setError: (NSError *) error toError: (NSError **) pError{
    if (pError == NULL){
        return;
    }

    *pError = error;
}

- (BOOL) receiptValidation {
    return [self receiptValidation:[RMAppReceipt bundleReceipt]];
}

- (BOOL) receiptValidation:(RMAppReceipt *)receipt {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSError *receiptError;
    BOOL isPresent = [receiptURL checkResourceIsReachableAndReturnError:&receiptError];
    if (!isPresent) {
        DDLogError(@"Receipt validation failed @ %@", receiptURL);
        return NO;
    }

    // Our validation.
    PEXReceipt * pexReceipt = [PEXReceipt receiptWithUrl:receiptURL];
    const BOOL signatureOK = [pexReceipt verify];
    if (!signatureOK){
        DDLogError(@"Receipt validation step 1 failed");
        return NO;
    }

    // Another one - with parsing.
    if (receipt == nil){
        receipt = [RMAppReceipt bundleReceipt];
    }

    return [self verifyAppReceipt:receipt];
}

- (BOOL)verify:(SKPaymentTransaction *)skTsx
        pError:(NSError **)pError
       success:(PEXReceiptVerifySuccessBlock)successBlock
       failure:(PEXReceiptVerifyFailureBlock)failureBlock
{
    return [self verify:skTsx
                 pError:pError
                receipt:[RMAppReceipt bundleReceipt]
                success:successBlock
                failure:failureBlock];
}

- (BOOL)verify:(SKPaymentTransaction *)skTsx
       receipt:(RMAppReceipt *)receipt
       success:(void (^)())successBlock
       failure:(void (^)(NSError *error))failureBlock
{
    return [self verify:skTsx
                 pError:nil
                receipt:receipt
                success:successBlock == nil ? nil : ^(PEXReceiptVerifySuccessResult *purchase) {
                    if (successBlock){
                        successBlock();
                    }
                }
                failure:failureBlock == nil ? nil : ^(PEXReceiptVerifySuccessResult *purchase, NSError *error) {
                    if (failureBlock){
                        failureBlock(error);
                    }
                }];
}


- (BOOL) verify: (SKPaymentTransaction *) skTsx
         pError: (NSError **) pError
        receipt: (RMAppReceipt *) receipt
        success: (PEXReceiptVerifySuccessBlock) successBlock
        failure: (PEXReceiptVerifyFailureBlock) failureBlock
{
    if (receipt == nil){
        receipt = [RMAppReceipt bundleReceipt];
    }

    PEXReceiptVerifySuccessResult * vRes = [[PEXReceiptVerifySuccessResult alloc] init];

    NSString * uploadTsxId = [PEXPaymentManager getUploadTsxId:skTsx];
    const BOOL receiptIsOk = [self receiptValidation: receipt];
    if (!receiptIsOk){
        DDLogError(@"Receipt seems invalid, sorry");

        NSError * error = [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionReceiptVerificationError userInfo:@{}];
        [self setError: error toError:pError];

        if (failureBlock){
            failureBlock(vRes, error);
        }

        return NO;
    }

    // Parse transaction data.
    RMStoreTransaction * tsx = [[RMStoreTransaction alloc] initWithPaymentTransaction:skTsx];

    // Find transaction in the receipt.
    RMAppReceiptIAP * inAppPurchase = nil;
    RMAppReceiptIAP * originalPurchase = nil;
    RMAppReceiptIAP * datePurchase = nil;
    NSInteger originalMatching = 0;
    NSInteger dateMatching = 0;

    for (RMAppReceiptIAP *purchase in receipt.inAppPurchases) {
        if (inAppPurchase == nil
                && [purchase.transactionIdentifier isEqualToString:uploadTsxId]
                && [purchase.productIdentifier isEqualToString:tsx.productIdentifier])
        {
            inAppPurchase = purchase;
        }

        // In case of failed transaction this info may provide insight to the verification problem.
        if ([purchase.transactionIdentifier isEqualToString:skTsx.originalTransaction.transactionIdentifier]
                && [purchase.productIdentifier isEqualToString:tsx.productIdentifier])
        {
            DDLogVerbose(@"Verification: original transaction matches %@ for tsxId: %@, purchase: %@",
                    skTsx.originalTransaction.transactionIdentifier, uploadTsxId, [PEXPaymentManager strInApp:purchase]);
            originalPurchase = purchase;
            originalMatching += 1;
        }

        // Test purchase date + product id in receipt.
        if ([purchase.purchaseDate isEqualToDate:skTsx.transactionDate]
                && [purchase.productIdentifier isEqualToString:tsx.productIdentifier])
        {
            DDLogVerbose(@"Verification: date transaction matchess %@ for tsxId: %@, purchase %@",
                    purchase.purchaseDate, uploadTsxId, [PEXPaymentManager strInApp:purchase]);
            datePurchase = purchase;
            dateMatching += 1;
        }
    }

    vRes.purchase = inAppPurchase;
    vRes.originalPurchase = originalPurchase;
    vRes.originalPurchaseNum = originalMatching;
    vRes.datePurchase = datePurchase;
    vRes.datePurchaseNum = dateMatching;

    // Given transaction was not found in the current receipt.
    if (inAppPurchase == nil){
        DDLogVerbose(@"Transaction not found in the receipt %@, failureNil: %d, originalMatching: %d, dateMatching: %d",
                uploadTsxId, failureBlock==nil, (int)originalMatching, (int)dateMatching);

        NSError * error = [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionNotFoundInReceipt userInfo:@{}];
        [self setError: error toError:pError];

        if (failureBlock){
            failureBlock(vRes, error);
        }

        return NO;
    }

    [self setError: nil toError:pError];

    if (successBlock){
        successBlock(vRes);
    }

    return YES;
}

- (void)verifyTransactionStrict: (SKPaymentTransaction *)skTsx
                        success: (PEXReceiptVerifySuccessBlock) successBlock
                        failure: (PEXReceiptVerifyFailureBlock) failureBlock
{
    WEAKSELF;
    dispatch_block_t verifyBlock = ^{ @autoreleasepool {
        NSError *curError = nil;
        const BOOL verified = [weakSelf verify:skTsx pError:&curError success:successBlock failure:nil]; // failureBlock is nil intentionally. See below.
        if (verified) {
            return;
        }

        // Immediate verification failed, receipt has to be refreshed.
        // Only one receipt refresh can be done at time, so we have to queue requests
        RMStoreSuccessBlock successReceiptBlock = ^{
            [weakSelf verify:skTsx pError:nil success:successBlock failure:failureBlock];
        };

        RMStoreFailureBlock failureReceiptBlock = ^(NSError *error) {
            if (failureBlock) {
                failureBlock(nil, error);
            }
        };

        PEXReceiptRefreshTask *task = [[PEXReceiptRefreshTask alloc] init];
        task.verif = weakSelf;
        task.tsx = skTsx;
        task.successBlock = successReceiptBlock;
        task.failureBlock = failureReceiptBlock;
        [weakSelf lazyInitQueue];
        [weakSelf.receiptRefreshQueue addOperation:task];
    }};

    [self lazyInitQueue];
    if (self.verifyQueue == nil){
        verifyBlock();

    } else {
        [self.verifyQueue addOperationWithBlock:verifyBlock];
    }
}

- (void)refreshReceiptOnSuccess:(RMStoreSuccessBlock)successBlock failure:(RMStoreFailureBlock)failureBlock forceRefresh:(BOOL)forceRefresh {
    PEXReceiptRefreshTask * task = [[PEXReceiptRefreshTask alloc] init];
    task.verif = self;
    task.tsx = nil;
    task.force = forceRefresh;
    task.successBlock = successBlock;
    task.failureBlock = failureBlock;
    [self lazyInitQueue];
    [self.receiptRefreshQueue addOperation:task];
}

- (void)resetLastReceiptRefresh {
    self.lastReceiptRefresh = nil;
}

/**
 * Debugging method that logs all the in-app purchases in the receipt file.
 */
-(void) dumpReceipt {
    if (![PEXUtils isDebug]){
        return;
    }

    RMAppReceipt * receipt = [RMAppReceipt bundleReceipt];
    DDLogVerbose(@"Receipt dump, app version: %@, bundleId: %@, expirationDate: %@",
    receipt.appVersion,
    receipt.bundleIdentifier,
    receipt.expirationDate);

    for (RMAppReceiptIAP *purchase in receipt.inAppPurchases) {
        DDLogVerbose(@"ReceiptElement: %@", [PEXPaymentManager strInApp:purchase]);
    }
}

// ---------------------------------------------
#pragma mark - Verification from AppReceiptVerifier
// ---------------------------------------------

- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                  success:(void (^)())successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    WEAKSELF;
    dispatch_block_t verifyBlock = ^{ @autoreleasepool {
        DDLogVerbose(@"Soft TsxId: %@ verification, strict: %d", transaction.transactionIdentifier, weakSelf.useStrictPolicyAsDefault);

        RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
        BOOL verified = NO;

        if (weakSelf.useStrictPolicyAsDefault) {
            verified = [weakSelf verify:transaction receipt:receipt success:successBlock failure:nil];

        } else {
            verified = [weakSelf verifyTransaction:transaction inReceipt:receipt success:successBlock failure:nil]; // failureBlock is nil intentionally. See below.
        }

        if (verified) return;

        // Apple recommends to refresh the receipt if validation fails on iOS.
        // Immediate verification failed, receipt has to be refreshed.
        // Only one receipt refresh can be done at time, so we have to queue requests
        RMStoreSuccessBlock successReceiptBlock = ^{
            RMAppReceipt *receiptx = [RMAppReceipt bundleReceipt];
            if (weakSelf.useStrictPolicyAsDefault) {
                [weakSelf verify:transaction receipt:receiptx success:successBlock failure:failureBlock];
            } else {
                [weakSelf verifyTransaction:transaction inReceipt:receiptx success:successBlock failure:failureBlock]; // failureBlock is nil intentionally. See below.
            }
        };

        RMStoreFailureBlock failureReceiptBlock = ^(NSError *error) {
            [weakSelf failWithBlock:failureBlock error:error];

        };

        PEXReceiptRefreshTask *task = [[PEXReceiptRefreshTask alloc] init];
        task.verif = weakSelf;
        task.tsx = transaction;
        task.successBlock = successReceiptBlock;
        task.failureBlock = failureReceiptBlock;
        [weakSelf lazyInitQueue];
        [weakSelf.receiptRefreshQueue addOperation:task];
    }};

    [self lazyInitQueue];
    if (self.verifyQueue == nil){
        verifyBlock();

    } else {
        [self.verifyQueue addOperationWithBlock:verifyBlock];
    }
}

#pragma mark - Properties

- (NSString*)bundleIdentifier
{
    if (!_bundleIdentifier)
    {
        return [[NSBundle mainBundle] bundleIdentifier];
    }
    return _bundleIdentifier;
}

- (NSString*)bundleVersion
{
    if (!_bundleVersion)
    {
#if TARGET_OS_IPHONE
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
#else
        return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#endif
    }
    return _bundleVersion;
}

#pragma mark - Private

- (BOOL)verifyAppReceipt:(RMAppReceipt*)receipt
{
    if (!receipt) return NO;

    if (![receipt.bundleIdentifier isEqualToString:self.bundleIdentifier]) return NO;

    if (![receipt.appVersion isEqualToString:self.bundleVersion]) return NO;

    if (![receipt verifyReceiptHash]) return NO;

    return YES;
}

- (BOOL)verifyTransaction:(SKPaymentTransaction*)transaction
                inReceipt:(RMAppReceipt*)receipt
                  success:(void (^)())successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    const BOOL receiptVerified = [self verifyAppReceipt:receipt];
    if (!receiptVerified)
    {
        [self failWithBlock:failureBlock message:NSLocalizedStringFromTable(@"The app receipt failed verification", @"RMStore", nil)];
        return NO;
    }
    SKPayment *payment = transaction.payment;
    const BOOL transactionVerified = [receipt containsInAppPurchaseOfProductIdentifier:payment.productIdentifier];
    if (!transactionVerified)
    {
        [self failWithBlock:failureBlock message:NSLocalizedStringFromTable(@"The app receipt does not contain the given product", @"RMStore", nil)];
        return NO;
    }
    if (successBlock)
    {
        successBlock();
    }
    return YES;
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock message:(NSString*)message
{
    NSError *error = [NSError errorWithDomain:RMStoreErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : message}];
    [self failWithBlock:failureBlock error:error];
}

- (void)failWithBlock:(void (^)(NSError *error))failureBlock error:(NSError*)error
{
    if (failureBlock)
    {
        failureBlock(error);
    }
}
@end

// ---------------------------------------------
#pragma mark - PEXReceiptRefreshTask
// ---------------------------------------------

/**
 * Delayed payment upload task.
 */
@implementation PEXReceiptRefreshTask
- (instancetype)init {
    self = [super init];
    if (self) {
        self.force = NO;
    }

    return self;
}

- (void)main {
    WEAKSELF;

    // Optimization: if receipt refresh was done a minute ago, do not refresh receipt.
    NSDate * lastRefresh = self.verif.lastReceiptRefresh;
    if (lastRefresh != nil && ![PEXUtils isDate:lastRefresh olderThan: self.verif.receiptCachingTime] && !self.force){
        DDLogVerbose(@"Skipping receipt refresh, too recent: %@ for tsxId: %@", lastRefresh, self.tsx.transactionIdentifier);
        [self.verif.receiptDoneQueue addOperationWithBlock:self.successBlock];
        return;
    }

    self.semaphore = dispatch_semaphore_create(0);
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 50 * 1000000ull);

    // Apple recommends to refresh the receipt if validation fails on iOS
    DDLogVerbose(@"Starting refresh for tsxId: %@", self.tsx.transactionIdentifier);
    [[RMStore defaultStore] refreshReceiptOnSuccess:^{
        weakSelf.verif.lastReceiptRefresh = [NSDate date];
        RMStoreSuccessBlock successBlock = weakSelf.successBlock;

        [weakSelf.verif.receiptDoneQueue addOperationWithBlock: ^{
            [weakSelf.verif dumpReceipt];
            if (successBlock){
                successBlock();
            }
        }];

        dispatch_semaphore_signal(weakSelf.semaphore);

    } failure:^(NSError *error) {
        RMStoreFailureBlock failureBlock = weakSelf.failureBlock;
        [weakSelf.verif.receiptDoneQueue addOperationWithBlock:^{
            if (failureBlock) {
                failureBlock(error);
            }
        }];

        dispatch_semaphore_signal(weakSelf.semaphore);

    }];

    // Wait for completion - semaphore indication.
    int waitRes =  [PEXSOAPManager waitWithCancellation:nil doneSemaphore:self.semaphore
                                            semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                            cancelBlock:nil];

    DDLogVerbose(@"Receipt waiting finished for tsxId: %@, res: %d", self.tsx.transactionIdentifier, waitRes);
}
@end

// ---------------------------------------------
#pragma mark - PEXReceiptVerifySuccessResult
// ---------------------------------------------

@implementation PEXReceiptVerifySuccessResult
- (BOOL)verified {
    return self.purchase != nil;
}

- (BOOL)verifiedDate {
    return self.datePurchase != nil;
}

@end
