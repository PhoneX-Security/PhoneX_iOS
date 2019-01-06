//
// Created by Matej Oravec on 24/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFileRestrictorManager.h"
#import "PEXFileSelectRestrictor.h"
#import "PEXSingleTransferRestrictor.h"
#import "PEXFileCountRestrictor.h"
#import "PEXLicenceManager.h"
#import "PEXPermissionsUtils.h"
#import "PEXFilePickManager.h"
#import "PEXDbAccountingPermission.h"
#import "PEXFileCOuntRestrictor.h"
#import "PEXService.h"

@interface PEXFileRestrictorFactory ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * managersInField;
@property (nonatomic, weak) PEXFilePickManager * pickManager;

@end

@implementation PEXFileRestrictorFactory {

}

- (void) permissionsChanges: (NSArray * const) permissions
{
    [self.lock lock];

    for (PEXFileRestrictorManager * const manager in self.managersInField)
        [manager setRestrictors:[self generateRestrictorsFromPermissions:permissions]];

    [self.lock unlock];
}

- (NSArray *) generateRestrictorsFromPermissions: (NSArray * const) permissions
{

    NSMutableArray * result = [[NSMutableArray alloc] init];

    [result addObject:[[PEXSingleTransferRestrictor alloc] init]];


    PEXFileCountRestrictor * const fileCountRestrictor =
            [PEXFileRestrictorFactory getCountRestrictorFromPermissions:permissions];

    if (fileCountRestrictor)
        [result addObject:fileCountRestrictor];

    return result;
}

+ (int64_t) getSpentFileCount: (NSArray * const) permissions limitOut: (int64_t * const) limitOut
{
    int64_t spent = 0;
    int64_t limit = 0;

    if (permissions && permissions.count) {

        for (const PEXDbAccountingPermission * const permission in permissions)
        {
            if (![PEXPermissionsUtils isPermissionForFiles:permission.name])
                continue;

            const int64_t value = [permission.value longLongValue];

            if (value == 0)
                continue;

            if (value == -1) {
                limit = value;
                spent = 0;
                break;
            }
            else
            {
                spent += [permission.spent longLongValue];
                limit += [permission.value longLongValue];
            }
        }
    }

    if (limitOut)
        *limitOut = limit;

    return spent;
}

+ (int64_t) getAvailableFileCountForPermissions: (NSArray * const) permissions
{
    int64_t limit = 0;
    const int64_t spent = [self getSpentFileCount:permissions limitOut:&limit];

    return (limit != -1) ? (limit - spent) : limit;
}

+ (PEXFileCountRestrictor *) getCountRestrictorFromPermissions: (NSArray * const) permissions
{
    int64_t limit = 0;
    const int64_t spent = [self getSpentFileCount:permissions limitOut:&limit];

    PEXFileCountRestrictor * result;

    if (limit == -1)
        result = nil;
    else if ((limit == 0) && (spent == 0))
        result = [[PEXFileCountRestrictor alloc] initWithMaxCount:0];
    else
        result = [[PEXFileCountRestrictor alloc] initWithMaxCount:limit - spent];

    return result;
}

- (id) init {
    self = [super init];

    self.lock = [[NSLock alloc] init];
    self.managersInField = [[NSMutableArray alloc] init];

    return self;
}

+ (NSArray *) getFilesPermissions
{
    return [[[PEXService instance] licenceManager] getPermissions:nil
                                                         forPrefix:PEX_PERMISSION_FILES_PREFIX
                                                      validForDate:[PEXLicenceManager currentTimeSinceReference]];
}

- (PEXFileRestrictorManager *)createManagerInstance {

    PEXFileRestrictorManager * const result = [[PEXFileRestrictorManager alloc] init];

    [self.lock lock];

    [self.managersInField addObject:result];

    NSArray * const permissions = [PEXFileRestrictorFactory getFilesPermissions];

    [result setRestrictors:[self generateRestrictorsFromPermissions:permissions]];

    [self.lock unlock];

    return result;
}

// Array cannot hold weak references
- (void) destroyManagerInstance: (const PEXFileRestrictorManager * const) managerInstance
{
    [self.lock lock];

    [self.managersInField removeObject:managerInstance];

    [self.lock unlock];
}


@end

// MANAGER

@interface PEXFileRestrictorManager ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSArray * selectedFiles;
@property (nonatomic) NSArray * currentRestrictors;

@end

@implementation PEXFileRestrictorManager {

}

- (bool) everythingIsOk
{
    return [self checkFileRestrictionStatus] == PEX_SELECTION_DESC_STATUS_OK;
}

- (void)setRestrictors: (NSArray *) restrictors
{
    [self.lock lock];

    self.currentRestrictors = restrictors;
    [self resetRestrictorsWithFiles];

    [self.lock unlock];

    [self.pickManager restrictiorChanged];
}

- (void) setFiles: (NSArray * const) files
{
    [self.lock lock];

    self.selectedFiles = files;
    [self resetRestrictorsWithFiles];

    [self.lock unlock];
}

- (void) resetRestrictorsWithFiles
{
    for (PEXFileSelectRestrictor * const restrictor in self.currentRestrictors)
        [restrictor setSelectedFiles:self.selectedFiles];
}

// TODO dispatch info on update if files/restrictors?

- (PEXSelectionDescriptionStatus)checkFileRestrictionStatus
{
    PEXSelectionDescriptionStatus result = PEX_SELECTION_DESC_STATUS_OK;

    [self.lock lock];

    for (PEXFileSelectRestrictor * const restrictor in [self.currentRestrictors reverseObjectEnumerator])
    {
        const PEXSelectionDescriptionStatus status = [restrictor overlaps];

        if (status != PEX_SELECTION_DESC_STATUS_OK)
            result = status;
    }

    [self.lock unlock];

    return result;
}

- (NSArray *) getRestrictorsDescriptions
{
    NSMutableArray * result = [[NSMutableArray alloc] init];

    [self.lock lock];

    for (PEXFileSelectRestrictor * const restrictor in self.currentRestrictors)
    {
        [result addObject: [restrictor getCurrentStateDescription]];
    }

    [self.lock unlock];

    return result;
}


- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];

    return self;
}

@end