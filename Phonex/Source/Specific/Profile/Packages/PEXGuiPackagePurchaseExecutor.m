//
// Created by Dusan Klinec on 16.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPackagePurchaseExecutor.h"
#import "PEXPackage.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiPackageDetailController.h"
#import "PEXGuiProgressController_Protected.h"
#import "PEXPaymentManager.h"

@interface PEXGuiPackagePurchaseExecutor() {}
@property (nonatomic) BOOL observerRegistered;
@property (nonatomic) PEXGuiProgressController * progress;
@end

@implementation PEXGuiPackagePurchaseExecutor {

}

- (void) show
{
    self.progress = [[PEXGuiProgressController alloc] init];
    self.progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowController =
            [[PEXGuiWindowController alloc] initWithViewController:self.progress];

    [self.progress setShowProgressBar:NO];
    [self.progress showTaskStarted:nil];
    self.topController = taskWindowController;

    [super show];

    [taskWindowController prepareOnScreen:self.parentController];
    [taskWindowController show:self.parentController];

    [[RMStore defaultStore] addStoreObserver:self];
    self.observerRegistered = YES;
}

- (void)dealloc {
    [self unregisterObserver];
}

- (void) unregisterObserver {
    @try {
        if (self.observerRegistered) {
            [[RMStore defaultStore] removeStoreObserver:self];
        }
        self.observerRegistered = NO;

    } @catch(NSException *e){
        DDLogError(@"Exception in removing observer");
    }
}

- (void)finishWithSuccess:(BOOL)success {
    WEAKSELF;
    PEXGuiPackageDetailController * const controller = (PEXGuiPackageDetailController *) self.parentController;
    void (^completion)(void) = success ?
            ^{
                [weakSelf unregisterObserver];
                [controller onPurchaseSuccess];
            } :
            ^{
                [weakSelf unregisterObserver];
                [controller onPurchaseError];
            };

    DDLogVerbose(@"Going to dismiss executor");
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf dismissWithCompletion:completion];
    });
}

- (void)storePaymentTransactionFailed:(NSNotification *)notification {

}

- (void)storePaymentTransactionFinished:(NSNotification *)notification {
    // Track progress, payment finished, or upload finished?
    SKPaymentTransaction * tsx = [notification rm_transaction];
    if (tsx == nil){
        return;
    }

    WEAKSELF;
    NSNumber * committed = [notification pex_transactionCommitted];
    NSNumber * updFailed = [notification pex_transactionUploadFailed];
    if (committed == nil && updFailed == nil){
        // Change label to uploading.
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress setTitle:PEXStr(@"L_tsx_uploading")];
        });
    } else {
        // Change label to finishing.
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.progress setTitle:PEXStr(@"L_tsx_finishing")];
        });
    }
}



@end