//
// Created by Matej Oravec on 17/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

// Consumable is always transferable ... because after refill it transfers to the next session
typedef NS_ENUM(NSInteger, PEXPackageItemAnchor)
{
    PEX_PACKAGE_ITEM_TRANSFERABLE,
    PEX_PACKAGE_ITEM_NON_TRANSFERABLE
};

typedef NS_ENUM(NSInteger, PEXPackageItemLife)
{
    PEX_PACKAGE_ITEM_CONSUMABLE,
    PEX_PACKAGE_ITEM_TARIF
};

typedef NS_ENUM(NSInteger, PEXPackageItemDescription)
{
    PEX_PACKAGE_ITEM_UNKNOWN,
    PEX_PACKAGE_ITEM_CALL_SECONDS,
    PEX_PACKAGE_ITEM_MESSAGES_COUNT,
    PEX_PACKAGE_ITEM_MESSAGES_DAILY_COUNT,
    PEX_PACKAGE_ITEM_FILES_COUNT
};

typedef NS_ENUM(NSInteger, PEXPackageItemSortOrder)
{
    PEX_PACKAGE_ITEM_SORT_CALL_SECONDS,
    PEX_PACKAGE_ITEM_SORT_MESSAGES_COUNT,
    PEX_PACKAGE_ITEM_SORT_MESSAGES_DAILY_COUNT,
    PEX_PACKAGE_ITEM_SORT_FILES_COUNT,
    PEX_PACKAGE_ITEM_SORT_UNKNOWN,
};

@interface PEXPackageItem : NSObject

@property (nonatomic) NSNumber * value;
@property (nonatomic) NSString *permissionServerName;
@property (nonatomic) NSDate * validUntil;

@property (nonatomic, assign) PEXPackageItemDescription descriptor;
@property (nonatomic, assign) PEXPackageItemLife life;
@property (nonatomic, assign) PEXPackageItemAnchor anchor;

@property (nonatomic) NSInteger guiSortOrder;

- (NSString *)description;
@end