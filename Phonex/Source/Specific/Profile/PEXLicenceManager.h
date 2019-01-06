//
// Created by Matej Oravec on 21/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXReferenceTimeManager.h"
#import "PEXServiceModuleProtocol.h"

@class PEXLicenceInfo;
@class PEXDbAccountingPermission;
@class PEXFileRestrictorFactory;
@class PEXLicenceCheckTask;
@class PEXSOAPResult;

@protocol PEXLicenceListener

- (void) permissionsChanged: (NSArray * const) permissions;

@end

@interface PEXLicenceManager : NSObject<PEXReferenceTimeUpdateListener, PEXServiceModuleProtocol>

@property (nonatomic, readonly) PEXFileRestrictorFactory * fileRestrictorFactory;

+ (void)addExpiredLicenceLogs:(NSArray *const)logs;;

- (void)onServerPolicyUpdate: (NSSet *) updated inserted: (NSSet *) inserted;

- (NSArray *)getPermissions:(NSArray **const)futures
                  forPrefix:(NSString *const)typePrefix
               validForDate: (NSDate * const) oldestValidFrom;

- (void) addListenerAndSet: (id<PEXLicenceListener>) listener;
- (void) addListenerAndSet: (id<PEXLicenceListener>) listener
                 forPrefix: (NSString * const) prefix;

- (void) removeListener: (id<PEXLicenceListener>) listener;

- (void)executeOnPermissionUpdateQueue: (dispatch_block_t) block;
- (void) triggerCheckPermissions;
- (void) checkPermissionsAsync;
- (void) checkPermissionsAsyncCompletion: (void(^)(PEXLicenceCheckTask *)) completionHandler;

/**
 * Updates policy settings from the given dictionary configuration.
 * Updates only if timestamp is newer or same as the previous update.
 * So the previous configuration does not overwrite newer in the database.
 */
-(void) updatePolicyFrom: (NSDictionary *) policySettings;

- (void)setExpirationCheckTaskIfNeeded;

- (void)permissionsValuesWereConsumedAsync:(const int64_t)consumedTimeInSeconds
                              validForDate:(NSDate *const)oldestValidFom
                                 forPrefix: (NSString * const) prefix;

- (void)outgoingMessageInExpiredModeAckedOn:(NSDate *const)sendDate;
- (void)outgoingFilesAckedOn:(NSDate *const)sendDate withCount: (const int64_t) count;

- (int64_t)getOutgoingMessageCountForLastDays: (const int) daysCount;

+ (NSDate *) currentTimeSinceReference;

// TODO preserve?
- (bool) checkPermissionsAndShowGetPremiumInParent: (PEXGuiController * const) parent;

@end