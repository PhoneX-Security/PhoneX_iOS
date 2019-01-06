//
// Created by Matej Oravec on 09/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiContentLoaderController.h"
#import "PEXLicenceManager.h"
#import "PEXGuiPackageDetailController.h"

@class PEXPaymentRestoreRecord;

@interface PEXGuiManageLicenceController : PEXGuiController
        <PEXLicenceListener,
        UICollectionViewDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout,
        PEXGuiPackagePurchaseListener>

+ (void) showOnParent: (UIViewController * const)parent;
- (void) onRestoreProductsFinished: (PEXPaymentRestoreRecord *) restoreRec withSuccess: (BOOL) success;
@end