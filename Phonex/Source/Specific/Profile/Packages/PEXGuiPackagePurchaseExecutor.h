//
// Created by Dusan Klinec on 16.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"
#import "RMStore.h"

@class PEXPackage;


@interface PEXGuiPackagePurchaseExecutor : PEXGuiExecutor<RMStoreObserver>
@property (nonatomic) PEXPackage const * item;

-(void) finishWithSuccess: (BOOL) success;
@end