//
// Created by Matej Oravec on 05/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPackageDeserializer.h"
#import "PEXPackage.h"
#import "PEXPackageItem.h"
#import "PEXPermissionsUtils.h"
#import "PEXUtils.h"


@implementation PEXPackageDeserializer {

}

+ (NSArray *) getPackagesFromJson: (NSDictionary * const) json
{
    NSNumber * const version = json[@"version"];
    NSArray * const packages = json[@"products"];

    NSMutableArray * const result = [[NSMutableArray alloc] init];

    for (NSDictionary * const packageDict in packages )
    {
        PEXPackage * const package = [[PEXPackage alloc] init];

        package.packageId = packageDict[@"id"];
        package.name = packageDict[@"name"];
        package.appleProductId = packageDict[@"name"];
        package.platform = packageDict[@"platform"];
        package.priority = packageDict[@"priority"];
        package.localizedTitle = packageDict[@"display_name"];
        package.localizedDescription = packageDict[@"description"];

        if ([@"subscription" isEqualToString:packageDict[@"type"]]){
            package.productType = PEXPackageSubscription;

            // Duration type
            if ([@"week" isEqualToString:packageDict[@"period_type"]]) {
                package.durationType = PEXPackageDurationWeek;
            } else if ([@"month" isEqualToString:packageDict[@"period_type"]]) {
                package.durationType = PEXPackageDurationMonth;
            } else if ([@"year" isEqualToString:packageDict[@"period_type"]]) {
                package.durationType = PEXPackageDurationYear;
            } else {
                package.durationType = PEXPackageDurationMonth;
            }

            // Duration length
            package.durationLength = [PEXUtils getAsNumber:packageDict[@"period"]];
            if (package.durationLength == nil){
                package.durationLength = @(1);
            }

        } else if ([@"consumable" isEqualToString:packageDict[@"type"]]){
            package.productType = PEXPackageConsumable;
            package.durationType = PEXPackageDurationNone;
        }

        NSMutableArray * const items = [[NSMutableArray alloc] init];
        NSArray * const itemDicts = packageDict[@"app_permissions"];

        for (NSDictionary * itemDict in itemDicts) {
            PEXPackageItem * const item = [[PEXPackageItem alloc] init];
            if (![self applyDescription: (itemDict[@"permission"]) to: item]) {
                continue;
            }

            item.value = [PEXUtils getAsNumber: itemDict[@"value"]];
            [items addObject:item];
        }

        package.items = items;
        [result addObject:package];
    }

    return result;
}

+ (bool)applyDescription: (NSString * const)permissionName to: (PEXPackageItem * const) item
{
    bool result = true;
    if ([permissionName isEqualToString:PEX_PERMISSION_CALLS_LIMIT_NAME]) {
        item.descriptor = PEX_PACKAGE_ITEM_CALL_SECONDS;
    } else if ([permissionName isEqualToString:PEX_PERMISSION_FILES_LIMIT_NAME]){
        item.descriptor = PEX_PACKAGE_ITEM_FILES_COUNT;
    } else if ([permissionName isEqualToString:PEX_PERMISSION_MESSAGES_LIMIT_NAME]){
        item.descriptor = PEX_PACKAGE_ITEM_MESSAGES_COUNT;
    } else if ([permissionName isEqualToString:PEX_PERMISSION_MESSAGES_DAILY_NAME]){
        item.descriptor = PEX_PACKAGE_ITEM_MESSAGES_DAILY_COUNT;
    } else {
        result = false;
    }

    item.permissionServerName = permissionName;
    return result;
}

@end