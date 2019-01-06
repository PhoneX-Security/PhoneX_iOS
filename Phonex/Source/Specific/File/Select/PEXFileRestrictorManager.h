//
// Created by Matej Oravec on 24/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXFileSelectRestrictor.h"
#import "PEXLicenceManager.h"

@class PEXSelectionDescriptionInfo;
@class PEXFileRestrictorManager;
@class PEXFilePickManager;
@class PEXFileCountRestrictor;

@interface PEXFileRestrictorFactory : NSObject

+ (NSArray *) getFilesPermissions;
- (PEXFileRestrictorManager *) createManagerInstance;
- (void) destroyManagerInstance: (const PEXFileRestrictorManager * const) managerInstance;
- (void) permissionsChanges: (NSArray * const) permissions;

+ (int64_t) getAvailableFileCountForPermissions: (NSArray * const) permissions;

@end


@interface PEXFileRestrictorManager : NSObject

@property (nonatomic, weak) PEXFilePickManager * pickManager;


- (void)setRestrictors: (NSArray *) restrictors;
- (void) setFiles: (NSArray * const) files;

- (PEXSelectionDescriptionStatus)checkFileRestrictionStatus;
- (bool) everythingIsOk;

- (NSArray *) getRestrictorsDescriptions;

@end