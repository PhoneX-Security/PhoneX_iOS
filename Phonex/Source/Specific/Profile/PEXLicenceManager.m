//
// Created by Matej Oravec on 21/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLicenceManager.h"
#import "PEXLicenceInfo.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDBUserProfile.h"
#import "PEXGuiManageLicenceController.h"
#import "PEXLicenceCheckTask.h"
#import "PEXSOAPResult.h"
#import "PEXDelayedTask.h"
#import "PEXTask_Protected.h"
#import "PEXService.h"
#import "PEXFileRestrictorManager.h"
#import "PEXConnectivityChange.h"
#import "PEXGuiTimeUtils.h"
#import "PEXDbAccountingPermission.h"
#import "PEXDbAccountingPermission.h"
#import "PEXPermissionsUtils.h"
#import "PEXDbAccountingLog.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXChatAccountingManager.h"
#import "PEXAccountingLogUpdaterTask.h"
#import "PEXPaymentManager.h"
#import "PEXApplicationStateChange.h"
#import "PEXAccountingHelper.h"
#import "PEXUtils.h"


@interface PEXLicenceManager ()

@property (nonatomic) BOOL registered;
@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * listeners;
@property (nonatomic) PEXDelayedTask * permissionsCheckTask;

@property (nonatomic) PEXFileRestrictorFactory * fileRestrictorFactory;

/**
 * If set to YES, licence refresh task should be called when (isActive && isConnected) starts to hold again.
 */
@property (nonatomic) BOOL deferredLicenceRefresh;
@property (nonatomic) NSInteger deferredLicenceRefreshFails;

/**
 * Last reference time obtained by calling permission update.
 * Not to fall in loop by calling fill callback, refresh, fill, refresh, ...
 */
@property (nonatomic) PEXReferenceTime * lastRefTime;

/**
 * Processing only newer configurations.
 */
@property (nonatomic) NSNumber * lastPolicyTimestampStart;
@property (nonatomic) NSNumber * lastPolicyTimestampFinished;
@end

@implementation PEXLicenceManager {

}

dispatch_queue_t getPermissionExpireCheckAsyncQueue(void)
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("PEXLicenceManager_getPermissionExpireCheckAsyncQueue", 0);
    });

    return queue;
}

dispatch_queue_t getUpdateAfterCallQueue(void)
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("PEXLicenceManager_getPermissionCheckAsyncQueue", 0);
    });

    return queue;
}

dispatch_queue_t getMessageAckedQueue(void)
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("PEXLicenceManager_getMessageAckedQueue", 0);
    });

    return queue;
}

dispatch_queue_t getLogUploadQueue(void)
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("PEXLicenceManager_getLogUploadQueue", 0);
    });

    return queue;
}

dispatch_queue_t getPermissionUpdateCheckAsyncQueue(void)
{
    static dispatch_queue_t queue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("PEXLicenceManager_getPermissionUpdateCheckAsyncQueue", DISPATCH_QUEUE_SERIAL);
    });

    return queue;
}

int64_t getActionId()
{
    static NSLock * lock = nil;
    static int64_t counter = 0;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSLock alloc] init];
    });

    int64_t result = 0;

    [lock lock];

    result = counter++;

    [lock unlock];

    return result;
}

- (id) init
{
    self = [super init];

    self.registered = NO;
    self.deferredLicenceRefresh = NO;
    self.deferredLicenceRefreshFails = 0;
    self.lock = [[NSLock alloc] init];
    self.listeners = [[NSMutableArray alloc] init];
    self.fileRestrictorFactory = [[PEXFileRestrictorFactory alloc] init];

    return self;
}

- (void)added:(const PEXReferenceTime *const)referenceTime
{
    WEAKSELF;
    dispatch_async(getPermissionUpdateCheckAsyncQueue(), ^{
        // Triggered by updating time as a side effect of this call?
        if (referenceTime != nil && weakSelf.lastRefTime != nil && [referenceTime isEqualToTime:weakSelf.lastRefTime]){
            return;
        }

        [weakSelf checkPermissionsAsyncInternalCompletion:nil];
    });
}

- (void)fill:(const PEXReferenceTime *const)referenceTime
{
    WEAKSELF;
    dispatch_async(getPermissionUpdateCheckAsyncQueue(), ^{
        // Triggered by updating time as a side effect of this call?
        if (referenceTime != nil && weakSelf.lastRefTime != nil && [referenceTime isEqualToTime:weakSelf.lastRefTime]){
            return;
        }

        [weakSelf checkPermissionsAsyncInternalCompletion:nil];
    });
}

+ (NSDate *) currentTimeSinceReference
{
    return [[[PEXAppState instance] referenceTimeManager] currentTimeSinceReference: [NSDate date]];
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for new presence notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        DDLogDebug(@"Licence manager registered");
        self.registered = YES;
        self.deferredLicenceRefresh = NO;
        self.deferredLicenceRefreshFails = 0;
        self.lastPolicyTimestampStart = nil;
        self.lastPolicyTimestampFinished = nil;
    }
}

-(void) doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];

        DDLogDebug(@"Licence manager unregistered");
        self.registered = NO;
    }
}

- (void)updatePrivData:(PEXUserPrivate *)privData {

}

- (void) dealloc
{
    [self doUnregister];
}

- (NSArray *)getPermissions:(NSArray **const)futures
                  forPrefix:(NSString *const)typePrefix
               validForDate: (NSDate * const) oldestValidFrom
{
    [self.lock lock];

    NSArray * const result = [PEXLicenceManager getPermissionsInternalNotSafe:futures
                                                                    forPrefix:typePrefix
                                                                 validForDate:oldestValidFrom];

    [self.lock unlock];

    return result;
}

+ (void) appedWhereTo: (NSMutableString * const) selection
                 args: (NSMutableArray * const) selectionArgs
            forPrefix: (NSString * const) prefix
{
    if ([prefix isEqualToString:PEX_PERMISSION_CALLS_PREFIX])
    {
        [selection appendString:[NSString stringWithFormat:@" AND (%@ = ?)",PEX_DBAP_FIELD_NAME]];
        [selectionArgs addObject:PEX_PERMISSION_CALLS_LIMIT_NAME];
    }
    else if ([prefix isEqualToString:PEX_PERMISSION_FILES_PREFIX])
    {
        [selection appendString:[NSString stringWithFormat:@" AND (%@ = ?)",PEX_DBAP_FIELD_NAME]];
        [selectionArgs addObject:PEX_PERMISSION_FILES_LIMIT_NAME];
    }
    else if ([prefix isEqualToString:PEX_PERMISSION_MESSAGES_PREFIX])
    {
        [selection appendString:[NSString stringWithFormat:@" AND (%@ = ? OR %@ = ?)",
                        PEX_DBAP_FIELD_NAME, PEX_DBAP_FIELD_NAME]];

        [selectionArgs addObject:PEX_PERMISSION_MESSAGES_DAILY_NAME];
        [selectionArgs addObject:PEX_PERMISSION_MESSAGES_LIMIT_NAME];
    }
}

+ (PEXDbCursor *)readPermissionsForPrefix:(NSString *const)typePrefix
                             validForDate: (NSDate * const) oldestValidFrom
{
    PEXDbContentProvider * const cp = [PEXDbAppContentProvider instance];

    const bool oldestFromIsValid = (oldestValidFrom != nil);

    NSString * sortOrder;

    NSMutableString * const selection =
            [[NSMutableString alloc] initWithFormat:@" WHERE (%@ = ? AND %@ != ?) ",
                            PEX_DBAP_FIELD_LOCAL_VIEW, PEX_DBAP_FIELD_AMOUNT];

    NSMutableArray * const selectionArgs = [[NSMutableArray alloc] init];
    [selectionArgs addObject:[@(1) stringValue]];
    [selectionArgs addObject:[@(0) stringValue]];


    if (typePrefix || oldestFromIsValid)
    {
        if (typePrefix)
        {
            [self appedWhereTo:selection
                          args:selectionArgs
                     forPrefix:typePrefix];
        }

        if (oldestFromIsValid)
        {
            [selection appendString:
                    [NSString stringWithFormat:@" AND (%@ <= ? AND %@ >= ?) ",
                                               PEX_DBAP_FIELD_VALID_FROM, PEX_DBAP_FIELD_VALID_TO]];

//            [NSString stringWithFormat:@" AND %@ <= ? ",
//                                       PEX_DBAP_FIELD_VALID_FROM]];

            NSNumber * const dateNumberRepresentation = [PEXDbContentValues getNumericDateRepresentation:oldestValidFrom];
            [selectionArgs addObject: dateNumberRepresentation];
            [selectionArgs addObject:[dateNumberRepresentation copy]];

            /*
             * also add order
             * OLD SUBSCRIPTION
             * NEW SUBSCRIPTION
             * OLD CONSUMABLE
             * NEW CONSUMABLE
             */
            sortOrder = [NSString stringWithFormat: @" ORDER BY %@ DESC, %@ ASC ",
                            PEX_DBAP_FIELD_SUBSCRIPTION, PEX_DBAP_FIELD_VALID_FROM];
        }
    }

    return [cp query:[PEXDbAccountingPermission getURI]
                                projection:[PEXDbAccountingPermission getFullProjection]
                                 selection:selection
                             selectionArgs:selectionArgs
                                 sortOrder:sortOrder];
}

+ (NSArray *)getPermissionsInternalNotSafe:(NSArray **const)futures
                                 forPrefix:(NSString *const)typePrefix
                              validForDate: (NSDate * const) oldestValidFrom
{
    PEXDbCursor * const cursor = [self readPermissionsForPrefix:typePrefix
                                                   validForDate:oldestValidFrom];

    NSMutableArray * const result = [[NSMutableArray alloc] init];
    NSMutableArray * const futuresResult = [[NSMutableArray alloc] init];

    while (cursor && [cursor moveToNext])
    {
        PEXDbAccountingPermission * const permission =
                [[PEXDbAccountingPermission alloc] initWithCursor:cursor];

        bool permissionIsRelevant = true;
        NSDate *const currentTime = [self currentTimeSinceReference];

        // we did not specify the time period
        if (!oldestValidFrom)
        {
            permissionIsRelevant =
                    [PEXDateUtils date:permission.validFrom isOlderThanOrEqualTo:currentTime] &&
                            [PEXDateUtils date:permission.validTo isNewerThanOrEqualTo:currentTime];
        }

        const bool isFromFuture = [PEXDateUtils date:permission.validFrom isNewerThan:currentTime];

        if (permissionIsRelevant)
            [result addObject:permission];
        else if (isFromFuture)
            [futuresResult addObject:permission];
    }

    if (futures)
        *futures = futuresResult;

    return result;
}

- (void) addListenerAndSet: (id<PEXLicenceListener>) listener
{
    [self addListenerAndSet:listener forPrefix:nil];
}

- (void) addListenerAndSet: (id<PEXLicenceListener>) listener
                 forPrefix: (NSString * const) prefix
{
    [self.lock lock];

    if (![self.listeners containsObject:listener]) {
        [self.listeners addObject:listener];

    } else {
        DDLogWarn(@"Listener already added %@", listener);

    }

    [listener permissionsChanged:[PEXLicenceManager getPermissionsInternalNotSafe:nil
                                                                        forPrefix:prefix
                                                                     validForDate:nil]];

    [self.lock unlock];
}

- (void) removeListener: (id<PEXLicenceListener>) listener
{
    [self.lock lock];

    [self.listeners removeObject:listener];

    [self.lock unlock];
}


// TODO light
// am  I a premium user?
// check number messages that will be sent?
// check minutes are more than needed minimum for a call?
- (bool)checkPermissionsAndShowGetPremiumInParent: (PEXGuiController * const) parent
{
    // add context
    // TODO check if minutes are available
    // TODO check if MBs are available
    // TODO check premium

    bool result = false;
    return result;
}

- (void)executeOnPermissionUpdateQueue: (dispatch_block_t) block {
    dispatch_async(getPermissionUpdateCheckAsyncQueue(), block);
}

- (void)triggerCheckPermissions
{
    DDLogVerbose(@"Triggering permission check, fails: %d", (int) self.deferredLicenceRefreshFails);
    WEAKSELF;
    [self checkPermissionsAsyncInternalCompletion:^(PEXLicenceCheckTask *task) {
        const BOOL failed = task.lastResult == nil
                || task.lastResult.err != nil
                || task.lastResult.code != PEX_SOAP_CALL_RES_OK;
        if (!failed){
            DDLogVerbose(@"Licence update completed successfully");
            weakSelf.deferredLicenceRefresh = NO;
            weakSelf.deferredLicenceRefreshFails = 0;
            return;
        }

        DDLogError(@"Licence update failed, error: %@", task.lastResult.err);
        weakSelf.deferredLicenceRefresh = YES;
        weakSelf.deferredLicenceRefreshFails += 1;

        // Try several times before giving up.
        [self retryCheckPermissions];
    }];
}

- (void)retryCheckPermissions {
    if (self.deferredLicenceRefreshFails >= 2){
        return;
    }

    if (![[PEXService instance] isConnectivityWorking]){
        return;
    }

    [self triggerCheckPermissions];
}

- (void)checkPermissionsAsync
{
    [self checkPermissionsAsyncInternalCompletion:nil];
}

- (void)checkPermissionsAsyncCompletion:(void (^)(PEXLicenceCheckTask *))completionHandler {
    [self checkPermissionsAsyncInternalCompletion:completionHandler];
}

- (void)checkPermissionsAsyncInternalCompletion:(void (^)(PEXLicenceCheckTask *))completionHandler
{
    // just call the task
    WEAKSELF;
    dispatch_async(getPermissionUpdateCheckAsyncQueue(), ^{
        PEXLicenceCheckTask *const task = [[PEXLicenceCheckTask alloc] init];
        task.policyProcessingSync = YES;

        [task requestUserInfo:[[PEXAppState instance] getPrivateData] cancelBlock:nil res:nil];
        if (task.lastRefTime != nil){
            weakSelf.lastRefTime = task.lastRefTime;
        }

        if (completionHandler){
            completionHandler(task);
        }
    });
}

-(void) updatePolicyFrom: (NSDictionary *) policySettings {
    NSNumber * timestamp = [PEXUtils getAsNumber:policySettings[@"timestamp"]];
    DDLogVerbose(@"Going to update policy, generated: %@", timestamp);

    // Do not accept empty policy.
    if (policySettings == nil || [policySettings count] == 0){
        DDLogVerbose(@"Not updating empty policy");
        return;
    }

    BOOL doUpdate = YES;
    if (timestamp != nil){
        if (self.lastPolicyTimestampStart != nil && [self.lastPolicyTimestampStart compare:timestamp] != NSOrderedAscending){
            DDLogVerbose(@"Not updating, started with newer: %@", self.lastPolicyTimestampStart);
            doUpdate = NO;
        }

        if (self.lastPolicyTimestampFinished != nil && [self.lastPolicyTimestampFinished compare:timestamp] != NSOrderedAscending){
            DDLogVerbose(@"Not updating, finished with newer: %@", self.lastPolicyTimestampFinished);
            doUpdate = NO;
        }
    }

    if (doUpdate){
        self.lastPolicyTimestampStart = timestamp;
        const BOOL success = [PEXAccountingHelper updatePermissionsDefinitionsJson:policySettings];
        self.lastPolicyTimestampStart = nil;
        if (success){
            self.lastPolicyTimestampFinished = timestamp;
        }
    }
}

- (void)onServerPolicyUpdate: (NSSet *) updated inserted: (NSSet *) inserted
{
    [self.lock lock];

    NSArray *newPermissions;
    NSArray *listenersCopy;

    const bool somethingUpdated = (updated && updated.count > 0) || (inserted && inserted.count > 0);
    const bool updateInformationIsVerified = true;

    // TODO on licence removal it is not reliable
    //if (somethingUpdated && updateInformationIsVerified)
    //{
        [self cancelPreviousPermissionsCheckTask];

        listenersCopy = [self.listeners copy];

        NSDate * const referenceTime = [PEXLicenceManager currentTimeSinceReference];
        NSArray * futures;
        newPermissions = [PEXLicenceManager getPermissionsInternalNotSafe:&futures
                                                                forPrefix:nil
                                                             validForDate:nil];

        DDLogVerbose(@"server policy updated. Reference time: %@, permissionsSize: %d, futureSize: %d",
                referenceTime,
                newPermissions == nil ? -1 : (int) [newPermissions count],
                futures == nil ? -1 : (int) [futures count]);

        // Debugging: get closest future
        const PEXDbAccountingPermission * const closestBeginning = [self getEarliestBeginning:futures];
        if (closestBeginning != nil){
            DDLogVerbose(@"Closest future valid from: %@", closestBeginning.validFrom);
        }
        if (futures != nil && [futures count] > 0){
            DDLogVerbose(@"Future permissions: %@", futures);
        }

        [self setPermissionCheckTaskForCurrent:newPermissions
                                       futures:futures
                              forReferenceTime:referenceTime];

    //}

    [self.lock unlock];

    if (listenersCopy)
    {
        [self notifyPermissionsChange:newPermissions toListeners:listenersCopy];
    }

    [self.fileRestrictorFactory permissionsChanges:newPermissions];
}

- (void) notifyPermissionsChange: (NSArray * const) permissions toListeners: (NSArray * const) listeners
{
    for (id <PEXLicenceListener> listener in listeners)
        [listener permissionsChanged:permissions];
}

- (void)cancelPreviousPermissionsCheckTask
{
    // cancel previous task if we are just changing the time of the time
    if (self.permissionsCheckTask && ![self.permissionsCheckTask isCancelled])
    {
        [self.permissionsCheckTask cancel];
        // DO NOT NIL-OUT THE reference.
        // the may may be stil doing something after cancel (cleanup)
    }
}

- (void)setExpirationCheckTaskIfNeeded
{
    [self.lock lock];

    if (!self.permissionsCheckTask)
    {
        [self setPermissionsCheckTaskInternal];
    }

    [self.lock unlock];
}

- (void)setPermissionsCheckTaskInternal
{
    NSArray * futures;
    NSArray * const currents = [PEXLicenceManager getPermissionsInternalNotSafe:&futures
                                                                      forPrefix:nil
                                                                   validForDate:nil];

    [self setPermissionCheckTaskForCurrent:currents
                                   futures:futures
                          forReferenceTime:[PEXLicenceManager currentTimeSinceReference]];
}

- (void)setPermissionCheckTaskForCurrent: (NSArray * const) currents
                                 futures: (NSArray * const) futures
                     forReferenceTime: (NSDate * const) referenceTime
{
    NSDate * const eventDate = [self getNextEventDate:currents futures:futures];

    if (eventDate) {
        DDLogVerbose(@"Scheduling new permission check. Next event date: %@, ref: %@", eventDate, referenceTime);
        [self createExpirationTaskForLicenceIn:[eventDate timeIntervalSinceDate:referenceTime]];
    }
}

- (void) createExpirationTaskForLicenceIn: (const NSTimeInterval)timeDelayInMilliseconds
{
    // TASK CREATION
    dispatch_time_t dispatchTime = [PEXDateUtils getDispatchTimeFromTimeInterval:timeDelayInMilliseconds];
    PEXDelayedTask * const expirationTask = [[PEXDelayedTask alloc] initWithEventTime:dispatchTime];
    self.permissionsCheckTask = expirationTask;

    WEAKSELF;

    self.permissionsCheckTask.completionBlock = ^{

        if (!expirationTask.isCancelled)
        {
            // set new task timed notification.
            // Capture strong reference so it cannot get nil during the execution of the block.
            PEXLicenceManager * sSelf = weakSelf;
            if (sSelf == nil){
                DDLogWarn(@"Weak self got nil");
                return;
            }

            DDLogVerbose(@"Permission check task running");
            NSArray * permissions = nil;

            [sSelf.lock lock];
            permissions = [PEXLicenceManager getPermissionsInternalNotSafe:nil
                                                                 forPrefix:nil
                                                              validForDate:nil];
            NSArray * const listenersCopy = [sSelf.listeners copy];
            [sSelf.lock unlock];

            // Re-schedule next run.
            __weak __typeof(sSelf) weakSelf2 = sSelf;
            dispatch_async(getPermissionExpireCheckAsyncQueue(), ^{
                // Capture strong reference so lock is in consistent state.
                PEXLicenceManager * sSelf2 = weakSelf2;
                [sSelf2.lock lock];

                if (!expirationTask.isCancelled){
                    [sSelf2 setPermissionsCheckTaskInternal];
                }

                [sSelf2.lock unlock];
            });

            [sSelf notifyPermissionsChange:permissions toListeners:listenersCopy];
        }
    };

    DDLogVerbose(@"Added new permission check task, interval: %.3f, dispatch: %llu mach.",
            timeDelayInMilliseconds,
            (long long unsigned) dispatchTime);

    dispatch_async(getPermissionExpireCheckAsyncQueue(), ^{
        DDLogVerbose(@"Permission check task starting");
        [weakSelf.permissionsCheckTask start];
    });
}

- (NSDate *) getNextEventDate: (NSArray * const) currents futures: (NSArray * const) futures
{
    const PEXDbAccountingPermission * const closestExpiring = [self getEarliestExpiring:currents];
    const PEXDbAccountingPermission * const closestBeginning = [self getEarliestBeginning:futures];

    NSDate * const first = closestExpiring.validTo;
    NSDate * const second = closestBeginning .validFrom;

    NSDate * result = nil;

    if (!first)
        result = second;
    else if (!second)
        result = first;
    else if ([PEXDateUtils date:first isOlderThan:second])
        result = first;
    else
        result = second;

    return result;
}

- (const PEXDbAccountingPermission *) getEarliestExpiring: (NSArray * const) permissions
{
    PEXDbAccountingPermission * result = nil;

    for (PEXDbAccountingPermission * const permission in permissions)
    {
        if (!result || ([PEXDateUtils date:permission.validTo isOlderThan: result.validTo]))
            result = permission;
    }

    return result;
}

- (const PEXDbAccountingPermission *) getEarliestBeginning: (NSArray * const) permissions
{
    PEXDbAccountingPermission * result = nil;

    for (PEXDbAccountingPermission * const permission in permissions)
    {
        if (!result || ([PEXDateUtils date:permission.validFrom isOlderThan: result.validFrom]))
            result = permission;
    }

    return result;
}

- (void)permissionsValuesWereConsumedAsync:(const int64_t)consumedTimeInSeconds
                              validForDate:(NSDate *const)oldestValidFom
                                 forPrefix: (NSString * const) prefix
{
    dispatch_async(getUpdateAfterCallQueue(), ^{

        [self permissionsValuesWereConsumed:consumedTimeInSeconds
                               validForDate:oldestValidFom
                                  forPrefix:prefix];
    });
}

- (void)resortAndMergeDailyIfNeeded:(NSMutableArray *const)permissions forPrefix: (NSString * const) prefix
{
    // move all daily to top;
    if ([prefix isEqualToString:PEX_PERMISSION_MESSAGES_PREFIX])
    {
        PEXDbAccountingPermission * dailyPermission = nil;

        for (int i = 0; i < permissions.count; ++i)
        {
            PEXDbAccountingPermission * const permission = permissions[i];
            if ([PEXPermissionsUtils isPermissionNameDaily:permission.name])
            {
                if (!dailyPermission)
                {
                    // move the daily permission to front
                    dailyPermission = permission;
                    [permissions removeObjectAtIndex:i];
                    [permissions insertObject:dailyPermission atIndex:0];
                }
                else
                {
                    // merge with other daily permissions
                    if ([PEXDateUtils date:permission.validFrom isOlderThan:dailyPermission.validFrom])
                        dailyPermission.validFrom = permission.validFrom;

                    if ([PEXDateUtils date:permission.validTo isNewerThan:dailyPermission.validTo])
                        dailyPermission.validTo = permission.validTo;

                    dailyPermission.value =
                            @([permission.value longLongValue] + [dailyPermission.value longLongValue]);
                }
            }
        }
    }
}

- (void)permissionsValuesWereConsumed:(int64_t)consumedValue
                         validForDate:(NSDate *const)oldestValidFom
                            forPrefix: (NSString * const) prefix
{
    // do nothing on nothing
    if (!consumedValue)
        return;

    [self.lock lock];

    NSMutableArray * const permissions =
            [[PEXLicenceManager getPermissionsInternalNotSafe:nil
                                                   forPrefix:prefix
                                                validForDate:oldestValidFom] mutableCopy];

    NSMutableArray * const permissionsToUpdate = [[NSMutableArray alloc] init];
    NSMutableArray * const logsToCreate = [[NSMutableArray alloc] init];
    NSMutableArray * const expirationLogsToCreate = [[NSMutableArray alloc] init];

    [self resortAndMergeDailyIfNeeded:permissions forPrefix:prefix];

    // See ::readPermissions for permission priority order
    for (PEXDbAccountingPermission * const permission in permissions)
    {
        const int64_t value = [permission.value longLongValue];

        if (value == -1) {
            // The subscription is unlimited, no update
            consumedValue = 0;
            break;
        }
        else if (value != 0)
        {
            if ([PEXPermissionsUtils isPermissionNameDaily:permission.name])
            {
                const int64_t spentDaily =
                        [self getOutgoingMessageCountForLastDays:[PEXChatAccountingManager getMessageCountLimitPeriodInDays]];

                int64_t availableDaily = value - spentDaily;

                int64_t consumedLogged = 0;
                if (availableDaily >= consumedValue) {
                    availableDaily -= consumedValue;
                    consumedLogged = consumedValue;
                    consumedValue = 0;
                }
                else {
                    availableDaily = 0;
                    consumedValue -= availableDaily;
                    consumedLogged = availableDaily;
                }

                for (int i = 0; i < consumedLogged; ++i)
                {
                    PEXDbExpiredLicenceLog * const log = [[PEXDbExpiredLicenceLog alloc] init];
                    log.type = @(PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE);
                    log.date = [PEXLicenceManager currentTimeSinceReference];
                    [expirationLogsToCreate addObject:log];
                }
            }
            else {

                int64_t available = value - [permission.spent longLongValue];

                if (available >= consumedValue) {
                    available -= consumedValue;
                    consumedValue = 0;
                }
                else {
                    available = 0;
                    consumedValue -= available;
                }

                const int64_t spent = value - available;
                const int64_t spentToLog = spent - [permission.spent longLongValue];
                permission.spent = @(spent);
                [permissionsToUpdate addObject:permission];

                [logsToCreate addObject:[PEXLicenceManager logFromPermission:permission withSpent:spentToLog]];
            }

            if (consumedValue == 0) {
                // all the consumed time was tracked down
                break;
            }
        }
    }

    if (consumedValue != 0)
    {
        DDLogWarn(@"Some consumed seconds for call survived: no futher permissions to apply");
    }

    PEXDbContentProvider * const provider = [PEXDbAppContentProvider instance];

    // expiredAction logs
    if (expirationLogsToCreate.count)
    {
        [PEXLicenceManager addExpiredLicenceLogs:expirationLogsToCreate];
    }

    // update permissions
    for (const PEXDbAccountingPermission * const permission in permissionsToUpdate)
    {
        [provider update:[PEXDbAccountingPermission getURI]
           ContentValues:[permission getDbContentValues]
               selection:[NSString stringWithFormat: @"WHERE %@ = ?", PEX_DBAL_FIELD_ID]
           selectionArgs:@[[permission.id stringValue]]];
    }

    // accounting logs
    if (logsToCreate.count)
    {
        NSMutableArray * const contentValues = [[NSMutableArray alloc] init];

        for (PEXDbAccountingLog * const log in logsToCreate)
            [contentValues addObject:[log getDbContentValues]];

        [provider bulk:[PEXDbAccountingLog getURI] insert: contentValues];

        PEXAccountingLogUpdaterTask * const task = [[PEXAccountingLogUpdaterTask alloc] init];
        task.privData = [[PEXAppState instance] getPrivateData];
        dispatch_async(getLogUploadQueue(), ^{
            [[PEXPaymentManager instance] triggerLogsUpload];
        });
    }

    [self.lock unlock];
}

+ (PEXDbAccountingLog *) logFromPermission: (const PEXDbAccountingPermission * const) permission
                                 withSpent: (const int64_t) spentToLog
{
    PEXDbAccountingLog * const result = [[PEXDbAccountingLog alloc] init];

    NSDate * const currentDate = [NSDate date];

    result.type = permission.name;
    // result.rkey = nil;
    result.dateCreated = currentDate;
    result.dateModified = currentDate;

    // to millis
    result.actionId = @(((int64_t)[currentDate timeIntervalSince1970]) * 1000);

    result.actionCounter = @(getActionId());
    result.amount = @(spentToLog);
    result.aggregated = @(1);
    //result.aref = nil;
    result.permId = permission.permId;
    result.licId = permission.licId;

    return result;
}

#pragma MESSAGES
// TODO PLUS take the message time when loading permissions

- (void) outgoingMessageInExpiredModeAckedOn: (NSDate * const) sendDate
{
    dispatch_async(getMessageAckedQueue(), ^{
        [self permissionsValuesWereConsumed:1 validForDate:sendDate forPrefix:PEX_PERMISSION_MESSAGES_PREFIX];

        NSArray *const permissions =
                [self getPermissions:nil forPrefix:PEX_PERMISSION_MESSAGES_PREFIX validForDate:nil];

        [[[PEXAppState instance] chatAccountingManager] loadStateAndnotifyListenersWithPermissions:permissions];
    });
}

- (void)outgoingFilesAckedOn:(NSDate *const)sendDate withCount: (const int64_t) count
{
    dispatch_async(getMessageAckedQueue(), ^{

        [self permissionsValuesWereConsumed:count validForDate:sendDate forPrefix:PEX_PERMISSION_FILES_PREFIX];
    });
}

- (int64_t) getOutgoingMessageCountForLastDays: (const int) daysCount
{
    return [self getCountForLastDays:PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE forLogType:daysCount];
}


- (int64_t)getCountForLastDays:(const int)type forLogType: (const int) daysCount
{
    NSDate * const currentDate = [PEXLicenceManager currentTimeSinceReference];
    const NSTimeInterval interval = daysCount * PEX_DAY_IN_SECONDS;
    NSDate * const oldDate = [currentDate dateByAddingTimeInterval: -interval];

    NSNumber * const oldTime =
            @([oldDate timeIntervalSince1970]);

    NSString * const query =
            [NSString stringWithFormat:@"SELECT COUNT(*) AS count FROM %@ WHERE %@=? AND %@>?",
                                       PEX_DBEXPIRED_TABLE, PEX_DBEXPIRED_FIELD_TYPE, PEX_DBEXPIRED_FIELD_DATE];


    PEXDbCursor * const cursor =
            [[PEXDbAppContentProvider instance]
                    queryRaw:query selectionArgs:@[@(PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE), oldTime]];

    int result = 0;

    if (cursor && [cursor moveToNext])
        result = [[cursor getInt:0] integerValue];

    return result;
}

+ (void) addExpiredLicenceLog: (PEXDbExpiredLicenceLog * const) log
{
    [[PEXDbAppContentProvider instance]
            insert:[PEXDbExpiredLicenceLog getURI]
     contentValues:[log getDbContentValues]];
}

+ (void) addExpiredLicenceLogs: (NSArray * const) logs
{
    if (logs.count == 0)
        return;

    NSMutableArray * const logsContentValues = [[NSMutableArray alloc] init];

    for (PEXDbExpiredLicenceLog * const log in logs)
        [logsContentValues addObject:[log getDbContentValues]];

    [[PEXDbAppContentProvider instance]
            bulk:[PEXDbExpiredLicenceLog getURI] insert:logsContentValues];
}

/**
* Receive local user presence changes in order to broadcast new presence state.
*/
- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil || ![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil || conChange.connection == PEX_CONN_NO_CHANGE){
        return;
    }

    WEAKSELF;
    const BOOL works = conChange.connectionWorks == PEX_CONN_IS_UP;
    const BOOL active = ![[PEXService instance] isInBackground];
    if (works && active){
        [self checkDeferredEvents];
    }
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    const BOOL conWorking = [[PEXService instance] isConnectivityWorking];

    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE && conWorking){
        [self checkDeferredEvents];
    }
}

- (void) checkDeferredEvents {
    self.deferredLicenceRefreshFails = 0;
    if (self.deferredLicenceRefresh) {
        [self triggerCheckPermissions];
    }
}

//// DEPRECATED:

/*

    static const int PEX_EXPIRES_SOON_FIRST_DAYS = 7;
    static const int PEX_EXPIRES_SOON_SECOND_DAYS = 1;

- (void) showNotification
{
    [[PEXGNFC instance] setLicenceUpdateNorificationAsync];
}

- (void) expireLicenceHard: (PEXLicenceInfo * const) licence forTask: (PEXTask * const) task
{
    if ([task isCancelled])
        return;

    NSArray *listenersCopy;

    [self.lock lock];

    if (![task isCancelled])
    {
        licence.licenseExpired = true;

        if ([self updateLicenceInfoInDatabse:licence])
            listenersCopy = [self.listeners copy];

        [self.lock unlock];
    }

    [self.lock unlock];

    if (listenersCopy)
        [self notifyLicence:licence toListeners:listenersCopy];
}

- (bool) updateLicenceInfoInDatabse: (const PEXLicenceInfo * const) newLicenceInfo
{
    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                                                  value:false];

    PEXDbContentProvider * const cp = [PEXDbAppContentProvider instance];
    PEXDbUserProfile * const user = [PEXDbUserProfile getProfileWithName:[[PEXAppState instance] getPrivateData].username
                                                                      cr:[PEXDbAppContentProvider instance]
                                                              projection:[PEXDbUserProfile getFullProjection]];

    if (!user)
    {
        DDLogVerbose(@"Licence Info update: unable to load user from DB");
        return false;
    }

    user.licenseType = newLicenceInfo.licenseType;
    user.licenseIssuedOn = newLicenceInfo.licenseIssuedOn;
    user.licenseExpiresOn = newLicenceInfo.licenseExpiresOn;
    user.licenseExpired = newLicenceInfo.licenseExpired;

    if (![cp update:[PEXDbUserProfile getURI]
      ContentValues:[user getDbContentValues]
          selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBUSR_FIELD_USERNAME]
      selectionArgs:@[user.username]])
    {
        DDLogVerbose(@"Licence Info update: unable to update user's licence in DB");
        return false;
    }

    [self updateLicenceNotificationPreferences:newLicenceInfo];

    return true;
}

// There will be a notification about an update, so timeing notifications are not needed
- (void) updateLicenceNotificationPreferences: (PEXLicenceInfo * const) licenceInfo
{
    int64_t diffInDays =
            [PEXLicenceManager diffInDays:[PEXLicenceManager currentTimeSinceReference] second:licenceInfo.licenseExpiresOn];

    int daysToWriteToPref = PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_DEFAULT;

    // less than a day
    if (diffInDays < PEX_EXPIRES_SOON_SECOND_DAYS)
        daysToWriteToPref = PEX_EXPIRES_SOON_SECOND_DAYS;
    // less than 7 days
    else if (diffInDays < PEX_EXPIRES_SOON_FIRST_DAYS)
        daysToWriteToPref = PEX_EXPIRES_SOON_FIRST_DAYS;

    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_KEY
                                                 value:daysToWriteToPref];
}

+ (bool) licenceExpiresSoon: (const PEXLicenceInfo * const) info
{
    NSDate * const current = [PEXLicenceManager currentTimeSinceReference];
    NSDate * const expires = info.licenseExpiresOn;

    const int64_t expiresInDays = [PEXLicenceManager diffInDays:current second:expires];

    return (expiresInDays <= PEX_EXPIRES_SOON_FIRST_DAYS);
}

+ (int64_t) diffInDays: (NSDate * const) first second: (NSDate * const) second
{
    return ((int64_t)([second timeIntervalSince1970] - [first timeIntervalSince1970])) / PEX_DAY_IN_SECONDS;
};

 - (void) notifyIfLicenceRequiresAttention
{
    const bool licenceUpdateSeen =
            ([[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                                                    defaultValue:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_DEFAULT]);

    [self notifyIfLicenceRequiresAttentionIfWasSeen:licenceUpdateSeen];
}

 - (void) notifyIfLicenceRequiresAttentionIfWasSeen: (const bool) wasSeen
{
    [self.lock lock];

    if (!wasSeen || [self licenceExpiredInternal])
        [self showNotification];

    [self.lock unlock];
}

 - (void) preparePreemptiveNotificationExpiresOn: (NSDate * const)  licenceExpiresOn
                         expireHardOut: (bool * const) expireHard
                             fireOnOut: (NSDate ** const) fireNotificationOn
                        daysToPrefsOut: (int64_t * const) daysToPrefsAfterNotification
{
    const int storedDays =
            [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_KEY
                                                  defaultValue:PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_DEFAULT];

    int64_t diffInDays =
            [PEXLicenceManager diffInDays:[PEXLicenceManager currentTimeSinceReference] second:licenceExpiresOn];
    int64_t daysBeforeExpirationToNotify = -1;


    if (((diffInDays > PEX_EXPIRES_SOON_FIRST_DAYS) && (storedDays != PEX_EXPIRES_SOON_FIRST_DAYS)) ||
            ((diffInDays > PEX_EXPIRES_SOON_SECOND_DAYS) && (storedDays != PEX_EXPIRES_SOON_FIRST_DAYS)))
    {
        *daysToPrefsAfterNotification = daysBeforeExpirationToNotify = PEX_EXPIRES_SOON_FIRST_DAYS;
    }
    else if ((diffInDays >= 0) && (storedDays != PEX_EXPIRES_SOON_SECOND_DAYS))
    {
        daysBeforeExpirationToNotify = PEX_EXPIRES_SOON_SECOND_DAYS;
    }

    if (daysBeforeExpirationToNotify >= 0)
    {
        *expireHard = false;
        *fireNotificationOn = [PEXDateUtils addTo:licenceExpiresOn days:-daysBeforeExpirationToNotify];
    }
    // else notify hard expiration
}

 TODO are there any minutes/MBs/files? left?
 - (bool) licenceExpiredInternal
{
    return [self getCurrentLicenceInternal].licenseExpired;
}

 - (bool) licenceExpired {
    bool result = false;

    [self.lock lock];

    result = [self licenceExpiredInternal];

    [self.lock unlock];

    return result;
}

 THIS ONLY CHEKS WHETHER TO NOTIFY USER

    NSDate * const licenceExpiresOn = nil; //licenceInfo.licenseExpiresOn;
    NSDate * fireNotificationOn = licenceExpiresOn;
    bool expireHard = true;
    //int64_t daysToPrefsAfterNotification = PEX_EXPIRES_SOON_SECOND_DAYS;

    if (!licenceInfo.licenseExpired)
    {
        [self preparePreemptiveNotificationExpiresOn:licenceExpiresOn
                                       expireHardOut:&expireHard
                                           fireOnOut:&fireNotificationOn
                                      daysToPrefsOut:&daysToPrefsAfterNotification];
    }

    const dispatch_time_t timeDelayInMilliseconds = [PEXDateUtils getIntervalUntilDate:fireNotificationOn
                                                           since:referenceTime];


    if ([self licenceExpired])
    {
        result = true;

        PEXGuiManageLicenceController * const controller = [[PEXGuiManageLicenceController alloc] init];
        [controller showInNavigation:parent title:PEXStrU(@"L_manage_licence")];
    }

*/
@end