//
// Created by Matej Oravec on 09/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPackageItem.h"

extern NSString * const PEX_PERMISSION_CALLS_PREFIX;
extern NSString * const PEX_PERMISSION_FILES_PREFIX;
extern NSString * const PEX_PERMISSION_MESSAGES_PREFIX;

extern NSString * const PEX_PERMISSION_MESSAGES_DAILY_NAME;
extern NSString * const PEX_PERMISSION_MESSAGES_LIMIT_NAME;
extern NSString * const PEX_PERMISSION_CALLS_LIMIT_NAME;
extern NSString * const PEX_PERMISSION_FILES_LIMIT_NAME;

@class PEXDbAccountingPermission;

@interface PEXPermissionsUtils : NSObject

+ (NSDictionary *)mergePermissionsForSummary: (NSArray * const) permissions zeroIfNone: (const bool) zeroIfNone;
+ (void) processPermissions: (NSArray * const) permissions
             toConsumeables: (NSDictionary ** const) consumeablesOut
           toSubscriptionss: (NSDictionary ** const) subscriptionsOut
                 zeroIfNone: (const bool) zeroIfNone
                skipDefault: (const bool) skipDefault;


+ (PEXPackageItemDescription) descriptionFromPermission: (const PEXDbAccountingPermission * const) permission;


+ (bool) isPermissionNameDaily: (NSString * const) name;
+ (bool) isPermissionForMessages: (NSString * const) name;
+ (bool) isPermissionForFiles: (NSString * const) name;
+ (bool) isPermissionForCalls: (NSString * const) name;

@end