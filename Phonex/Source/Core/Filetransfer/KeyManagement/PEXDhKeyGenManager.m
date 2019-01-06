//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDhKeyGenManager.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXCertificateUpdateTask.h"
#import "PEXService.h"
#import "PEXUserPrivate.h"
#import "PEXUtils.h"
#import "PEXDbContact.h"
#import "PEXCertRefreshParams.h"
#import "PEXCanceller.h"
#import "PEXConcurrentHashMap.h"
#import "PEXConcurrentLinkedList.h"
#import "PEXUserKeyRefreshQueue.h"
#import "PEXCertCheckListEntry.h"
#import "PEXConcurrentPriorityQueue.h"
#import "PEXUserKeyRefreshQueue.h"
#import "PEXDHKeyGeneratorProgress.h"
#import "PEXDHUserCheckParam.h"
#import "PEXDHKeyCheckOperation.h"
#import "PEXDHKeyGenOperation.h"
#import "PEXUserKeyRefreshRecord.h"
#import "PEXConnectivityChange.h"
#import "PEXContactRemoveTask.h"
#import "PEXContactAddTask.h"
#import "PEXApplicationStateChange.h"

NSString *PEX_ACTION_DHKEYGEN_UPDATE_PROGRESS_DB = @"net.phonex.phonex.dhkeygen.action.progress";
NSString *PEX_ACTION_DHKEYS_UPDATED = @"net.phonex.phonex.dhkeygen.action.keysupdated";
NSString *PEX_EXTRA_DHKEYS_UPDATED = @"net.phonex.phonex.dhkeygen.extra.keysupdated";
NSString *PEX_ACTION_TRIGGER_DHKEYCHECK = @"net.phonex.phonex.dhkeygen.action.triggercheck";
NSString *PEX_PREFS_LAST_SUCCESS_KEY_CHECK = @"net.phonex.phonex.dhkeygen.lastcheck";
NSString *PEX_PREFS_LAST_KEY_CHECK_TRIGGER = @"net.phonex.phonex.dhkeygen.lastchecktrigger";

@interface PEXDhKeyGenManager () {}
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
* Concurrent priority user queue to generate keys for, main scheduling structure.
*/
@property(nonatomic) PEXUserKeyRefreshQueue * userQueue;

/**
* Certificate check progress.
*/
@property(nonatomic) PEXConcurrentHashMap *keygenProgress;

@property(nonatomic) BOOL registered;
@property(nonatomic) BOOL shouldStartTaskOnConnectionRecovered;
@property(nonatomic) BOOL lastUploadTaskNoConnection;
@property(nonatomic) NSError * lastUploadTaskError;
@property(nonatomic) NSError * lastCheckTaskError;
@end

@implementation PEXDhKeyGenManager { }
- (instancetype)init {
    self = [super init];
    if (self) {
        self.opqueue = [[NSOperationQueue alloc] init];
        self.opqueue.maxConcurrentOperationCount = 1;   // Serial queue;
        self.opqueue.name = @"ftKeyCheckQueue";

        self.certCheckList = [[PEXConcurrentLinkedList alloc] initWithQueueName:@"dhkeygen.certcheck"];
        self.keygenProgress = [[PEXConcurrentHashMap alloc] initWithQueueName:@"dhkeygen.progress"];
        self.userQueue = [[PEXUserKeyRefreshQueue alloc] initWithQueueName:@"dhkeygen.userqueue"];
        self.registered = NO;
        self.shouldStartTaskOnConnectionRecovered = NO;
        self.lastUploadTaskNoConnection = NO;
        self.lastUploadTaskError = nil;
        self.lastCheckTaskError = nil;
    }

    return self;
}

+ (PEXDhKeyGenManager *)instance {
    static PEXDhKeyGenManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)onAccountLoggedIn {

}

/**
* Receive connectivity changes so we can react on this.
*/
- (void)onConnectivityChangeNotification:(NSNotification *)notification {
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
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"connChange" async:YES block:^{
        PEXDhKeyGenManager * mgr = weakSelf;
        if (mgr == nil){
            return;
        }

        if (recovered && mgr.shouldStartTaskOnConnectionRecovered) {
            DDLogVerbose(@"Connectivity recovered & previous task failed.");
            mgr.shouldStartTaskOnConnectionRecovered = NO;
            [mgr triggerUserCheck:nil allUsers:YES];
        } else if (recovered) {
            // Connectivity recovered -> may check DH keys if the last check happened long time ago.
            [mgr triggerIfTooOld];
        }
    }];
}

- (void)onCertUpdated:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_UPDATED_USERS] == nil){
        return;
    }

    NSArray * usersChanged = notification.userInfo[PEX_EXTRA_UPDATED_USERS];
    if (usersChanged == nil || [usersChanged count] == 0){
        return;
    }

    // Certificate check, mine (local) vs. database (new, updated).
    DDLogVerbose(@"Cert changed, trigger user check");
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"selfCertCheck" async:YES block:^{
        [weakSelf triggerUserCheck];
    }];
}

- (void)onUserUpdated:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil){
        return;
    }

    DDLogVerbose(@"User added/removed.");
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"selfCertCheck" async:YES block:^{
        [weakSelf triggerUserCheck];
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
        [PEXService executeWithName:@"appActiveDhKeyCheckTooOld" async:YES block:^{
            [weakSelf triggerIfTooOld];
        }];
    }
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for connectivity notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onConnectivityChangeNotification:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];

        // Register on certificate updates.
        [center addObserver:self selector:@selector(onCertUpdated:) name:PEX_ACTION_CERT_UPDATED object:nil];

        // Register to user added/removed event.
        [center addObserver:self selector:@selector(onUserUpdated:) name:PEX_ACTION_CONTACT_ADDED object:nil];
        [center addObserver:self selector:@selector(onUserUpdated:) name:PEX_ACTION_CONTACT_REMOVED object:nil];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        // TODO: register on file received event.

        DDLogDebug(@"DHKey manager registered");
        self.registered = YES;
    }
}

-(void) doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        [center removeObserver:self];
        DDLogDebug(@"Message manager unregistered");
        self.registered = NO;
    }
}

/**
* Empties work queue.
*/
-(void) quit {
    [self.opqueue cancelAllOperations];
}

/**
* Returns recent progress for DH key gen.
* @return
*/
-(NSArray *)getDhUpdateProgress {
    NSDictionary * srcDict = [self.keygenProgress copyData];
    NSMutableArray * lst = [[NSMutableArray alloc] initWithCapacity:[srcDict count]];
    for(id<NSCopying> key in srcDict){
        id anObj = srcDict[key];
        if (anObj == nil || ![anObj isKindOfClass:[PEXDHKeyGeneratorProgress class]]){
            DDLogError(@"Invalid object in progress: %@", anObj);
            continue;
        }

        [lst addObject:[srcDict[key] copy]];
    }

    return lst;
}

/**
* Update certificate update state for a single user.
*
* @param user
* @param state
*/
-(void) updateState: (NSString *) user state: (PEXKeyGenStateEnum) state{
    [self.keygenProgress put:[PEXDHKeyGeneratorProgress progressWithUser:user state:state]
                         key:user async:YES];
}

-(void) updateStateBatch: (NSArray *) users state: (PEXKeyGenStateEnum) state{
    NSDate * when = [NSDate date];
    NSMutableDictionary * prog = [[NSMutableDictionary alloc] init];

    for(NSString * u in users){
        prog[u] = [PEXDHKeyGeneratorProgress progressWithUser:u state:state when:when];
    }

    [self.keygenProgress addAll:prog async:YES];
}

/**
* Reset state of all updates to done.
*/
-(void) resetState{
    NSDate * when = [NSDate date];
    [self.keygenProgress enumerateAsync:YES usingBlock:^(id <NSCopying> aKey, id anObject, BOOL *stop) {
        PEXDHKeyGeneratorProgress *obj = (PEXDHKeyGeneratorProgress *) anObject;
        if (obj != nil) {
            obj.state = PEX_KEYGEN_STATE_DONE;
            obj.when = when;
        }
    }];
}

/**
* Broadcast certificate update state.
*/
-(void) bcastState{
    NSArray * cup = [self getDhUpdateProgress];
    [PEXService executeWithName:@"bcast_dhkeyegen_progress" async:YES block:^{
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

        // Post notification to the notification center.
        [center postNotificationName:PEX_ACTION_DHKEYGEN_UPDATE_PROGRESS_DB object:nil userInfo:@{
                PEX_EXTRA_UPDATE_PROGRESS : cup
        }];
    }];
}

-(void)keysGenerated: (NSArray *) updatedUsers{
    if (updatedUsers == nil || [updatedUsers count] == 0){
        return;
    }

    DDLogDebug(@"CertRefresh, cert modified, trigger dh key update");
    NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

    // Post notification to the notification center.
    [center postNotificationName:PEX_ACTION_DHKEYS_UPDATED object:nil userInfo:@{
            PEX_EXTRA_DHKEYS_UPDATED : updatedUsers,
    }];
}

/**
* Generates certificate check list for users in contactlist of a given sip profile.
* If argument is null, all contacts are loaded.
*
* @param sipProfile
* @return
* @throws SameThreadException
* TODO: migrate
*/
-(NSArray *)checkAllAccounts:(NSString *)sipProfile forceCheck: (BOOL) forceCheck {
    NSMutableArray * ret = [[NSMutableArray alloc] init];

    NSString * selection = nil;
    NSArray * selectionArgs = nil;
    if ([PEXUtils isEmpty:sipProfile]){
        selection = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBCL_FIELD_ACCOUNT];
        selectionArgs = @[sipProfile];
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
            [ret addObject:[PEXDHUserCheckParam paramWithUser:cl.sip forceRecheck:forceCheck]];
        }
    } @catch (NSException * e) {
        DDLogError(@"Error on looping over sip profiles, exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    return [NSArray arrayWithArray:ret];
}

/**
* Event called when user check task completes.
*/
-(void) onUserCheckCompleted: (PEXDHKeyCheckOperation *) task {
    DDLogVerbose(@"DhUserCheck completed");
}

/**
* Event called when key upload task finishes.
*/
-(void) onKeyCheckCompleted: (PEXDHKeyGenOperation *) task {
    DDLogVerbose(@"DhKeyGen completed");

    // If key check is OK, store last check date to the prefs.
    if (task.opError == nil && !task.interruptedDueToConnectionError) {
        DDLogVerbose(@"Key check successful, store last time.");
        PEXUserAppPreferences *prefs = [PEXUserAppPreferences instance];
        [prefs setDoublePrefForKey:PEX_PREFS_LAST_SUCCESS_KEY_CHECK value:[[NSDate date] timeIntervalSince1970]];
    }

    [self keysGenerated:task.usersWithKeysGenerated];
}

/**
* Triggers a new check task if there is currently no running and the last trigger is too old.
*/
-(void) triggerIfTooOld {
    // Only if currently there is no job running.
    if ([_opqueue operationCount] > 0){
        return;
    }

    PEXUserAppPreferences *prefs = [PEXUserAppPreferences instance];
    NSDate * nextCheckDate = nil;
    if ([prefs hasKey:PEX_PREFS_LAST_KEY_CHECK_TRIGGER]){
        double timeInterval = [prefs getDoublePrefForKey:PEX_PREFS_LAST_KEY_CHECK_TRIGGER defaultValue:0.0];
        nextCheckDate = [NSDate dateWithTimeIntervalSince1970:timeInterval + 12.0 * 60.0 * 60.0];
    }

    if (nextCheckDate == nil || [[NSDate date] compare:nextCheckDate] == NSOrderedDescending){
        DDLogVerbose(@"Last check is too old, triggering a new one, nextCheck=%@", nextCheckDate);
        [self triggerUserCheck];
    }
}

/**
* Function for certificate update for a particular user.
* Function decides whether to update certificate for user implementing
* DoS avoidance policy.
*
* @param paramsList
* @param allUsers
*/
-(void)triggerUserCheck:(NSArray *)paramsList allUsers: (BOOL) allUsers {
    // For now, we check everything and everybody.
    // TODO: implement in a better way, if nil, return. If empty and allusers == YES, check all users. If still empty, return.
    // ...

    // Store time of the last task trigger.
    PEXUserAppPreferences *prefs = [PEXUserAppPreferences instance];
    [prefs setDoublePrefForKey:PEX_PREFS_LAST_KEY_CHECK_TRIGGER value:[[NSDate date] timeIntervalSince1970]];

    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"dhKeyUserCheckStart" async:YES block:^{
        // If executing, add to queue.
        PEXDhKeyGenManager * mgr = weakSelf;
        mgr.lastCheckTaskError = nil;

        // Submit new worker task.
        PEXDHKeyCheckOperation *task = [[PEXDHKeyCheckOperation alloc] initWithMgr:self privData:self.privData];
        __weak __typeof(task) weakTask = task;

        task.canceller = mgr.canceller;
        task.mgr = mgr;
        task.maxDhKeys = 7;
        task.shouldExpireKeys = YES;
        task.shouldPerformCleaning = YES;
        task.triggerKeyUpdate = YES;
        task.completionBlock = ^{
            PEXDHKeyCheckOperation * cTask = weakTask;
            PEXDhKeyGenManager     * cMgr  = mgr;
            if (cTask == nil || cMgr == nil){
                DDLogVerbose(@"Completion block - nil");
                return;
            }

            if (cTask.opError != nil) {
                DDLogDebug(@"Task finished with error=%@", cTask.opError);
                mgr.shouldStartTaskOnConnectionRecovered |= YES;
                mgr.lastCheckTaskError = cTask.opError;
            }

            [mgr onUserCheckCompleted: cTask];
        };

        // Start task if it is not running.
        // Wait some amount of time in order to group multiple users in one check (optimization).
        // Schedules new task only if there is none scheduled or previous has finished.
        DDLogVerbose(@"Starting new user key check");
        [mgr.opqueue addOperation:task];
    }];
}

+(void)triggerUserCheck {
    [[self instance] triggerUserCheck];
}

-(void)triggerUserCheck {
    [self triggerUserCheck:nil allUsers:YES];
}

/**
* Task to trigger a new key check task.
* Key check task uses internal queue for computation, which is initialized by triggering a triggerUserCheck.
*/
-(void)triggerKeyGen {
    __weak __typeof(self) weakSelf = self;
    [PEXService executeWithName:@"dhKeyCheckStart" async:YES block:^{
        // If executing, add to queue.
        PEXDhKeyGenManager * mgr = weakSelf;
        mgr.lastUploadTaskNoConnection = NO;
        mgr.lastUploadTaskError = nil;

        // Submit new worker task.
        PEXDHKeyGenOperation *task = [[PEXDHKeyGenOperation alloc] initWithMgr:self privData:self.privData];
        __weak __typeof(task) weakTask = task;
        task.canceller = mgr.canceller;
        task.mgr = mgr;
        task.completionBlock = ^{
            PEXDHKeyGenOperation * cTask = weakTask;
            PEXDhKeyGenManager   * cMgr  = mgr;
            if (cTask == nil || cMgr == nil){
                DDLogVerbose(@"Completion block - nil");
                return;
            }

            if (cTask.interruptedDueToConnectionError || cTask.opError != nil) {
                DDLogDebug(@"ConnectionInterrupted:%d error=%@", cTask.interruptedDueToConnectionError, cTask.opError);
                mgr.lastUploadTaskNoConnection = cTask.interruptedDueToConnectionError;
                mgr.shouldStartTaskOnConnectionRecovered |= cTask.interruptedDueToConnectionError;
                mgr.lastUploadTaskError = cTask.opError;
            }

            [mgr onKeyCheckCompleted: cTask];
        };

        // Start task if it is not running.
        // Wait some amount of time in order to group multiple users in one check (optimization).
        // Schedules new task only if there is none scheduled or previous has finished.
        DDLogVerbose(@"Starting new key check");
        [mgr.opqueue addOperation:task];
    }];
}

- (PEXUserKeyRefreshRecord *)getUserRecord:(NSString *)user {
    return [self.userQueue getRecordForUser:user];
}

- (PEXUserKeyRefreshRecord *)peekUserRecord {
    return [self.userQueue peek];
}

- (PEXUserKeyRefreshRecord *)pollUserRecord {
    return [self.userQueue poll];
}

- (void)updateUserRecord:(PEXUserKeyRefreshRecord *)record {
    [self.userQueue update:record];
}


@end