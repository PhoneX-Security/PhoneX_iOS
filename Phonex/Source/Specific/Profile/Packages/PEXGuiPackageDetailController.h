//
// Created by Matej Oravec on 01/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPackage;
@class PEXPaymentTransactionRecord;

@protocol PEXGuiPackagePurchaseListener<NSObject>
-(void) onProductPurchaseFinished: (PEXPaymentTransactionRecord *) tsxRec success: (BOOL) success;
@end

@interface PEXGuiPackageDetailController : PEXGuiController
@property (nonatomic, weak) id<PEXGuiPackagePurchaseListener> purchaseListener;

- (id) initWithPackage: (const PEXPackage * const) package;
-(void) onPurchaseError;
-(void) onPurchaseSuccess;

@end