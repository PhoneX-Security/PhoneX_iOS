//
// Created by Dusan Klinec on 22.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiRestoreProductsExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiProgressController_Protected.h"
#import "RMStore.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXPaymentRestoreRecord.h"
#import "PEXPaymentManager.h"

@interface PEXGuiRestoreProductsExecutor() {}
@property (nonatomic) BOOL observerRegistered;
@property (nonatomic) PEXGuiProgressController * progress;
@end

@implementation PEXGuiRestoreProductsExecutor {

}

- (void) show
{
    self.progress = [[PEXGuiProgressController alloc] init];
    self.progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowController =
            [[PEXGuiWindowController alloc] initWithViewController:self.progress];

    [self.progress setShowProgressBar:NO];
    [self.progress showTaskStarted:nil];
    [self.progress setTitle:PEXStr(@"L_restore_receipt_refresh")];
    self.topController = taskWindowController;

    [super show];

    [taskWindowController prepareOnScreen:self.parentController];
    [taskWindowController show:self.parentController];

    [[RMStore defaultStore] addStoreObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUploadFinished:) name:RMSKReceiptUploadFinished object:nil];
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

- (void) onRestoreProductsFinished: (PEXPaymentRestoreRecord *)restoreRec withSuccess: (BOOL) success {
    WEAKSELF;
    PEXGuiManageLicenceController * const controller = (PEXGuiManageLicenceController *) self.parentController;
    void (^completion)(void) = ^{
                [weakSelf unregisterObserver];
                [controller onRestoreProductsFinished:restoreRec withSuccess:success];
            };

    DDLogVerbose(@"Going to dismiss executor");
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [weakSelf dismissWithCompletion:completion];
    });
}

- (void)storeRestoreTransactionsFinished:(NSNotification *)notification {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.progress setTitle:PEXStr(@"L_restore_uploading")];
    });
}

- (void)storeRefreshReceiptFinished:(NSNotification *)notification {
    WEAKSELF;
    const BOOL nextStepRestore = [[PEXPaymentManager instance] shouldRestoreAllTransactions];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.progress setTitle: nextStepRestore ? PEXStr(@"L_restore_transaction_replay") : PEXStr(@"L_restore_uploading")];
    });
}

- (void)onUploadFinished:(id)onUploadFinished {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.progress setTitle: PEXStr(@"L_wait_refresh_license")];
    });
}


@end