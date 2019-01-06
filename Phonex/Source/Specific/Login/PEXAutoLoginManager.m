//
// Created by Dusan Klinec on 01.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "PEXService.h"
#import "PEXCredentials.h"
#import "PEXLoginHelper.h"
#import "PEXAutoLoginManager.h"
#import "PEXCanceller.h"
#import "PEXUtils.h"
#import "PEXConnectivityChange.h"
#import "PEXSOAPManager.h"
#import "PEXCertificateUpdateManager.h"
#import "Flurry.h"
#import "PEXReport.h"

int PEX_AUTOLOGIN_SUCC  = 0;
int PEX_AUTOLOGIN_LATER = 1;
int PEX_AUTOLOGIN_FAIL  = -1;

static PEXAutoLoginManager * s_activeInstance;

@interface PEXAutoLoginManager () {
    dispatch_semaphore_t _svcFinSem;
    dispatch_time_t _tdeadline;
}
@property (nonatomic) PEXCredentials * creds;
@property (nonatomic) PEXReachability * reachability;

@property (nonatomic) BOOL credentialsWereLookedUp;
@property (nonatomic) BOOL databaseWasTriedToBeOpened;

@property (nonatomic) BOOL shouldTryNormalLogin;
@property (nonatomic) BOOL lastDbOpenWasOk;
@property (nonatomic) BOOL lastServiceStartWasOk;
@property (nonatomic) BOOL registered;
@property (nonatomic) BOOL wasConnectionWorkingLastTime;
@property (nonatomic) NetworkStatus lastNetworkStatus;
@property (nonatomic) BOOL doLoginWhenConnectivityOff;
@end

@implementation PEXAutoLoginManager {

}

+(PEXAutoLoginManager *)  newInstanceNotThreadSafe {

    if (s_activeInstance)
        s_activeInstance = nil;

    return s_activeInstance = [[self alloc] init];
}

-(instancetype) init {
    self = [super init];
    if (self) {
        self.lastDbOpenWasOk = NO;
        self.lastServiceStartWasOk = NO;
        self.registered = NO;
        self.doLoginWhenConnectivityOff = NO;
        self.credentialsWereLookedUp = NO;
        self.databaseWasTriedToBeOpened = NO;
        self.shouldTryNormalLogin = NO;
    }

    return self;
}

-(BOOL) wasCancelled {
    return self.canceller != nil && [self.canceller isCancelled];
}

- (void)quit {
    [self doUnregister];
    self.lastServiceStartWasOk = NO;
    self.creds = nil;
    self.privData = nil;

}

-(BOOL) fastInit {
    BOOL credOk = [self wasCancelled] ? NO : [self tryLoadCredentials];
    if (!credOk){
        [self notifyLoginFinished];
    }

    // Register for notifications, mainly for watching connectivity.
    [self doRegister];
    return credOk;
}

-(BOOL) prepareAutoLogin {
    BOOL openOk = [self wasCancelled] ? NO : [self tryOpenDatabase];
    if (!openOk){
        [self notifyLoginFinished];
        return NO;
    }

    return YES;
}

-(int) doAutoLogin{
    if ([self wasCancelled]){
        [self notifyLoginFinished];
        return PEX_AUTOLOGIN_FAIL;
    }

    // Do we have internet connection?
    // For now, we are performing only fast auto login, without internet connection required.
    BOOL svcStartOk = [self tryStartServices];

    // We don't need notifications anymore. The job is over.
    [self doUnregister];

    // Finally return the final value.
    [self notifyLoginFinished];
    return svcStartOk ? PEX_AUTOLOGIN_SUCC : PEX_AUTOLOGIN_FAIL;
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        // Register for connectivity changes
        [self connectivityWatcherInit];

        DDLogDebug(@"AutoLoginManager registered");
        self.registered = YES;
    }
}

-(void) doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogInfo(@"Already unregistered");
            return;
        }

        // Stop network monitor thread.
        [self connectivityWatcherTeardown];

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];

        DDLogDebug(@"XMPP manager unregistered");
        self.registered = NO;
    }
}

- (BOOL)wasLoggedIn {
    return self.lastServiceStartWasOk;
}

-(void) connectivityWatcherInit {
    self.reachability = [PEXReachability reachabilityForInternetConnection];

    DDLogVerbose(@"notifs");
    // Register for reachability notifications.
    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs addObserver:self selector:@selector(onReachabilityChange:) name:kReachabilityChangedNotification object:nil];
    [notifs addObserver:self selector:@selector(onRadioChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];

    DDLogVerbose(@"reachab");
    // Start reachability notifications, has to be done on main thread because
    // reachability requires active runloop.
    //[self.reachability startNotifier:CFRunLoopGetMain()];

    DDLogVerbose(@"curReach");
    self.lastNetworkStatus = [self.reachability currentReachabilityStatus];
    DDLogInfo(@"Current network status=%ld", (long)self.lastNetworkStatus);
}

-(void) connectivityWatcherTeardown {
    if (self.reachability != nil){
        //[self.reachability stopNotifier:CFRunLoopGetMain()];
    }
}

-(void) dealloc {
    [self doUnregister];
    s_activeInstance = nil;
}

-(void) notifyLoginFinished {
    if (self.onLoginFinishedBlock != nil){
        __weak __typeof(self) weakSelf = self;
        self.onLoginFinishedBlock(weakSelf);
    }
}

-(BOOL) tryLoadCredentials {
    PEXCredentials *creds = [PEXLoginHelper loadCredentialsFromKeyChain];
    self.credentialsWereLookedUp = YES;
    if (creds == nil || [creds isMissingData]){
        self.shouldTryNormalLogin = NO;
        return NO;
    }

    self.creds = creds;
    return YES;
}

-(BOOL) tryOpenDatabase {
    // If previous required step was not performed, do it now.
    if ((self.creds == nil || [self.creds isMissingData]) && !self.credentialsWereLookedUp){
        [self tryLoadCredentials];
    }

    // If credentials are not found, cannot continue.
    self.databaseWasTriedToBeOpened = YES;
    self.shouldTryNormalLogin = NO;
    if (self.creds == nil || [self.creds isMissingData]){
        self.lastDbOpenWasOk = NO;
        DDLogError(@"Credentials is nil, cannot open database");
        return NO;
    }

    // Check cert state, derive enc keys, open database.
    @synchronized (self) {
        // Check service state, wait for finished / initialized state for 5 seconds.
        PEXService * svc = [PEXService instance];
        const int waitRes = [PEXLoginHelper waitForServiceIsOK:svc canceller:self.canceller];
        DDLogVerbose(@"Stage 2");
        if (waitRes == -2){
            DDLogError(@"Autologin - service waiting was cancelled");
            return NO;

        } else if (waitRes == -1){
            DDLogError(@"Service waiting timed out");
            [[PEXReport reportWith:YES uName:self.creds.username]
                    logError:@"alogin.svcTimeout" message:@"Autologin: service waiting timed out" error:nil];

            // Notify user autologin failed, prepare login screen with filled in password.
            self.shouldTryNormalLogin = YES;
            return NO;
        }

        // Derive encryption keys and load stored identity, if any.
        PEXUserPrivate *privData = [PEXUserPrivate aPrivateWithUsername:self.creds.username pass:self.creds.password];
        const int derivationOk = [PEXLoginHelper derivePrivData:privData creds:self.creds canceller:self.canceller tryCached:NO];
        if (derivationOk != 0){
            // Missing stored salts, database cannot be opened. Stored password can still be used to login.
            // Notify user autologin failed, he needs to login manually, with filled in password.
            self.lastDbOpenWasOk = NO;
            self.shouldTryNormalLogin = YES;
            DDLogError(@"Autologin failed - invalid key derivation, res=%d", derivationOk);
            return NO;
        }

        // Try to open database.
        DDLogVerbose(@"<open_db>");
        const BOOL dbOpenRes = [PEXLoginHelper tryOpenDatabase:privData openResult:NULL];
        if (!dbOpenRes) {
            // Database could not be opened. User has to login again.
            // Notify user autologin failed, he needs to login manually, with filled in password.
            self.lastDbOpenWasOk = NO;
            self.shouldTryNormalLogin = YES;
            DDLogWarn(@"DB open with given password failed. Aborting auto login.");
            return NO;
        }
        DDLogVerbose(@"</open_db>");

        // Load account info from DB.
        const BOOL accLoadSuccessful = [PEXLoginHelper loadAccountId:privData];
        if (!accLoadSuccessful){
            // Database does not contain vital information, probably in inconsistent state.
            // Notify user autologin failed, he needs to login manually, with filled in password.
            DDLogError(@"Opened database does not contain any user profile.");
            self.shouldTryNormalLogin = YES;
            return NO;
        }

        self.privData = privData;
        self.lastDbOpenWasOk = YES;
        return YES;
    }
}

-(BOOL) tryStartServices {

    // If previous required step is not performed, do it now. Open encrypted database.
    if (self.privData == nil && !self.databaseWasTriedToBeOpened){
        BOOL dbOK = [self tryOpenDatabase];
        if (!dbOK){
            return NO;
        }
    }

    if (self.creds == nil){
        self.lastServiceStartWasOk = NO;
        DDLogError(@"Credentials is nil, cannot open database");
        return NO;
    }

    if (self.privData == nil){
        self.lastServiceStartWasOk = NO;
        DDLogError(@"Private data is missing, database was probably not opened correctly.");
        return NO;
    }

    @try {
        @synchronized (self) {
            PEXService *svc = [PEXService instance];
            if (self.waitOnCompleteSvcInit) {
                _svcFinSem = dispatch_semaphore_create(0);
                _tdeadline = dispatch_time(DISPATCH_TIME_NOW, 100 * 1000000ull);
                svc.onSvcFinishedBlock = ^{
                    DDLogVerbose(@"Service start completed");
                    dispatch_semaphore_signal(_svcFinSem);
                };
            }

            // Update privdata state to the app state.
            PEXAppState *appState = [PEXAppState instance];
            [appState setPrivData:self.privData];

            // Start service.
            DDLogVerbose(@"update priv data");
            [svc updatePrivData:self.privData];

            // Wait if service is in ready state for login.
            int waitRes = [self waitForServiceIsReadyToStart:svc timeout:2.5 canceller:nil];
            if (waitRes < 0){
                DDLogError(@"Waiting for service ready state failed, error: %d", waitRes);
                self.shouldTryNormalLogin = YES;
                return NO;
            }

            DDLogVerbose(@"onLoginCompleted");
            [svc onLoginCompleted];

            DDLogVerbose(@"fast login completed");

            // IPH-230: Trigger cert check for all users, in the background.
            [[PEXCertificateUpdateManager instance] triggerCertUpdateForAll:NO];

            // In case of full service init wait.
            if (self.waitOnCompleteSvcInit) {
                __weak __typeof(self) weakSelf = self;
                int wRes = [PEXSOAPManager waitWithCancellation:nil
                                                  doneSemaphore:_svcFinSem
                                                    semWaitTime:_tdeadline
                                                        timeout:30.0
                                                      doRunLoop:NO
                                                    cancelBlock:^BOOL {
                    return [weakSelf wasCancelled];
                }];

                DDLogVerbose(@"Svc finished event, waiting result: %d", wRes);
            }
            self.lastServiceStartWasOk = YES;
        }

        self.shouldTryNormalLogin = NO;
        return YES;
    } @catch(NSException * ex){
        DDLogError(@"Cannot start services, exception=%@", ex);
    }

    self.lastServiceStartWasOk = NO;
    return NO;
}

-(int) waitForServiceIsReadyToStart:(PEXService *)svc timeout: (NSTimeInterval) timeout canceller:(id <PEXCanceller>)canceller {
    DDLogVerbose(@"Starting wait loop for service to become ready.");

    NSDate * date = [NSDate date];
    int returnVal = 0;
    while (YES) {
        if (svc.initState == PEX_SERVICE_FINISHED || svc.initState == PEX_SERVICE_INITIALIZED) {
            DDLogDebug(@"Service is ready for a new login process.");
            break;
        }

        if ([date timeIntervalSinceNow] < (-1.0 * timeout)) {
            returnVal = -1;
            DDLogError(@"Waiting for service to become ready for login timed out.");
            break;
        }

        if (canceller != nil && [canceller isCancelled]){
            returnVal = -2;
            DDLogWarn(@"Waiting for serice to become ready was cancelled");
            break;
        }

        // adapt this value in microseconds.
        usleep(10000);
    }

    return returnVal;
}

-(void) onReachabilityChange:(NSNotification *)notice {
    // called after network status changes
    NetworkStatus internetStatus = [self.reachability currentReachabilityStatus];
    BOOL works = NO;
    switch (internetStatus) {
        case NotReachable: {
            DDLogVerbose(@"The internet is down.");
            break;
        }
        case ReachableViaWiFi: {
            DDLogVerbose(@"The internet is working via WIFI");
            works = YES;
            break;
        }
        case ReachableViaWWAN: {
            DDLogVerbose(@"The internet is working via WWAN!");
            works = YES;
            break;
        }
    }

    self.wasConnectionWorkingLastTime = works;
    PEXConnectivityChange * conChange = [PEXConnectivityChange changeWithConnection:PEX_CONN_NO_CHANGE sip:PEX_CONN_NO_CHANGE xmpp:PEX_CONN_NO_CHANGE];

    BOOL conWoks = [PEXService isNetworkStatusWorking:internetStatus];
    conChange.connectionWorks = conWoks ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    conChange.networkStatusPrev = self.lastNetworkStatus;
    conChange.networkStatus = internetStatus;
    conChange.connection = works ? PEX_CONN_GOES_UP : PEX_CONN_GOES_DOWN;
    self.lastNetworkStatus = internetStatus;
    [self onConnectivityChange:conChange];
}

-(void) onRadioChanged:(NSNotification *)notice {

}

/**
* Receive local user presence changes in order to broadcast new presence state.
*/
- (void)onConnectivityChange:(PEXConnectivityChange *)conChange {
    if (conChange == nil){
        return;
    }

    __weak __typeof(self) weakSelf = self;
    if (conChange.connection == PEX_CONN_NO_CHANGE) {
        return;
    }

    BOOL works = conChange.connectionWorks == PEX_CONN_IS_UP;
    if (!works){
        return;
    }

    // New auto-login attempt when connectivity is recovered.
    [PEXService executeWithName:@"autoLoginStart" async:YES block:^{
        PEXAutoLoginManager * mgr = weakSelf;
        DDLogDebug(@"Connectivity OK again, trying auto login");


    }];
}


@end