//
// Created by Dusan Klinec on 03.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPaymentManager.h"
#import "PEXMessageDigest.h"
#import "PEXReceipt.h"
#import "RMStore.h"
#import "RMStoreAppReceiptVerifier.h"
#import "PEXPaymentTransactionDelayedRecord.h"
#import "PEXUtils.h"
#import "PEXCryptoUtils.h"
#import "RMStoreTransaction.h"
#import "PEXPaymentTransactionRecord.h"
#import "RMAppReceipt.h"
#import "PEXConcurrentHashMap.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXPaymentRestoreRecord.h"
#import "PEXService.h"
#import "PEXConnectivityChange.h"
#import "PEXApplicationStateChange.h"
#import "PEXPaymentTransactionDelayedRecord.h"
#import "PEXPaymentTransactionRecord.h"
#import "PEXPaymentUploadJob.h"
#import "PEXAccountingLogUpdaterTask.h"
#import "PEXReceiptVerifier.h"
#import "PEXLicenceManager.h"
#import "PEXSOAPResult.h"
#import "PEXLicenceCheckTask.h"

// ---------------------------------------------
#pragma mark - Definitions
// ---------------------------------------------

NSString* const PEXTransactionErrorDomain = @"PEXTransactionErrorDomain";
int PEXTransactionUploadError = 1;
int PEXTransactionReceiptVerificationError = 2;
int PEXTransactionNotFoundInReceipt = 3;
int PEXTransactionCannotBuy = 4;

NSString* const PEXTransactionRestoreErrorDomain = @"PEXTransactionRestoreErrorDomain";
int PEXTransactionRestoreCannotBuy = -1;
int PEXTransactionRestoreTooEarly = -2;
int PEXTransactionRestoreAlreadyRunning = -3;

NSString* const RMSKPaymentTransactionRecord = @"RMSKPaymentTransactionRecord";
NSString* const RMSKPaymentTransactionRecovered = @"RMSKPaymentTransactionRecovered";
NSString* const RMSKPaymentTransactionCommitted = @"RMSKPaymentTransactionCommitted";
NSString* const RMSKPaymentTransactionUploadFailed = @"RMSKPaymentTransactionUploadFailed";

NSString* const RMSKReceiptUploadFinished = @"RMSKReceiptUploadFinished";
NSString* const RMSKReceiptUploadFailed = @"RMSKReceiptUploadFailed";

// ---------------------------------------------
#pragma mark - PEXPaymentUploadTask
// ---------------------------------------------

@interface PEXPaymentDelayedUploadTask : NSOperation
@property(nonatomic, weak) PEXPaymentManager * pmgr;
-(void) main;
@end

// ---------------------------------------------
#pragma mark - PEXLogUploadTask
// ---------------------------------------------

@interface PEXAccountingLogUploadTask : NSOperation
@property(nonatomic, weak) PEXPaymentManager * pmgr;
-(void) main;
@end

// ---------------------------------------------
#pragma mark - PEXPaymentManager()
// ---------------------------------------------

@interface PEXPaymentManager() {}
/**
 * Manager dedicated for uploading payments to the server.
 */
@property(nonatomic) PEXPaymentUploadManager * uploadManager;

/**
 * ConcurrentHashMap<transactionId -> uploader>.
 * Uploaders has to be hold somewhere (ARC).
 */
@property(nonatomic) PEXConcurrentHashMap * uploaders;
@property(nonatomic) PEXConcurrentHashMap * receiptUploaders;

/**
 * ConcurrentHashMap<transactionId -> productId>.
 * Stores all currently pending purchases of the product.
 * Used to avoid situations where user wants to buy the same product which was bought and for which transaction
 * was not yet finished. In this case StoreKit stops payment transaction as the product is already bought and
 * user will be provided it for free. StoreKit does not invoke any delegate method.
 */
@property(nonatomic) PEXConcurrentHashMap * pendingProductsPayments;

/**
 * YES if there is active registration to observers (after login).
 */
@property(nonatomic) BOOL registered;

/**
 * YES if default payment queue observer was installed.
 */
@property(nonatomic) BOOL observerInstalled;

/**
 * Array of transactions that occurred from app start till user login.
 * They can be processed after user has logged in.
 */
@property(nonatomic) NSMutableArray * delayedTransactionEvents;

/**
 * List of the transaction records that were marked as purchased, but server upload failed.
 * Upload is invoked on connectivity change and application state change to foreground.
 */
@property(nonatomic) PEXConcurrentLinkedList * delayedPaymentTransactionsUpload;

/**
 * Transaction verification queue.
 */
@property(nonatomic) NSOperationQueue *opqueueTsxVerif;

/**
* Operation queue for delayed transaction upload tasks
*/
@property(nonatomic) NSOperationQueue *opqueueDelayed;
@property(nonatomic) int runningDelayedUploads;
@property(nonatomic) int failedDelayedUploads;

/**
 * Operation queue for log upload task.
 */
@property(nonatomic) NSOperationQueue *opqueueLogs;

/**
 * Cache of the product IDs that are handled by RMStore module.
 * When app starts, RMStore is not active as the payments were not made through this module
 * so the local observer takes an action.
 */
@property(nonatomic) NSCache * productIdHandledCache;

/**
 * Serialized queue for receipt refresh task.
 */
@property(nonatomic) NSOperationQueue *receiptRefreshQueue;

/**
 * Our custom strict verifier.
 */
@property(nonatomic) PEXReceiptVerifier *strictVerifier;

/**
 * Transaction restoration status info.
 */
@property (nonatomic) PEXPaymentRestoreRecord * restoreRec;
@property (nonatomic) NSDate * lastRestore;
@end

// ---------------------------------------------
#pragma mark - PEXPaymentManager implementation
// ---------------------------------------------

@implementation PEXPaymentManager {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploaders = [[PEXConcurrentHashMap alloc] initWithQueueName:@"payment.uploaders"];
        self.receiptUploaders = [[PEXConcurrentHashMap alloc] initWithQueueName:@"payment.receipt.uploaders"];
        self.delayedTransactionEvents = [[NSMutableArray alloc] init];
        self.productIdHandledCache = [[NSCache alloc] init];
        self.delayedPaymentTransactionsUpload = [[PEXConcurrentLinkedList alloc] initWithQueueName:@"payment.delayedTsx"];
        self.pendingProductsPayments = [[PEXConcurrentHashMap alloc] initWithQueueName:@"payment.pending"];
        self.registered = NO;
        self.observerInstalled = NO;
        self.shouldRestoreAllTransactions = NO;
        self.runningDelayedUploads = 0;
        self.failedDelayedUploads = 0;

        self.opqueueDelayed = [[NSOperationQueue alloc] init];
        self.opqueueDelayed.maxConcurrentOperationCount = 1;
        self.opqueueDelayed.name = @"delayedTsxUpload";

        self.opqueueLogs = [[NSOperationQueue alloc] init];
        self.opqueueLogs.maxConcurrentOperationCount = 1;
        self.opqueueLogs.name = @"accLogsUpload";

        self.opqueueTsxVerif = [[NSOperationQueue alloc] init];
        self.opqueueTsxVerif.maxConcurrentOperationCount = 1;
        self.opqueueTsxVerif.name = @"tsxVerif";

        self.receiptRefreshQueue = [[NSOperationQueue alloc] init];
        self.receiptRefreshQueue.maxConcurrentOperationCount = 1;
        self.receiptRefreshQueue.name = @"receiptRefresh";

        self.strictVerifier = [[PEXReceiptVerifier alloc] initWithReceiptRefreshQueue:self.receiptRefreshQueue];
        self.strictVerifier.receiptDoneQueue = self.opqueueTsxVerif;
        self.strictVerifier.verifyQueue = self.opqueueTsxVerif;

        self.uploadManager = [[PEXPaymentUploadManager alloc] init];
        self.restoreRec = [[PEXPaymentRestoreRecord alloc] init];

        [RMStore defaultStore].receiptVerifier = self.strictVerifier;
        [RMStore defaultStore].transactionRestorer = self;
    }

    return self;
}

+ (PEXPaymentManager *)instance {
    static PEXPaymentManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

+ (void)registerForDelayed {
    [[self instance] registerForDelayed];
}

- (void)registerForDelayed {
    if (self.registered){
        DDLogError(@"Invalid registration state");
        return;
    }

    if (self.observerInstalled){
        DDLogError(@"Observer already installed");
        return;
    }

    DDLogVerbose(@"Registering for delayed transactions");
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    self.observerInstalled = YES;
}

- (void)doRegister {
    self.registered = YES;
    if (!self.observerInstalled) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.observerInstalled = YES;

    } else {
        if (![[PEXService instance] isInBackground]) {
            [self dumpDelayedTransactions];
        }

    }

    // Register for new presence notification.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];

    // Register on app state changes - on app becomes active.
    [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];
}

- (void)doUnregister {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    self.registered = NO;
    self.observerInstalled = NO;
    [self.productIdHandledCache removeAllObjects];
    [self.delayedTransactionEvents removeAllObjects];
    [self.delayedPaymentTransactionsUpload removeAllObjects];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)updatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;
    self.uploadManager.privData = privData;
    [self.uploadManager prepareSecurity:privData];
    [self.uploadManager prepareSession];
}

- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil || conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    // Try to re-upload purchased transactions on connectivity up.
    PEXService * svc = [PEXService instance];
    if (conChange.connection == PEX_CONN_GOES_UP && !svc.isInBackground){
        DDLogVerbose(@"Connectivity goes up, dumping background tsx");
        [self triggerNewDelayedUpload];
        [self triggerLogsUpload];
    }
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change == nil){
        DDLogError(@"Illegal notification state");
        return;
    }

    // Try to reupload if connectivity is working.
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        DDLogVerbose(@"App state active, dump delayed tsxs");
        [self dumpDelayedTransactions];
        [self dumpDelayedNonUploadedTransactions];
        [self triggerLogsUpload];
    }
}

// ---------------------------------------------
#pragma mark - Transaction & product API
// ---------------------------------------------

/**
 * Returns hashed username for fraud-detection.
 */
-(NSString *) getApplicationUsername {
    NSData * dt = [PEXMessageDigest md5Message:[NSString stringWithFormat:@"phonexInApp:%@", _privData.username]];
    return [PEXMessageDigest bytes2hex:dt];
}

- (NSString *)getSubscriptionManagementUrlString {
    // https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Subscriptions.html#//apple_ref/doc/uid/TP40008267-CH7-SW6
    return @"itms-apps://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions";
}

-(void) getProductInfo: (NSArray *) productIds
             successBlock: (RMSKProductsRequestSuccessBlock) successBlock
             failureBlock: (RMSKProductsRequestFailureBlock) failureBlock
{
    RMSKProductsRequestSuccessBlock successBlockEx = ^(NSArray *products, NSArray *invalidIdentifiers) {
        DDLogVerbose(@"Products loaded");
        if (successBlock != nil){
            successBlock(products, invalidIdentifiers);
        }
    };

    RMSKProductsRequestFailureBlock failureBlockEx = ^(NSError *error) {
        DDLogError(@"Product load error");
        if (failureBlock != nil){
            failureBlock(error);
        }
    };

    // Do the request in an async way.
    [[RMStore defaultStore] requestProducts:[NSSet setWithArray:productIds]
                                    success:successBlockEx
                                    failure:failureBlockEx];
}

- (BOOL)isPaymentPending:(NSString *)productIdentifier {
    NSDictionary * dict = [self.pendingProductsPayments copyData];
    if (dict == nil || [dict count] == 0){
        return NO;
    }

    for(NSString *tsxId in dict){
        NSString * prodId = dict[tsxId];
        if ([productIdentifier isEqualToString:prodId]){
            return YES;
        }
    }

    return NO;
}

-(void)addPayment:(NSString *)productIdentifier
     successBlock:(PEXPaymentSuccessBlock)successBlock
     failureBlock: (PEXPaymentFailureBlock) failureBlock
{
    WEAKSELF;
    RMSKPaymentTransactionSuccessFinishBlock succBlockEx = ^(SKPaymentTransaction *transaction, RMSKPaymentTransactionFinishBlock finishBlock) {
        PEXPaymentTransactionRecord * tsxRec = [PEXPaymentTransactionRecord recordWithTransaction:transaction];
        [weakSelf.opqueueTsxVerif addOperationWithBlock:^{
            const BOOL handledSuccessfully = [weakSelf transactionPurchasedHandler:tsxRec
                                                                      successBlock:successBlock
                                                                      failureBlock: failureBlock
                                                                       finishBlock: finishBlock];
            if (!handledSuccessfully && failureBlock != nil){
                failureBlock(tsxRec);
            }
        }];
    };

    RMSKPaymentTransactionFailureFinishBlock failBlockEx = ^(SKPaymentTransaction *transaction, NSError *error, RMSKPaymentTransactionFinishBlock finishBlock) {
        PEXPaymentTransactionRecord * tsxRec = [PEXPaymentTransactionRecord recordWithTransaction:transaction];
        [weakSelf.opqueueTsxVerif addOperationWithBlock:^{
            DDLogError(@"Transaction failed: %@, error: %@", [PEXPaymentManager strTransaction:transaction], error);
            if (failureBlock != nil) {
                failureBlock(tsxRec);
            }

            // Finish transaction.
            finishBlock();
        }];
    };

    [self.productIdHandledCache setObject:@(1) forKey:productIdentifier];

    // Add payment with
    [self.opqueueTsxVerif addOperationWithBlock:^{
        [[RMStore defaultStore] addPayment:productIdentifier
                                      user:[self getApplicationUsername]
                             successFinish:succBlockEx
                             failureFinish:failBlockEx];
    }];
}

// ---------------------------------------------
#pragma mark - Transaction processing logic
// ---------------------------------------------

/**
 * Unverified is used for delayed transactions, when our custom handler was used to receive transaction,
 * not the RM one.
 *
 * After receipt verification control calls back transactionPurchasedHandler.
 */
- (void) unverifiedTransactionPurchasedHandler:(SKPaymentTransaction *)transaction
                                         queue:(SKPaymentQueue *)queue
                                           rec:(PEXPaymentRestoreRecord *) rec
                                       success:(PEXPaymentSuccessBlock) success
                                       failure:(PEXPaymentSuccessBlock) failure
{
    WEAKSELF;
    [self.strictVerifier verifyTransaction:transaction success:^{
        DDLogVerbose(@"Transaction verification passed, handling verified transaction");

        // As the unverified transaction handler bypasses RM logic, we want to preserve same flow w.r.t. notifications.
        // Finish blocks are not used.
        PEXPaymentSuccessBlock successBlock = ^(PEXPaymentTransactionRecord *tx) {
            DDLogVerbose(@"Unverified transaction finished successfully %@", tx);

            // Add transaction as processed so receipt uploader ignores it.
            [rec addTsxId:tx.transactionId];

            if (success){
                success(tx);
            }

            [[RMStore defaultStore] postNotificationWithName:RMSKPaymentTransactionFinished
                                                 transaction:tx.transaction
                                              userInfoExtras:@{RMSKPaymentTransactionRecovered : @(1),
                                                      RMSKPaymentTransactionRecord : tx}];
        };

        PEXPaymentFailureBlock failureBlock = ^(PEXPaymentTransactionRecord * tx) {
            DDLogError(@"Transaction failed: %@, error: %@", [PEXPaymentManager strTransaction:tx.transaction], tx.error);

            if (failure){
                failure(tx);
            }

            [[RMStore defaultStore] postNotificationWithName:RMSKPaymentTransactionFailed
                                                 transaction:tx.transaction
                                              userInfoExtras:@{RMSKPaymentTransactionRecovered : @(1),
                                                      RMSKPaymentTransactionRecord : tx}];
        };

        dispatch_block_t finishBlock = ^{
            DDLogVerbose(@"Finishing transaction from unverif.");
            [queue finishTransaction:transaction];
        };

        PEXPaymentTransactionRecord * tsxRec = [PEXPaymentTransactionRecord recordWithTransaction:transaction];
        tsxRec.isRmTransaction = NO;

        [weakSelf transactionPurchasedHandler:tsxRec
                                 successBlock:successBlock
                                 failureBlock:failureBlock
                                  finishBlock:finishBlock];

    } failure:^(NSError *error) {
        DDLogError(@"Transaction verification failed: %@", error);
    }];
}

/**
 * Main transaction handler, handling transaction state: purchased.
 * After proper receipt verification, transaction is uploaded to the server and finished if everything goes fine.
 */
- (BOOL) transactionPurchasedHandler: (PEXPaymentTransactionRecord *)tsxRec
                        successBlock: (PEXPaymentSuccessBlock) successBlock
                        failureBlock: (PEXPaymentFailureBlock) failureBlock
                         finishBlock: (RMSKPaymentTransactionFinishBlock) finishBlock {
    WEAKSELF;
    const BOOL isRestore = tsxRec != nil && tsxRec.transactionState == SKPaymentTransactionStateRestored;
    DDLogVerbose(@"Tsx: %@", [PEXPaymentManager strTransaction:tsxRec.transaction]);

    // If uploader already exists, do nothing.
    NSString *uploadTsxId = [PEXPaymentManager getUploadTsxId:tsxRec.transaction];
    if ([_uploaders get:uploadTsxId] != nil) {
        DDLogError(@"Transaction uploader already exists for: %@, restore: %d", uploadTsxId, isRestore);
        return NO;
    }

    RMStoreTransaction *tsx = [[RMStoreTransaction alloc] initWithPaymentTransaction:tsxRec.transaction];
    DDLogVerbose(@"Tsx: %@, consumed: %d, prodId: %@, txDate: %@, tsxId: %@, originalTsxId: %@, updTsx: %@, restore: %d",
            tsx, tsx.consumed, tsx.productIdentifier, tsx.transactionDate, tsx.transactionIdentifier,
            tsxRec.transaction.originalTransaction.transactionIdentifier,
            uploadTsxId,
            isRestore);

    // Transaction verification, success block.
    PEXReceiptVerifySuccessBlock verifySuccessBlock = ^(PEXReceiptVerifySuccessResult *purchase) {
        DDLogVerbose(@"TsxVerification passed for tsx: %@", tsxRec.transactionId);
        const BOOL started = [weakSelf onVerificationPassed:tsxRec
                                                   purchase:purchase
                                               successBlock:successBlock
                                               failureBlock:failureBlock
                                                finishBlock:finishBlock];
        if (!started && failureBlock != nil){
            failureBlock(tsxRec);
        }
    };

    // Transaction verification, failure block.
    PEXReceiptVerifyFailureBlock verifyFailureBlock = ^(PEXReceiptVerifySuccessResult * purchase, NSError *error) {
        // Verification failed totally, even after receipt refresh.
        DDLogError(@"TsxVerification failed for tsx: %@, error: %@", uploadTsxId, error);
        tsxRec.error = [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionNotFoundInReceipt userInfo:@{}];
        tsxRec.verificationError = YES;

        if (finishBlock){
            finishBlock();
        }

        if (failureBlock) {
            failureBlock(tsxRec);
        }
    };

    [self.strictVerifier verifyTransactionStrict:tsxRec.transaction
                                         success:verifySuccessBlock
                                         failure:verifyFailureBlock];

    // Asynchronous processing.
    return YES;
}

/**
 * Called when transaction verification against to receipt has finished with success.
 * Starts transaction upload to the server.
 */
-(BOOL) onVerificationPassed: (PEXPaymentTransactionRecord *)tsxRec
                    purchase: (PEXReceiptVerifySuccessResult *) verifyResult
                successBlock: (PEXPaymentSuccessBlock) successBlock
                failureBlock: (PEXPaymentFailureBlock) failureBlock
                 finishBlock: (RMSKPaymentTransactionFinishBlock) finishBlock
{
    WEAKSELF;
    NSString *uploadTsxId = [PEXPaymentManager getUploadTsxId:tsxRec.transaction];
    RMStoreTransaction *tsx = [[RMStoreTransaction alloc] initWithPaymentTransaction:tsxRec.transaction];
    RMAppReceiptIAP * inAppPurchase = verifyResult.purchase;

    // Receipt is uploaded to the server.
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString * receiptBase64 = [receiptData base64EncodedStringWithOptions:0];

    PEXUserPrivate * const privateData = [[PEXAppState instance] getPrivateData];
    PEXPaymentUploadJob * updJob = [PEXPaymentUploadJob jobWithUser:privateData.username
                                                              guuid:[[PEXReceipt getUUIDData] base64EncodedStringWithOptions:0]
                                                        transaction:tsxRec.transaction
                                                           purchase:inAppPurchase
                                                          receipt64:receiptBase64];
    updJob.tsxRec = tsxRec;
    updJob.tsxId = uploadTsxId;
    updJob.retryCount = 2;

    // When async upload finishes, check the result and finish the transaction.
    updJob.finishBlock = ^(PEXPaymentUploadJob *job, NSString *response, NSError *error) {
        [weakSelf onUploaderFinishes:job
                         transaction:tsxRec
                        successBlock:successBlock
                        failureBlock:failureBlock
                         finishBlock:finishBlock];
    };

    @synchronized (self) {
        // If uploader already exists, do nothing.
        if ([_uploaders get:uploadTsxId] != nil){
            DDLogError(@"Transaction uploader already exists for: %@, 2", uploadTsxId);
            return NO;
        }

        [_uploaders put:updJob key:uploadTsxId async:NO];
        [_pendingProductsPayments put:tsx.productIdentifier key:uploadTsxId async:YES];
    }

    // Start async transaction data upload.
    DDLogVerbose(@"Starting upload task for prod[%@], tsxId: %@", [PEXPaymentManager strInApp:inAppPurchase], tsx.transactionIdentifier);
    [self.uploadManager addUploadJob:updJob];
    return YES;
}

/**
 * Called when transaction uploader finishes its processing.
 */
-(void) onUploaderFinishes: (PEXPaymentUploadJob *) job
               transaction: (PEXPaymentTransactionRecord *) tsxRec
        successBlock: (PEXPaymentSuccessBlock) successBlock
        failureBlock: (PEXPaymentFailureBlock) failureBlock
         finishBlock: (RMSKPaymentTransactionFinishBlock) finishBlock
{
    BOOL isok = YES;
    BOOL doEnqueue = NO;
    NSString * uploadTsxId = [PEXPaymentManager getUploadTsxId:tsxRec.transaction];

    // Upload does not need to be hold for any longer after this method finishes.
    [self.uploaders remove:uploadTsxId async:YES];

    if (job == nil){
        DDLogError(@"Upload failed");
        tsxRec.error = [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionUploadError userInfo:nil];
        isok = NO;
    }

    if (isok && (job.error != nil || job.jsonResponse == nil)){
        DDLogError(@"Error in uploading transaction: %@", job.error);
        // Add to deferred transaction local list, when internet connection is UP again, try upload again
        // or when app is turned to active state and internet connection is working.
        tsxRec.error = job.error;
        isok = NO;
        doEnqueue = YES;
    }

    // Check json response.
    if (isok){
        DDLogVerbose(@"Transaction tsxId %@ upload result: %@", tsxRec.transactionId, job.jsonResponse);
        isok = [self wasUploadSuccessful:job pError:nil];

        // Response invalid - enqueue.
        if (!isok){
            tsxRec.error = [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionUploadError userInfo:nil];
            doEnqueue = YES;
        }
    }

    // Finish transaction when everything is OK.
    if (isok) {
        if (finishBlock != nil) {
            DDLogVerbose(@"Going to finish transaction %@", tsxRec.transactionId);
            finishBlock();
        }

        if (successBlock != nil){
            successBlock(tsxRec);
        }

        // Remove from pending requests since the payment has finished right now.
        @synchronized (self) {
            [_pendingProductsPayments remove:tsxRec.transactionId async:YES];
        }

        // Post notification, transaction finished, commited.
        [[RMStore defaultStore] postNotificationWithName:RMSKPaymentTransactionFinished
                                             transaction:tsxRec.transaction
                                          userInfoExtras:@{RMSKPaymentTransactionCommitted : @(1)}];
    } else {
        if (failureBlock != nil){
            failureBlock(tsxRec);
        }

        // Post notification, transaction finished, upload failed.
        [[RMStore defaultStore] postNotificationWithName:RMSKPaymentTransactionFailed
                                             transaction:tsxRec.transaction
                                          userInfoExtras:@{RMSKPaymentTransactionUploadFailed : @(1)}];
    }

    [self.uploaders remove:uploadTsxId async:YES];

    if (doEnqueue){
        [self enqueuePurchasedTransaction:tsxRec finishBlock:finishBlock];
    }
}

+(NSString *) getUploadTsxId: (SKPaymentTransaction *) tsx {
    if (tsx == nil){
        return nil;
    }

    return tsx.transactionIdentifier;
}

-(BOOL) wasUploadSuccessful: (PEXPaymentUploadJob *) job pError: (NSError **) pError{
    BOOL isok = NO;
    @try {
        NSError *error = nil;
        NSDictionary * resultJson = [NSJSONSerialization JSONObjectWithData:[job.jsonResponse dataUsingEncoding:NSUTF8StringEncoding]
                                                                    options:0 error:&error];

        if (resultJson == nil || error != nil) {
            DDLogError(@"Could not parse returned json, error: %@", error);
            if (error != nil && pError != nil) {
                *pError = error;
            }

            isok = NO;

        } else {
            NSNumber * responseCode = [PEXUtils getAsNumber:resultJson[@"responseCode"]];
            if (responseCode == nil || [responseCode integerValue] != 0){
                DDLogError(@"Error response code returned from license server payment call %@", responseCode);
                isok = NO;

            } else {
                DDLogVerbose(@"Payment persisted on lic server");
                isok = YES;
            }
        }

    } @catch(NSException * ex){
        DDLogError(@"Exception in validating purchase %@", ex);
        isok = NO;
    }

    return isok;
}

-(void) processTransaction: (SKPaymentTransaction *) transaction
                     queue: (SKPaymentQueue *)queue
                       rec: (PEXPaymentRestoreRecord *) rec
                   success: (PEXPaymentSuccessBlock) success
                   failure: (PEXPaymentSuccessBlock) failure
{
    WEAKSELF;
    PEXPaymentTransactionRecord * tsxRec = [PEXPaymentTransactionRecord recordWithTransaction:transaction];
    tsxRec.isRmTransaction = NO;

    switch (transaction.transactionState) {
        // Call the appropriate custom method
        case SKPaymentTransactionStatePurchasing:
            DDLogVerbose(@"Transaction purchasing, tsxId: %@", transaction.transactionIdentifier);
            if (success){
                success(tsxRec);
            }
            break;

        case SKPaymentTransactionStateDeferred:
            DDLogVerbose(@"Transaction deferred, tsxId: %@", transaction.transactionIdentifier);
            if (success){
                success(tsxRec);
            }
            break;

        case SKPaymentTransactionStatePurchased: {
            // Unfinished Transaction was recovered by StoreKit, RMStore did not recognize this one.
            DDLogVerbose(@"Transaction purchased, tsxId: %@", transaction.transactionIdentifier);
            [self.opqueueTsxVerif addOperationWithBlock:^{
                [weakSelf unverifiedTransactionPurchasedHandler:transaction queue:queue rec:rec success:success failure:failure];
            }];
        }
            break;

        case SKPaymentTransactionStateRestored: {
            // Unfinished Transaction was recovered by StoreKit, RMStore did not recognize this one.
            DDLogVerbose(@"Transaction restored, tsxId: %@", transaction.transactionIdentifier);
            if (success){
                success(tsxRec);
            }
        }
            break;

        case SKPaymentTransactionStateFailed:
            DDLogVerbose(@"Transaction failed, tsxId: %@", transaction.transactionIdentifier);
            if (success){
                success(tsxRec);
            }
            break;

        default:
            if (success){
                success(tsxRec);
            }
            break;
    }
}

/**
 * Entry point for processing all transactions going out of RMStore.
 */
- (void)processTransactions:(NSArray *)transactions queue: (SKPaymentQueue *)queue {
    if (transactions == nil || [transactions count] == 0){
        return;
    }

    NSInteger purchasedTransactionsProcessed = 0;
    NSInteger restoredTransactionsProcessed = 0;
    PEXPaymentRestoreRecord * rec = [[PEXPaymentRestoreRecord alloc] init];
    rec.transactionsToHandle = [transactions count];

    // Compute statistics so we know whether to start uploader or not.
    for(SKPaymentTransaction * transaction in transactions) {
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            purchasedTransactionsProcessed += 1;
        } else if (transaction.transactionState == SKPaymentTransactionStateRestored) {
            restoredTransactionsProcessed += 1;
        }
    }

    // Completion handlers for transaction handling.
    WEAKSELF;
    void(^txHandledHandler)(PEXPaymentTransactionRecord *) = ^(PEXPaymentTransactionRecord *tsxRec) {
        [rec incTsxHandled];
        if (rec.transactionsToHandle > rec.transactionsHandled){
            return;
        }

        DDLogVerbose(@"All unverified transactions have been processed.");
        if (purchasedTransactionsProcessed == 0){
            return;
        }

        // If there have been some transactions processed by our engine
        DDLogVerbose(@"Unverified transaction processed, purchased: %d, restored: %d. Going to upload receipt.",
                (int) purchasedTransactionsProcessed, (int) restoredTransactionsProcessed);

        // Receipt re-upload.
        // As we use serial queue receipt re-upload should happen after all transactions are processed.
        [weakSelf.opqueueTsxVerif addOperationWithBlock:^{
            [weakSelf receiptReUpload:rec
                              success:^{
                                  DDLogVerbose(@"Receipt upload in unverified block successful");
                              }
                              failure:^(NSError *error) {
                                  DDLogError(@"Receipt upload failed in unverified block, error: %@", error);
                              }];
        }];
    };

    // Transaction processing one-by-one.
    for(SKPaymentTransaction * transaction in transactions){
        // Process individual transaction.
        [self processTransaction:transaction
                           queue:queue
                             rec:rec
                         success:txHandledHandler
                         failure:txHandledHandler];
    }
}

// ---------------------------------------------
#pragma mark - Delayed transactions
// ---------------------------------------------

/**
 * Inserts given purchased transaction to delayed transaction list.
 */
-(void) enqueuePurchasedTransaction: (PEXPaymentTransactionRecord *) tsxRec finishBlock: (RMSKPaymentTransactionFinishBlock) finishBlock {
    PEXPaymentTransactionDelayedRecord * tsxRecDelayed = [[PEXPaymentTransactionDelayedRecord alloc] init];
    tsxRecDelayed.transaction = tsxRec.transaction;
    tsxRecDelayed.finishBlock = finishBlock;
    tsxRecDelayed.tsxRec = tsxRec;

    [self.delayedPaymentTransactionsUpload pushBack:tsxRecDelayed async:YES];
    DDLogVerbose(@"Enqueueing transaction %@", tsxRec.transaction.transactionIdentifier);
}

-(void)triggerNewDelayedUpload {
    self.failedDelayedUploads = 0;
    [self dumpDelayedNonUploadedTransactions];
}

/**
 * Dumps delayed transaction in a default dispatch queue.
 */
-(void)dumpDelayedNonUploadedTransactions {
    WEAKSELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PEXPaymentManager * pmgr = weakSelf;
        NSUInteger opCount = [pmgr.opqueueDelayed operationCount];
        if (opCount >= 1 || [pmgr.delayedPaymentTransactionsUpload count] == 0){
            return;
        }

        // Submit new worker task.
        PEXPaymentDelayedUploadTask *task = [[PEXPaymentDelayedUploadTask alloc] init];
        task.pmgr = pmgr;

        DDLogVerbose(@"Starting new delayed upload task. QueueSize: %u", [pmgr.delayedPaymentTransactionsUpload count]);
        [pmgr.opqueueDelayed addOperation:task];
    });
}

/**
 * If connectivity is UP, pops one transaction from the queue and adds for processing.
 */
-(void)dumpDelayedNonUploadedTransactionsInternal {
    PEXService * svc = [PEXService instance];
    if (![svc isConnectivityWorking]){
        return;
    }

    const unsigned queueSize = [self.delayedPaymentTransactionsUpload count];
    for(unsigned iterations = 0; ![self.delayedPaymentTransactionsUpload isEmpty]; iterations++) {
        @synchronized (self) {
            if (self.runningDelayedUploads >= 1){
                DDLogVerbose(@"Too many upload tasks running, not going to start new upload");
                return;
            }
        }

        PEXPaymentTransactionDelayedRecord *rec = [self.delayedPaymentTransactionsUpload popFront];
        if (rec == nil) {
            break;
        }

        rec.retryCount += 1;

        // Global retry count too high?
        @synchronized (self) {
            if (self.failedDelayedUploads > 5){
                DDLogVerbose(@"Global failed count too high, %d", self.failedDelayedUploads);
                return;
            }
        }

        // Retry count too big, move to the end, exit, wait for new event.
        if (rec.retryCount >= 2) {
            DDLogVerbose(@"Retry count too high for transaction: %@, stopping.", rec.transaction.transactionIdentifier);
            rec.retryCount = 0;
            [self.delayedPaymentTransactionsUpload pushBack:rec async:YES];

            // Iterate over the whole queue.
            if (iterations >= queueSize){
                return;
            } else {
                continue;
            }
        }

        const PEXPaymentSuccessBlock successBlock = ^(PEXPaymentTransactionRecord *transaction) {
            DDLogVerbose(@"Success dumping delayed transaction %@, retry: %d",
                    transaction.transaction.transactionIdentifier, (int)rec.retryCount);

            @synchronized (self) {
                self.runningDelayedUploads -= 1;
                self.failedDelayedUploads -= 1;
            }
            [self dumpDelayedNonUploadedTransactions];
        };

        const PEXPaymentFailureBlock failureBlock = ^(PEXPaymentTransactionRecord *transaction) {
            DDLogVerbose(@"Failure dumping delayed transaction %@, error: %@, retry: %d",
                    transaction.transaction.transactionIdentifier, transaction.error, (int)rec.retryCount);

            @synchronized (self) {
                self.runningDelayedUploads -= 1;
                self.failedDelayedUploads += 1;
            }

            // Re-enqueue to the end, increased retry count.
            [self.delayedPaymentTransactionsUpload pushBack:rec async:YES];
            [self dumpDelayedNonUploadedTransactions];
        };

        // Process
        DDLogVerbose(@"Going to dump delayed transaction %@", rec.transaction.transactionIdentifier);
        const BOOL uploadEnqueued = [self transactionPurchasedHandler:rec.tsxRec
                                                         successBlock:successBlock
                                                         failureBlock:failureBlock
                                                          finishBlock:rec.finishBlock];
        if (!uploadEnqueued){
            DDLogError(@"Unable to enqueue upload task: %@", rec.tsxRec);
            [self.delayedPaymentTransactionsUpload pushBack:rec async:YES];
            continue;
        }

        @synchronized (self) {
            self.runningDelayedUploads += 1;
        }

        // Only one transaction.
        break;
    }
}

/**
 * Goes through all stored transaction updates that observer collected in a time period from the initial queue observer
 * registration to the user login. After user login we are able to process transactions normally.
 */
-(void) dumpDelayedTransactions{
    PEXService * svc = [PEXService instance];
    if (![svc isConnectivityWorking]){
        return;
    }

    NSArray * delayed = [self.delayedTransactionEvents copy];
    [self.delayedTransactionEvents removeAllObjects];

    for(SKPaymentTransaction * transaction in delayed) {
        DDLogVerbose(@"Delayed SKTransaction %@", [PEXPaymentManager strTransaction:transaction]);
    }

    WEAKSELF;
    [self.opqueueTsxVerif addOperationWithBlock:^{
        [weakSelf processTransactions:delayed queue:[SKPaymentQueue defaultQueue]];
    }];
}

// ---------------------------------------------
#pragma mark - Payment restoration
// ---------------------------------------------

- (void)restorePayment:(PEXPaymentRestoreSuccessBlock)successBlock failureBlock:(PEXPaymentRestoreFailureBlock)failureBlock {
    // Cannot make payments -> do nothing.
    if (![RMStore canMakePayments]){
        DDLogError(@"User is not able to make payments, cannot restore payments");
        PEXPaymentRestoreRecord * tmprec = [self.restoreRec copy];
        tmprec.error = [NSError errorWithDomain:PEXTransactionRestoreErrorDomain code:PEXTransactionRestoreCannotBuy userInfo:@{}];
        if (failureBlock){
            failureBlock(self.restoreRec);
        }

        return;
    }

    // Only one running restoration is allowed.
    // Warning, this is not a thread-safe check.
    if (self.restoreRec.restoreInProgress){
        DDLogInfo(@"Restoration is already in progress");
        PEXPaymentRestoreRecord * tmprec = [self.restoreRec copy];
        tmprec.error = [NSError errorWithDomain:PEXTransactionRestoreErrorDomain code:PEXTransactionRestoreAlreadyRunning userInfo:@{}];
        if (failureBlock){
            failureBlock(tmprec);
        }

        return;
    }

    // As restoration is also server-demanding process, allow restoration each minute.
    if (![PEXUtils isDate:self.lastRestore olderThan:60]){
        DDLogInfo(@"Restoration is too early, previous: %@", self.lastRestore);
        PEXPaymentRestoreRecord * tmprec = [self.restoreRec copy];
        tmprec.error = [NSError errorWithDomain:PEXTransactionRestoreErrorDomain code:PEXTransactionRestoreTooEarly userInfo:@{}];
        tmprec.tooEarly = YES;
        if (failureBlock){
            failureBlock(tmprec);
        }

        return;
    }

    [self.restoreRec reset];
    self.restoreRec.restoreInProgress = YES;

    // At first, refresh receipt.
    WEAKSELF;
    [self.strictVerifier refreshReceiptOnSuccess:^{
        DDLogVerbose(@"Receipt refreshed");
        weakSelf.restoreRec.restoreReceiptOK = YES;

        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRefreshReceiptFinished object:self userInfo:@{}];

        // Receipt refresh was performed, now restore all transactions.
        [weakSelf restoreTransactions:weakSelf.restoreRec
                         successBlock:^(PEXPaymentRestoreRecord *rec) {
                             weakSelf.lastRestore = [NSDate date];
                             if (successBlock){
                                 successBlock(rec);
                             }
                         }
                         failureBlock:^(PEXPaymentRestoreRecord *rec) {
                             weakSelf.lastRestore = [NSDate date];
                             if (failureBlock){
                                 failureBlock(rec);
                             }
                         }];

    } failure:^(NSError *error) {
        DDLogError(@"Receipt refresh failed %@", error);
        weakSelf.restoreRec.restoreReceiptOK = NO;
        weakSelf.restoreRec.error = error;
        if (failureBlock){
            failureBlock(weakSelf.restoreRec);
        }
        weakSelf.restoreRec.restoreInProgress = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRefreshReceiptFailed object:self userInfo:@{}];

    } forceRefresh: YES];
}

/**
 * Called during restoration process after receipt was refreshed.
 * Calls transaction restoration procedure on the RMStore causing StoreKit to replay
 * all transactions to its observer. Restored transactions are handler by our restorer in the callback below,
 * uploading them on the server.
 */
-(void) restoreTransactions: (PEXPaymentRestoreRecord*) restoreRec
               successBlock: (PEXPaymentRestoreSuccessBlock)successBlock
               failureBlock: (PEXPaymentRestoreFailureBlock)failureBlock
{
    WEAKSELF;
    RMStore * store = [RMStore defaultStore];

    // Restore transactions -> upload receipt -> fetch policy
    // Success & failure block for upload procedure.
    PEXPaymentRestoreSuccessBlock uploadSuccessBlock = ^(PEXPaymentRestoreRecord *rec) {
        // We do this when transaction was marked as purchased, and upload either succeeded or failed.
        // Refresh license, pass this success block
        [weakSelf refreshLicenseInfoAfterDelay:20.0
                                       success:^{
                                           if (successBlock){
                                               successBlock(restoreRec);
                                           }
                                           restoreRec.licenseRefreshOK = YES;
                                           weakSelf.restoreRec.restoreInProgress = NO;
                                       }
                                       failure:^(NSError *error) {
                                           if (failureBlock){
                                               failureBlock(rec);
                                           }
                                           restoreRec.licenseRefreshOK = NO;
                                           weakSelf.restoreRec.restoreInProgress = NO;
                                       }];
    };

    PEXPaymentRestoreFailureBlock uploadFailureBlock = ^(PEXPaymentRestoreRecord *rec) {
        if (failureBlock){
            failureBlock(rec);
        }
        weakSelf.restoreRec.restoreInProgress = NO;
    };

    // Success block for restore.
    // Called when all transactions have been processed.
    // Valid receipt in-app purchases should be uploaded now.
    void (^restoreSuccessBlock)(NSArray *transactions) = ^(NSArray *transactions) {
        DDLogVerbose(@"Restore transaction passed, tsxs: %u", (unsigned) [transactions count]);
        restoreRec.restoreTransactionOK = YES;
        restoreRec.transactions = transactions;
        NSMutableSet * set = [[NSMutableSet alloc] init];
        for(SKPaymentTransaction * tsx in transactions){
            [set addObject:tsx.transactionIdentifier];
        }

        restoreRec.transactionIdentifiers = set;
        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFinished object:self userInfo:@{}];

        // We do this when transaction was marked as purchased, and upload either succeeded or failed.
        // Now start receipt re-upload.
        [weakSelf reUploadReceipt:restoreRec
                     successBlock:uploadSuccessBlock
                     failureBlock:uploadFailureBlock];
    };

    // Failure block for restore.
    void (^restoreFailureBlock)(NSError *error) = ^(NSError *error) {
        DDLogError(@"Restore transaction failed with error %@", error);
        restoreRec.restoreTransactionOK = NO;
        restoreRec.error = error;
        if (failureBlock){
            failureBlock(restoreRec);
        }

        weakSelf.restoreRec.restoreInProgress = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKRestoreTransactionsFailed object:self userInfo:@{}];
    };

    // Call restoration on the queue.
    if (self.shouldRestoreAllTransactions) {
        [store restoreTransactionsOfUser:[self getApplicationUsername]
                               onSuccess:restoreSuccessBlock
                                 failure:restoreFailureBlock];
    } else {
        DDLogVerbose(@"Transactions restoration skipped");
        restoreSuccessBlock(@[]);
    }
}

/**
 * Receipt re-uploading code, part of the restoration process.
 * Code parses receipt and uploads all non-expired records fro the receipt to the server.
 * Configures success and failure blocks for new asynchronous receipt reupload.
 */
-(void) reUploadReceipt: (PEXPaymentRestoreRecord*) restoreRec
               successBlock: (PEXPaymentRestoreSuccessBlock)successBlock
               failureBlock: (PEXPaymentRestoreFailureBlock)failureBlock
{
    WEAKSELF;
    dispatch_block_t uploadSuccessBlock = ^{
        DDLogVerbose(@"Receipt reupload successful");
        restoreRec.receiptUploadOK = YES;

        // We do this when transaction was marked as purchased, and upload either succeeded or failed.
        if (successBlock){
            successBlock(restoreRec);
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKReceiptUploadFinished object:self userInfo:@{}];
    };

    void (^uploadFailureBlock)(NSError *error) = ^(NSError *error) {
        DDLogError(@"Recept reupload failed with error %@", error);
        restoreRec.receiptUploadOK = NO;
        restoreRec.error = error;
        if (failureBlock){
            failureBlock(restoreRec);
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:RMSKReceiptUploadFailed object:self userInfo:@{}];
    };

    // Start upload process on the background.
    [self.opqueueTsxVerif addOperationWithBlock:^{
        [weakSelf receiptReUpload: restoreRec success:uploadSuccessBlock failure:uploadFailureBlock];
    }];
}

/**
 * Receipt re-upload code.
 */
- (void) receiptReUpload: (PEXPaymentRestoreRecord*) restoreRec
                        success: (dispatch_block_t) success
                        failure: (void(^)(NSError *error)) failure
{
    WEAKSELF;
    NSMutableArray * inAppToUpload = [[NSMutableArray alloc] init];

    // Select only relevant up-to-date purchases for upload.
    RMAppReceipt * receipt = [RMAppReceipt bundleReceipt];
    for (RMAppReceiptIAP *purchase in receipt.inAppPurchases) {
        if (purchase == nil || purchase.productIdentifier == nil){
            continue;
        }

        // Do not upload expired record, useless.
        if (purchase.subscriptionExpirationDate != nil && [PEXUtils isDate:purchase.subscriptionExpirationDate olderThan:0]){
            continue;
        }

        // If transaction is being processed as a part of current restoration, skip.
        if (restoreRec
                && [restoreRec.transactionIdentifiers containsObject:purchase.transactionIdentifier]
                && !self.shouldRestoreAllTransactions)
        {
            continue;
        }

        [inAppToUpload addObject:purchase];
        DDLogVerbose(@"Receipt ToUpload: %@", [PEXPaymentManager strInApp:purchase]);
    }

    // Finish if nothing to re-upload.
    restoreRec.receiptToReupload = [inAppToUpload count];
    if (restoreRec.receiptToReupload == 0){
        DDLogVerbose(@"Receipt upload: nothing to upload");
        if (success){
            success();
        }

        return;
    }

    // Receipt is uploaded to the server.
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *receiptURL = [mainBundle appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receiptBase64 = [receiptData base64EncodedStringWithOptions:0];
    PEXUserPrivate *const privateData = [[PEXAppState instance] getPrivateData];
    NSString * guuid = [[PEXReceipt getUUIDData] base64EncodedStringWithOptions:0];

    // For each purchase start a separate upload job.
    for (RMAppReceiptIAP *purchase in inAppToUpload) {
        PEXPaymentUploadJob *updJob = [[PEXPaymentUploadJob alloc] init];
        updJob.user = privateData.username;
        updJob.guuid = guuid;
        updJob.purchase = purchase;
        updJob.receipt64 = receiptBase64;
        updJob.tsxId = purchase.transactionIdentifier;
        updJob.isReceiptReUpload = YES;
        updJob.retryCount = 2;

        // When async upload finishes, check the result and finish the transaction.
        updJob.finishBlock = ^(PEXPaymentUploadJob *job, NSString *response, NSError *error) {
            [weakSelf onReceiptTsxUploadFinishes:job
                                      restoreRec:restoreRec
                                        purchase:purchase
                                         success:success
                                         failure:failure];
        };

        @synchronized (self) {
            // If uploader already exists, do nothing.
            if ([_receiptUploaders get:updJob.tsxId] != nil) {
                DDLogError(@"Transaction receipt uploader already exists for: %@, 2", updJob.tsxId);
                restoreRec.receiptToReupload -= 1;
                continue;
            }

            // Do not interfere also with normal uploaders, no need to upload this one when another one is currently uploading.
            // Receipt uploader has lower priority, thus normal uploader do not check receipt uploaders for conflict.
            if ([_uploaders get:updJob.tsxId] != nil) {
                DDLogError(@"Transaction uploader already exists for: %@, 2", updJob.tsxId);
                restoreRec.receiptToReupload -= 1;
                continue;
            }

            [_receiptUploaders put:updJob key:updJob.tsxId async:NO];
        }

        // Start async transaction data upload.
        DDLogVerbose(@"Starting upload task for prod[%@], tsxId: %@", [PEXPaymentManager strInApp:purchase], updJob.tsxId);
        [self.uploadManager addUploadJob:updJob];
    }

    // If no upload was started, just finish with success immediately.
    if (restoreRec.receiptToReupload <= 0){
        DDLogVerbose(@"Receipt upload: nothing to upload, uploaders probably exist");
        if (success){
            success();
        }
    }
}

-(void) onReceiptTsxUploadFinishes: (PEXPaymentUploadJob *) job
                        restoreRec: (PEXPaymentRestoreRecord *) restoreRec
                          purchase: (RMAppReceiptIAP *) purchase
                           success: (dispatch_block_t) success
                           failure: (void(^)(NSError *error)) failure
{
    BOOL isok = YES;
    NSError * error = nil;
    BOOL lastFinished = NO;
    BOOL allSuccess = NO;

    @synchronized (restoreRec) {
        restoreRec.receiptReuploaded += 1;
        lastFinished = restoreRec.receiptToReupload <= restoreRec.receiptReuploaded;
        allSuccess = restoreRec.receiptReuploadFailed == 0;
    }

    // Remove reference on the upload process.
    [self.receiptUploaders remove:job.tsxId async:YES];

    if (job == nil || job.error != nil || job.jsonResponse == nil){
        DDLogError(@"Error in uploading transaction: %@", job.error);
        error = job != nil && job.error != nil ? job.error : [NSError errorWithDomain:PEXTransactionErrorDomain code:PEXTransactionUploadError userInfo:nil];
        isok = NO;
    }

    // Check json response.
    if (isok){
        DDLogVerbose(@"Transaction tsxId %@ upload result: %@", job.tsxId, job.jsonResponse);
        isok = [self wasUploadSuccessful:job pError:&error];
    }

    if (!isok) {
        // Mark number of failed receipt uploads.
        @synchronized (restoreRec) {
            restoreRec.receiptReuploadFailed += 1;
        }

        DDLogError(@"Receipt reupload failed for %@", job.tsxId);
    }

    // Finish transaction when everything is OK.
    if (lastFinished){
        DDLogVerbose(@"Last transaction processed");

        const BOOL wasSuccessful = allSuccess && isok;
        if (wasSuccessful && success){
            success();
        } else if (!wasSuccessful && failure){
            failure(error);
        }
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
                    finish:(RMSKPaymentTransactionFinishBlock)finishBlock
                finishInfo:(RMSKPaymentTransactionRestoreFinishSignalBlock)finishInfoBlock
{
    WEAKSELF;
    PEXPaymentTransactionRecord * tsxRec = [PEXPaymentTransactionRecord recordWithTransaction:transaction];
    tsxRec.isRmTransaction = NO;

    const PEXPaymentSuccessBlock successBlock = ^(PEXPaymentTransactionRecord *rec) {
        // Transaction was successfully uploaded and finished.
        // Broadcast info transaction was processed and finished so listeners are notified.
        if (finishInfoBlock) {
            finishInfoBlock();
        }
        [weakSelf.restoreRec incOk];
    };

    const PEXPaymentFailureBlock failureBlock = ^(PEXPaymentTransactionRecord *rec) {
        // Transaction upload failed, will be tried again later.
        // Transaction verification might failed also.
        // Broadcast info transaction was processed and finished so listeners are notified.
        if (finishInfoBlock) {
            finishInfoBlock();
        }
        [weakSelf.restoreRec incKo];
    };

    [self.opqueueTsxVerif addOperationWithBlock:^{
        const BOOL uploadStarted = [weakSelf transactionPurchasedHandler:tsxRec
                                                            successBlock:successBlock
                                                            failureBlock:failureBlock
                                                             finishBlock:finishBlock];
        if (!uploadStarted){
            DDLogError(@"Error with restore transaction - uploader exists");
            [weakSelf.restoreRec incUnverified];

            // Finish transaction to get rid of if from queue, receipt was just refreshed,
            // if verification went wrong transaction is not supposed to pass.
            if (finishBlock){
                finishBlock();
            }

            // Broadcast info transaction was processed and finished so listeners are notified.
            if (finishInfoBlock) {
                finishInfoBlock();
            }
        }
    }];
}

/**
 * Causes to refresh license info from the server.
 */
-(void) refreshLicenseInfoAfterDelay: (NSTimeInterval) delay
                             success: (dispatch_block_t) success
                             failure: (void(^)(NSError *error)) failure
{
    dispatch_block_t blockToExec = ^{
        [[[PEXService instance] licenceManager] checkPermissionsAsyncCompletion:^(PEXLicenceCheckTask *task) {
            DDLogVerbose(@"License refreshed %@", task.lastResult.err);
            if (task.lastResult.err != nil || task.lastResult.code != PEX_SOAP_CALL_RES_OK){
                DDLogError(@"License refreshed with error");
                if (failure){
                    failure(task.lastResult.err);
                }

                return;
            } else {
                DDLogVerbose(@"License refreshed successfully");
                if (success){
                    success();
                }
            }

        }];
    };

    // Execute the whole thing either with delay or directly.
    if (delay > 0){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), blockToExec);
    } else {
        blockToExec();
    }
}

// ---------------------------------------------
#pragma mark - Observers
// ---------------------------------------------

/**
 * Called when the product request failed.
 */
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    // Prints the cause of the product request failure
    DDLogError(@"Product Request Status: %@, %@",error.localizedDescription, error);
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    DDLogVerbose(@"Transactions removed %@, num: %d", transactions, transactions == nil ? -1 : (int) [transactions count]);
}

/**
 * Default transaction observer, used mainly when app is started.
 * After payment is made via RM, transaction events should flow through RM.
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    NSMutableArray * toProcess = [[NSMutableArray alloc] init];
    for(SKPaymentTransaction * transaction in transactions) {
        // Each purchased transaction should reset last receipt refresh time.
        if (transaction.transactionState == SKPaymentTransactionStatePurchased){
            [self.strictVerifier resetLastReceiptRefresh];
        }

        DDLogVerbose(@"SKTransaction %@", [PEXPaymentManager strTransaction:transaction]);
        if (!self.registered){
            [self.delayedTransactionEvents addObject:transaction];
            continue;

        } else if ([self.productIdHandledCache objectForKey:transaction.payment.productIdentifier] != nil){
            DDLogVerbose(@"Transaction handled by RM processor");
            continue;

        }

        [toProcess addObject:transaction];
    }

    WEAKSELF;
    [self.opqueueTsxVerif addOperationWithBlock:^{
        [weakSelf processTransactions:toProcess queue:[SKPaymentQueue defaultQueue]];
    }];
}

// ---------------------------------------------
#pragma mark - Log upload task
// ---------------------------------------------

-(void)triggerLogsUpload {
    [self postNewLogUploadTask];
}

-(void)postNewLogUploadTask {
    WEAKSELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PEXPaymentManager * pmgr = weakSelf;
        NSUInteger opCount = [pmgr.opqueueLogs operationCount];
        if (opCount >= 2){
            return;
        }

        // Submit new worker task.
        PEXAccountingLogUploadTask *task = [[PEXAccountingLogUploadTask alloc] init];
        task.pmgr = pmgr;

        DDLogVerbose(@"Starting new acc log upload task, count: %u", (unsigned)opCount);
        [pmgr.opqueueLogs addOperation:task];
    });
}

// ---------------------------------------------
#pragma mark - Debugging & toString()
// ---------------------------------------------

+ (NSString *) strTransactionState: (SKPaymentTransactionState)state {
    switch(state){
        case SKPaymentTransactionStatePurchased:
            return @"Purchased";
        case SKPaymentTransactionStatePurchasing:
            return @"Purchasing";
        case SKPaymentTransactionStateRestored:
            return @"Restored";
        case SKPaymentTransactionStateDeferred:
            return @"Deferred";
        case SKPaymentTransactionStateFailed:
            return @"Failed";
        default:
            return [NSString stringWithFormat:@"State %d", (int) state];
    }
}

+ (NSString *) strTransaction: (SKPaymentTransaction *) tx {
    return [NSString stringWithFormat:@"Transaction: id: %@, originalId: %@ state: %@, error: %@, date: %@, originalDate: %@, "
                                              "payment: [%@]",
                                      tx.transactionIdentifier,
                                      tx.originalTransaction.transactionIdentifier,
                                      [self strTransactionState:tx.transactionState],
                                      tx.error,
                                      tx.transactionDate,
                                      tx.originalTransaction.transactionDate,
                                      [self strPayment: tx.payment]];
}

+ (NSString *) strPayment: (SKPayment *) pay {
    return [NSString stringWithFormat:@"Payment: productId: %@, quantity: %ld, app: %@",
                                      pay.productIdentifier,
                                      (long)pay.quantity,
                                      pay.applicationUsername];
}

+ (NSString *) strInApp: (RMAppReceiptIAP *) inAppPurchase {
    return [NSString stringWithFormat:@"ProductId: %@, "
                                              "PurchaseDate: %@, "
                                              "originalPurchaseDate: %@, "
                                              "cancellationDate: %@, "
                                              "quantity: %d, "
                                              "subExpiration: %@, "
                                              "tsxId: %@, "
                                              "origTsx: %@",
                                      inAppPurchase.productIdentifier,
                                      inAppPurchase.purchaseDate,
                                      inAppPurchase.originalPurchaseDate,
                                      inAppPurchase.cancellationDate,
                                      (int)inAppPurchase.quantity,
                                      inAppPurchase.subscriptionExpirationDate,
                                      inAppPurchase.transactionIdentifier,
                                      inAppPurchase.originalTransactionIdentifier];
}

@end

// ---------------------------------------------
#pragma mark - PEXPaymentUploadTask
// ---------------------------------------------

/**
 * Delayed payment upload task.
 */
@implementation PEXPaymentDelayedUploadTask
- (void)main {
    [self.pmgr dumpDelayedNonUploadedTransactionsInternal];
}
@end


// ---------------------------------------------
#pragma mark - PEXLogUploadTask
// ---------------------------------------------

/**
 * Delayed payment upload task.
 */
@implementation PEXAccountingLogUploadTask
- (void)main {
    PEXAccountingLogUpdaterTask * updTask = [[PEXAccountingLogUpdaterTask alloc] init];
    updTask.privData = self.pmgr.privData;
    [updTask uploadLogs:nil res:nil];
}
@end

// ---------------------------------------------
#pragma mark - NSNotification(PEXPayment)
// ---------------------------------------------

/**
 * Notification extension.
 */
@implementation NSNotification(PEXPayment)

- (PEXPaymentTransactionRecord *)pex_transactionRecord {
    return (self.userInfo)[RMSKPaymentTransactionRecord];
}

- (NSNumber *)pex_transactionRecovered {
    return (self.userInfo)[RMSKPaymentTransactionRecovered];
}

- (NSNumber *)pex_transactionCommitted {
    return (self.userInfo)[RMSKPaymentTransactionCommitted];
}

- (NSNumber *)pex_transactionUploadFailed {
    return (self.userInfo)[RMSKPaymentTransactionUploadFailed];
}
@end
