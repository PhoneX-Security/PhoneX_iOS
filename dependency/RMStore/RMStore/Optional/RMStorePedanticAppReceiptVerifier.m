//
// Created by Dusan Klinec on 21.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "RMStorePedanticAppReceiptVerifier.h"
#import "RMAppReceipt.h"
#import "RMStoreTransaction.h"

#ifndef WEAKSELF
#  define WEAKSELF __weak __typeof(self) weakSelf = self
#endif

#ifndef RMStoreLog
#if DEBUG
#define RMStoreLog(...) NSLog(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]);
#else
#define RMStoreLog(...)
#endif
#endif

NSString * const RMStorePedanticAppReceiptVerificationErrorDomain = @"RMStorePedanticAppReceiptVerificationErrorDomain";
const NSInteger RMStorePedanticReceiptVerificationError = -1;
const NSInteger RMStorePedanticTransactionNotFoundInReceipt = -2;

typedef enum RMStoreWaitResult {
    RMSTORE_WAIT_RESULT_FINISHED = 0,
    RMSTORE_WAIT_RESULT_CANCELLED = 1,
    RMSTORE_WAIT_RESULT_TIMEOUTED = 2
} RMStoreWaitResult;

// ---------------------------------------------
#pragma mark - PEXReceiptRefreshTask
// ---------------------------------------------

@interface RMStorePedanticReceiptRefreshTask : NSOperation
@property(nonatomic, weak) RMStorePedanticAppReceiptVerifier * verif;

@property(nonatomic) BOOL force;
@property(nonatomic) SKPaymentTransaction * tsx;
@property(nonatomic, copy) RMStoreSuccessBlock successBlock;
@property(nonatomic, copy) RMStoreFailureBlock failureBlock;
@property(nonatomic) dispatch_semaphore_t semaphore;
-(void) main;
@end

// ---------------------------------------------
#pragma mark - RMStorePedanticAppReceiptVerifier()
// ---------------------------------------------

@interface RMStorePedanticAppReceiptVerifier() {}
@property (nonatomic) NSDate * lastReceiptRefresh;
@end

// ---------------------------------------------
#pragma mark - RMStorePedanticAppReceiptVerifier implementation
// ---------------------------------------------

@implementation RMStorePedanticAppReceiptVerifier {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.useStrictPolicyAsDefault = NO;
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
       failure:(PEXReceiptVerifyFailureBlock)failureBlock
{
    return [self verify:skTsx
                 pError:nil
                receipt:receipt
                success:successBlock == nil ? nil : ^(RMAppReceiptIAP *purchase) {
                    if (successBlock){
                        successBlock();
                    }
                }
                failure:failureBlock];
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

    NSString * uploadTsxId = skTsx.transactionIdentifier;
    const BOOL receiptIsOk = [self receiptValidation: receipt];
    if (!receiptIsOk){
        RMStoreLog(@"Receipt seems invalid, sorry");

        NSError * error = [NSError errorWithDomain:RMStorePedanticAppReceiptVerificationErrorDomain
                                              code:RMStorePedanticReceiptVerificationError userInfo:@{}];
        [self setError: error toError:pError];

        if (failureBlock){
            failureBlock(error);
        }

        return NO;
    }

    // Parse transaction data.
    WEAKSELF;
    RMStoreTransaction * tsx = [[RMStoreTransaction alloc] initWithPaymentTransaction:skTsx];

    // Find transaction in the receipt.
    RMAppReceiptIAP * inAppPurchase = nil;
    RMAppReceiptIAP * originalPurchase = nil;
    NSInteger originalMatching = 0;

    for (RMAppReceiptIAP *purchase in receipt.inAppPurchases) {
        if ([purchase.transactionIdentifier isEqualToString:uploadTsxId]
                && [purchase.productIdentifier isEqualToString:tsx.productIdentifier])
        {
            inAppPurchase = purchase;
            break;
        }

        if ([purchase.transactionIdentifier isEqualToString:skTsx.originalTransaction.transactionIdentifier]
                && [purchase.productIdentifier isEqualToString:tsx.productIdentifier])
        {
            RMStoreLog(@"Original transaction matches %@ for tsxId: %@, purchase: %@",
                    skTsx.originalTransaction.transactionIdentifier, uploadTsxId, purchase);
            originalPurchase = purchase;
            originalMatching += 1;
        }
    }

    // Given transaction was not found in the current receipt.
    if (inAppPurchase == nil){
        RMStoreLog(@"Transaction not found in the receipt %@, failureNil: %d", uploadTsxId, failureBlock==nil);
        NSError * error = [NSError errorWithDomain:RMStorePedanticAppReceiptVerificationErrorDomain
                                              code:RMStorePedanticTransactionNotFoundInReceipt userInfo:@{}];
        [self setError: error toError:pError];

        if (failureBlock){
            failureBlock(error);
        }

        return NO;
    }

    [self setError: nil toError:pError];
    if (successBlock){
        successBlock(inAppPurchase);
    }

    return YES;
}

- (void)verifyTransactionStrict: (SKPaymentTransaction *)skTsx
                        success: (PEXReceiptVerifySuccessBlock) successBlock
                        failure: (PEXReceiptVerifyFailureBlock) failureBlock
{
    NSError * curError = nil;
    const BOOL verified = [self verify:skTsx pError:&curError success:successBlock failure:nil]; // failureBlock is nil intentionally. See below.
    if (verified) {
        return;
    }

    // Immediate verification failed, receipt has to be refreshed.
    // Only one receipt refresh can be done at time, so we have to queue requests
    WEAKSELF;
    RMStoreSuccessBlock successReceiptBlock = ^{
        [weakSelf verify:skTsx pError:nil success:successBlock failure:failureBlock];
    };

    RMStoreFailureBlock failureReceiptBlock = ^(NSError *error) {
        if (failureBlock) {
            failureBlock(error);
        }
    };

    RMStorePedanticReceiptRefreshTask * task = [[RMStorePedanticReceiptRefreshTask alloc] init];
    task.verif = self;
    task.tsx = skTsx;
    task.successBlock = successReceiptBlock;
    task.failureBlock = failureReceiptBlock;
    [self lazyInitQueue];
    [self.receiptRefreshQueue addOperation:task];
}

- (void)refreshReceiptOnSuccess:(RMStoreSuccessBlock)successBlock failure:(RMStoreFailureBlock)failureBlock forceRefresh:(BOOL)forceRefresh {
    RMStorePedanticReceiptRefreshTask * task = [[RMStorePedanticReceiptRefreshTask alloc] init];
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
    RMAppReceipt * receipt = [RMAppReceipt bundleReceipt];
    RMStoreLog(@"Receipt dump, app version: %@, bundleId: %@, expirationDate: %@",
    receipt.appVersion,
    receipt.bundleIdentifier,
    receipt.expirationDate);

    for (RMAppReceiptIAP *purchase in receipt.inAppPurchases) {
        RMStoreLog(@"ReceiptElement: %@", purchase);
    }
}

// ---------------------------------------------
#pragma mark - Verification from AppReceiptVerifier
// ---------------------------------------------

- (void)verifyTransaction:(SKPaymentTransaction*)transaction
                  success:(void (^)())successBlock
                  failure:(void (^)(NSError *error))failureBlock
{
    RMStoreLog(@"Soft TsxId: %@ verification", transaction.transactionIdentifier);
    RMAppReceipt *receipt = [RMAppReceipt bundleReceipt];
    BOOL verified = NO;

    if (self.useStrictPolicyAsDefault){
        verified = [self verify:transaction receipt:receipt success:successBlock failure:nil];

    } else {
        verified = [self verifyTransaction:transaction inReceipt:receipt success:successBlock failure:nil]; // failureBlock is nil intentionally. See below.
    }

    if (verified) return;

    // Apple recommends to refresh the receipt if validation fails on iOS.
    // Immediate verification failed, receipt has to be refreshed.
    // Only one receipt refresh can be done at time, so we have to queue requests
    WEAKSELF;
    RMStoreSuccessBlock successReceiptBlock = ^{
        RMAppReceipt *receiptx = [RMAppReceipt bundleReceipt];
        if (weakSelf.useStrictPolicyAsDefault){
            [weakSelf verify:transaction receipt:receiptx success:successBlock failure:failureBlock];
        } else {
            [weakSelf verifyTransaction:transaction inReceipt:receiptx success:successBlock failure:failureBlock]; // failureBlock is nil intentionally. See below.
        }
    };

    RMStoreFailureBlock failureReceiptBlock = ^(NSError *error) {
        [weakSelf failWithBlock:failureBlock error:error];

    };

    RMStorePedanticReceiptRefreshTask * task = [[RMStorePedanticReceiptRefreshTask alloc] init];
    task.verif = self;
    task.tsx = transaction;
    task.successBlock = successReceiptBlock;
    task.failureBlock = failureReceiptBlock;
    [self lazyInitQueue];
    [self.receiptRefreshQueue addOperation:task];
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

+ (BOOL)isDate:(NSDate *)a olderThan:(NSTimeInterval)b {
    NSTimeInterval intA = a == nil ? 0 : [a timeIntervalSince1970];
    NSTimeInterval cur = [[NSDate date] timeIntervalSince1970];
    return intA < (cur - b);
}

+ (int)waitWithCancellation:(NSOperation *)operation doneSemaphore:(dispatch_semaphore_t)sem
                semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout doRunLoop:(BOOL)doRunLoop
                cancelBlock:(BOOL (^)())cancelBlock
{
    NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
    for(;[loopUntil timeIntervalSinceNow] > 0;){
        int64_t semResult = dispatch_semaphore_wait(sem, semTime);
        if (semResult==0){
            // Semaphore acquired - return 0, wait is over.
            return RMSTORE_WAIT_RESULT_FINISHED;
        }

        if (doRunLoop){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        // If cancelled - cancel the whole queue.
        // Still has to wait on semaphore signaling.
        if (cancelBlock != nil && cancelBlock()){
            // Cancel background SOAP task, if non-nil.
            if (operation!=nil) {
                [operation cancel];
            }

            // Cancellation = 1;
            return RMSTORE_WAIT_RESULT_CANCELLED;
        }
    }

    // Loop apparently timeouted.
    return RMSTORE_WAIT_RESULT_TIMEOUTED;
}
@end

// ---------------------------------------------
#pragma mark - PEXReceiptRefreshTask
// ---------------------------------------------

/**
 * Delayed payment upload task.
 */
@implementation RMStorePedanticReceiptRefreshTask
- (instancetype)init {
    self = [super init];
    if (self) {
        self.force = NO;
    }

    return self;
}

- (void)main {
    WEAKSELF;

    // Optimalization: if receipt refresh was done a minute ago, do not refresh receipt.
    NSDate * lastRefresh = self.verif.lastReceiptRefresh;
    if (lastRefresh != nil && ![RMStorePedanticAppReceiptVerifier isDate:lastRefresh olderThan:60] && !self.force){
        RMStoreLog(@"Skipping receipt refresh, too recent: %@ for tsxId: %@", lastRefresh, self.tsx.transactionIdentifier);
        [self.verif.receiptDoneQueue addOperationWithBlock:self.successBlock];
        return;
    }

    self.semaphore = dispatch_semaphore_create(0);
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, 50 * 1000000ull);

    // Apple recommends to refresh the receipt if validation fails on iOS
    RMStoreLog(@"Starting refresh for tsxId: %@", self.tsx.transactionIdentifier);
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
    int waitRes =  [RMStorePedanticAppReceiptVerifier waitWithCancellation:nil doneSemaphore:self.semaphore
                                                               semWaitTime:tdeadline timeout:-1.0 doRunLoop:YES
                                                               cancelBlock:nil];

    RMStoreLog(@"Receipt waiting finished for tsxId: %@, res: %d", self.tsx.transactionIdentifier, waitRes);
}
@end