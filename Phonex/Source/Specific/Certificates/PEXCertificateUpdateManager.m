//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertificateUpdateManager.h"
#import "PEXCertificateUpdateTask.h"
#import "PEXService.h"
#import "PEXUserPrivate.h"
#import "PEXUtils.h"
#import "PEXDbContact.h"
#import "PEXCertRefreshParams.h"
#import "PEXConcurrentHashMap.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXCertCheckListEntry.h"
#import "PEXConnectivityChange.h"
#import "PEXApplicationStateChange.h"

NSString *PEX_ACTION_CERT_UPDATE_PROGRESS_DB = @"net.phonex.phonex.cert.action.progress";
NSString *PEX_ACTION_CERT_UPDATED = @"net.phonex.phonex.cert.action.updated";
NSString *PEX_EXTRA_UPDATE_PROGRESS = @"progress_array";
NSString *PEX_EXTRA_UPDATED_USERS = @"updated_certificate_users";

// Number of fail count to block next cert checks.
#define PEX_CERT_CHECK_FAIL_COUNT_THRESHOLD 8

// Time to reset fail count after the last fail event.
#define PEX_CERT_CHECK_FAIL_COUNT_RESET_TIME (60.0*30.0)

@interface PEXCertificateUpdateManager () {
    /**
    * Number of consecutive fails to update certificates.
    * For backoff - connectivity on, but 100% packet loss.
    */
    NSUInteger _failCount;
    /**
    * Time of the last fail. If it was too distant, fail count may get reset.
    */
    NSTimeInterval _lastFailTstamp;
}
/**
* Operation queue for certificate refresh task.
* Serial queue for execution in background.
*/
@property(nonatomic) NSOperationQueue * opqueue;

/**
* Concurrent queue of certificate check requests.
*/
@property(nonatomic) PEXConcurrentLinkedList * certCheckList;

/**
* Certificate check progress.
*/
@property(nonatomic) PEXConcurrentHashMap * certCheckProgress;
@property(nonatomic) BOOL registered;

@end

@implementation PEXCertificateUpdateManager { }
- (instancetype)init {
    self = [super init];
    if (self) {
        self.opqueue = [[NSOperationQueue alloc] init];
        self.opqueue.maxConcurrentOperationCount = 1;
        self.opqueue.name = @"certUpdateQueue";

        self.certCheckList = [[PEXConcurrentLinkedList alloc] init];
        self.certCheckProgress = [[PEXConcurrentHashMap alloc] init];
        self.registered = NO;
        _failCount = 0;
    }

    return self;
}

+ (PEXCertificateUpdateManager *)instance {
    static PEXCertificateUpdateManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // Register on connectivity changes.
        [center addObserver:self selector:@selector(onConnectivityChange:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];
        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        self.registered = YES;
    }
}

- (void)dealloc {
    if (self.registered) {
        [self doUnregister];
    }
}

- (void)doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];

        self.registered = NO;
    }
}

/**
* Receive connectivity changes so we can react on this - process deferred cert check request which failed due to connection error.
*/
- (void)onConnectivityChange:(NSNotification *)notification {
    if (notification == nil) {
        return;
    }

    if (![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name]){
        DDLogError(@"Unknown action %@", notification);
        return; // Notification not for us.
    }

    PEXConnectivityChange * conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];
    if (conChange == nil || conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    // IP changed?
    BOOL recovered = conChange.connection == PEX_CONN_GOES_UP;
    if (!recovered){
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"certUpdateConnOn" async:YES block:^{
        __typeof(self) mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        // Reset fail count. If there is non-empty queue, run processing task.
        [weakSelf retryQueuedRequests];
    }];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        // If check was completed 12 hours ago or more, trigger a new check...
        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:@"certUpdAppActive" async:YES block:^{
            [weakSelf retryQueuedRequests];
        }];
    }
}

/**
* Returns recent progress for certificate update.
* @return
*/
-(NSArray *) getCertUpdateProgress{
    NSDictionary * srcDict = [self.certCheckProgress copyData];
    NSMutableArray * lst = [[NSMutableArray alloc] initWithCapacity:[srcDict count]];
    for(id<NSCopying> key in srcDict){
        id anObj = srcDict[key];
        if (anObj == nil || ![anObj isKindOfClass:[PEXCertUpdateProgress class]]){
            DDLogError(@"Invalid object in progress: %@", anObj);
            continue;
        }

        [lst addObject:[srcDict[key] copy]];
    }

    return lst;
}

/**
* Adds users to the check list.
*
* @param paramsList
*/
-(void) addToCheckList: (NSArray * ) paramsList async: (BOOL) async { // List<CertUpdateParams>
    // Add all params to the check list.
    NSMutableArray * arr = [[NSMutableArray alloc] init];

    for(PEXCertRefreshParams * params in paramsList){
        PEXCertCheckListEntry * e = [[PEXCertCheckListEntry alloc] init];
        e.usr = params.user;
        e.policyCheck = !params.forceRecheck;
        e.params = params;

        // Add this check entry to the queue.
        [arr addObject:e];

        // Add to progress monitor.
        DDLogVerbose(@"Added [%@] to the cert check queue", e.usr);
        [self.certCheckProgress put:[PEXCertUpdateProgress progressWithUser:e.usr state:PEX_CERT_UPDATE_STATE_IN_QUEUE]
                                key:e.usr async:YES];
    }

    // Add as a bulk to the list, async.
    [self addToCertCheckList:arr async:YES];
}

/**
* Adds array of PEXCertCheckListEntry directly to the cert check list.
* Warning: should be considered as protected.
*/
-(void) addToCertCheckList: (NSArray *) certCheckEntryList async: (BOOL) async {
    [self.certCheckList addAll:certCheckEntryList async:async];
}

/**
* Update certificate update state for a single user.
*
* @param user
* @param state
*/
-(void) updateState: (NSString *) user state: (PEXCertUpdateStateEnum) state{
    [self.certCheckProgress put:[PEXCertUpdateProgress progressWithUser:user state:state]
                            key:user async:YES];
}

-(void) updateStateBatch: (NSArray *) users state: (PEXCertUpdateStateEnum) state{
    NSDate * when = [NSDate date];
    NSMutableDictionary * prog = [[NSMutableDictionary alloc] init];

    for(NSString * u in users){
        prog[u] = [PEXCertUpdateProgress progressWithUser:u state:state when:when];
    }

    [self.certCheckProgress addAll:prog async:YES];
}

/**
* Reset state of all updates to done.
*/
-(void) resetState{
    NSDate * when = [NSDate date];
    [self.certCheckProgress enumerateAsync:YES usingBlock:^(id <NSCopying> aKey, id anObject, BOOL *stop) {
        PEXCertUpdateProgress * obj = (PEXCertUpdateProgress *) anObject;
        if (obj != nil) {
            obj.state = PEX_CERT_UPDATE_STATE_DONE;
            obj.when = when;
        }
    }];
}

/**
* Broadcast certificate update state.
*/
-(void) bcastState{
    NSArray * cup = [self getCertUpdateProgress];
    [PEXService executeWithName:nil async:YES block:^{
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

        // Post notification to the notification center.
        [center postNotificationName:PEX_ACTION_CERT_UPDATE_PROGRESS_DB object:nil userInfo:@{
                PEX_EXTRA_UPDATE_PROGRESS : cup
        }];
    }];
}

-(void) certificatesUpdated: (NSArray *) updatedUsers{
    if (updatedUsers == nil || [updatedUsers count] == 0){
        return;
    }

    DDLogDebug(@"CertRefresh, cert modified, trigger dh key update");
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    // Post notification to the notification center.
    [center postNotificationName:PEX_ACTION_CERT_UPDATED object:nil userInfo:@{
            PEX_EXTRA_UPDATED_USERS : updatedUsers,
    }];
}

/**
* Generates certificate check list for users in contactlist of a given sip profile.
* If argument is null, all contacts are loaded.
*
* @param sipProfile
* @return
* @throws SameThreadException
*/
-(NSArray *) certCheckAllAccounts: (NSString *) sipProfile forceCheck: (BOOL) forceCheck {
    NSMutableArray * ret = [[NSMutableArray alloc] init];
    //List<CertUpdateParams> ret = new ArrayList<CertUpdateParams>();

    NSString * selection = nil;
    NSArray * selectionArgs = nil;
    if (![PEXUtils isEmpty:sipProfile]){
        selection = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_ACCOUNT];
        selectionArgs = @[sipProfile];
    } else {
        selection = @"WHERE 1 ";
        selectionArgs = [NSArray array];
    }

    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbCursor * c = [cr query:[PEXDbContact getURI] projection:[PEXDbContact getLightProjection]
                      selection:selection
                  selectionArgs:selectionArgs
                      sortOrder:nil];

    if (c == nil) {
        return @[];
    }

    @try {
        while([c moveToNext]){
            PEXDbContact * cl = [[PEXDbContact alloc] initWithCursor:c];
            [ret addObject: [PEXCertRefreshParams paramsWithUser:cl.sip forceRecheck:forceCheck]];
        }
    } @catch (NSException * e) {
        DDLogError(@"Error on looping over sip profiles, exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    return [NSArray arrayWithArray:ret];
}

-(void) triggerCertUpdateForAll: (BOOL) forceAll {
    NSArray * paramsList = [self certCheckAllAccounts:nil forceCheck: forceAll];
    DDLogVerbose(@"Trigger cert update for all, size: %lu", (unsigned long)[paramsList count]);
    [self triggerCertUpdate:paramsList];
}

/**
* Function for certificate update for a particular user.
* Function decides whether to update certificate for user implementing
* DoS avoidance policy.
*
* @param paramsList
* @param allUsers
*/
-(void) triggerCertUpdate: (NSArray *) paramsList {
    if (paramsList == nil || [paramsList count] == 0){
        DDLogDebug(@"Empty contact list, nothing to recheck");
        return;
    }

    // Initialize task if not initialized.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"certUpdateStart" async:YES block:^{
        // If executing, add to queue.
        PEXCertificateUpdateManager * mgr = weakSelf;

        // Filosophy - for each request add a new task to process it.
        // Do not optimize tasks here, since we want to be sure that each request is processed.
        // Previous pattern (if accepting new jobs, re-use existing) is a bit faulty due to race conditions.
        // Optimization is here automatic, if task discovers there are no more tasks to process, it quits itself.
        // Thus we have no handle to task. Task should ask manager what to do. Manager should not call tasks methods
        // after submission to the queue.
        // Add all params to the check list. Async=NO so we are sure operation is added to the worker queue
        // when next decision about starting a new worker thread is made.
        [mgr addToCheckList:paramsList async:NO];
        [mgr internalStartUpdateTask];
    }];
}

/**
* Starts an update task given current cert check list for processing.
* Should be called only internally since
*/
-(void) internalStartUpdateTask {
    // Inspect our worker queue, only cert refresh jobs are here.
    NSUInteger opCount = [self.opqueue operationCount];
    if (opCount >= 2){
        // If there are 2 work jobs queued
        DDLogVerbose(@"OpCount=%lu, not starting a new worker", (unsigned long)opCount);
        return;
    }

    // Check fail count policy.
    if (![self isFailCountOK]){
        DDLogInfo(@"Skipping cert check, fail count too high.");
        return;
    }

    // Submit new worker task.
    PEXCertificateUpdateTask *task = [[PEXCertificateUpdateTask alloc] init];
    task.canceller = self.canceller;
    task.privData = self.privData;
    task.certCheckList = self.certCheckList;
    task.mgr = self;

    // Start task if it is not running.
    // Wait some amount of time in order to group multiple users in one check (optimization).
    // Schedules new task only if there is none scheduled or previous has finished.
    DDLogVerbose(@"Starting new certificate refresh run, opCount: %u, checklistSize: %u", (unsigned)opCount, [self.certCheckList count]);
    [self.opqueue addOperation:task];
}

- (void)retryQueuedRequests {
    // Reset fail counter and try to check the queue.
    [self failCountReset];

    // Ignore empty queue, do nothing, save battery.
    if ([_certCheckList count] == 0){
        return;
    }

    // Start queue checking task.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"retryQueue" async:YES block:^{
        [weakSelf internalStartUpdateTask];
    }];
}

- (void)keepAlive:(BOOL)async {
    [self retryQueuedRequests];
}

/**
* Returns YES if failcount is under threshold and cert check should be triggered.
*/
-(BOOL) isFailCountOK {
    if (_failCount < PEX_CERT_CHECK_FAIL_COUNT_THRESHOLD) {
        return YES;
    }

    // Check if last fail event is too old.
    NSTimeInterval curTime = [[NSDate date] timeIntervalSince1970];
    if ((curTime - _lastFailTstamp) > PEX_CERT_CHECK_FAIL_COUNT_RESET_TIME){
        [self failCountReset];
        return YES;
    }

    return NO;
}

- (void)failCountInc {
    _failCount += 1;
    _lastFailTstamp = [[NSDate date] timeIntervalSince1970];
    DDLogVerbose(@"Increased fail count to: %lu", (unsigned long)_failCount);
}

- (void)failCountReset {
    _failCount = 0;
    _lastFailTstamp = 0.0;
}

- (NSUInteger)failCountGet {
    return _failCount;
}


@end