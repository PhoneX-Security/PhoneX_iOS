//
// Created by Matej Oravec on 17/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "PEXPackage.h"


@implementation PEXPackage {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.productType = PEXPackageNone;
        self.sortOrder = 0;
        self.durationType = PEXPackageDurationNone;
    }

    return self;
}


@end