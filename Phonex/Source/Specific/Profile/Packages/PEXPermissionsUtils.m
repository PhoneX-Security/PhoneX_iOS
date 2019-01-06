//
// Created by Matej Oravec on 09/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPermissionsUtils.h"

#import "PEXDbAccountingPermission.h"
#import "PEXPackageItem.h"
#import "PEXGuiCallManager.h"
#import "PEXChatAccountingManager.h"
#import "PEXFileRestrictorManager.h"

NSString * const PEX_PERMISSION_CALLS_PREFIX = @"calls";
NSString * const PEX_PERMISSION_FILES_PREFIX = @"files";
NSString * const PEX_PERMISSION_MESSAGES_PREFIX = @"messages";

NSString * const PEX_PERMISSION_MESSAGES_DAILY_NAME = @"messages.outgoing.day_limit";
NSString * const PEX_PERMISSION_MESSAGES_LIMIT_NAME = @"messages.outgoing.limit";
NSString * const PEX_PERMISSION_CALLS_LIMIT_NAME = @"calls.outgoing.seconds";
NSString * const PEX_PERMISSION_FILES_LIMIT_NAME = @"files.outgoing.files";


@implementation PEXPermissionsUtils {

}

+ (void) addItem: (const PEXPackageItemDescription) description
          ToDict: (NSMutableDictionary * const) dictionary
             for: (const int64_t) value
       sortOrder: (NSInteger) sortOrder
{
    PEXPackageItem * const item = [[PEXPackageItem alloc] init];
    item.descriptor = description;
    item.value = @(value);
    item.guiSortOrder = sortOrder;

    dictionary[@(description)] = item;
}

+ (NSDictionary *)mergePermissionsForSummary: (NSArray * const) permissions zeroIfNone: (const bool) zeroIfNone
{
    NSMutableDictionary * const mergedPackages = [[NSMutableDictionary alloc] init];

    // calls
    const int64_t calls = [PEXGuiCallManager getMaxDuration:permissions];
    if ((calls != 0) || zeroIfNone)
    {
        [PEXPermissionsUtils addItem:PEX_PACKAGE_ITEM_CALL_SECONDS
                              ToDict:mergedPackages
                                 for:calls
                           sortOrder:PEX_PACKAGE_ITEM_SORT_CALL_SECONDS];
    }

    const int64_t messages = [PEXChatAccountingManager getAvailableMessages:permissions];
    if ((messages != 0) || zeroIfNone)
    {
        // messagges
        [PEXPermissionsUtils addItem:PEX_PACKAGE_ITEM_MESSAGES_COUNT
                              ToDict:mergedPackages
                                 for:messages
                           sortOrder:PEX_PACKAGE_ITEM_SORT_MESSAGES_COUNT];
    }

    const int64_t files = [PEXFileRestrictorFactory getAvailableFileCountForPermissions:permissions];
    if ((files != 0) || zeroIfNone) {
        // files
        [PEXPermissionsUtils addItem:PEX_PACKAGE_ITEM_FILES_COUNT
                              ToDict:mergedPackages
                                 for:files
                           sortOrder:PEX_PACKAGE_ITEM_SORT_FILES_COUNT];
    }


    return mergedPackages;
}

+ (PEXPackageItemDescription) descriptionFromPermission: (const PEXDbAccountingPermission * const) permission
{
    NSString * const name = permission.name;
    NSArray * const splits = [name componentsSeparatedByString: @"."];

    return [self descriptionFromNameSplits:splits];
}

+ (PEXPackageItemDescription) descriptionFromNameSplits: (NSArray * const) splits
{
    PEXPackageItemDescription result = PEX_PACKAGE_ITEM_UNKNOWN;

    NSString * const typeName = splits[0];

    if ([typeName isEqualToString:PEX_PERMISSION_CALLS_PREFIX])
        result = PEX_PACKAGE_ITEM_CALL_SECONDS;
    else if ([typeName isEqualToString:PEX_PERMISSION_MESSAGES_PREFIX])
        result = PEX_PACKAGE_ITEM_MESSAGES_COUNT;
    else if ([typeName isEqualToString:PEX_PERMISSION_FILES_PREFIX])
        result = PEX_PACKAGE_ITEM_FILES_COUNT;

    return result;
}

+ (bool) isPermissionNameDaily: (NSString * const) name
{
    NSArray * splits = [name componentsSeparatedByString:@"."];

    return (splits && (splits.count >= 3) && ([splits[2] isEqualToString: @"day_limit"]));
}

+ (bool) isPermissionForMessages: (NSString * const) name
{
    NSArray * const splits = [name componentsSeparatedByString:@"."];

    return (splits && (splits.count >= 1) && ([splits[0] isEqualToString: PEX_PERMISSION_MESSAGES_PREFIX]));
}

+ (bool) isPermissionForFiles: (NSString * const) name
{
    NSArray * const splits = [name componentsSeparatedByString:@"."];

    return (splits && (splits.count >= 1) && ([splits[0] isEqualToString: PEX_PERMISSION_FILES_PREFIX]));
}

+ (bool) isPermissionForCalls: (NSString * const) name
{
    NSArray * const splits = [name componentsSeparatedByString:@"."];

    return (splits && (splits.count >= 1) && ([splits[0] isEqualToString: PEX_PERMISSION_CALLS_PREFIX]));
}

+ (PEXPackageItem *) getCleanPackage
{
    PEXPackageItem * const result = [[PEXPackageItem alloc] init];

    result.value = @(0);
    result.descriptor = PEX_PACKAGE_ITEM_UNKNOWN;

    return result;
}

+ (void) processPermissions: (NSArray * const) permissions
             toConsumeables: (NSDictionary ** const) consumeablesOut
           toSubscriptionss: (NSDictionary ** const) subscriptionsOut
                 zeroIfNone: (const bool) zeroIfNone
                skipDefault: (const bool) skipDefault
{
    if (!permissions || !permissions.count)
        return;

    NSDictionary * mergedSimpleConsumeableSummary;
    NSDictionary * mergedSubscriptionsSummary;

    // find where consumeables start: they are returned sorted already from the licence manager

    NSMutableArray * subscriptions = [[NSMutableArray alloc] init];
    NSMutableArray * consumeables = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i < permissions.count; ++i)
    {
        const PEXDbAccountingPermission * const permission = permissions[i];
        if (skipDefault && [permission isDefaultPermission]){
            continue;
        }

        if ([permission.subscription isEqualToNumber:@(1)])
        {
            [subscriptions addObject:permission];
        }
        else
        {
            [consumeables addObject:permission];
        }
    }

    mergedSimpleConsumeableSummary =
            [self mergePermissionsForSummary:consumeables zeroIfNone:zeroIfNone];

    if (subscriptions && subscriptions.count)
        mergedSubscriptionsSummary = [self mergeSubscriptions:subscriptions];


    // result
    if (mergedSimpleConsumeableSummary && consumeablesOut)
        *consumeablesOut = mergedSimpleConsumeableSummary;

    if (mergedSubscriptionsSummary && subscriptionsOut)
        *subscriptionsOut = mergedSubscriptionsSummary;
}

+ (NSDictionary *) mergeSubscriptions: (NSArray * const) subscriptions
{
    NSMutableDictionary * const result = [[NSMutableDictionary alloc] init];

    for (PEXDbAccountingPermission * const permission in subscriptions)
    {
        NSNumber * const licenceId = permission.licId;
        NSMutableArray * group = result[licenceId];
        if (!group)
        {
            group = [[NSMutableArray alloc] init];
            result[licenceId] = group;
        }
        [group addObject:permission];
    }

    return result;
}

@end