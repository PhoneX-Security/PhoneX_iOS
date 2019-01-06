//
// Created by Dusan Klinec on 03.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "PEXServiceModuleProtocol.h"
#import "RMStore.h"

@class PEXPaymentTransactionDelayedRecord;
@class PEXPaymentTransactionRecord;
@class PEXPaymentRestoreRecord;
@class RMAppReceiptIAP;

typedef void (^PEXPaymentSuccessBlock)(PEXPaymentTransactionRecord * rec);
typedef void (^PEXPaymentFailureBlock)(PEXPaymentTransactionRecord * rec);

typedef void (^PEXPaymentRestoreSuccessBlock)(PEXPaymentRestoreRecord * rec);
typedef void (^PEXPaymentRestoreFailureBlock)(PEXPaymentRestoreRecord * rec);

/**
 * Transaction domain error ID.
 */
extern NSString* const PEXTransactionErrorDomain;
extern int PEXTransactionUploadError;
extern int PEXTransactionReceiptVerificationError;
extern int PEXTransactionNotFoundInReceipt;
extern int PEXTransactionCannotBuy;

extern NSString* const PEXTransactionRestoreErrorDomain;
extern int PEXTransactionRestoreCannotBuy;
extern int PEXTransactionRestoreTooEarly;
extern int PEXTransactionRestoreAlreadyRunning;

/**
 * Extra transaction record.
 */
extern NSString* const RMSKPaymentTransactionRecord;

/**
 * Extra key for notification for transaction that has been marked as finished without corresponding RM
 * record, thus recovered after app start from previous crash.
 */
extern NSString* const RMSKPaymentTransactionRecovered;

/**
 * Extra key for notification for transaction that has been committed by the server.
 */
extern NSString* const RMSKPaymentTransactionCommitted;

/**
 * Extra key for notification for transaction that could not be commited by the server.
 * Transaction is not marked as finished.
 */
extern NSString* const RMSKPaymentTransactionUploadFailed;

extern NSString* const RMSKReceiptUploadFinished;
extern NSString* const RMSKReceiptUploadFailed;

/**
 * Main payment manager for the application.
 */
@interface PEXPaymentManager : NSObject<
        SKPaymentTransactionObserver,
        SKRequestDelegate,
        SKStoreProductViewControllerDelegate,
        PEXServiceModuleProtocol,
        RMStoreTransactionRestorer>

@property (nonatomic, weak) PEXUserPrivate * privData;
@property (nonatomic, readonly) PEXPaymentRestoreRecord * restoreRec;

/**
 * Boolean variable saying whether during restore process manager should attempt to restore previous transactions
 * via restore transactions logic.
 * As our logic is mainly based on transaction identifiers, restoring all transactions for auto-renewable subscriptions
 * is merely useless as restore transactions do not have any reference to original purchase transaction, only on the first one.
 *
 * If set to NO, restore transactions step is skipped.
 * @default NO
 */
@property (nonatomic) BOOL shouldRestoreAllTransactions;


+ (PEXPaymentManager *)instance;

/**
 * Registers as a transaction observer to the default payment queue.
 * Has to be done after application has started so we can process unfinished transactions.
 * Unfinished transactions are delayed (stored to the internal queue) until module gets properly registered
 * thus user has logged in.
 */
+ (void)registerForDelayed;

/**
 * Returns user name in this application, hashed, used as for fraud-detection techniques in SKPaymentRequest.
 */
-(NSString *) getApplicationUsername;

/**
 * Returns URL as a string where user can manage his subscriptions.
 * Source: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Subscriptions.html#//apple_ref/doc/uid/TP40008267-CH7-SW6
 */
-(NSString *) getSubscriptionManagementUrlString;

/**
 * Asynchronously loads product information from the store.
 */
-(void) getProductInfo: (NSArray *) productIds
          successBlock: (RMSKProductsRequestSuccessBlock) successBlock
          failureBlock: (RMSKProductsRequestFailureBlock) failureBlock;

/**
 * Returns YES if there is currently a pending transaction upload of a payment with a specified product.
 * If YES is returned user should not start new purchase.
 */
-(BOOL) isPaymentPending: (NSString *) productIdentifier;

/**
 * Adds a new payment to the queue for given product identifier.
 * When payment is successful it is uploaded to the license server.
 * When upload is successful, transaction is finished.
 *
 * User can add own success/failure blocks.
 */
-(void) addPayment:(NSString *)productIdentifier
      successBlock:(PEXPaymentSuccessBlock) successBlock
      failureBlock:(PEXPaymentFailureBlock) failureBlock;

/**
 * Tries to restore previous purchases according to
 * https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html
 *
 * User can add own success/failure blocks.
 * Restore procedure consists of the following steps:
 *  1. refresh receipt
 *  2. restore all transactions (can be disabled)
 *  3. re-upload relevant receipt purchases to the server.
 */
-(void) restorePayment:(PEXPaymentRestoreSuccessBlock) successBlock
          failureBlock:(PEXPaymentRestoreFailureBlock) failureBlock;

/**
 * Causes to start a new dumping of the delayed transaction update.
 */
-(void)triggerNewDelayedUpload;

/**
 * Triggers usage log upload.
 */
-(void)triggerLogsUpload;

/**
 * Returns transaction id. If it is a restore transaction, returns id of the original one.
 */
+(NSString *) getUploadTsxId: (SKPaymentTransaction *) tsx;
+ (NSString *) strTransaction: (SKPaymentTransaction *) tx;
+ (NSString *) strInApp: (RMAppReceiptIAP *) inAppPurchase;
@end

/**
 * Notification extended with our extra fields getters.
 */
@interface NSNotification(PEXPayment)
- (PEXPaymentTransactionRecord *)pex_transactionRecord;
- (NSNumber *)pex_transactionRecovered;
- (NSNumber *)pex_transactionCommitted;
- (NSNumber *)pex_transactionUploadFailed;
@end;