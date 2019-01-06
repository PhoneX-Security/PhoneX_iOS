//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbAccountingLog;
@class PEXDbAccountingPermission;


@interface PEXAccountingHelper : NSObject

+(NSMutableDictionary *) accountingLogToDict: (PEXDbAccountingLog *) alog;
+(PEXDbAccountingPermission *) permissionFromDict: (NSDictionary *) permDict;

+(BOOL) updatePermissionsDefinitionsJson: (NSDictionary *) json;
+(void) updatePermissionsDefinitionsJson: (NSArray *)json subscription: (BOOL) subscription;
+(BOOL) updatePermissionsDefinitions: (NSArray *)policy subscription: (BOOL) subscription;
+(void) updatePermissionsFromServerJson: (NSArray *) permissions;
+(void) updatePermissionsFromServer: (NSArray *) permissions;

@end