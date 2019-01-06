//
// Created by Dusan Klinec on 22.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"
#import "RMStore.h"

@class PEXPaymentRestoreRecord;


@interface PEXGuiRestoreProductsExecutor : PEXGuiExecutor<RMStoreObserver>
- (void) onRestoreProductsFinished: (PEXPaymentRestoreRecord *)restoreRec withSuccess: (BOOL) success;
@end