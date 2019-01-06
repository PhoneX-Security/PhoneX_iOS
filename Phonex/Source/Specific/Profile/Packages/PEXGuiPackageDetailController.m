//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPackageDetailController.h"
#import "PEXGuiController_Protected.h"

#import "PEXPackage.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXPaymentTransactionRecord.h"
#import "PEXPackageHumanDescription.h"
#import "PEXReport.h"
#import "PEXPaymentManager.h"
#import "PEXGuiDetailView.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXGuiPackagePurchaseExecutor.h"
#import "PEXGuiFactory.h"
#import "PEXPaymentTransactionRecord.h"

@interface PEXGuiPackageDetailController ()

@property (nonatomic) const PEXPackage * package;
@property (nonatomic) PEXPaymentTransactionRecord * tsxRec;

@property (nonatomic) PEXGuiButtonMain * B_buy;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_info;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_price;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_detail;
@property (nonatomic) PEXGuiPackagePurchaseExecutor * executor;

@end

@implementation PEXGuiPackageDetailController {

}

- (id) initWithPackage: (const PEXPackage * const) package
{
    self = [super init];

    self.package = package;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_buy = [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_buy];

    self.TV_info = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_info];

    self.TV_price = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_price];

    self.TV_detail = [[PEXGuiReadOnlyTextView alloc] init];
    [self.mainView addSubview:self.TV_detail];
}

- (void)initContent
{
    [super initContent];

    [self.B_buy setTitle:PEXStrU(@"L_buy") forState:UIControlStateNormal];

    PEXPackageHumanDescription * descritpion = [[PEXPackageHumanDescription alloc] init];
    [descritpion applyPackage:self.package];

    PEXGuiDetailsTextBuilder * const builder1 = [[PEXGuiDetailsTextBuilder alloc] init];
    if (self.package.productType == PEXPackageSubscription){
        [builder1 appendFirstLabel:PEXStr(@"L_product_type_subscription")];
    } else if (self.package.productType == PEXPackageConsumable){
        [builder1 appendFirstLabel:PEXStr(@"L_product_type_consumable")];
    } else {
        [builder1 appendFirstLabel:PEXStr(@"L_product_name")];
    }
    [builder1 appendValue:descritpion.shortLabel];

    PEXGuiDetailsTextBuilder * const builder2 = [[PEXGuiDetailsTextBuilder alloc] init];
    [builder2 appendFirstLabel:PEXStr(@"L_product_price")];
    if (descritpion.localizedDuration != nil) {
        [builder2 appendValue:[NSString stringWithFormat:@"%@ / %@", descritpion.localizedPrice, descritpion.localizedDuration]];
    } else {
        [builder2 appendValue:descritpion.localizedPrice];
    }

    PEXGuiDetailsTextBuilder * const builder3 = [[PEXGuiDetailsTextBuilder alloc] init];
    [builder3 appendFirstLabel:PEXStr(@"L_product_description")];
    [builder3 appendValue:descritpion.superDetail];

    [self.TV_info setAttributedText:builder1.result];
    [self.TV_price setAttributedText:builder2.result];
    [self.TV_detail setAttributedText:builder3.result];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TV_info];
    [self.TV_info sizeToFit];
    [PEXGVU moveToTop:self.TV_info];

    [PEXGVU scaleHorizontally:self.TV_price];
    [self.TV_price sizeToFit];
    [PEXGVU move:self.TV_price below:self.TV_info];

    [PEXGVU scaleHorizontally:self.TV_detail];
    [PEXGVU move:self.TV_detail below:self.TV_price];

    [PEXGVU scaleHorizontally:self.B_buy withMargin:PEXVal(@"dim_size_large")];
    const CGRect mainFrame = self.mainView.frame;
    const float lowBound = mainFrame.size.height - 2.0F * PEXVal(@"dim_size_large") - self.B_buy.frame.size.height;
    const float maxHeight = lowBound - self.TV_detail.frame.origin.y;
    if (maxHeight <= 0){
        DDLogError(@"Screen size is small to display the product");
    } else {
        [self.TV_detail sizeToFitMaxHeight:maxHeight];
    }

    [PEXGVU move:self.B_buy below:self.TV_detail withMargin:PEXVal(@"dim_size_large")];
}

- (void)initBehavior {
    [super initBehavior];
    [self.B_buy addTarget:self action:@selector(onBuyClicked:) forControlEvents:UIControlEventTouchUpInside];
}

-(void) onPurchaseError {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString * text =
        (weakSelf.tsxRec != nil
                && weakSelf.tsxRec.transaction != nil
                && weakSelf.tsxRec.transaction.transactionState == SKPaymentTransactionStatePurchased)
        ?  PEXStr(@"txt_purchase_error_upload") : PEXStr(@"txt_purchase_error");
        [PEXGuiFactory showErrorTextBox:weakSelf
                               withText:text
                             completion:^{
            if (weakSelf.purchaseListener){
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [weakSelf.purchaseListener onProductPurchaseFinished:weakSelf.tsxRec success:NO];
                });
            }
        }];
    });
}

-(void) onPurchaseSuccess {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        [PEXGuiFactory showInfoTextBox:weakSelf
                              withText:PEXStr(@"txt_purchase_success")
                            completion:^{[weakSelf.fullscreener dismissViewControllerAnimated:NO completion:^{
                                if (weakSelf.purchaseListener){
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        [weakSelf.purchaseListener onProductPurchaseFinished:weakSelf.tsxRec success:YES];
                                    });
                                }
                            }];}];
    });
}

-(void) onTsxFinished: (PEXPaymentTransactionRecord *) tsxRec success: (BOOL) success {
    self.tsxRec = tsxRec;
    [self.executor finishWithSuccess:success];
}

- (IBAction) onBuyClicked: (id) sender
{
    //[PEXReport logUsrButton:PEX_EVENT_BTN_ADD_CONTACT_ALIAS_CLICKED];
    DDLogVerbose(@"Buy clicked, product: %@", self.package.appleProductId);
    PEXPaymentManager * pmgr = [PEXPaymentManager instance];
    WEAKSELF;

    // If user is not able to make payments, show him warning and go on.
    if (![RMStore canMakePayments]){
        DDLogVerbose(@"User is not able to make payments");
        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showInfoTextBox:weakSelf
                                  withText:PEXStr(@"txt_purchase_no_payment")
                                completion:^{[weakSelf.fullscreener dismissViewControllerAnimated:NO completion:^{}];}];
        });
        return;
    }

    // If there is currently unfinished purchased transaction for the same product ID, do not start a new purchase.
    // Apple StoreKit says to the user he has purchased the product already and provides a product for free what may
    // lead to confusion.
    if ([pmgr isPaymentPending:self.package.appleProductId]){
        DDLogVerbose(@"Payment is already pending for product: %@", self.package.appleProductId);
        [pmgr triggerNewDelayedUpload];

        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showInfoTextBox:weakSelf
                                  withText:PEXStr(@"txt_purchase_pending")
                                completion:^{[weakSelf.fullscreener dismissViewControllerAnimated:NO completion:^{}];}];
        });
        return;
    }

    PEXPaymentSuccessBlock successBlock = ^(PEXPaymentTransactionRecord *transaction) {
        // Show popup that product was purchased, back to products / main.
        DDLogVerbose(@"Product was purchased, tsxId: %@", transaction.transactionId);
        [weakSelf onTsxFinished:transaction success:YES];
    };

    PEXPaymentFailureBlock failureBlock = ^(PEXPaymentTransactionRecord *transaction) {
        // Show error informing user that purchase was not successful. Tell him to
        // Try again and if problem perists to restart application. Or contact phonex-support.
        DDLogError(@"Transaction was not successful, %@ error: %@", transaction.productIdentifier, transaction.error);
        [weakSelf onTsxFinished:transaction success:NO];
    };

    [pmgr addPayment:self.package.appleProductId
        successBlock:successBlock
        failureBlock:failureBlock];

    // Progress monitor, indeterminate.
    self.executor = [[PEXGuiPackagePurchaseExecutor alloc] init];
    self.executor.parentController = self;
    self.executor.item = self.package;
    [self.executor show];
}


@end