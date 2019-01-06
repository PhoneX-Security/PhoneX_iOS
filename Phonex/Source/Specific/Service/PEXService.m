//
// Created by Dusan Klinec on 01.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "PEXService.h"
#import "PEXXmppCenter.h"
#import "PEXPjManager.h"
#import "PEXMessageManager.h"
#import "PEXUserPrivate.h"
#import "PEXXmppManager.h"
#import "PEXDatabase.h"
#import "PEXCertificateUpdateManager.h"
#import "PEXFirewall.h"
#import "PEXBlockThread.h"
#import "PEXPresenceCenter.h"
#import "PEXReachability.h"
#import "PEXPjRegStatus.h"
#import "PEXUtils.h"
#import "PEXConnectivityChange.h"
#import "PEXApplicationStateChange.h"
#import "PEXStringUtils.h"
#import "PEXContactAddSelfTask.h"
#import "PEXSingleLoginWatcher.h"
#import "PEXSipUri.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXDhKeyGenManager.h"
#import "PEXVersionChecker.h"
#import "PEXFtTransferManager.h"
#import "PEXLicenceManager.h"

#import "PEXGuiNoticeManager.h"
#import "PEXXMPPPhxPushModule.h"
#import "PEXPushManager.h"
#import "PEXSOAPManager.h"
#import "Flurry.h"
#import "PEXFlurry.h"
#import "PEXLoginHelper.h"
#import "PEXReport.h"
#import "PEXDBMessage.h"
#import "PEXDbWatchdog.h"
#import "PEXMovingAverage.h"
#import "PEXPaymentManager.h"
#import "PEXAccountSettingsTask.h"
#import "PEXSOAPResult.h"
#import "PEXSecurityCenter.h"
#import "PEXFileSecurityManager.h"
#import "PEXBackGroundTask.h"

static NSUncaughtExceptionHandler * prevExceptionHandler = NULL;
static NSException * lastReportedException = NULL;
static void uncaughtExceptionHandler(NSException * e);

@interface PEXService () {
    volatile BOOL _userLoggedIn;
    volatile BOOL _isInBackgroundMode;
    volatile NSUInteger _numOfActiveCellularCalls;
}

@property(nonatomic) NSOperationQueue * serialOpQueue;
@property(nonatomic) NSOperationQueue * parallelOpQueue;
@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(nonatomic) PEXServiceInitState initState;

@property(atomic) BOOL xmppStarted;
@property(atomic) BOOL sipStarted;
@property(atomic) BOOL initFinished;

@property (nonatomic) BOOL wasSipRegisteredLastTime;
@property (nonatomic) BOOL wasXMPPRegisteredLastTime;
@property (nonatomic) BOOL wasConnectionWorkingLastTime;
@property (nonatomic) NetworkStatus lastNetworkStatus;
@property (nonatomic) PEXConnectivityChange * lastConnectionChangeNotification;
@property (nonatomic) PEXBackGroundTask * backgroundKeepAliveTask;
@property (nonatomic) PEXApplicationStateChange * lastAppStateChangeSinceRegistered;
@property (nonatomic) NSDate * appLoggedInTime;
@property (nonatomic) NSRecursiveLock * callCenterLock;
@property (nonatomic) PEXAccountSettingsTask * logoutSettingTask;

@property (nonatomic) NSInteger numKeepAlives;
@property (nonatomic) NSDate * lastKeepAlive;

// Reporting / debugging statistics.
@property (nonatomic) NSInteger numForegroundSwitches;
@property (nonatomic) NSInteger numBackgroundSwitches;
@property (nonatomic) NSInteger numMemoryWarnings;
@property (nonatomic) NSInteger lastTakenMemoryOnWarning;
@property (nonatomic) NSDate * lastMemoryWarning;
@property (nonatomic) PEXMovingAverage * residentMemoryAvg;

@property (nonatomic) NSInteger keepAliveConnectivityOn;
@property (nonatomic) NSInteger keepAliveConnectivityOff;
@end

NSString *PEX_ACTION_USER_LOGIN = @"net.phonex.phonex.user.action.login";
NSString *PEX_ACTION_USER_LOGOUT = @"net.phonex.phonex.user.action.logout";
NSString *PEX_ACTION_CONNECTIVITY_CHANGE = @"net.phonex.phonex.system.action.connectivity_change";
NSString *PEX_EXTRA_CONNECTIVITY_CHANGE = @"net.phonex.phonex.system.extra.connectivity_change";
NSString *PEX_ACTION_APPSTATE_CHANGE = @"net.phonex.phonex.system.action.appstate_change";
NSString *PEX_EXTRA_APPSTATE_CHANGE = @"net.phonex.phonex.system.extra.appstate_change";
NSString *PEX_EXTRA_APPSTATE_APP = @"net.phonex.phonex.system.extra.appstate_app";
NSString *PEX_ACTION_LOW_MEMORY = @"net.phonex.phonex.system.action.low_memory";
NSString *PEX_EXTRA_LOW_MEMORY = @"net.phonex.phonex.system.extra.low_memory";

@implementation PEXService {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.serialOpQueue = [[NSOperationQueue alloc] init];
        self.serialOpQueue.maxConcurrentOperationCount = 1;
        self.serialOpQueue.name = @"svcSerialQ";

        self.parallelOpQueue = [[NSOperationQueue alloc] init];
        self.parallelOpQueue.maxConcurrentOperationCount = -1;
        self.parallelOpQueue.name = @"svcParallelQ";

        self.dispatchQueue = dispatch_queue_create("svcDispatchSQ", NULL);

        self.pjManager = [PEXPjManager instance];
        self.msgManager = [PEXMessageManager instance];
        self.xmppCenter = [PEXXmppCenter instance];
        self.xmppCenter.xmppManager = [[PEXXmppManager alloc] init];
        self.certUpdateManager = [PEXCertificateUpdateManager instance];
        self.firewall = [[PEXFirewall alloc] init];
        self.presenceCenter = [PEXPresenceCenter instance];
        self.dhKeyGenManager = [PEXDhKeyGenManager instance];
        self.ftManager = [PEXFtTransferManager instance];
        self.singleLoginWatcher = [[PEXSingleLoginWatcher alloc] init];
        self.pushManager = [[PEXPushManager alloc] init];
        self.dbWatchdog = [[PEXDbWatchdog alloc] init];
        self.paymentManager = [PEXPaymentManager instance];
        self.licenceManager = [[PEXLicenceManager alloc] init];
        self.fileSecManager = [[PEXFileSecurityManager alloc] init];
        self.backgroundKeepAliveTask = [[PEXBackGroundTask alloc] initWithName:@"keepAlive"];

        self.versionChecker = [[PEXVersionChecker alloc] init];
        self.versionChecker.onNewVersionBlock = ^(BOOL afterUpdate, uint64_t versionCode,
                                                  NSString * versionName, NSString * releaseNotes, PEXVersionChecker * checker)
        {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[PEXGuiNoticeManager instance] showNotice:versionCode];
            });
        };

        // Has to be allocated on main thread, otherwise we get stale data.
        WEAKSELF;
        [PEXSystemUtils executeOnMainAsync:YES block:^{
            DDLogVerbose(@"On-main initialization of cellular objects");
            weakSelf.callCenter = [[CTCallCenter alloc] init];
            weakSelf.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        }];

        self.callCenterLock = [[NSRecursiveLock alloc] init];
        self.initState = PEX_SERVICE_INITIALIZED;

        self.xmppStarted = NO;
        self.sipStarted = NO;
        self.initFinished = NO;
        self.lastNetworkStatus = NotReachable;
        _isInBackgroundMode = YES;
        _numOfActiveCellularCalls = 0;
        _numKeepAlives = 0;
        _lastKeepAlive = nil;

        _numForegroundSwitches = 0;
        _numBackgroundSwitches = 0;
        _numMemoryWarnings = 0;
        _lastTakenMemoryOnWarning = -1;
        _lastMemoryWarning = nil;
        _residentMemoryAvg = [PEXMovingAverage averageWithSmoothingFactor:0.15 current:0.0];

        _keepAliveConnectivityOn = 0;
        _keepAliveConnectivityOff = 0;
    }

    return self;
}

-(void) resetState {
    self.initState = PEX_SERVICE_INITIALIZED;
    self.xmppStarted = NO;
    self.sipStarted = NO;
    self.initFinished = NO;
    _isInBackgroundMode = YES;
    _numOfActiveCellularCalls = 0;
}

+ (PEXService *)instance {
    static PEXService *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

-(void) executeBareAsync: (BOOL) async block: (dispatch_block_t) block{
    if(async) {
        dispatch_async(self.dispatchQueue, block);
    } else {
        dispatch_sync(self.dispatchQueue, block);
    }
}

- (void)execute:(dispatch_block_t)block {
    [self executeWithName:@"" async: YES block:block];
}

- (void)executeAsync: (BOOL) async block: (dispatch_block_t)block {
    [self executeWithName:@"" async:async block:block];
}

- (void)executeWithName:(NSString *)name block:(dispatch_block_t)block {
    [self executeWithName:name async: YES block:block];
}

- (void)executeWithName: (NSString *)name async: (BOOL) async onQueue:(dispatch_queue_t) queue block:(dispatch_block_t)block {
    [PEXUtils executeOnQueue:queue async:async block: ^{ @autoreleasepool {
        // Create main wrapper here. May check for the cancellation.
        if (name != nil) {
            DDLogVerbose(@"<execute task=%@>", name);
        }

        @try {
            block();
        } @catch(NSException * ex){
            DDLogError(@"Exception during block execution [%@], exception=%@", name, ex);
        }

        if (name != nil) {
            DDLogVerbose(@"</execute task=%@>", name);
        }
    }}];
}

- (void)executeWithName:(NSString *)name async: (BOOL) async block:(dispatch_block_t)block {
    [self executeWithName:name async:async onQueue:self.dispatchQueue block:block];
}

- (void)executeOnGlobalQueueWithName: (NSString *)name async: (BOOL) async block:(dispatch_block_t)block {
    [self executeWithName:name async:async onQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) block:block];
}

+ (void)executeOnGlobalQueueWithName: (NSString *)name async: (BOOL) async block:(dispatch_block_t)block {
    [[self instance] executeOnGlobalQueueWithName:name async:async block:block];
}

+ (void)executeOnMain: (BOOL) async block: (dispatch_block_t)block {
    if (!block) {
        return;
    } else if ([NSThread isMainThread]) {
        block();
    } else if (async) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)executeOnMainDelayed: (NSTimeInterval) delay block: (dispatch_block_t)block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (unsigned long long)(delay * NSEC_PER_SEC)),
            dispatch_get_main_queue(), block);
}

+ (void)execute:(dispatch_block_t)block {
    [[self instance] execute:block];
}

+ (void)executeWithName:(NSString *)name block:(dispatch_block_t)block {
    [[self instance] executeWithName:name block:block];
}

+(void)executeWithName:(NSString *)name async: (BOOL) async block:(dispatch_block_t)block{
    [[self instance] executeWithName:name async:async block:block];
}

+ (void)executeWithName: (NSString *)name async: (BOOL) async onQueue:(dispatch_queue_t) queue block:(dispatch_block_t)block {
    [[self instance] executeWithName:name async:async onQueue:queue block:block];
}

-(void) executeDelayedWithName: (NSString *)name timeout:(NSTimeInterval) timeout block:(dispatch_block_t)block{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (unsigned long long)(timeout * NSEC_PER_SEC)),
            dispatch_get_main_queue(),
            ^{ @autoreleasepool {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ @autoreleasepool {
                    DDLogVerbose(@"<exec_delayed_%@>", name);
                    block();
                    DDLogVerbose(@"</exec_delayed_%@>", name);
                }});
            }});
}

+(void) executeDelayedWithName: (NSString *)name timeout:(NSTimeInterval) timeout block:(dispatch_block_t)block {
    [[self instance] executeDelayedWithName:name timeout:timeout block:block];
}

-(void) executeParallel: (NSString *)name block:(dispatch_block_t)block {
    [self.parallelOpQueue addOperationWithBlock:^{ @autoreleasepool {
        if (name) {
            DDLogVerbose(@"<exec_parallel_%@>", name);
        }

        block();

        if (name) {
            DDLogVerbose(@"</exec_parallel_%@>", name);
        }
    }}];
}

- (void)updatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;
    self.msgManager.privData = privData;
    [self.pjManager updatePrivData:privData];
    self.certUpdateManager.privData = privData;
    self.dhKeyGenManager.privData = privData;
    self.ftManager.privData = privData;
    [self.pushManager updatePrivData:privData];
    self.versionChecker.privData = privData;
    [self.dbWatchdog udatePrivData:privData];
    [self.paymentManager updatePrivData:privData];
    [self.licenceManager updatePrivData:privData];
    [self.fileSecManager updatePrivData:privData];

    // XMPP manager / center.
    if (self.xmppCenter.xmppManager != nil) {
        [self.xmppCenter.xmppManager updatePrivData:privData];
    } else {
        DDLogError(@"XMPP center has no manager");
    }
}

- (BOOL)updateInitState{
    if (self.initState == PEX_SERVICE_STARTING){
        if (self.sipStarted  && self.xmppStarted && self.initFinished){
            self.initState = PEX_SERVICE_STARTED;
            DDLogVerbose(@"Service state changed to=%lu", (unsigned long)self.initState);
            [self onServiceStarted];
            if (self.onSvcFinishedBlock != nil){
                self.onSvcFinishedBlock();
            }

            return YES;
        }
    } else if (self.initState == PEX_SERVICE_FINISHING){
        if (!self.sipStarted  && !self.xmppStarted && !self.initFinished){
            self.initState = PEX_SERVICE_FINISHED;
            DDLogVerbose(@"Service state changed to=%lu", (unsigned long)self.initState);
            [self onServiceFinished];
            if (self.onSvcFinishedBlock != nil){
                self.onSvcFinishedBlock();
            }

            return YES;
        }
    }

    return NO;
}

-(void) doRegister {
    self.reachability = [PEXReachability reachabilityForInternetConnection];

    DDLogVerbose(@"notifs");
    // Register for reachability notifications.
    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs addObserver:self selector:@selector(onReachabilityChange:) name:kReachabilityChangedNotification object:nil];
    [notifs addObserver:self selector:@selector(onRadioChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
    [notifs addObserver:self selector:@selector(onDbReloadRequest:) name:PEX_ACTION_DB_RELOAD_REQUEST object:nil];
    [notifs addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

    DDLogVerbose(@"reachab");
    // Start reachability notifications with main RunLoop.
    [self.reachability startNotifier:CFRunLoopGetMain()];

    DDLogVerbose(@"curReach");
    self.lastNetworkStatus = [self.reachability currentReachabilityStatus];
    DDLogInfo(@"Current network status=%ld", (long)self.lastNetworkStatus);

    // Register for XMPP connectivity notifications.
    [notifs addObserver:self selector:@selector(onXmppConnection:) name:PEX_ACTION_XMPP_CONNECTION object:nil];

    // Register for SIP connectivity notifications.
    [notifs addObserver:self selector:@selector(onSipConnection:) name:PEX_ACTION_SIP_REGISTRATION object:nil];
}

-(void) doUnregister {
    // Stop reachability notifications.
    if (self.reachability != nil){
        [self.reachability stopNotifier:CFRunLoopGetMain()];
    }

    // Unregister from notifications.
    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs removeObserver:self];
}

+ (BOOL) isNetworkStatusWorking: (NetworkStatus) status{
    return status == ReachableViaWiFi || status == ReachableViaWWAN;
}

- (BOOL) isIPProbablyChanged: (NetworkStatus) status{
    return status != self.lastNetworkStatus;
}

- (void)onReachabilityChange:(NSNotification *)notice {
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
    [self updateConChangeWithReachability:conChange netStatus:internetStatus];
    conChange.connection = works ? PEX_CONN_GOES_UP : PEX_CONN_GOES_DOWN;

    self.lastNetworkStatus = internetStatus;
    [self onConnectivityChanged: conChange];
}

- (void)onRadioChanged:(NSNotification *)notice {
    NetworkStatus internetStatus = [self.reachability currentReachabilityStatus];
    DDLogVerbose(@"onRadioChanged, radioTech=%@", [self getCurrentRadioTechnology]);

    PEXConnectivityChange * conChange = [PEXConnectivityChange changeWithConnection:PEX_CONN_NO_CHANGE sip:PEX_CONN_NO_CHANGE xmpp:PEX_CONN_NO_CHANGE];
    [self updateConChangeWithReachability:conChange netStatus:internetStatus];
    [self onConnectivityChanged: conChange];
}

- (void) updateConChangeWithReachability: (PEXConnectivityChange *) conChange netStatus: (NetworkStatus) internetStatus {
    BOOL conWoks = [PEXService isNetworkStatusWorking:internetStatus];
    conChange.connectionWorks = conWoks ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    conChange.networkStatusPrev = self.lastNetworkStatus;
    conChange.networkStatus = internetStatus;
    conChange.recheckIPChange |= conWoks && [self isIPProbablyChanged:internetStatus];
    conChange.radioTechnology = [self getCurrentRadioTechnology];
}

- (NetworkStatus) getCurentNetworkStatus {
    return [self.reachability currentReachabilityStatus];
}

- (BOOL) isConnectivityWorking {
    return [PEXService isNetworkStatusWorking:[self getCurentNetworkStatus]];
}

- (BOOL) isConnectivityAndServiceWorking {
    return [self isConnectivityWorking] && _wasXMPPRegisteredLastTime;
}

- (NSString *) getCurrentRadioTechnology {
    NetworkStatus status = [self getCurentNetworkStatus];
    if (status != ReachableViaWWAN) {
        return nil;
    }

    return self.telephonyInfo.currentRadioAccessTechnology;
}

- (BOOL)isInBackground {
    return _isInBackgroundMode;
}

-(NSUInteger) getNumberOfActiveCellularCalls {
    return _numOfActiveCellularCalls;
}

// Internal call!
-(void) setNumberOfActiveCellularCalls: (NSUInteger) param {
    _numOfActiveCellularCalls = param;
}

- (void)setAllToOffline {
    [self.presenceCenter setOfflinePresence:self.privData.username];
}

- (void)onXmppConnection:(NSNotification *)notice {
    NSNumber * connected = notice.userInfo[PEX_EXTRA_XMPP_CONNECTION];
    if (connected == nil){
        return;
    }

    if (self.wasXMPPRegisteredLastTime == [connected boolValue]){
        return; // we know already.
    }

    self.wasXMPPRegisteredLastTime = [connected boolValue];
    PEXConnChangeVal xmppChange = self.wasXMPPRegisteredLastTime ? PEX_CONN_GOES_UP : PEX_CONN_GOES_DOWN;
    PEXConnectivityChange * conChange = [PEXConnectivityChange changeWithConnection:PEX_CONN_NO_CHANGE sip:PEX_CONN_NO_CHANGE xmpp:xmppChange];
    conChange.xmppWorksPrev = !self.wasXMPPRegisteredLastTime ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;

    [self onConnectivityChanged:conChange];
    DDLogInfo(@"XMPP connection: %@, notif=%@", connected, notice);
}

- (void)onSipConnection:(NSNotification *)notice{
    PEXPjRegStatus * regStatus = notice.userInfo[PEX_EXTRA_SIP_REGISTRATION];
    if (regStatus == nil){
        return;
    }

    if (self.wasSipRegisteredLastTime == [regStatus registered]){
        return; // we know already.
    }

    const BOOL registered = [regStatus registered];

    PEXConnChangeVal sipChange = registered ? PEX_CONN_GOES_UP : PEX_CONN_GOES_DOWN;
    PEXConnectivityChange * conChange = [PEXConnectivityChange changeWithConnection:PEX_CONN_NO_CHANGE sip:sipChange xmpp:PEX_CONN_NO_CHANGE];
    conChange.sipWorks = registered ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    conChange.sipWorksPrev = !self.wasSipRegisteredLastTime ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;

    self.wasSipRegisteredLastTime = registered;
    [self onConnectivityChanged:conChange];
    DDLogInfo(@"SIP connection: %@, notif=%@", regStatus, notice);
}

-(void) onConnectivityChanged: (PEXConnectivityChange *) conChange{
    // Broadcast this event.

    // Fetch connectivity information if not provided.
    if (conChange.connection == PEX_CONN_NO_CHANGE){
        NetworkStatus internetStatus = [self.reachability currentReachabilityStatus];
        [self updateConChangeWithReachability:conChange netStatus:internetStatus];

        self.lastNetworkStatus = internetStatus;
        self.wasConnectionWorkingLastTime = [PEXService isNetworkStatusWorking:internetStatus];
    }

    // Fill additional information, current state of the connection.
    if (conChange.connectionWorks == PEX_CONN_DONT_KNOW) {
        conChange.connectionWorks = self.wasConnectionWorkingLastTime ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    }

    if (conChange.sipWorks == PEX_CONN_DONT_KNOW) {
        conChange.sipWorks = self.wasSipRegisteredLastTime ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    }

    if (conChange.xmppWorks == PEX_CONN_DONT_KNOW){
        conChange.xmppWorks = self.wasXMPPRegisteredLastTime ? PEX_CONN_IS_UP : PEX_CONN_IS_DOWN;
    }

    DDLogVerbose(@"New connectivity change = %@", conChange);
    self.lastConnectionChangeNotification = conChange;

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_CONNECTIVITY_CHANGE object:nil userInfo:@{PEX_EXTRA_CONNECTIVITY_CHANGE : conChange}];
}

- (PEXConnectivityChange *)getLastConnectionChange {
    return [self.lastConnectionChangeNotification copy];
}

-(BOOL) isUriSystemContact:(NSString *)uri {
    return [self isUriOneOfOurs:uri];
}

- (BOOL)isUriOneOfOurs:(NSString *)uri {
    if (uri == nil || self.privData == nil || self.privData.username == nil){
        return NO;
    }

    NSString * trimAndSmall = [[PEXStringUtils trimWhiteSpaces:uri] lowercaseString];
    return [self.privData.username isEqualToString:trimAndSmall];
}

- (NSString *) sanitizeUserContact: (NSString *) address {
    NSString * toReturn = [[PEXStringUtils trimWhiteSpaces:address] lowercaseString];
    if ([toReturn rangeOfString:@"@"].location == NSNotFound){
        // Obtain default domain of the current user.
        BOOL domainAdded = NO;
        if (self.privData != nil && self.privData.username != nil) {
            PEXSIPURIParsedSipContact *contact = [PEXSipUri parseSipContact:self.privData.username];
            if (contact != nil && contact.domain != nil) {
                toReturn = [NSString stringWithFormat:@"%@@%@", toReturn, contact.domain];
                domainAdded = YES;
            }
        }

        if (!domainAdded){
            toReturn = [NSString stringWithFormat:@"%@@phone-x.net", toReturn];
            domainAdded = YES;
        }

    }

    return toReturn;
}

- (void) fixFileProtectionParameters {
    [self executeWithName:nil async:YES block:^{
        NSUInteger checked = [PEXSecurityCenter setDefaultProtectionModeOnAll:[PEXSecurityCenter getDefaultPrivateDirectory:YES]];
        DDLogVerbose(@"Number of checked files for protection level: %lu", (long unsigned) checked);
    }];
}

/**
 * Recomputes number of active cellular calls properly.
 * Completion block can be set. If async is YES, return value is always zero.
 */
- (NSUInteger) recomputeNumberOfCellularCallsAsync: (BOOL) async
                                   completionBlock: (void (^)(NSArray *, NSUInteger)) completionBlock
{
    NSMutableArray * callsArray = [[NSMutableArray alloc] init];
    WEAKSELF;

    // Do the processing outside of the lock & main thread.
    // Postprocessing block called later on. Calls completion handler, sets current number to the service counter.
    NSUInteger (^postProcessBlock)(NSMutableArray * callsArrayParam) = ^NSUInteger(NSMutableArray * callsArrayParam){
        NSUInteger activeCount = 0;
        @try {
            for (id callObj in callsArrayParam) {
                if (callObj == nil || ![callObj isKindOfClass:[CTCall class]]) {
                    continue;
                }

                CTCall *call = (CTCall *) callObj;
                NSString *callState = call.callState;
                if ([CTCallStateDialing isEqualToString:callState]
                        || [CTCallStateIncoming isEqualToString:callState]
                        || [CTCallStateConnected isEqualToString:callState]) {
                    DDLogVerbose(@"CellularCallActive: %@, state: %@", call, callState);
                    activeCount += 1;
                }
            }

            // Set correct number to the service.
            [weakSelf setNumberOfActiveCellularCalls:activeCount];

            // Call completion block if set.
            if (completionBlock != nil){
                completionBlock(callsArrayParam, activeCount);
            }

        } @catch (NSException *e) {
            DDLogError(@"Exception thrown in #of active calls, exception: %@", e);
        }

        return activeCount;
    };

    // Get copy of all calls, on the main thread.
    // Due to http://stackoverflow.com/questions/9304063/ctcallcenter-currentcalls-not-updating-only-works-once-per-installation
    // bug in the call center - setting handler will obsolete current calls.
    DDLogVerbose(@"Enumerating active calls on the main thread");
    [PEXSystemUtils executeOnMainAsync:async block:^{ @autoreleasepool {
        PEXService *sSelf = weakSelf;
        [sSelf.callCenterLock lock];
        @try {
            DDLogVerbose(@"<cellular_callback_registration2>");
            if (sSelf.callCenter) {
                sSelf.callCenter.callEventHandler = nil;
            }

            sSelf.callCenter = [[CTCallCenter alloc] init];

            // Fill mutable array outside of the block with obtained calls.
            NSArray *currentCallsArray = [sSelf.callCenter.currentCalls allObjects];
            if (currentCallsArray != nil) {
                [callsArray addObjectsFromArray:currentCallsArray];
            }

            // Set handler back so we get updated about next call events.
            [sSelf.callCenter setCallEventHandler:^(CTCall *call) {
                [weakSelf onCellularCallStateChanged:call];
            }];

            DDLogVerbose(@"</cellular_callback_registration2>");

            // In asynchronous mode, start a new parallel async task to escape main thread.
            if (async) {
                [sSelf executeParallel:nil block:^{
                    postProcessBlock(callsArray);
                }];
            }

        } @catch (NSException *e) {
            DDLogError(@"Exception thrown in #of active calls, exception: %@", e);
        } @finally {
            [sSelf.callCenterLock unlock];
        }
    }
    }];

    // Post processing for synchronous call.
    return async ? 0 : postProcessBlock(callsArray);
}

/**
 * Recomputes cellular calls and triggers update handlers in the background.
 */
- (NSUInteger) recheckCellularCallsAsync: (BOOL) async completionBlock: (void (^)(NSArray *, NSUInteger)) completionBlock {
    // Post processing block for handler invocations.
    WEAKSELF;
    void (^postProcessBlock)(NSUInteger) = ^void(NSUInteger numOfActive){
        DDLogInfo(@"CellularCalls recomputed, #ofActive=%lu", (unsigned long)numOfActive);

        // Broadcast calling state to the presence manager.
        PEXPresenceUpdateMsg *msg = [PEXPresenceUpdateMsg msgWithUser:weakSelf.privData.username];
        msg.isCellularCallingRightNow = @(numOfActive > 0);

        // Send presence update message for given user to the presence center.
        PEXPresenceCenter *pc = [PEXPresenceCenter instance];
        [pc updatePresenceForLogged:msg];

        // Pj manager handler.
        [weakSelf.pjManager onCellularCall:nil numActiveCalls:numOfActive];
    };

    // Prepare custom completion block, with invocation of update.
    void (^completionBlockEx)(NSArray *, NSUInteger) = ^(NSArray *calls, NSUInteger numOfActive) {
        // Previous completion block
        if (completionBlock){
            completionBlock(calls, numOfActive);
        }

        // Handlers - always asynchronous.
        [weakSelf executeWithName:@"cellularUpdate" async:YES block:^{
            postProcessBlock(numOfActive);
        }];
    };

    // Do the re-computation.
    NSUInteger toReturn = [self recomputeNumberOfCellularCallsAsync:async completionBlock:completionBlockEx];
    return toReturn;
}

-(void) onCellularCallStateChanged: (CTCall *) call {
    PJ_UNUSED_ARG(call);
    WEAKSELF;

    if (self.initState != PEX_SERVICE_STARTED || self.privData == nil){
        DDLogError(@"Service is not started or privData is nil");
        return;
    }

    if ([PEXUtils isEmpty: self.privData.username]){
        DDLogError(@"Empty user name in priv data %p", self.privData.username);
    }

    DDLogInfo(@"CellularStateChange, call=%@", call);
    [self executeWithName:@"onCellularChange" async:YES block:^{
        [weakSelf recheckCellularCallsAsync:YES completionBlock:nil];
    }];
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        [self onAppActive];
    }
}

- (void) onAppActive {
    @try {
        // File permissions fix.
        [self fixFileProtectionParameters];

        // Database test.
        DDLogVerbose(@"DB test");
        const BOOL dbOK = [self.dbWatchdog doBackgroundCheck];
        if (!dbOK) {
            DDLogError(@"DB failed during keep alive, report: %@", [[PEXDatabase instance] genDbLogReport]);
        }

        // XMPP test
        if (dbOK && _xmppCenter != nil && _xmppCenter.xmppManager != nil) {
            DDLogVerbose(@"<XMPP-keep-alive>");
            [_xmppCenter.xmppManager keepAlive];  // Fully async call.
            DDLogVerbose(@"</XMPP-keep-alive>");
        }

        // Certificate update logic.
        if (dbOK && _certUpdateManager != nil) {
            [_certUpdateManager keepAlive:YES];
        }

        // Recheck message queue for sending requests.
        if (dbOK && _msgManager != nil) {
            [_msgManager keepAlive:YES];
        }

        // Cellular call check
        [self onCellularCallStateChanged:nil];

    } @catch(NSException *e){
        DDLogError(@"Exception on keep alive: %@", e);
    }
}

- (void)onLoginCompleted {
    if (self.initState == PEX_SERVICE_FINISHED){
        self.initState = PEX_SERVICE_INITIALIZED;
    }

    if (self.initState != PEX_SERVICE_INITIALIZED){
        DDLogError(@"Service is not in state for login. State: %lu", (unsigned long)self.initState);
        return;
    }

    // Log level.
    [PEXBase loadLogLevelFromPrefs];
    [PEXBase setLogSyncFromPrefs];
    [PEXReport checkGoogleAnalyticsEnabledStatus];

    // Exception handler setup.
    [self installExceptionHandler];

    // Set init state to starting = start in progress.
    self.initState = PEX_SERVICE_STARTING;
    _userLoggedIn = YES;
    __weak __typeof(self) weakSelf = self;
    DDLogVerbose(@"doRegister");
    // Register to connectivity changes.
    [self doRegister];

    DDLogVerbose(@"doreg2");
    // Firewall init.
    [self.firewall doRegister];
    [self.singleLoginWatcher doRegister];
    [self.versionChecker doRegister];
    [self.versionChecker checkVersion];
    [self.pushManager doRegister];
    [self.certUpdateManager doRegister];
    [self.dbWatchdog doRegister];

    DDLogVerbose(@"setOffline all contacts");
    // Turn everybody offline
    [self.presenceCenter setOfflinePresence:self.privData.username];

    // Register for cellular uodates, callback on the main thread as cellular object is sensitive for that.
    [PEXSystemUtils executeOnMainAsync:YES block:^{
        DDLogVerbose(@"Cellular callback registration");
        [weakSelf.callCenter setCallEventHandler:^(CTCall *call) {
            [weakSelf onCellularCallStateChanged:call];
        }];
    }];

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];

    DDLogVerbose(@"xmppReg");
    // Start XMPP stack.
    [self.xmppCenter.xmppManager doRegister];
    [self.xmppCenter.xmppManager onLoginCompleted];
    // Mark as started although XMPP is not completely prepared for sending/receiving.
    self.xmppStarted = YES;

    DDLogVerbose(@"SipInit");
    // Start SIP stack.
    [self executeWithName:@"sip_stack_init" block:^{
        NSError * error = nil;
        [self.pjManager startStack:&error];
        [self.pjManager doRegister];
        if (error != nil){
            DDLogError(@"Error! start of pj stack did not go well..., error: %@", error);
            return;
        }

        self.sipStarted = YES;
        [self updateInitState];
    }];

    DDLogVerbose(@"msgInit");
    // Messaging stack init.
    self.msgManager.fetchCertIfMissing = YES;
    [self.msgManager doRegister];
    [self.msgManager onAccountLoggedIn];

    // Presence center
    [self.presenceCenter doRegister];

    DDLogVerbose(@"dhkeyman");
    // DH key gen manager
    [self.dhKeyGenManager doRegister];
    [self.dhKeyGenManager triggerUserCheck];
    [self.ftManager doRegister];
    [self.pushManager onLoginCompleted];
    [self.paymentManager doRegister];
    [self.licenceManager doRegister];
    [self.fileSecManager doRegister];

    DDLogVerbose(@"updInit");
    // Take care of the init state.
    self.initFinished = YES;
    [self updateInitState];

    DDLogVerbose(@"notif");
    [notifs postNotificationName:PEX_ACTION_USER_LOGIN object:nil userInfo:nil];
    [Flurry logEvent:@FLURRY_EVT_STATE_LOGIN];

    // Install keep alive handler right after login completes, due to auto-login after crash.
    [self installKeepAlive:[UIApplication sharedApplication]];
    DDLogVerbose(@"Service init finished after login");

    // Fix permissions.
    [self fixFileProtectionParameters];

    // If application state was changed before components were registered, broadcast this delayed
    // app state change to the components so they know whether app is running in background or not.
    if (_lastAppStateChange != nil && _lastAppStateChange != _lastAppStateChangeSinceRegistered) {
        DDLogDebug(@"Broadcasting delayed app state event: %@", _lastAppStateChange);
        _lastAppStateChangeSinceRegistered = _lastAppStateChange;
        [self executeWithName:nil async:YES block:^{
            NSNotificationCenter * notifs2 = [NSNotificationCenter defaultCenter];
            [notifs2 postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                                userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : _lastAppStateChangeSinceRegistered,
                                        PEX_EXTRA_APPSTATE_APP : [UIApplication sharedApplication]}];
        }];
    }

    _appLoggedInTime = [NSDate date];
}

-(void) onLogout: (const bool) resetKeychain {
    if (self.initState != PEX_SERVICE_STARTED){
        DDLogError(@"Service is not in state for logout. State: %lu", (unsigned long)self.initState);
        return;
    }

    // Set state to finishing = finish in progress.
    self.initState = PEX_SERVICE_FINISHING;
    _userLoggedIn = NO;

    // Send logout state to server so push server knows we are out.
    [self setLogoutEvent];

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_USER_LOGOUT object:nil userInfo:nil];

    // Unregister from connectivity changes.
    [self doUnregister];

    // Report user triggered logout manually.
    [PEXReport logUsrEvent:PEX_EVENT_LOGOUT];

    // Shutdown & unregister message manager.
    [self executeWithName:@"message_manager_deinit" block:^{
        DDLogVerbose(@"Going to shutdown Message manager / DH key manager");
        [self.paymentManager doUnregister];
        [self.fileSecManager doUnregister];
        [self.licenceManager doUnregister];
        [self.dbWatchdog doUnregister];
        [self.msgManager quit];
        [self.msgManager doUnregister];
        [self.dhKeyGenManager quit];
        [self.dhKeyGenManager doUnregister];
        [self.ftManager quit];
        [self.ftManager doUnregister];
        [self.certUpdateManager doUnregister];
        [self updateInitState];
    }];

    // Shutdown SIPStack.
    [self executeWithName:@"sip_stack_deinit" block:^{
        DDLogVerbose(@"Going to shutdown SIP stack");
        [self.pjManager doUnregister];
        [self.pjManager cleanDestroy];

        // Mark as finished. In case of an extension (e.g., another tasks launched from destroy), add completion block.
        self.sipStarted = NO;
        [self updateInitState];
    }];

    // Shutdown XMPPstack.
    [self executeWithName:@"xmpp_deinit" block:^{
        DDLogVerbose(@"Going to shutdown XMPP stack");
        [self.xmppCenter.xmppManager quit];
        [self.xmppCenter.xmppManager doUnregister];

        // Turn everybody offline.
        [self.presenceCenter setOfflinePresence:self.privData.username];

        self.xmppStarted = NO;
        [self updateInitState];
    }];

    // Firewall deinit.
    [self executeWithName:@"firewall_&_presence_deinit" block:^{
        [self.firewall doUnregister];
        [self.presenceCenter doUnregister];
        [self.singleLoginWatcher doUnregister];
        [self.versionChecker doUnregister];
        [self.pushManager doUnregister];
    }];

    [self executeWithName:@"unload_database" block:^{
        DDLogVerbose(@"Unloading database");
        [PEXDatabase unloadDatabase];
    }];

    __weak __typeof(self) weakSelf = self;
    [self executeWithName:@"logout_finished" block:^{
        __strong PEXService * strongSelf = weakSelf;
        if (strongSelf == nil){
            return;
        }

        // Mark as finished.
        self.initFinished = NO;
        [self updateInitState];

        DDLogVerbose(@"Logout finished successfully.");
    }];

    // Delete stored password.
    if (resetKeychain) {
        [PEXLoginHelper resetKeychain];
    }

    [self updateInitState];
    DDLogVerbose(@"onLogout call finished");
}

- (void) onSettingsUpdate: (NSDictionary *) settings privData: (PEXUserPrivate *) privData {
    // Pass configuration update to individual components.
    [self.pjManager onSettingsUpdate:settings privData:privData];
}

-(void) setLogoutEvent {
    WEAKSELF;
    [self executeWithName:@"logoutEvent" block:^{
        @try {
            if (![weakSelf isConnectivityWorking]){
                DDLogError(@"Connectivity is not working, cannot logout properly");
                return;
            }

            DDLogVerbose(@"Setting logout state");
            // Settings task.
            weakSelf.logoutSettingTask = [[PEXAccountSettingsTask alloc] init];
            weakSelf.logoutSettingTask.privData = [[PEXAppState instance] getPrivateData];
            weakSelf.logoutSettingTask.retryCount = 1;
            weakSelf.logoutSettingTask.loggedOut = @(1);
            weakSelf.logoutSettingTask.completionHandler = ^(PEXAccountSettingsTask *task) {
                if (task.lastResult.code == PEX_SOAP_CALL_RES_OK) {
                    DDLogVerbose(@"Logout update successful");

                } else {
                    DDLogError(@"Logout update task failed");
                }
            };

            [weakSelf.logoutSettingTask requestWithRetryCount];

        } @catch(NSException * ex){
            DDLogError(@"Exception when setting logout event: %@", ex);
        }
    }];
}

-(void) addCurrentUserToContactList {
    PEXContactAddSelfTask * task = [[PEXContactAddSelfTask alloc] initWithController:nil];
    task.contactAddress = self.privData.username;

    DDLogVerbose(@"Going to add current user: %@", task.contactAddress);
    [task start];
}

- (BOOL) startBgKeepAlive: (dispatch_block_t) expirationHandler {
    return [self.backgroundKeepAliveTask start:expirationHandler];
}

- (BOOL) stopBgKeepAlive {
    return [self.backgroundKeepAliveTask stop];
}

// @deprecated
- (void)keepAlive {
    dispatch_block_t keepAliveBlock = ^{
        __block volatile BOOL cancelled = NO;
        dispatch_block_t expirationHandler = ^{
            // Custom expiration handler - terminate waiting if something changed and iOS wants us to quit.
            cancelled = YES;
        };

        // Mark start of the background task.
        _numKeepAlives += 1;
        _lastKeepAlive = [NSDate date];
        [self startBgKeepAlive:expirationHandler];
        NSTimeInterval timeStart = [[NSDate date] timeIntervalSince1970];

        // Completion signalization from registration routine.
        dispatch_semaphore_t semWait = dispatch_semaphore_create(0);

        // Another modules may want keep-alive handler here, e.g., XMPP module.
        DDLogVerbose(@"<keep-alive appRunningSince=%@ numKeepAlives=%ld>", _appLoggedInTime, (long int)_numKeepAlives);

        // Connectivity statistics for UI report.
        if ([self isConnectivityWorking]){
            _keepAliveConnectivityOn += 1;
        } else {
            _keepAliveConnectivityOff += 1;
        }

        // File permissions fix.
        [self fixFileProtectionParameters];

        // Database test.
        DDLogVerbose(@"DB test");
        const BOOL dbOK = [self.dbWatchdog doBackgroundCheck];
        if (!dbOK){
            DDLogError(@"DB failed during keep alive, report: %@", [[PEXDatabase instance] genDbLogReport]);
        }

        // XMPP test
        if (dbOK && _xmppCenter != nil && _xmppCenter.xmppManager != nil){
            DDLogVerbose(@"<XMPP-keep-alive>");
            [_xmppCenter.xmppManager keepAlive];  // Fully async call.
            DDLogVerbose(@"</XMPP-keep-alive>");
        }

        // Certificate update logic.
        if (dbOK && _certUpdateManager != nil){
            [_certUpdateManager keepAlive:YES];
        }

        // Recheck message queue for sending requests.
        if (dbOK && _msgManager != nil){
            [_msgManager keepAlive:YES];
        }

        // Registration in keep-alive. Takes the most of the time.
        // TODO: transfer to outbound keep-alive ping with \r\n\r\n.
        if (dbOK && _pjManager != nil){
            DDLogVerbose(@"Performing keep-alive re-registration. offset: %f", [[NSDate date] timeIntervalSince1970] - timeStart);
            [_pjManager keepAlive: YES completionBlock:^(pj_status_t status) {
                DDLogVerbose(@"Re-registration call finished, offset: %f.", [[NSDate date] timeIntervalSince1970] - timeStart);
                if (semWait != nil){
                    dispatch_semaphore_signal(semWait);
                }
            }];
        } else {
            DDLogError(@"PjManager is nil in keepalive / DB broken");
            return;
        }

        // Cellular call check
        [self onCellularCallStateChanged:nil];

        // We have 10 seconds at maximum, then we are going to be terminated, in background task somewhat more.
        NSTimeInterval timeRemaining = [[UIApplication sharedApplication]backgroundTimeRemaining];
        timeRemaining = MIN(10.0, timeRemaining);
        DDLogVerbose(@"Time remaining: %.2f", timeRemaining);

        // Wait for completion or expire with remaining time.
        int waitRes = [PEXSOAPManager waitWithCancellation:nil doneSemaphore:semWait
                                 semWaitTime:dispatch_time(DISPATCH_TIME_NOW, 250 * 1000000ull)
                                     timeout:timeRemaining - 3.0
                                   doRunLoop:YES
                                 cancelBlock:^BOOL {
                                     return cancelled;
                                 }];

        // Wait is finished here, either registration succeeded or timed out.
        semWait = nil;

        // Installing keep-alive handler again.
        [self installKeepAlive:[UIApplication sharedApplication]];

        // Memory reporting in keep-alive. From logs we can trace memory consumption in time.
        NSInteger residentMemory = 0;
        NSString * memReport = [PEXUtils getFreeMemoryReport:NULL resident:&residentMemory suspend:NULL];
        if (_numKeepAlives <= 1){
            _residentMemoryAvg.current = (double)residentMemory;
        } else {
            [_residentMemoryAvg update:(double)residentMemory];
        }

        DDLogVerbose(@"Terminating keep-alive handler. Memory (%@) </keep-alive wait_res=%d, time=%f>",
                memReport, waitRes, [[NSDate date] timeIntervalSince1970] - timeStart);

        [self stopBgKeepAlive];
    };

    // This method is executed in GUI thread so call keep-alive networking code on background.
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), keepAliveBlock);
    keepAliveBlock();
}

-(void) installKeepAlive: (UIApplication *) application {
    // KeepAlive was deprecated and disabled in iOS 10.
#ifdef PEX_KEEPALIVE_ENABLED
    DDLogVerbose(@"Installing keep alive handler");
    [application setKeepAliveTimeout:600 handler: ^{
        DDLogVerbose(@"iOS keep-alive handler called");
        [self performSelectorOnMainThread:@selector(keepAlive) withObject:nil waitUntilDone:YES];
    }];
#endif
}

-(void) onServiceFinished {
    DDLogInfo(@"Service finished");
}

-(void) onServiceStarted {
    DDLogInfo(@"Service started");
}

- (void)onDbReloadRequest:(NSNotification *)notice {
    __weak __typeof(self) weakSelf = self;
    [self executeWithName:@"db_reload" block:^{
        PEXService * svc = weakSelf;
        if (svc == nil){
            DDLogError(@"svc is nill in db_reload");
            return;
        }

        // Check if database is reloadable = we have login credentials available.
        if (svc.privData == nil
                || [PEXUtils isEmpty:svc.privData.username]
                || [PEXUtils isEmpty:svc.privData.pkcsPass]){
            DDLogError(@"Could not reload database - missing DB credentials. User: %@", svc.privData.username);
            return;
        }

        if (!svc.userLoggedIn){
            DDLogError(@"DB wont be reloaded as user is not logged in anymore");
            return;
        }

        // PEXUser for Database API.
        PEXUser * const user = [[PEXUser alloc] init];
        user.email = svc.privData.username;

        PEXDbOpenStatus openStatus;
        BOOL success = [[PEXDatabase instance] tryReloadDatabase:user encryptionKey:svc.privData.pkcsPass pStatus:&openStatus];
        if (!success){
            DDLogError(@"Database was not reloaded properly, openStatus: %d, userName: %@", (int) openStatus, svc.privData.username);
            [PEXReport logEvent:PEX_EVENT_DB_RELOAD_FAILED];

            // Current solution is to trigger an assertion to restart the app.
            // iOS should restart the application and autologin should handle the rest.
            [DDLog flushLog];
            assert(success && "DB reload failed with fatal error");

            // TODO: display warning to the user that error occurred in the app and ask user to restart the app.
            // TODO: ask user to logout and login if problem persists.
        } else {
            // Log DB reloaded event to the Flurry. We should know about this.
            [PEXReport logEvent:PEX_EVENT_DB_RELOADED];
        }
    }];
}

- (void)onApplicationWillResignActive:(UIApplication *)application {
    PEXApplicationStateChange * appStateChange = [PEXApplicationStateChange changeWithStateChange:PEX_APPSTATE_WILL_RESIGN_ACTIVE];
    _isInBackgroundMode = YES;
    _lastAppStateChange = appStateChange;
    if (self.initState == PEX_SERVICE_STARTED){
        _lastAppStateChangeSinceRegistered = appStateChange;
    }

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                        userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : appStateChange,
                        PEX_EXTRA_APPSTATE_APP: application}];
}

- (void)onApplicationDidEnterBackground:(UIApplication *)application {
    PEXApplicationStateChange * appStateChange = [PEXApplicationStateChange changeWithStateChange:PEX_APPSTATE_DID_ENTER_BACKGROUND];
    _isInBackgroundMode = YES;
    _lastAppStateChange = appStateChange;
    _numBackgroundSwitches += 1;
    if (self.initState == PEX_SERVICE_STARTED){
        _lastAppStateChangeSinceRegistered = appStateChange;
    }

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                        userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : appStateChange,
                                PEX_EXTRA_APPSTATE_APP: application}];

    // Timeout handler is set here, usually. Since there can be only one timeout handler, register a single one
    // which invokes multiple registered modules.
    // On to background transition - re-register quickly and then each 600 seconds (iOS minimum for keep-alive).
    // 600s is useless in NAT keep-alive scenario, but will at least try to keep registration around.
    DDLogVerbose(@"App in background");
    [self installKeepAlive:application];
    [Flurry logEvent:@FLURRY_EVT_STATE_INACTIVE];
}

- (void)onApplicationWillEnterForeground:(UIApplication *)application {
    PEXApplicationStateChange * appStateChange = [PEXApplicationStateChange changeWithStateChange:PEX_APPSTATE_WILL_ENTER_FOREGROUND];
    _lastAppStateChange = appStateChange;
    if (self.initState == PEX_SERVICE_STARTED){
        _lastAppStateChangeSinceRegistered = appStateChange;
    }

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                        userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : appStateChange,
                                PEX_EXTRA_APPSTATE_APP: application}];
}

- (void)onApplicationDidBecomeActive:(UIApplication *)application {
    PEXApplicationStateChange * appStateChange = [PEXApplicationStateChange changeWithStateChange:PEX_APPSTATE_DID_BECOME_ACTIVE];
    _lastAppStateChange = appStateChange;
    _isInBackgroundMode = NO;
    _numForegroundSwitches += 1;
    if (self.initState == PEX_SERVICE_STARTED){
        _lastAppStateChangeSinceRegistered = appStateChange;
    }

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                        userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : appStateChange,
                                PEX_EXTRA_APPSTATE_APP: application}];
}

- (void)onApplicationWillTerminate:(UIApplication *)application {
    PEXApplicationStateChange * appStateChange = [PEXApplicationStateChange changeWithStateChange:PEX_APPSTATE_WILL_TERMINATE];
    _isInBackgroundMode = YES; // Termination, but got the point.
    _lastAppStateChange = appStateChange;
    if (self.initState == PEX_SERVICE_STARTED){
        _lastAppStateChangeSinceRegistered = appStateChange;
    }

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_APPSTATE_CHANGE object:nil
                        userInfo:@{PEX_EXTRA_APPSTATE_CHANGE : appStateChange,
                                PEX_EXTRA_APPSTATE_APP: application}];

    // Log termination event. Watch how often app gets killed.
    [PEXReport logEvent:PEX_EVENT_APP_TERMINATED];

    DDLogVerbose(@"Cleaning up parser");
    xmlCleanupParser();
}

- (void)onLowMemoryWarning:(UIApplication *)application {
    // The logging is separated to two calls on purpose. There may not be enough memory for generating the memory report.
    DDLogError(@"%@: %@. Application has received low memory warning", THIS_FILE, THIS_METHOD);

    // Get current memory report.
    NSInteger memUsed = 0;
    NSInteger memVirtual = 0;

    NSString * report = [PEXUtils getFreeMemoryReport:&memVirtual resident:&memUsed suspend:NULL];
    DDLogError(@"Low memory warning, memory report: %@; MB used: %ld. #KeepAlives: %ld, LogginTime: %@",
            report, (long) memUsed/1024/1024, (long)_numKeepAlives, _appLoggedInTime);

    _numMemoryWarnings += 1;
    _lastTakenMemoryOnWarning = memUsed;
    _lastMemoryWarning = [NSDate date];

    // TODO: implement memory watchdog here. If consumption is too big, e.g., > 300 MB, assert the app.
    // ...

    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_LOW_MEMORY object:nil
                        userInfo:@{PEX_EXTRA_LOW_MEMORY : @{}}];

    // Log low memory event.
    [PEXReport logEvent:PEX_EVENT_MEMORY_WARNING];
}

- (NSString *) getServiceReport {
    NSString const * memReport = [PEXUtils getFreeMemoryReport:NULL resident:NULL suspend:NULL];
    NSString const * sysMemReport = [PEXUtils getSystemFreeMemoryReport:NULL memUsed:NULL memTotal:NULL];
    NSArray const * lsofArray = [PEXUtils lsof];
    NSString const * lsofReport = [lsofArray componentsJoinedByString:@"\n\n"];
    NSDate * appLoggedInTime = _appLoggedInTime;
    NSDate * lastKeepAlive = _lastKeepAlive;
    NSDate * lastMemoryWarning = _lastMemoryWarning;
    NSString * toReturn = [NSString stringWithFormat:@"Last login: %@, %@"
                                              "\n#keepAlives: %ld,"
                                              "\nlastKeepAlive: %@, %@"
                                              "\n\n#foregroundSwitches: %ld, "
                                              "\n#backgroundSwitches: %ld, "
                                              "\nratiofTb: %.4f,"
                                              "\n\n"
                                              "#keepAliveConnON: %ld,"
                                              "\n#keepAliveConnOff: %ld, "
                                              "\nONratio: %.4f"
                                              "\n\n#lowMemWarn: %ld, "
                                              "\nlastMemWarn: %@, %@"
                                              "\nlastWarnMemUsed: %ld (%.2f MB), "
                                              "\nResident memory avg: %.4f MB"
                                              "\n\nMemory report: %@"
                                              "\n\nSystem Memory report: %@"
                                              "\n\nlsof[%lu]: \n%@\n",
                    appLoggedInTime, [PEXUtils dateDiffFromNowFormatted:appLoggedInTime compact:YES],
                    (long)_numKeepAlives,
                    lastKeepAlive, [PEXUtils dateDiffFromNowFormatted:lastKeepAlive compact:YES],
                    (long)_numForegroundSwitches,
                    (long)_numBackgroundSwitches,
                    _numBackgroundSwitches == 0 ? -1.0 : (double)_numForegroundSwitches / (double)_numBackgroundSwitches,
                    (long)_keepAliveConnectivityOn,
                    (long)_keepAliveConnectivityOff,
                    _keepAliveConnectivityOn == 0 ? -1.0 : (double)(_keepAliveConnectivityOn+_keepAliveConnectivityOff) / (double) _keepAliveConnectivityOn,
                    (long)_numMemoryWarnings,
                    lastMemoryWarning, [PEXUtils dateDiffFromNowFormatted:lastMemoryWarning compact:YES],
                    (long)_lastTakenMemoryOnWarning,
                    _lastTakenMemoryOnWarning/1024.0/1024.0,
                    [_residentMemoryAvg current]/1024.0/1024.0,
                    memReport,
                    sysMemReport,
                    (long unsigned)[lsofArray count],
                    lsofReport];

    return toReturn;
}

- (void)installExceptionHandler {
    @try {
        NSUncaughtExceptionHandler *curHandler = NSGetUncaughtExceptionHandler();
        if (curHandler == uncaughtExceptionHandler) {
            DDLogVerbose(@"Current uncaught exception handler is set to ours.");
            return;
        }

        // Store current handler pointer to the static variable - so we have it for chaining.
        prevExceptionHandler = curHandler;

        // Set our exception handler.
        NSSetUncaughtExceptionHandler(uncaughtExceptionHandler);
        DDLogVerbose(@"Uncaught exception handler modified, current: %p, original: %p", uncaughtExceptionHandler, curHandler);

    } @catch(NSException * e){
        DDLogError(@"Exception in setting exception handler %@", e);
    }
}

+(void) uncaughtException: (NSException *) e fromUncaughtHandler: (BOOL) fromHandler{
    @try {
        DDLogError(@"Uncaught exception[handler=%d]: %@, reason: %@", fromHandler, e, e.reason);
        [DDLog flushLog];

        // Exception stack.
        DDLogError(@"Exception: %@, Exception stack: %@", e, e.callStackSymbols);
        if (lastReportedException == e){
            DDLogVerbose(@"Exception already reported.");
            return;
        }

        // Report.
        [PEXReport logError:@"UE" message:@"UE" exception:e];
        lastReportedException = e;

    }@catch(NSException * e){
        DDLogError(@"Exception in backtrace: %@", e);
    }@finally {
        [DDLog flushLog];
    }
}
@end

static void uncaughtExceptionHandler(NSException * e){
    // Report it via service handler.
    [PEXService uncaughtException:e fromUncaughtHandler:YES];

    // Call original one.
    if (prevExceptionHandler != NULL && e != NULL){
        // This code is perfectly OK and well tested.
        // Do not panic when Xcode / AppCode stops you here with signal / exception / breakpoint.
        // It is a normal condition since we are in the uncaught exception handler and
        // passing control to the previously installed exception handler.
        // Once the execution flow reaches default exception handler it signalizes to
        // the IDE uncaught exception, often in a form of a breakpoint on the line below (last application code line
        // where exception popped out).
        //
        // Passing exception to the default exception handler is desired behavior, we want application to crash
        // on uncaught exception, it was properly logged by now and it is the time for application to exit
        // as it may be in highly inconsistent state.
        prevExceptionHandler(e);
    }
}