//
// Created by Matej Oravec on 18/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiRowItemView.h"

@class PEXPackageItem;
@class PEXPackage;


@interface PEXGuiPackageView : PEXGuiRowItemView

- (void) applyPackage: (const PEXPackage * const) package;

@end