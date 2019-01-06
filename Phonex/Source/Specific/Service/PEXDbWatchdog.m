//
// Created by Dusan Klinec on 20.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbWatchdog.h"
#import "PEXService.h"
#import "PEXApplicationStateChange.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDBUserProfile.h"
#import "PEXUtils.h"
#import "PEXDatabase.h"
#import "PEXBlockThread.h"
#import "PEXReport.h"

static const int PEX_DB_ERROR_RELOAD_THRESHOLD = 3;
static const int PEX_DB_ERROR_RELOAD_FAILS_THRESHOLD = 10;
static const NSTimeInterval PEX_DB_FOREGROUND_WATCHDOG_CHECK_TIME = 20.0;
static const NSTimeInterval PEX_DB_FOREGROUND_WATCHDOG_CHECK_TIME_WITH_ERROR = 2.0;

@interface PEXDbWatchdog () {
    NSTimer * _dbTimer;
    NSTimeInterval _dbTimerLastDelay;
    NSTimeInterval _dbTimerSet;
}

@property(nonatomic) BOOL registered;
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) int cntStatGlobalErrors;
@property(nonatomic) int cntConsecutiveFails;
@property(nonatomic) int cntRestartCalls;
@end

@implementation PEXDbWatchdog {

}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        _cntStatGlobalErrors = 0;
        _cntConsecutiveFails = 0;
        _cntRestartCalls = 0;

        // Register observer for message sent / message received events.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        // Register on certificate updates.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];
        [center addObserver:self selector:@selector(onDbOpened:) name:PEX_ACTION_DB_OPENED object:nil];
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

        _dbTimer = nil;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];
        self.registered = NO;
    }
}

- (void)udatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;
}

- (void) foregroundCheckStart {
    __weak __typeof(self) weakSelf = self;
    [[PEXService instance] executeWithName:@"db_check" async:YES block:^{
        [weakSelf doForegroundCheck];
    }];
}

- (void) foregroundCheckStop {
    _dbTimer = nil;
}

-(void) scheduleForegroundCheck {
    NSTimeInterval timerInterval = _cntConsecutiveFails > 0 ? PEX_DB_FOREGROUND_WATCHDOG_CHECK_TIME_WITH_ERROR : PEX_DB_FOREGROUND_WATCHDOG_CHECK_TIME;
    _dbTimer = [NSTimer timerWithTimeInterval:timerInterval
                                       target:self
                                     selector:@selector(onDbWatchTimerFired:)
                                     userInfo:@{}
                                      repeats:NO];

    [[NSRunLoop mainRunLoop] addTimer:_dbTimer forMode:NSRunLoopCommonModes];
    _dbTimerLastDelay = timerInterval;
    _dbTimerSet = [[NSDate date] timeIntervalSince1970];
}

-(void) onDbWatchTimerFired:(NSTimer *)timer {
    // Check if DB watch timer is enabled.
    if (timer == nil || _dbTimer == nil || timer != _dbTimer ){
        DDLogDebug(@"DB watch timer fired, not found as current timer");
        return;
    }

    // Drift computation for debugging.
    const NSTimeInterval drift = [[NSDate date] timeIntervalSince1970] - _dbTimerSet - _dbTimerLastDelay;
    DDLogDebug(@"DB watch timer fired. %@, origDelay: %f, fire drift: %f", timer, _dbTimerLastDelay, drift);
    PEXService * svc = [PEXService instance];
    const BOOL inBack = [svc isInBackground];
    const BOOL userLoggedIn = [svc userLoggedIn];

    // If in background / user logged out, do nothing, quit watchdog.
    if (inBack || !userLoggedIn){
        DDLogDebug(@"DB watchdog no more required");
        return;
    }

    // Broadcast message with lost registration.
    __weak __typeof(self) weakSelf = self;
    [[PEXService instance] executeWithName:@"db_check" async:YES block:^{
        [weakSelf doForegroundCheck];
    }];
}

- (BOOL) doForegroundCheck {
    if (![self isForegroundCheckAllowed]){
        DDLogDebug(@"DB watchdog is not allowed");
        return YES;
    }

    // Do simple read check. If success, then leave it and schedule next run.
    // If failed, ask for DB reload when fail count reached given threshold.
    bool success = false;
    for(int i = 0; i < 3 && !success; i++){
        // Check if we can run - conditions are met.
        if (![self isForegroundCheckAllowed]){
            DDLogDebug(@"DB watchdog is not allowed");
            return YES;
        }

        success |= [self dbReadCheck];
    }

    if (success){
        DDLogVerbose(@"DB check success");
        _cntConsecutiveFails = 0;
        [self scheduleForegroundCheck];
        return YES;
    }

    [PEXReport logEvent:PEX_EVENT_DB_WATCHDOG_ERROR];

    // 3 consecutive read fails, check if privData is OK.
    DDLogError(@"DB foreground watchdog detected problem with database. PrivData user: %@, ptr: %p. "
            "#err: %d, #totalErr: %d, #dbReloadCnt: %d.", _privData.username, _privData,
            _cntConsecutiveFails, _cntStatGlobalErrors, _cntRestartCalls);
    DDLogError(@"DB log report: %@", [[PEXDatabase instance] genDbLogReport]);
    [DDLog flushLog];

    _cntConsecutiveFails += 1;
    _cntStatGlobalErrors += 1;

    if (_cntRestartCalls >= PEX_DB_ERROR_RELOAD_FAILS_THRESHOLD){
        DDLogError(@"DB reload query count is too high");
        [DDLog flushLog];
        assert(_cntRestartCalls < PEX_DB_ERROR_RELOAD_FAILS_THRESHOLD);
        return NO;
    }

    if (_cntConsecutiveFails >= PEX_DB_ERROR_RELOAD_THRESHOLD){
        // Place DB reload request. If DB reload fails, app will be restarted by the service.
        _cntRestartCalls += 1;
        _cntConsecutiveFails = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_DB_RELOAD_REQUEST object:nil userInfo:@{}];
    }

    // Schedule next DB check.
    [self scheduleForegroundCheck];
    return success;
}

- (BOOL) doBackgroundCheck {
    // In the background check we do fast 3 consecutive read attempts.
    bool success = false;
    for(int i = 0; i < 3 && !success; i++){
        // Logged out meanwhile?
        PEXService * svc = [PEXService instance];
        if (![svc userLoggedIn]){
            DDLogInfo(@"User is not logged in, stopping background DB watchdog for now");
            return YES;
        }

        success |= [self dbReadCheck];
    }

    if (success){
        DDLogVerbose(@"Background DB check success");
        return YES;
    }

    [PEXReport logEvent:PEX_EVENT_DB_WATCHDOG_ERROR];

    // 3 consecutive read fails, check if privData is OK.
    _cntStatGlobalErrors += 1;
    DDLogError(@"DB watchdog detected problem with database. PrivData user: %@, ptr: %p "
            "#err: %d, #totalErr: %d, #dbReloadCnt: %d", _privData.username, _privData,
            _cntConsecutiveFails, _cntStatGlobalErrors, _cntRestartCalls);

    if (_cntRestartCalls >= PEX_DB_ERROR_RELOAD_FAILS_THRESHOLD){
        DDLogError(@"DB reload query count is too high");
        [DDLog flushLog];
        [PEXReport logEvent:PEX_EVENT_DB_WATCHDOG_THRESHOLD];
        assert(_cntRestartCalls < PEX_DB_ERROR_RELOAD_FAILS_THRESHOLD);
        return NO;
    }

    // Place DB reload request. If DB reload fails, app will be restarted by the service.
    _cntRestartCalls += 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:PEX_ACTION_DB_RELOAD_REQUEST object:nil userInfo:@{}];
    return NO;
}

- (BOOL) isForegroundCheckAllowed {
    PEXService * svc = [PEXService instance];
    const BOOL inBack = [svc isInBackground];
    const BOOL userLoggedIn = [svc userLoggedIn];
    return !inBack && userLoggedIn;
}

+ (int) dbReadCheck: (PEXUserPrivate *) privData {
    PEXDbContentProvider * cp = [PEXDbAppContentProvider instance];

    // Both read test & account fetch test has to pass.
    int readStatus = 0;
    bool readSuccess = [cp testDatabaseRead:&readStatus];
    if (!readSuccess){
        DDLogError(@"Basic read DB check failed with code: %d", readStatus);
        return -1;
    }

    // If private data is nil, do no read test, makes no sense.
    if (privData == nil || [PEXUtils isEmpty:privData.username]){
        DDLogError(@"Read test with empty private data user name: %@, privData ptr: %p", privData.username, privData);
        // Read test itself passed, but with failed privData - should be handled on a different place.
        return 1;
    }

    // Account load test.
    PEXDbUserProfile *acc = [PEXDbUserProfile getProfileWithName:privData.username cr:cp projection:nil];
    if (acc == nil){
        DDLogError(@"Could not fetch account information about current user %@", privData.username);
        return -2;
    }

    return 0;
}

- (bool) dbReadCheck {
    return [PEXDbWatchdog dbReadCheck:_privData] >= 0;
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change == nil){
        DDLogError(@"Illegal notification state");
        return;
    }

    __weak __typeof(self) weakSelf = self;
    if (change.stateChange == PEX_APPSTATE_DID_ENTER_BACKGROUND){
        DDLogVerbose(@"App in background - stop watchdog.");
        [self foregroundCheckStop];
    }

    // On foreground enter re-register again to reset all potential backoffs.
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        // Enable client initiated pings, throttling recovery.

        DDLogVerbose(@"Did become active - start DB watchdog");
        [self foregroundCheckStart];
    }
}

- (void)onDbOpened:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil){
        return;
    }

    DDLogVerbose(@"Database was opened successfully");
    _cntRestartCalls = 0;
    _cntStatGlobalErrors = 0;
    _cntConsecutiveFails = 0;
}


@end