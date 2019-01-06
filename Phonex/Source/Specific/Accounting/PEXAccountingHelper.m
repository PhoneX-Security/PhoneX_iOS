//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAccountingHelper.h"
#import "PEXDbAccountingLog.h"
#import "PEXDbAccountingPermission.h"
#import "PEXUtils.h"
#import "PEXAccountingPermissionId.h"
#import "PEXDbAppContentProvider.h"
#import "PEXAccountingLogId.h"
#import "PEXLicenceManager.h"
#import "PEXService.h"


@implementation PEXAccountingHelper {

}

// ---------------------------------------------
#pragma mark - JSON conversion
// ---------------------------------------------

/**
 * {"type":"m.om", "aid":1443185624488, "ctr":3, "vol": "120", "perm":{"licId":123, "permId":2}},
 */
+ (NSMutableDictionary *)accountingLogToDict:(PEXDbAccountingLog *)alog {
    NSMutableDictionary * d = [[NSMutableDictionary alloc] init];
    d[@"type"] = alog.type;
    d[@"aid"] = alog.actionId;
    d[@"ctr"] = alog.actionCounter;
    d[@"vol"] = alog.amount;

    if (alog.permId != nil && alog.licId != nil) {
        d[@"perm"] = @{@"licId" : alog.licId, @"permId" : alog.permId};
    }

    if (![PEXStringUtils isEmpty:alog.aref]){
        d[@"ref"] = alog.aref;
    }

    return d;
}

/**
 * Volume set to spent.
 */
+ (PEXDbAccountingPermission *)permissionFromDict:(NSDictionary *)permDict {
    if (permDict == nil){
        return nil;
    }

    PEXDbAccountingPermission * p = [[PEXDbAccountingPermission alloc] init];
    // Volume is set to spent counter.
    if (permDict[@"vol"] != nil){
        p.spent = [PEXUtils getAsNumber: permDict[@"vol"]];
    }

    if (permDict[@"permId"] != nil){
        p.permId = [PEXUtils getAsNumber: permDict[@"permId"]];
    }
    if (permDict[@"licId"] != nil){
        p.licId = [PEXUtils getAsNumber: permDict[@"licId"]];
    }
    if (permDict[@"acount"] != nil){
        p.aggregationCount = [PEXUtils getAsNumber: permDict[@"acount"]];
    }
    if (permDict[@"aidFst"] != nil){
        p.actionIdFirst = [PEXUtils getAsNumber: permDict[@"aidFst"]];
    }
    if (permDict[@"ctrFst"] != nil){
        p.actionCtrFirst = [PEXUtils getAsNumber: permDict[@"ctrFst"]];
    }
    if (permDict[@"aidLst"] != nil){
        p.actionIdLast = [PEXUtils getAsNumber: permDict[@"aidLst"]];
    }
    if (permDict[@"ctrLst"] != nil){
        p.actionCtrLast = [PEXUtils getAsNumber: permDict[@"ctrLst"]];
    }
    if (permDict[@"dcreated"] != nil){
        p.dateCreated = [PEXUtils dateFromMillis:(uint64_t)[[PEXUtils getAsNumber: permDict[@"dcreated"]] longLongValue]];
    }
    if (permDict[@"dmodif"] != nil){
        p.dateModified = [PEXUtils dateFromMillis:(uint64_t)[[PEXUtils getAsNumber: permDict[@"dmodif"]] longLongValue]];
    }

    return p;
}

/**
 * {"license_id":"3551","permission_id":"1","permission":"outgoing_calls_seconds","value":"600","starts_at":1443657600,"expires_at":1446422399}
 */
+ (PEXDbAccountingPermission *)permissionFromPolicyDict:(NSDictionary *)permDict{
    if (permDict == nil){
        return nil;
    }

    PEXDbAccountingPermission * p = [[PEXDbAccountingPermission alloc] init];
    // Volume is set to value counter = total maximum value.
    if (permDict[@"value"] != nil){
        p.value = [PEXUtils getAsNumber: permDict[@"value"]];
    }

    if (permDict[@"permission_id"] != nil){
        p.permId = [PEXUtils getAsNumber: permDict[@"permission_id"]];
    }
    if (permDict[@"license_id"] != nil){
        p.licId = [PEXUtils getAsNumber: permDict[@"license_id"]];
    }
    if (permDict[@"permission"] != nil){
        p.name = permDict[@"permission"];
    }
    if (permDict[@"starts_at"] != nil){
        p.validFrom = [PEXUtils dateFromMillis:(uint64_t)[[PEXUtils getAsNumber: permDict[@"starts_at"]] unsignedLongLongValue] * 1000];
    }
    if (permDict[@"expires_at"] != nil){
        p.validTo = [PEXUtils dateFromMillis:(uint64_t)[[PEXUtils getAsNumber: permDict[@"expires_at"]] unsignedLongLongValue] * 1000];
    }
    else
    {
        p.validTo = [NSDate distantFuture];
    }

    return p;
}

// ---------------------------------------------
#pragma mark - Permission from policy merge
// ---------------------------------------------

/**
 * Updates permissions definitions from current policy loaded from the account info, passed in JSON form.
 * Mainly targets value field - information fixed in policy, not changed by application usage.
 * Called from the account info response handling procedures, entry point.
 * Accepts following JSON:
 *
 * {"subscriptions":[
 * {"license_id":"3551","permission_id":"1","permission":"outgoing_calls_seconds","value":"600","starts_at":1443657600,"expires_at":1446422399},
 * {"license_id":"3551","permission_id":"5","permission":"outgoing_messages_per_day","value":"-1","starts_at":1443657600,"expires_at":1446422399},
 * {"license_id":"3551","permission_id":"6","permission":"outgoing_messages","value":"-1","starts_at":1443657600,"expires_at":1446422399}],
 *
 * "consumables":[
 * {"license_id":"3552","permission_id":"1","permission":"outgoing_calls_seconds","value":"1800","starts_at":1443657600}
 * ]}
 */
+ (BOOL)updatePermissionsDefinitionsJson:(NSDictionary *)json {
    BOOL success = YES;
    @try {
        if (json[@"subscriptions"] != nil){
            NSArray * arr = json[@"subscriptions"];
            [self updatePermissionsDefinitionsJson:arr subscription:YES];
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in parsing permissions, %@", e);
        success = NO;
    }

    @try {
        if (json[@"consumables"] != nil){
            NSArray * arr = json[@"consumables"];
            [self updatePermissionsDefinitionsJson:arr subscription:NO];
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in parsing permissions, %@", e);
        success = NO;
    }

    return success;
}

/**
 * Updates permissions definitions from current policy loaded from the account info, passed in JSON form.
 * Differentiates between consumable and subscription permission type.
 * Parses NSArray<NSDictionary *>* to NSArray<PEXDbAccountingPermission *>* and passes to updatePermissionsDefinitions:arr subscription:subscription
 * to do the real job.
 */
+ (void)updatePermissionsDefinitionsJson:(NSArray *)json subscription: (BOOL) subscription {
    NSMutableArray * arr = [[NSMutableArray alloc] init];
    for(id elem in json){
        @try {
            NSDictionary * permDict = (NSDictionary *) elem;
            PEXDbAccountingPermission * perm = [self permissionFromPolicyDict:permDict];
            perm.subscription = @(subscription);
            [arr addObject:perm];

        } @catch(NSException * e){
            DDLogError(@"Exception parsing policy permission %@", e);
        }
    }

    [self updatePermissionsDefinitions:arr subscription:subscription];
}

/**
 * Updates permissions definitions from current policy loaded from the account info.
 */
+ (BOOL)updatePermissionsDefinitions:(NSArray *)policy subscription: (BOOL) subscription {
    BOOL success = YES;
    NSMutableSet * permIdsUpdated = [[NSMutableSet alloc] init];
    NSMutableSet * permIdsInserted = [[NSMutableSet alloc] init];

    NSMutableDictionary * permMap = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * permDbMapLocal = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * permDbMapServer = [[NSMutableDictionary alloc] init];
    NSMutableArray * permDbArray = [[NSMutableArray alloc] init];

    NSMutableSet * permIdsToInsert = [[NSMutableSet alloc] init];
    NSMutableSet * permIdsNotOnServer = [[NSMutableSet alloc] init];

    NSMutableArray * permIdsVals = [[NSMutableArray alloc] init];
    NSMutableArray * whereSql = [[NSMutableArray alloc] init];

    NSInteger numInserted = 0;
    NSInteger numUpdated = 0;
    NSInteger numReset = 0;

    // Sorting, mapping, SQL query building.
    for(PEXDbAccountingPermission * perm in policy){
        PEXAccountingPermissionId * permId = [PEXAccountingPermissionId idWithPermission:perm];
        perm.localView = nil;
        perm.subscription = @(subscription);

        [permIdsToInsert addObject:permId];
        permMap[permId] = perm;

        [permIdsVals addObject:perm.licId];
        [permIdsVals addObject:perm.permId];
        [whereSql addObject:[NSString stringWithFormat:@" (%@=? AND %@=?) ", PEX_DBAP_FIELD_LIC_ID, PEX_DBAP_FIELD_PERM_ID]];
    }

    // Load all permissions from database, with both local and server view.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * cursor = nil;
    @try {
        cursor = [cr query:[PEXDbAccountingPermission getURI]
                projection:[PEXDbAccountingPermission getFullProjection]
                 selection:[NSString stringWithFormat:@"WHERE %@ = ?", PEX_DBAP_FIELD_SUBSCRIPTION] //[NSString stringWithFormat:@" WHERE (%@)", [whereSql componentsJoinedByString:@" OR "]]
                selectionArgs: @[@(subscription)] //permIdsVals
                    sortOrder:nil];

        while ([cursor moveToNext]) {
            PEXDbAccountingPermission * const permission = [PEXDbAccountingPermission accountingPermissionWithCursor:cursor];
            PEXAccountingPermissionId * permId = [PEXAccountingPermissionId idWithPermission:permission];
            if (permission) {
                if ([permission.localView isEqualToNumber:@(1)]){
                    permDbMapLocal[permId] = permission;
                } else {
                    permDbMapServer[permId] = permission;
                }

                [permDbArray addObject:permission];
                [permIdsNotOnServer addObject:permId];
            }
        }

        // 1. update permissions DB && SERVER
        for (PEXDbAccountingPermission * const permission in permDbArray) {
            PEXDbAccountingPermission * dbPerm = permission;
            PEXAccountingPermissionId * curId = [PEXAccountingPermissionId idWithPermission:dbPerm];
            PEXDbAccountingPermission * serverPerm = permMap[curId];
            if (serverPerm == nil){
                continue;
            }

            // Exists in database, remove from insert set.
            [permIdsToInsert removeObject:curId];
            [permIdsNotOnServer removeObject:curId];

            dbPerm.value = serverPerm.value;
            dbPerm.validFrom = serverPerm.validFrom;
            dbPerm.validTo = serverPerm.validTo;
            dbPerm.subscription = serverPerm.subscription;
            dbPerm.name = serverPerm.name;

            // Update existing record with current values defined by policy that are not changed locally.
            @try {
                int changed = [cr updateEx:[PEXDbAccountingPermission getURI]
                             ContentValues:[dbPerm getDbContentValues]
                                 selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBAP_FIELD_ID]
                             selectionArgs:@[dbPerm.id]];

                if (changed > 0) {
                    [permIdsUpdated addObject:curId];
                    numUpdated += 1;
                }
            } @catch (NSException *ex2) {
                DDLogError(@"Could not update permission %@, exception %@", curId, ex2);
            }
        }

        // 2. set value to 0 for DB && !SERVER
        for(PEXAccountingPermissionId * permId in permIdsNotOnServer){
            PEXDbAccountingPermission * permLocal = permDbMapLocal[permId];
            PEXDbAccountingPermission * permServer = permDbMapServer[permId];

            // Local view.
            if (permLocal != nil && ![permLocal.value isEqualToNumber:@(0)]) {
                @try {
                    permLocal.value = @(0);
                    int changed = [cr updateEx:[PEXDbAccountingPermission getURI]
                                 ContentValues:[permLocal getDbContentValues]
                                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBAP_FIELD_ID]
                                 selectionArgs:@[permLocal.id]];

                    if (changed > 0) {
                        [permIdsUpdated addObject:permId];
                        DDLogVerbose(@"Permission reset (local view): %@", permLocal);
                        numReset += 1;
                    }
                } @catch (NSException *ex2) {
                    DDLogError(@"Could not reset permission %@, exception %@", permId, ex2);
                }
            }

            // Server view.
            if (permServer != nil && ![permServer.value isEqualToNumber:@(0)]) {
                @try {
                    permServer.value = @(0);
                    int changed = [cr updateEx:[PEXDbAccountingPermission getURI]
                                 ContentValues:[permServer getDbContentValues]
                                     selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBAP_FIELD_ID]
                                 selectionArgs:@[permServer.id]];

                    if (changed > 0) {
                        [permIdsUpdated addObject:permId];
                        DDLogVerbose(@"Permission reset (server view): %@", permServer);
                        numReset += 1;
                    }
                } @catch (NSException *ex2) {
                    DDLogError(@"Could not reset permission %@, exception %@", permId, ex2);
                }
            }
        }

        // 3. !DB && SERVER
        // All records were updated, now insert new ones, both local and remote views.
        for(PEXAccountingPermissionId * curId in permIdsToInsert){
            // Remote view.
            @try {
                PEXDbAccountingPermission *serverPerm = permMap[curId];
                serverPerm.localView = @(0);
                serverPerm.spent = @(0);

                PEXDbUri const * uri = [cr insert:[PEXDbAccountingPermission getURI] contentValues:[serverPerm getDbContentValues]];
                if (uri != nil){
                    numInserted += 1;
                    DDLogVerbose(@"Permission inserted (local view): %@", serverPerm);
                    [permIdsInserted addObject:curId];
                }

            } @catch(NSException * ex2){
                DDLogError(@"Could not insert permission to database, %@, exception %@", curId, ex2);
            }

            // Local view.
            @try {
                PEXDbAccountingPermission *serverPerm = permMap[curId];
                serverPerm.localView = @(1);
                serverPerm.spent = @(0);

                PEXDbUri const * uri = [cr insert:[PEXDbAccountingPermission getURI] contentValues:[serverPerm getDbContentValues]];
                if (uri != nil){
                    DDLogVerbose(@"Permission inserted (server view): %@", serverPerm);
                    [permIdsInserted addObject:curId];
                }

            } @catch(NSException * ex2){
                DDLogError(@"Could not insert permission to database, %@, exception %@", curId, ex2);
            }
        }

        DDLogVerbose(@"Server policy updated: %d, reset: %d, inserted: %d, subscription: %d",
                (int) numUpdated, (int) numReset, (int) numInserted, subscription);

        [self onServerPolicyUpdate:permIdsUpdated inserted:permIdsInserted];
    }@catch(NSException * ex){
        DDLogError(@"Exception in DB load: %@", ex);
        success = NO;

    }@finally{
        [PEXUtils closeSilentlyCursor:cursor];
    }

    return success;
}

// ---------------------------------------------
#pragma mark - Permission from permission counters merge
// ---------------------------------------------

/**
 * Parses JSON array of permissions, updating server view of the permission counters locally.
 * Mainly targets spent field.
 */
+ (void)updatePermissionsFromServerJson:(NSArray *)permissions {
    if (permissions == nil || [permissions count] == 0){
        DDLogVerbose(@"Empty permissions list, nothing to process");
        return;
    }

    NSMutableArray * permArr = [[NSMutableArray alloc] init];
    for(id permSer in permissions){
        @try {
            NSDictionary * permDict = (NSDictionary *) permSer;
            PEXDbAccountingPermission * perm = [self permissionFromDict:permDict];
            [permArr addObject:perm];

        } @catch (NSException * e){
            DDLogError(@"Exception in parsing permission %@", e);
        }
    }

    [self updatePermissionsFromServer:permArr];
}

/**
 * Updates server view of the permissions.
 * Array contains PEXDbAccountingPermission objects.
 */
+ (void)updatePermissionsFromServer:(NSArray *)permissions {
    if (permissions == nil || [permissions count] == 0){
        DDLogVerbose(@"Empty permissions list, nothing to process");
        return;
    }

    // Load existing from database, update existing, insert new.
    // Trigger server change if any. Recalculate local view?
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    @try {
        NSMutableSet * permIdsUpdated = [[NSMutableSet alloc] init];
        NSMutableSet * permIdsInserted = [[NSMutableSet alloc] init];

        NSMutableSet * permIdsToInsert = [[NSMutableSet alloc] init];
        NSMutableDictionary * permMap = [[NSMutableDictionary alloc] init];
        NSMutableArray * permIdsVals = [[NSMutableArray alloc] init];
        NSMutableArray * whereSql = [[NSMutableArray alloc] init];
        for(PEXDbAccountingPermission * perm in permissions){
            PEXAccountingPermissionId * permId = [PEXAccountingPermissionId idWithPermission:perm];
            perm.localView = @(0);

            [permIdsToInsert addObject:permId];
            permMap[permId] = perm;

            [permIdsVals addObject:perm.licId];
            [permIdsVals addObject:perm.permId];
            [whereSql addObject:[NSString stringWithFormat:@" (%@=? AND %@=?) ", PEX_DBAP_FIELD_LIC_ID, PEX_DBAP_FIELD_PERM_ID]];
        }

        // Load all permissions from database, only with server view.
        PEXDbCursor * cursor = nil;
        @try {
            cursor = [cr query:[PEXDbAccountingPermission getURI]
                    projection:[PEXDbAccountingPermission getFullProjection]
                     selection:[NSString stringWithFormat:@" WHERE %@=0 AND (%@)",
                                     PEX_DBAP_FIELD_LOCAL_VIEW,
                                     [whereSql componentsJoinedByString:@" OR "]]
                 selectionArgs:permIdsVals
                     sortOrder:nil];

            while([cursor moveToNext]){
                PEXDbAccountingPermission * dbPerm = [PEXDbAccountingPermission accountingPermissionWithCursor:cursor];
                PEXAccountingPermissionId * curId = [PEXAccountingPermissionId idWithPermission:dbPerm];

                // Exists in database, remove from insert set.
                [permIdsToInsert removeObject:curId];

                // Update existing record.
                @try {
                    PEXDbAccountingPermission *serverPerm = permMap[curId];
                    int changed = [cr updateEx:[PEXDbAccountingPermission getURI]
                                 ContentValues:[serverPerm getDbContentValues]
                                     selection:[NSString stringWithFormat:@"WHERE %@=0 AND %@=? AND %@=?",
                                                                          PEX_DBAP_FIELD_LOCAL_VIEW,
                                                                          PEX_DBAP_FIELD_LIC_ID,
                                                                          PEX_DBAP_FIELD_PERM_ID]
                                 selectionArgs:@[serverPerm.licId, serverPerm.permId]];

                    if (changed > 0) {
                        [permIdsUpdated addObject:curId];
                    }

                } @catch(NSException * ex2){
                    DDLogError(@"Could not update permission %@, exception %@", curId, ex2);
                }
            }

            // All records were updated, now insert new ones.
            for(PEXAccountingPermissionId * curId in permIdsToInsert){
                @try {
                    PEXDbAccountingPermission *serverPerm = permMap[curId];
                    PEXDbUri const * uri = [cr insert:[PEXDbAccountingPermission getURI] contentValues:[serverPerm getDbContentValues]];
                    if (uri != nil){
                        [permIdsInserted addObject:curId];
                    }

                } @catch(NSException * ex2){
                    DDLogError(@"Could not insert permission to database, %@, exception %@", curId, ex2);
                }
            }

        }@catch(NSException * ex){
            DDLogError(@"Exception in DB load: %@", ex);

        }@finally{
            [PEXUtils closeSilentlyCursor:cursor];
        }

        // Post processing.
        [self onServerPermissionChange:permIdsUpdated inserted:permIdsInserted];

    } @catch (NSException * e){
        DDLogError(@"Exception in parsing permission %@", e);
    }
}

// ---------------------------------------------
#pragma mark - Local change handler
// ---------------------------------------------

/**
 * Called when server view of the permission is changed and persisted in the local database.
 * If sets are nil, each record is considered as updated / new one.
 * Internal call.
 *
 * Mainly performs 2 steps:
 * 1. Get permission counter diff, if server perm is bigger, update local one.
 *    Local counters can contain higher values as they might be updated with recent activity not yet presented to the server.
 * 2. Store all server-only permissions to local.
 */
+ (void)onServerPermissionChange: (NSSet *) updated inserted: (NSSet *) inserted{
    NSMutableDictionary * serverViews = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * localViews = [[NSMutableDictionary alloc] init];

    PEXDbCursor * cursor = nil;
    @try {
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        cursor = [cr query:[PEXDbAccountingPermission getURI]
                projection:[PEXDbAccountingPermission getFullProjection]
                 selection:@"WHERE 1"
             selectionArgs:@[]
                 sortOrder:nil];

        while([cursor moveToNext]){
            PEXDbAccountingPermission * cPer = [PEXDbAccountingPermission accountingPermissionWithCursor:cursor];
            PEXAccountingPermissionId * curId = [PEXAccountingPermissionId idWithPermission:cPer];
            const BOOL localView = [cPer.localView boolValue];

            if (localView){
                localViews[curId] = cPer;
            } else {
                serverViews[curId] = cPer;
            }
        }

        // Step 1 - get diff, if server perm is bigger, update local one.
        // Local counters can contain higher values as they might be updated with recent activity not yet presented to the server.
        for(PEXAccountingPermissionId * curId in serverViews) {
            if (localViews[curId] == nil) {
                continue;
            }

            BOOL doUpdate = NO;
            PEXDbAccountingPermission * serverPerm = serverViews[curId];
            PEXDbAccountingPermission * localPerm = localViews[curId];

            // Compare value values. If server one has bigger, take local one.
            if ([localPerm.spent compare:serverPerm.spent] == NSOrderedAscending){
                DDLogVerbose(@"Server side counter has higher spent counter: id=%@, local=%@, server=%@", curId, localPerm.spent, serverPerm.spent);
                doUpdate = YES;
            }

            PEXAccountingLogId * lastIdServer = [PEXAccountingLogId idWithId:serverPerm.actionIdLast ctr:serverPerm.actionCtrLast];
            PEXAccountingLogId * lastIdLocal = [PEXAccountingLogId idWithId:localPerm.actionIdLast ctr:localPerm.actionCtrLast];
            NSComparisonResult lastCmpRes = [PEXAccountingLogId compare:lastIdLocal b:lastIdServer];
            if (lastCmpRes == NSOrderedSame){
                // TODO: remove stale, expired permissions from database.
                //DDLogVerbose(@"Server view & local view for last accounting log is the same for %@, last: %@", curId, lastIdLocal);
            }

            if (doUpdate && lastCmpRes == NSOrderedDescending){
                // Server has older view but bigger number?
                DDLogError(@"Server view of permission has bigger spent counter, but older record!");
            }

            if (doUpdate){
                PEXDbAccountingPermission * newLocal = [serverPerm copy];
                newLocal.localView = @(1);
                int affected = [cr updateEx:[PEXDbAccountingPermission getURI]
                              ContentValues:[newLocal getDbContentValues]
                                  selection:@"WHERE %@=?"
                              selectionArgs:@[localPerm.id]];
                DDLogVerbose(@"Updateing counter %@, new spent value %@, affected: %d", curId, newLocal.spent, affected);
            }
        }

        // Step 2 - Store all server-only permissions to local.
        for(PEXAccountingPermissionId * curId in serverViews){
            if (localViews[curId] != nil){
                continue;
            }

            PEXDbAccountingPermission * serverPerm = serverViews[curId];
            PEXDbAccountingPermission * localPerm = [serverPerm copy];
            localPerm.localView = @(1);
            localPerm.id = nil;

            @try {
                PEXDbUri const *uri = [cr insert:[PEXDbAccountingPermission getURI] contentValues:[localPerm getDbContentValues]];

            }@catch(NSException * ex){
                DDLogError(@"Exception when inserting server-only permission %@, exc=%@", curId, ex);
            }
        }

        // Permissions were updated, recalculate counters.
        [self recalculateCountersFromPermissions];

    }@catch(NSException * e){
        DDLogError(@"DB error when processing permissions: %@", e);

    }@finally{
        [PEXUtils closeSilentlyCursor:cursor];
    }
}

// ---------------------------------------------
#pragma mark - Change Handlers
// ---------------------------------------------


+(void) recalculateCountersFromPermissions {
    // TODO: implement, call logic from Matej.
}


// everything in database
+(void) onServerPolicyUpdate: (NSSet *) updated inserted: (NSSet *) inserted
{
    [[[PEXService instance] licenceManager] onServerPolicyUpdate:updated inserted:inserted];
}
@end