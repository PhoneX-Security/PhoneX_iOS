//
// Created by Matej Oravec on 17/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SKProduct;

typedef enum PEXPackageType : NSInteger {
    PEXPackageNone = 0,
    PEXPackageSubscription = 1,
    PEXPackageConsumable = 2,
}PEXPackageType;

typedef enum PEXPackageDurationType : NSInteger {
    PEXPackageDurationNone = 0,
    PEXPackageDurationWeek = 1,
    PEXPackageDurationMonth = 2,
    PEXPackageDurationYear = 3,
}PEXPackageDurationType;

@interface PEXPackage : NSObject

@property (nonatomic) NSNumber * packageId;
@property (nonatomic) NSString * name;
@property (nonatomic) NSString * platform;
@property (nonatomic) NSNumber * priority;
@property (nonatomic) NSArray * items;
@property (nonatomic) NSString * appleProductId;

/**
 * Value provided by license server.
 */
@property (nonatomic) NSString * localizedTitle;

/**
 * Value provided by license server.
 */
@property (nonatomic) NSString * localizedDescription;

/**
 * Value returned by Apple.
 */
@property (nonatomic) NSString * localizedPrice;

/**
 * Duration for subscription packages.
 */
@property (nonatomic) PEXPackageDurationType durationType;
@property (nonatomic) NSNumber * durationLength;

@property (nonatomic) SKProduct * product;
@property (nonatomic) PEXPackageType productType;
@property (nonatomic) NSInteger sortOrder;

@end