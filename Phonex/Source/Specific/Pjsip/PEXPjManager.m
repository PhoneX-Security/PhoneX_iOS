//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCall.h>
#import "PEXPjManager.h"
#import "PEXUserPrivate.h"
#import "PEXPjConfig.h"
#import "PEXUtils.h"
#import "PEXPjUtils.h"
#import "PEXMessageDispatcher.h"
#import "PEXSipUri.h"
#import "PEXPjHelper.h"
#import "PEXSystemUtils.h"
#import "PEXPjSign.h"
#import "PEXPjZrtp.h"
#import "pjsua-lib/pjsua_internal.h"
#import "PEXPjZrtpTransport.h"
#import "PEXPjRingback.h"
#import "idn-int.h"
#import "PEXResSounds.h"
#import "PEXService.h"
#import "PEXFirewall.h"
#import "PEXPjZrtpStateInfo.h"
#import "PEXConcurrentHashMap.h"
#import "PEXPjCall.h"
#import "PEXPjManager+PjCall.h"
#import "PEXPjCallCallbacks.h"
#import "PEXPjManager+Threads.h"
#import "PEXPjRegStatus.h"
#import "PEXPresenceCenter.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXGuiCallManager.h"
#import "PEXDbCallLog.h"
#import "PEXDbAppContentProvider.h"
#import "PEXConnectivityChange.h"
#import "PEXPjExecutor.h"
#import "PEXPhonexSettings.h"
#import "PEXPjToneBusy.h"
#import "PEXPjToneError.h"
#import "PEXApplicationStateChange.h"
#import "PEXDBUserProfile.h"
#import "PEXAmpDispatcher.h"
#import "PEXReport.h"
#import "PEXMovingAverage.h"
#import "PEXStopwatch.h"
#import "pjsip/sip_transport.h"
#import "PEXPjToneBye.h"
#import "PEXPjToneZrtpOk.h"
#import "PEXPjMsgSendAux.h"
#import "PEXPjConfigPrefs.h"
#import "PEXBackGroundTask.h"

NSString *PEX_ACTION_SIP_REGISTRATION = @"net.phonex.phonex.sip.action.registration";
NSString *PEX_EXTRA_SIP_REGISTRATION = @"net.phonex.phonex.sip.extra.registration";

NSString * const PEXPjManagerErrorDomain = @"PEXPjManagerErrorDomain";
NSInteger const PEXPjStartFailed = 1;
NSInteger const PEXPjSubCreateFailed = 1;
NSInteger const PEXPjSubInitFailed = 2;
NSInteger const PEXPjSubStartFailed = 3;
NSInteger const PEXPjSubAccAddFailed = 4;

// Watchdog settings.
// Exponential moving average smoothing factor. - window of size 75 samples ish.
static const double PEX_PJERROR_WEIGHT = 0.015;
// Threshold for triggering PJSIP restart by watchdog for exponential moving average. Ratio of fails.
static const double PEX_PJERROR_THRESHOLD = 0.60;
// Threshold for triggering PJSIP restart by watchdog for number of consecutive errors in the given time slot.
static const NSInteger PEX_PJERROR_CNT_THRESHOLD = 5;
// Threshold for triggering PJSIP restart by watchdog for number of total errors from the last stack start.
static const NSInteger PEX_PJERROR_TOTAL_CNT_THRESHOLD = 30;
// Size of the consecutive error time window for triggering PJSIP restart by watchdog.
static const NSTimeInterval PEX_PJERROR_TIME_THRESHOLD = 30.0;
// Number of seconds to block PJSIP restarts by watchdog after PJSIP was started.
static const NSTimeInterval PEX_PJERROR_TIME_START_THRESHOLD = 60.0;
// Exponential moving average smoothing factor for registration errors.
static const double PEX_PJ_SET_REG_ERROR_WEIGHT = 0.015;

struct pjsua_player_eof_data{
    pj_pool_t          *pool;
    pjsua_player_id player_id;
};

static pj_status_t on_pjsua_wav_file_end_callback(pjmedia_port* media_port, void* args);

#define ME PEXPjManager
@interface PEXPjManager () {}
@property(nonatomic) PEXConcurrentHashMap * callRegister;
@property(nonatomic) PEXConcurrentHashMap * callDelegates;
@property(nonatomic) dispatch_queue_t pjQueue;
@property(nonatomic) BOOL registered;
@end

@implementation PEXPjManager {
    pjsua_acc_id _acc_id;
    PEXPjRingback * _ringTone;
    PEXPjToneBusy * _busyTone;
    PEXPjToneError * _errorTone;
    PEXPjToneBye * _byeTone;
    PEXPjToneZrtpOk * _zrtpOkTone;
    PEXPjRegStatus * _regStatus;
    NSTimer *_regWatchTimer;
    NSTimeInterval _regWatchTimerLastDelay;
    NSTimeInterval _regWatchTimerSet;
    PEXBackGroundTask * _unregisterBgTask;

    // Registration transport.
    pjsip_transport *_regTransport;
    NSLock          *_regTransportLock;
    // Registration transport that is being shutted down.
    pjsip_transport *_regTransportShuttingDown;

    // Executor.
    PEXPjExecutor * _executor;

    // Sound level & mute state
    float _soundLevelMic;
    float _soundLevelOut;
    volatile BOOL _micMuted;
    volatile BOOL _loudSpeakerActive;
    volatile BOOL _handsfreeActive;
    volatile BOOL _handsfreeEnableOnCall;
    volatile BOOL _audioSetToAmbient;

    // Watchdog
    NSDate * _stackStartedTime;
    int _lstErrorCode;
    NSDate * _lstErrorTime;
    NSDate * _fstErrorTime;
    NSInteger _numErrors;
    NSInteger _numErrorsTotal;
    NSInteger _numStackRestarts;
    PEXMovingAverage * _ewmaErrorRate;

    // Registration fail counters.
    NSInteger _numSetRegErrorsConsecutive;
    NSInteger _numSetRegErrorsTotal;
    NSInteger _numSetRegOKsTotal;
    PEXMovingAverage * _ewmaSetRegErrorRate;
    NSDate * _lstSetRegError;
    NSDate * _lstSetRegSuccess;
    NSDate * _lstRegSuccess;
    NSDate * _lstRegFailed;
    NSDate * _lstRegStarted;
    NSDate * _lstRegTpFail;
    NSInteger _numRegStarted;
    NSInteger _numRegOKsTotal;
    NSInteger _numRegNOKsTotal;
    NSInteger _numRegTpFail;
    PEXMovingAverage * _bgConnectionStability;
    PEXMovingAverage * _unregisteredPeriodsAvg;
    PEXMovingAverage * _unregisteredAttemptsAvg;
    PEXMovingAverage * _unregisteredDueExpirationAvg;
    PEXStopwatch * _lstUnregisteredPeriodSw;
    NSTimeInterval _lstUnregisteredPeriod;
    NSTimeInterval _lstRegistrationExpiration;
    NSTimeInterval _lstUnregisteredExpiration;
    NSInteger _lstUnregisteredAttempts;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.created = NO;
        self.callRegister = [[PEXConcurrentHashMap alloc] initWithQueueName:@"pjcalls"];
        self.callDelegates = [[PEXConcurrentHashMap alloc] initWithQueueName:@"pjdeleg"];
        self.pjQueue = dispatch_queue_create("pjQueue", DISPATCH_QUEUE_SERIAL);
        self.registered = NO;
        _pjThreads = [[NSMutableDictionary alloc] initWithCapacity:4];
        _regTransportLock = [[NSLock alloc] init];
        _unregisterBgTask = [[PEXBackGroundTask alloc] initWithName:@"unregisterBgTask"];
        _numStackRestarts = 0;
        _ewmaErrorRate = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJERROR_WEIGHT current:0.0 valMax:@(1.0) valMin:@(0.0)];
        _ewmaSetRegErrorRate = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJ_SET_REG_ERROR_WEIGHT current:0.0 valMax:@(1.0) valMin:@(0.0)];
        _bgConnectionStability = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJ_SET_REG_ERROR_WEIGHT current:1.0 valMax:@(1.0) valMin:@(0.0)];
        _unregisteredPeriodsAvg = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJ_SET_REG_ERROR_WEIGHT current:0.0];
        _unregisteredAttemptsAvg = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJ_SET_REG_ERROR_WEIGHT current:0.0];
        _unregisteredDueExpirationAvg = [PEXMovingAverage averageWithSmoothingFactor:PEX_PJ_SET_REG_ERROR_WEIGHT current:0.0];
        _lstUnregisteredPeriodSw = nil;
        [self resetState];
    }

    return self;
}

-(void) resetState {
    _acc_id = PJSUA_INVALID_ID;
    _regStatus = [[PEXPjRegStatus alloc] init];
    _soundLevelMic = 1.0;
    _soundLevelOut = 1.0;
    _micMuted = FALSE;
    _loudSpeakerActive = FALSE;
    _handsfreeActive = FALSE;
    _handsfreeEnableOnCall = FALSE;
    _audioSetToAmbient = YES;
    _regWatchTimer = nil;
    _regWatchTimerLastDelay = 0;
    _regWatchTimerSet = 0;
    _ringTone = nil;
    _busyTone = nil;
    _errorTone = nil;
    _byeTone = nil;
    _zrtpOkTone = nil;

    _stackStartedTime = nil;
    _lstErrorCode = PJ_SUCCESS;
    _lstErrorTime = nil;
    _fstErrorTime = nil;
    _numErrors = 0;
    _numErrorsTotal = 0;
    _ewmaErrorRate.current = 0.0;

    _numSetRegErrorsConsecutive = 0;
    _numSetRegErrorsTotal = 0;
    _numSetRegOKsTotal = 0;
    _ewmaSetRegErrorRate.current = 0.0;
    _numRegOKsTotal = 0;
    _numRegStarted = 0;
    _numRegNOKsTotal = 0;

    _lstSetRegError = nil;
    _lstSetRegSuccess = nil;
    _lstRegSuccess = nil;
    _lstRegStarted = nil;
    _lstRegFailed = nil;
    _bgConnectionStability.current = 1.0;
    _unregisteredPeriodsAvg.current = 0.0;
    _unregisteredAttemptsAvg.current = 0.0;
    _unregisteredDueExpirationAvg.current = 0.0;
    _lstUnregisteredPeriodSw = nil;
    _lstUnregisteredPeriod = -1.0;
    _lstRegistrationExpiration = -1.0;
    _lstUnregisteredExpiration = 0.0;
    _lstUnregisteredAttempts = 0;
    _lstRegTpFail = nil;
    _numRegTpFail = 0;

    [_regTransportLock lock];
    _regTransport = NULL;
    _regTransportShuttingDown = NULL;
    [_regTransportLock unlock];
}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [self init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

+ (PEXPjManager *)instance {
    static PEXPjManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

+ (void)pjLogWrapper:(int)level data:(const char *)data len:(int)len {
    const char delims[] = "\n";
    if (data == NULL || len < 0){
        DDLogError(@"Invalid logging call: %p, len: %d", data, len);
        return;
    }

    char* cpy = strndup(data, (size_t)len);
    char *line = strtok(cpy, delims);
    while(line != NULL){
        if (level <= 0){
            DDLogError(@"A: %s", line);
        } else if (level == 1) {
            DDLogError(@"%s", line);
        } else if (level == 2) {
            DDLogWarn(@"%s", line);
        } else if (level == 3) {
            DDLogInfo(@"%s", line);
        } else if (level == 4) {
            DDLogDebug(@"%s", line);
        } else if (level >= 5) {
            DDLogVerbose(@"%s", line);
        }
        line = strtok(NULL, delims);
    }
    free(cpy);
}

+ (void) logPjError: (NSString *) sender title: (NSString *) title status: (pj_status_t) status{
    pjsua_perror([sender cStringUsingEncoding:NSUTF8StringEncoding], [title cStringUsingEncoding:NSUTF8StringEncoding], status);
}

- (void)updatePrivData:(PEXUserPrivate *)privData {
    self.privData = privData;

    PEXPjSign * signMod = [PEXPjSign instance];
    signMod.privData = privData;
}

- (void) pjExecName: (NSString *) name async:(BOOL) async block: (dispatch_block_t) block {
    // Check if we have worker.
    if (_executor == nil){
        _executor = [[PEXPjExecutor alloc] init];
    }

    if (![_executor isRunning]){
        [_executor startExecutor:self.pjQueue];
    }

    __weak __typeof(self) weakSelf = self;
    //[PEXUtils executeOnQueue:self.pjQueue async:async block:^{ @autoreleasepool {

    // Now we use custom thread-fixed serial executor.
    [_executor addJobAsync:async name:name block:^{ @autoreleasepool {
        PEXPjManager * mgr = weakSelf;
        DDLogVerbose(@"<pjexec_%@>", name);
        [mgr registerCurrentThreadIfNotRegistered];
        block();
        DDLogVerbose(@"</pjexec_%@>", name);
    }}];
}

- (int)startStack: (NSError **) pError {
    __block pj_status_t status = EFAULT;

    [self pjExecName:@"startStack" async:NO block:^{
        status = [self startStackInternal:pError];
    }];

    return status;
}

- (int)startStackInternal: (NSError **) pError {
    pj_status_t status = EFAULT;

    // Create pjsua first
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        [ME logPjError:THIS_FILE title:@"Cannot create a new pjsua" status:status];
        [PEXUtils setError:pError domain:PEXPjManagerErrorDomain code:PEXPjStartFailed subCode:PEXPjSubCreateFailed];
        [self errorDestroy];
        return status;
    }

    // Create a new configurator object.
    self.configuration = [[PEXPjConfig alloc] initWithPrivData:self.privData];

    // Init pjsua
    {
        // Init the config structure
        [self.configuration configureAll];

        // Init the pjsua
        status = pjsua_init([self.configuration getPjsuaConfig], [self.configuration getLoggingConfig], [self.configuration getMediaConfig]);
        if (status != PJ_SUCCESS) {
            [ME logPjError:THIS_FILE title:@"Cannot init pjsua" status:status];
            [PEXUtils setError:pError domain:PEXPjManagerErrorDomain code:PEXPjStartFailed subCode:PEXPjSubInitFailed];
            [self errorDestroy];
            return status;
        }

        // Init ringback tone.
        _ringTone = [PEXPjRingback ringbackWithConfig:self.configuration];
        [_ringTone tone_init];

        _busyTone = [PEXPjToneBusy toneWithConfig:self.configuration];
        [_busyTone tone_init];

        _errorTone = [PEXPjToneError toneWithConfig:self.configuration];
        [_errorTone tone_init];

        _byeTone = [PEXPjToneBye toneWithConfig:self.configuration];
        [_byeTone tone_init];

        _zrtpOkTone = [PEXPjToneZrtpOk toneWithConfig:self.configuration];
        [_zrtpOkTone tone_init];
    }

    // Add transports.
    [self.configuration configureTransports];

    // Initializing ZRTP library.
    PEXPjZrtp * zrtp = [PEXPjZrtp instance];
    zrtp.configuration = self.configuration;
    zrtp.delegate = self;

    // Adding PJSIP modules.
    // Add signature module.
    PEXPjSign * signMod = [PEXPjSign instance];
    signMod.privData = self.privData;
    [signMod doRegister];

    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        [ME logPjError:THIS_FILE title:@"Cannot start pjsua" status:status];
        [PEXUtils setError:pError domain:PEXPjManagerErrorDomain code:PEXPjStartFailed subCode:PEXPjSubStartFailed];
        [self errorDestroy];
        return status;
    }

    // Register the account on local sip server
    pjsua_acc_config accCfg;
    [self.configuration configureAccount:&accCfg withPrivData:self.privData error:nil];

    DDLogVerbose(@"Adding PJ account");
    status = pjsua_acc_add(&accCfg, PJ_TRUE, &_acc_id);
    if (status != PJ_SUCCESS) {
        [ME logPjError:THIS_FILE title:@"Error adding account" status:status];
        [PEXUtils setError:pError domain:PEXPjManagerErrorDomain code:PEXPjStartFailed subCode:PEXPjSubAccAddFailed];
        [self errorDestroy];
        return status;
    }

    // TODO: add codecs.
    // TODO: add entropy.
    self.created = YES;
    _stackStartedTime = [NSDate date];
    status = PJ_SUCCESS;

    NSString * curThreadKey = [PEXSystemUtils getCurrentThreadKey];
    DDLogInfo(@"SIP stack started, stack id=%d, thread started=%@", _acc_id, curThreadKey);

    // Set resolver retry counts based on whether connectivity is on or not.
    [self setResolverDelayInternal:[[PEXService instance] isConnectivityWorking]];

    return status;
}

// ZRTP and other media dispatcher
-(pjmedia_transport*) on_transport_created: (pjsua_call_id) call_id media_idx: (unsigned) media_idx
                                   base_tp: (pjmedia_transport *) base_tp flags: (unsigned) flags {
    pj_status_t status = PJ_SUCCESS;
    pjsua_call_info call_info;
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    // By default, use default global def
    pj_bool_t use_zrtp = TRUE;
    status = pjsua_call_get_info(call_id, &call_info);
    if(status == PJ_SUCCESS && pjsua_acc_is_valid (call_info.acc_id)){
        ;
    }

    if(use_zrtp){
        DDLogInfo(@"Dispatch transport creation on ZRTP one");
        return [[PEXPjZrtp instance] on_zrtp_transport_created:call_id media_idx:media_idx base_tp:base_tp flags:flags];
    }

    return base_tp;
}

- (void)on_transport_srtp_created:(pjsua_call_id)call_id media_idx:(unsigned)media_idx settings:(pjmedia_srtp_setting *)settings {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

-(void) errorDestroy {
    DDLogVerbose(@"Going to destroy stack - error condition.");
    [self pjExecName:@"errorDestroy" async:NO block:^{
        pjsua_destroy();
    }];
}

-(void) cleanDestroy{
    [self pjExecName:@"cleanDestroy" async:NO block:^{
        [self cleanDestroyInternal];
    }];
}

-(void) cleanDestroyInternal {
    if (!self.created){
        DDLogWarn(@"Nothing to destroy");
        return;
    }

    // This will destroy all accounts so synchronize with accounts
    // management lock
    // long flags = 1; /*< Lazy disconnect : only RX */
    // Try with TX & RX if network is considered as available
    PEXService * svc = [PEXService instance];
    unsigned int flags = 0;
    if ([svc isConnectivityWorking] && ![svc isInBackground]) {
        // If we are current not valid for outgoing,
        // it means that we don't want the network for SIP now
        // so don't use RX | TX to not consume data at all
        DDLogVerbose(@"Flag=3");
        flags = 3;
    }

    // hangup all existing calls.
    pjsua_call_hangup_all();
    DDLogVerbose(@"Shutting down SIP stack.");

    // Unregister modules.
    // Unregister signature module.
    PEXPjSign * signMod = [PEXPjSign instance];
    [signMod doUnregister];

    // Shutdown pjstack
    DDLogVerbose(@"<stack_destroy>");

    // Destroy ringback.
    [_ringTone tone_destroy];
    [_busyTone tone_destroy];
    [_errorTone tone_destroy];
    [_byeTone tone_destroy];
    [_zrtpOkTone tone_destroy];

#if PJMEDIA_HAS_VIDEO
	unsigned i;
	for (i = 0; i < css_var.extra_vid_codecs_cnt; i++) {
		dynamic_factory *codec = &css_var.extra_vid_codecs_destroy[i];
		pj_status_t (*destroy_factory)() = get_library_factory(codec);
		if(destroy_factory != NULL){
			pj_status_t status = destroy_factory();
			if(status != PJ_SUCCESS) {
				PJ_LOG(2, (THIS_FILE,"Error loading dynamic codec plugin"));
			}
    	}
	}
#endif

    // Destroy stack.
    pj_status_t destroyStatus = pjsua_destroy2(flags);

    NSString * curThreadKey = [PEXSystemUtils getCurrentThreadKey];
    DDLogVerbose(@"</stack_destroy thread_id=%@ status=%d>", curThreadKey, destroyStatus);

    // Pool is released for us. Reset it for future use.
    [self.configuration resetPool];
    [self freeThreads];
    // Stop worker thread.
    [_executor stopExecutor];
    _executor = nil;
    [self resetState];

    // Set current state appropriately.
    self.created = NO;
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

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        DDLogDebug(@"PJ manager registered");
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

        DDLogDebug(@"PJ manager unregistered");
        self.registered = NO;
    }
}

- (BOOL)isStackTurnedOff {
    __block pjsua_state sipState;
    [self pjExecName:@"isStackTurnedOff" async:NO block:^{
        sipState = pjsua_get_state();
    }];

    return sipState == PJSUA_STATE_CLOSING || sipState == PJSUA_STATE_NULL;
}

/**
* Transform a string callee into a valid sip uri in the context of an
* account
*
* @param callee    the callee string to call
* @param accountId the context account
* @return ToCall object representing what to call and using which account
*/
-(PEXToCall *) sanitizeSipUri: (NSString *) callee accountId: (NSNumber *) accountId {
    NSString * canonCallee = [PEXSipUri getCanonicalSipContact:callee includeScheme:YES];

    // Able to send only if account is available for call
    // Check integrity of callee field
    PEXSIPURIParsedSipContact * finalCallee = [PEXSipUri parseSipContact:canonCallee];
    if ([PEXUtils isEmpty:finalCallee.scheme]) {
        finalCallee.scheme = @"sips";
    }

    NSString * threadKey = [PEXSystemUtils getCurrentThreadKey];
    DDLogDebug(@"callee [%@], thread=%@", finalCallee, threadKey);
    NSString * finalCalleeString = [finalCallee toStringWithBoolean:NO];

    // URI stack check.
    char const * urlCstring = [finalCalleeString cStringUsingEncoding:NSUTF8StringEncoding];
    if (pjsua_verify_sip_url(urlCstring) != 0){
        DDLogWarn(@"SIP uri verification failed");
        return nil;
    }

    // Available?
    if (!pjsua_acc_is_valid(_acc_id)){
        DDLogWarn(@"Account is not valid: %d", _acc_id);
        return nil;
    }

    // TODO: check current registration state. Registration state is needed.

    PEXToCall * toCall = [PEXToCall callWithPjsipAccountId:@(_acc_id) callee:canonCallee];
    return toCall;
}

// ---------------------------------------------
#pragma mark - Watchdog & reporting
// ---------------------------------------------

/**
 * Called when set_registration() call finishes.
 * Collects statistics about manual registration success for further debugging.
 */
-(void) onSetRegistrationFinished: (pj_status_t) status {
    const BOOL isLockIndication = status == PJSIP_EBUSY;
    const BOOL isFailed = status != PJ_SUCCESS;
    if (isLockIndication || isFailed){
        _numSetRegErrorsConsecutive += 1;
        _numSetRegErrorsTotal += 1;
        _lstSetRegError = [NSDate date];
    }

    // Success.
    if (!isFailed){
        _numSetRegErrorsConsecutive = 0;
        _numSetRegOKsTotal += 1;
        _lstSetRegSuccess = [NSDate date];
    }

    // Moving average.
    [_ewmaSetRegErrorRate update:isFailed ? 1.0 : 0.0];
    DDLogVerbose(@"regwatcher; set_registration(). status: %d, report: %@", status, [self regWatcherReport]);
}

/**
 * Called when registration transaction finishes.
 * Collects registration success statistics for further debugging.
 */
-(void) onRegistrationFinished: (pjsua_acc_id)acc_id info:(pjsua_reg_info *)info registered: (BOOL) registered {
    if (info == NULL || info->cbparam == NULL){
        return;
    }

    const BOOL success = info->cbparam->code / 100 == 2;
    if (registered){
        _numRegOKsTotal += 1;
        _lstRegSuccess = [NSDate date];
    } else {
        _numRegNOKsTotal += 1;
        _lstRegFailed = [NSDate date];
    }

    DDLogVerbose(@"regwatcher; reg_finished. code: %d, registered: %d, report: %@", (int) info->cbparam->code, registered, [self regWatcherReport]);
}

/**
 * Generates a string report from registration watcher.
 */
-(NSString *) regWatcherReport{
    return [self regWatcherReportForUI];
}

/**
 * Generates a string report from registration watcher for GUI logging.
 */
-(NSString *) regWatcherReportForUI{
    NSString * report = nil;
    @try {
        NSDate *regWatchdogFire = [NSDate dateWithTimeIntervalSince1970:_regWatchTimerSet + _regWatchTimerLastDelay];

        // Manually retain those dates. Fixing IPH-466 - sending message to deallocated instance.
        NSDate *lstSetRegError = _lstSetRegError;
        NSDate *lstSetRegSuccess = _lstSetRegSuccess;
        NSDate *lstRegSuccess = _lstRegSuccess;
        NSDate *lstRegFailed = _lstRegFailed;
        NSDate *lstRegStarted = _lstRegStarted;
        NSDate *lstRegTpFail = _lstRegTpFail;
        PEXPjRegStatus * regStatus = _regStatus;

        report = [NSString stringWithFormat:@"setRegErrConCnt: %ld,"
                                                  "\nsetRegErrTotalCnt: %ld,"
                                                  "\nlastSetRegError: %@, %@,"
                                                  "\nlastSetRegSuccess: %@, %@,"
                                                  "\nlastRegSuccess: %@, %@,"
                                                  "\nlastRegFailed: %@, %@,"
                                                  "\nlastRegStarted: %@, %@,"
                                                  "\nsetRegOKTotalCnt: %ld,"
                                                  "\nsetRegErrorRate: %f,"
                                                  "\nregSuccessCnt: %ld,"
                                                  "\nregFailCnt: %ld,"
                                                  "\nRegTimSched: %@, %@,"
                                                  "\nlastUnregPeriod: %lf, %@"
                                                  "\nunregPeriodAvg: %lf, %@"
                                                  "\nunregAttempts: %ld, avg: %.3f,"
                                                  "\nlastExpired: %.3f, %@,"
                                                  "\nregExpiredAvg: %.3f, %@,"
                                                  "\nlstRegTpFail: %@, %@,"
                                                  "\nnumRegTpFail: %ld"
                                                  "\nbgRegStabilityRate: %lf"
                                                  "\n\nlastRegStatus: %@"
                                                  "\n\nPjConfig: %@",
                                          (long) _numSetRegErrorsConsecutive,
                                          (long) _numSetRegErrorsTotal,
                                          lstSetRegError, [PEXUtils dateDiffFromNowFormatted:lstSetRegError compact:YES],
                                          lstSetRegSuccess, [PEXUtils dateDiffFromNowFormatted:lstSetRegSuccess compact:YES],
                                          lstRegSuccess, [PEXUtils dateDiffFromNowFormatted:lstRegSuccess compact:YES],
                                          lstRegFailed, [PEXUtils dateDiffFromNowFormatted:lstRegFailed compact:YES],
                                          lstRegStarted, [PEXUtils dateDiffFromNowFormatted:lstRegStarted compact:YES],
                                          (long) _numSetRegOKsTotal,
                                          _ewmaSetRegErrorRate == nil ? 0 : _ewmaSetRegErrorRate.current,
                                          (long) _numRegOKsTotal,
                                          (long) _numRegNOKsTotal,
                                          regWatchdogFire, [PEXUtils dateDiffFromNowFormatted:regWatchdogFire compact:YES],
                                          _lstUnregisteredPeriod, [PEXUtils timeIntervalFormatted:_lstUnregisteredPeriod compact:YES],
                                          _unregisteredPeriodsAvg == nil ? 0 : _unregisteredPeriodsAvg.current,
                                          _unregisteredPeriodsAvg == nil ? @"" : [PEXUtils timeIntervalFormatted:_unregisteredPeriodsAvg.current compact:YES],
                                          (long) _lstUnregisteredAttempts,
                                          _unregisteredAttemptsAvg == nil ? 0 : _unregisteredAttemptsAvg.current,
                                          _lstUnregisteredExpiration, [PEXUtils timeIntervalFormatted:_lstUnregisteredExpiration compact:YES],
                                          _unregisteredDueExpirationAvg == nil ? 0 : _unregisteredDueExpirationAvg.current,
                                          [PEXUtils timeIntervalFormatted:_unregisteredDueExpirationAvg.current compact:YES],
                                          lstRegTpFail, [PEXUtils dateDiffFromNowFormatted:lstRegTpFail compact:YES],
                                          (long) _numRegTpFail,
                                          _bgConnectionStability == nil ? 0 : _bgConnectionStability.current,
                                          regStatus == nil || regStatus.lastStatusText == nil ? @"-" : regStatus.lastStatusText,
                                          [[PEXPjConfigPrefs prefsFromSettings] description]];
    } @catch(NSException * e){
        DDLogError(@"Exception in log report generation %@", e);
    }

    return report;
}

/**
 * Generates stack watchdog report.
 */
-(NSString *) watchdogReport {
    NSDate * stackStartedTime = _stackStartedTime;
    NSDate * fstErrorTime = _fstErrorTime;
    NSDate * lstErrorTime = _lstErrorTime;
    NSString * report = [NSString stringWithFormat:@"Moving average: %f. Stack started since %@, "
            "#err: %ld, #errTotal: %ld, fstError: %@, lstError: %@, #restarts: %ld",
                    _ewmaErrorRate == nil ? 0 : _ewmaErrorRate.current,
                    stackStartedTime, (long int)_numErrors, (long int)_numErrorsTotal,
            fstErrorTime, lstErrorTime, (long int) _numStackRestarts];

    return report;
}

-(void) watchdogStatus: (int) status {
    // For now we assume only pipe broken error.
    const BOOL isRestartError = status == PJ_ERRNO_START_SYS + 32;
    // Moving average computation on error distribution.
    [_ewmaErrorRate update:isRestartError ? 1.0 : 0.0];
    if (!isRestartError){
        // No error, clear consecutive error logging
        _numErrors = 0;
        _lstErrorCode = status;
        _lstErrorTime = nil;
        _fstErrorTime = nil;
        return;
    }

    if (_fstErrorTime == nil){
        _fstErrorTime = [NSDate date];
    }

    _lstErrorTime = [NSDate date];
    _lstErrorCode = status;
    _numErrors += 1;
    _numErrorsTotal += 1;

    DDLogError(@"Error with code: %d, moving average: %f. Stack started since %@, "
            "#err: %ld, #errTotal: %ld, fstError: %@, lstError: %@, #restarts: %ld",
            status, _ewmaErrorRate.current, _stackStartedTime, (long int)_numErrors, (long int)_numErrorsTotal,
            _fstErrorTime, _lstErrorTime, (long int) _numStackRestarts);

    // Do not trigger restart if previous start was only several seconds ago.
    if (_stackStartedTime != nil){
        const NSTimeInterval deltaStart = [[NSDate date] timeIntervalSince1970] - [_stackStartedTime timeIntervalSince1970];
        if (deltaStart <= PEX_PJERROR_TIME_START_THRESHOLD){
            DDLogInfo(@"Not going to restart stack, since it was restarted quite recently: %f", deltaStart);
            return;
        }
    }

    // Watchdog trigger settings
    if (_ewmaErrorRate.current >= PEX_PJERROR_THRESHOLD){
        DDLogError(@"Watchdog triggered with EWMA threshold: %f", _ewmaErrorRate.current);
        [self watchdogTrigger];
        return;
    }

    // Trigger error with # of errors > threshold and affected time period > threshold.
    const NSTimeInterval delta = [_lstErrorTime timeIntervalSince1970] - [_fstErrorTime timeIntervalSince1970];
    if (delta >= PEX_PJERROR_TIME_THRESHOLD && _numErrors >= PEX_PJERROR_CNT_THRESHOLD){
        DDLogError(@"Watchdog trigerred by time delta %f and numErrors %ld", delta, (long int) _numErrors);
        [self watchdogTrigger];
        return;
    }

    // Trigger watchdog if number of total error is high
    if (_numErrorsTotal >= PEX_PJERROR_TOTAL_CNT_THRESHOLD){
        DDLogError(@"Watchdog triggered with total error threshold: %ld", (long int) _numErrorsTotal);
        [self watchdogTrigger];
        return;
    }
}

-(void) watchdogTrigger {
    [PEXService executeWithName:@"pjWatchdogRestart" async:YES block:^{
        NSError * error = nil;
        [PEXReport logEvent:PEX_EVENT_SIP_RESTART];

        // Do only if service is logged in.
        if (![[PEXService instance] userLoggedIn]){
            DDLogError(@"PJSIP watchdog disabled - user is not logged in");
            return;
        }

        DDLogInfo(@"Going to stop PJSIP by watchdog");
        [self cleanDestroy];

        DDLogInfo(@"Going to start PJSIP by watchdog");
        const int startResult = [self startStack:&error];
        if (startResult != PJ_SUCCESS) {
            DDLogError(@"Could not start PJSIP stack, error: %d, #restarts: %ld, running since: %@",
                    startResult, (long int) _numStackRestarts, _stackStartedTime);

            [DDLog flushLog];
            [PEXReport logEvent:PEX_EVENT_SIP_RESTART_FAILED code:@(startResult)];

            assert(startResult == PJ_SUCCESS && "Could not start SIP stack");
        }

        _numStackRestarts += 1;
        DDLogInfo(@"PJSIP restarted successfully by watchdog, #restarts: %ld", (long int) _numStackRestarts);
    }];
}

// ---------------------------------------------
#pragma mark - API to the application
// ---------------------------------------------

/**
* Send message using SIP server.
*/
- (PEXToCall *)sendMessage:(NSString *)callee
                   message:(NSString *)message
                 accountId:(NSNumber *)accountId
                      mime:(NSString *)mime
                 msgTypeId:(PEXPjMsgSendAux *)msgTypeId
                    status:(int *)pStatus
                     error:(NSError **)pError
{
    __block PEXToCall * toCall = nil;

    [self pjExecName:@"sendMessage" async:NO block:^{
        toCall = [self sendMessageInternal:callee
                                   message:message
                                 accountId:accountId
                                      mime:mime
                                 msgTypeId:msgTypeId
                                    status:pStatus
                                     error:pError];
    }];

    return toCall;
}

- (PEXToCall *)sendMessageInternal:(NSString *)callee
                           message:(NSString *)message
                         accountId:(NSNumber *)accountId
                              mime:(NSString *)mime
                         msgTypeId:(PEXPjMsgSendAux *)msgTypeId
                            status:(int *)pStatus
                             error:(NSError **)pError
{
    PEXToCall *toCall = [self sanitizeSipUri:callee accountId:accountId];
    if (toCall != nil) {
        pj_str_t pjmime = {0,0};
        pj_str_t uri = {0,0};
        pj_str_t text = {0,0};
        pjsua_msg_data * p_msg_data = NULL;
        pjsua_msg_data msg_data;
        pjsip_generic_string_hdr msg_type_hdr;

        [PEXPjUtils assignToPjString:mime pjstr:&pjmime];
        [PEXPjUtils assignToPjString:toCall.callee pjstr:&uri];
        [PEXPjUtils assignToPjString:message pjstr:&text];

        // New header - message type.
        // If we terminate a call due to GSM unavailability, add a special header.
        if (msgTypeId != nil) {
            char hVal[64];
            p_msg_data = &msg_data;
            pjsua_msg_data_init(p_msg_data);

            NSString * codeString = [NSString stringWithFormat:@"%@;%@",
                            msgTypeId.msgType == nil ? @(-1) : msgTypeId.msgType,
                            msgTypeId.msgSubType == nil ? @(-1) : msgTypeId.msgSubType
            ];

            const char * cCodeString = [codeString cStringUsingEncoding:NSUTF8StringEncoding];
            strncpy(hVal, cCodeString, 63);

            pj_str_t hname = pj_str(PEX_HEADER_MESSAGE_TYPE);
            pj_str_t hvalue = pj_str(hVal);

            /* Add warning header */
            pjsip_generic_string_hdr_init2(&msg_type_hdr, &hname, &hvalue);
            pj_list_push_back(&msg_data.hdr_list, &msg_type_hdr);
        }

        int status = pjsua_im_send([toCall.pjsipAccountId integerValue], &uri, &pjmime, &text, p_msg_data, NULL);
        if (pStatus != NULL) {
            *pStatus = status;
        }

        [self watchdogStatus:status];
        return (status == PJ_SUCCESS) ? toCall : nil;
    }

    return toCall;
}

/**
* Is call using a secure RTP method (SRTP/ZRTP)
*/
-(NSString *) call_secure_media_info: (pjsua_call_id) call_id {
    pjsua_call *call;
    pj_status_t status;
    unsigned i;
    pjmedia_transport_info tp_info;

    if (!(call_id>=0 && call_id<(int)pjsua_var.ua_cfg.max_calls)){
        DDLogError(@"Invalid call id! [%d]", call_id);
        return nil;
    }

    NSMutableString * result = [[NSMutableString alloc] init];
    PJSUA_LOCK();

    if (pjsua_call_has_media(call_id)) {
        call = &pjsua_var.calls[call_id];
        for (i = 0; i < call->med_cnt; ++i) {
            pjsua_call_media *call_med = &call->media[i];
            DDLogDebug(@"Get secure for media type %d", call_med->type);
            if (call_med->tp && call_med->type != PJMEDIA_TYPE_AUDIO) {
                continue;
            }

            pjmedia_transport_info_init(&tp_info);
            pjmedia_transport_get_info(call_med->tp, &tp_info);
            if (tp_info.specific_info_cnt <= 0) {
                continue;
            }

            unsigned j;
            for (j = 0; j < tp_info.specific_info_cnt; ++j) {
                if (tp_info.spc_info[j].type == PJMEDIA_TRANSPORT_TYPE_SRTP) {
                    pjmedia_srtp_info *srtp_info = (pjmedia_srtp_info*) tp_info.spc_info[j].buffer;
                    if (srtp_info->active) {
                        [result appendString:@"SRTP"];
                        break;
                    }
                }

                else if (tp_info.spc_info[j].type == PJMEDIA_TRANSPORT_TYPE_ZRTP) {
                    PEXPjZrtp * zrtp = [PEXPjZrtp instance];
                    PEXPjZrtpStateInfo * info = [zrtp getInfoFromTransport:call_med->tp];
                    if(info.secure){
                        char zrtphash[64] = {0};
                        DDLogVerbose(@"ZRTP :: V %d", info.sas_verified);
                        DDLogVerbose(@"ZRTP :: S L %@", info.sas);
                        DDLogVerbose(@"ZRTP :: C L %@", info.cipher);
                        DDLogVerbose(@"ZRTP :: hashMatch %d", info.zrtp_hash_match);

                        if (info.zrtp_hash_match == 1){
                            [result appendString:@"OK"];
                        } else {
                            [result appendFormat:@"Error %d", info.zrtp_hash_match];
                        }

                        [result appendFormat:@"ZRTP - %s\n%@\n%@\nzrtp-hash: %s",
                                info.sas_verified ? "Verified" : "Not verified",
                                info.sas,
                                info.cipher,
                                zrtphash];
                        break;
                    }
                }
            }
        }
    }

    PJSUA_UNLOCK();
    return [NSString stringWithString:result];
}

- (pj_status_t) makeCallTo:(NSString *)destUri {
    return [self makeCallTo:destUri callId:NULL];
}

- (pj_status_t)makeCallTo:(NSString *)destUri callId:(pjsua_call_id *)callId {
    __block pj_status_t status = !PJ_SUCCESS;

    [self pjExecName:@"makeCallTo" async:NO block:^{
        status = [self makeCallInternalTo:destUri callId:callId];
    }];

    return status;
}

- (pj_status_t)makeCallInternalTo:(NSString *)destUri callId:(pjsua_call_id *)callId {
    pj_status_t status = 0;
    pj_str_t uri;

    [PEXReport logUsrEvent:PEX_EVENT_CALLED_SOMEONE];
    NSString * toCallUri = [NSString stringWithFormat:@"sips:%@", [PEXSipUri getCanonicalSipContact:destUri includeScheme:NO]];
    PEXToCall * toCall = [self sanitizeSipUri:toCallUri accountId:nil];
    if (toCall != nil) {
        pjsua_call_id callId2 = PJSUA_INVALID_ID;
        [PEXPjUtils assignToPjString:toCall.callee pjstr:&uri];

        // IPH-257: Reset mute status of the call & loudspeaker status to disabled to switch back to default state.
        [self resetAudioInternal:YES];

        // Default bluetooth setting
        _handsfreeEnableOnCall = [self isHandsfreeDefault];

        status = pjsua_call_make_call(_acc_id, &uri, 0, NULL, NULL, &callId2);
        [self watchdogStatus:status];

        if (status != PJ_SUCCESS) {
            DDLogError(@"Cannot make a new call, result code=%d", status);
        } else {
            if (callId != NULL){
                *callId = callId2;
            }
            DDLogVerbose(@"New call created. CallId=%d", callId2);

            // Refresh call state information.
            [self updateCallInfoFromStack:callId2 event:NULL updateCode:@(PEX_CALL_UPDATE_MAKE_CALL)];
        }
    }

    return status;
}

- (void)endCall {
    [self pjExecName:@"endCall" async:YES block:^{
        pjsua_call_hangup_all();
    }];
}

-(pj_status_t) endCallWithId: (pjsua_call_id) callId {
    [self endCallWithId:callId async:YES];
    return PJ_SUCCESS;
}

-(pj_status_t) endCallWithId: (pjsua_call_id) callId async: (BOOL) async {
    return [self endCallWithId:callId async:async code:0];
}

-(pj_status_t) endCallWithId: (pjsua_call_id) callId async: (BOOL) async code: (unsigned) code {
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:[NSString stringWithFormat:@"endCallWithId_%d", callId] async:YES block:^{
        pj_status_t status2 = [self endCallInternalWithId:callId async:async code:code];
        if(!async){
            status = status2;
        }
    }];

    return status;
}

-(pj_status_t) endCallInternalWithId: (pjsua_call_id) callId async: (BOOL) async code: (unsigned) code {
    pj_status_t status2 = PJ_EINVAL;
    pjsua_msg_data * p_msg_data = NULL;
    pjsua_msg_data msg_data;
    pjsip_generic_string_hdr bye_cause;

    // Get current call state.
    PEXPjCall * callInfo = [self getCallInfo:callId];
    if (callInfo != nil){
        // If was already ahng up, null or disconnected, ignore with error.
        if (callInfo.hangupCalled){
            DDLogError(@"Call already hangup, curState: %@", callInfo.callState);
            return PJ_EINVAL;
        }
    }

    // End call disconnects audio, if hangup takes too long, user assumes no
    // sound is not connected after hangup was called.
    [self disconnectSoundInternal:callId callInfo:callInfo.confPort];

    // If we terminate a call due to GSM unavailability, add a special header.
    if (code != 0) {
        char hVal[64];
        p_msg_data = &msg_data;
        pjsua_msg_data_init(p_msg_data);

        NSString * codeString = [NSString stringWithFormat:@"%d", code];
        const char * cCodeString = [codeString cStringUsingEncoding:NSUTF8StringEncoding];
        strncpy(hVal, cCodeString, 63);

        pj_str_t hname = pj_str(PEX_HEADER_BYE_TERMINATION);
        pj_str_t hvalue = pj_str(hVal);

        /* Add warning header */
        pjsip_generic_string_hdr_init2(&bye_cause, &hname, &hvalue);
        pj_list_push_back(&msg_data.hdr_list, &bye_cause);
    }

    status2 = pjsua_call_hangup(callId, code, NULL, p_msg_data);
    [self watchdogStatus:status2];

    [self setCallHangup:callId localByeCode:@(code)];
    return status2;
}

-(pj_status_t) terminateCallInternalWithId:  (pjsua_call_id) callId {
    // Get current call state.
    PEXPjCall * callInfo = [self getCallInfo:callId];
    if (callInfo != nil){
        // If was already ahng up, null or disconnected, ignore with error.
        if (callInfo.hangupCalled &&
                ([callInfo hasCallState:PJSIP_INV_STATE_DISCONNECTED] || [callInfo hasCallState:PJSIP_INV_STATE_NULL]))
        {
            DDLogError(@"Call already disconnected, curState: %@", callInfo.callState);
            return PJ_EINVAL;
        }
    }

    return pjsua_call_terminate(callId, 0);
}

-(pj_status_t) terminateCallWithId: (pjsua_call_id) callId async: (BOOL) async completionBlock: (pj_completion_block) completionBlock {
    __block pj_status_t status = PJ_SUCCESS;
    [self pjExecName:[NSString stringWithFormat:@"terminate_call_%d", callId] async:async block:^{
        pj_status_t statusInternal = [self terminateCallInternalWithId:callId];
        if (completionBlock != nil){
            completionBlock(statusInternal);
        }

        if (!async){
            status = statusInternal;
        }
    }];

    // Warning, if async, return value is not affected.
    return status;
}

-(pj_status_t) answerCall: (pjsua_call_id) callId {
    return [self answerCall:callId code:200 async:NO completionBlock:nil];
}

-(pj_status_t) answerCall: (pjsua_call_id) callId code: (NSUInteger) code {
    [PEXReport logUsrEvent: (code == 200) ? PEX_EVENT_CALL_ANSWERED : PEX_EVENT_CALL_REJECTED];
    return [self answerCall:callId code:code async:NO completionBlock:nil];
}

-(pj_status_t) answerCall: (pjsua_call_id) callId code: (NSUInteger) code async: (BOOL) async completionBlock: (pj_completion_block) completionBlock {
    __block pj_status_t status = PJ_SUCCESS;
    [self pjExecName:[NSString stringWithFormat:@"answer_call_%d_code_%d", callId, (int)code] async:async block:^{
        pj_status_t statusInternal = [self answerCallInternal:callId code:code];
        if (completionBlock != nil){
            completionBlock(statusInternal);
        }

        if (!async){
            status = statusInternal;
        }
    }];

    // Warning, if async, return value is not affected.
    return status;
}

-(pj_status_t) answerCallInternal: (pjsua_call_id) callId code: (NSUInteger) code {
    // Get current call state.
    PEXPjCall * callInfo = [self getCallInfo:callId];
    if (callInfo != nil){
        // If call is already connected, null or disconnected, ignore with error.
        if (callInfo.answerCalled
            || [callInfo hasCallState:PJSIP_INV_STATE_DISCONNECTED]
            || [callInfo hasCallState:PJSIP_INV_STATE_NULL]
            || [callInfo hasCallState:PJSIP_INV_STATE_CONFIRMED])
        {
            DDLogError(@"Call already answered, curState: %@", callInfo.callState);
            return PJ_EINVAL;
        }
    }

    pj_status_t status = pjsua_call_answer(callId, (unsigned int)code, NULL, NULL);
    [self setCallAnswered:callId];
    return status;
}

-(void) sasVerified: (pjsua_call_id) call_id async: (BOOL) async {
    [self pjExecName:@"sasVerified" async:async block:^{
        PEXPjZrtp * zrtp = [PEXPjZrtp instance];
        [zrtp sasVerified:call_id];
    }];
}

-(void) sasRevoked: (pjsua_call_id) call_id async: (BOOL) async {
    [self pjExecName:@"sasRevoked" async:async block:^{
        PEXPjZrtp * zrtp = [PEXPjZrtp instance];
        [zrtp sasRevoked:call_id];
    }];
}

// ---------------------------------------------
#pragma mark - App listeners
// ---------------------------------------------

/**
* Receive local user presence changes in order to broadcast new presence state.
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

    // DNS resolver settings, if connectivity is down, set retry count to 1.
    // Optimizes battery usage if stack is obsessed by resolving DNS even if network is down.
    if (conChange.connection == PEX_CONN_GOES_UP){
        [self setResolverDelay:YES];

        // Connectivity is ON, start measuring unregistered period (valid, SIP stack could not register when
        // network was unreachable).
        if (_lstUnregisteredPeriodSw != nil){
            [_lstUnregisteredPeriodSw resume];
        }

    } else if (conChange.connection == PEX_CONN_GOES_DOWN){
        [self setResolverDelay:NO];

        // Network is unreachable, pause unregistered period stopwatch as SIP stack is not able to register.
        if (_lstUnregisteredPeriodSw != nil){
            [_lstUnregisteredPeriodSw pause];
        }
    }

    // IP changed?
    if (conChange.connection == PEX_CONN_GOES_UP || conChange.recheckIPChange){
        DDLogInfo(@"Connection goes up, IP change update.");
        [self ipChange];
    }
}

- (void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    UIApplication * application = notification.userInfo[PEX_EXTRA_APPSTATE_APP];
    if (change == nil || application == nil){
        DDLogError(@"Illegal notification state");
        return;
    }

    // On to background transition - VoIP backgrounding is disabled from iOS 10 thus unregister
    // after transition to background to close server socket - messages are not sent to UAC until
    // registration expires, its stored on the server as offline message instead.
    if (change.stateChange == PEX_APPSTATE_DID_ENTER_BACKGROUND){
        [self unregisterBgTaskStartAllowCall:NO];
    }

    // On foreground enter re-register again to reset all potential backoffs.
    // Perform only if there is currently no incoming / ongoing call. This creates error 488.
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        DDLogVerbose(@"Did become active - reregister if not calling");
        [self resetRegistrationBackoff:YES];
        [self reregister:YES allowDuringCall:NO];
    }
}

- (void)onSettingsUpdate:(NSDictionary *)settings privData:(PEXUserPrivate *)privData {
    if (settings == nil || settings[@"pjsip"] == nil){
        return;
    }

    WEAKSELF;
    NSDictionary * pjset = settings[@"pjsip"];
    [self pjExecName:@"pjsipSettings" async:YES block:^{
        const BOOL changed = [self.configuration updateConfigFromServer:pjset privData:privData];
        if (!changed) {
            return;
        }

        DDLogVerbose(@"PJconfiguration has changed, modify account");
        if (_created && pjsua_acc_is_valid(_acc_id)) {
            DDLogVerbose(@"Settings change on running stack, reload settings.");

            pjsua_acc_config accCfg;
            [weakSelf.configuration configureAccount:&accCfg withPrivData:privData error:nil];

            pj_status_t modifyStatus = pjsua_acc_modify(_acc_id, &accCfg);
            DDLogVerbose(@"Settings modification done with result: %d", modifyStatus);
        }
    }];
}

- (void)onCellularCall:(CTCall *)call numActiveCalls:(int)numOfActive {
    // We would like to have ON-HOLD logic here as IPH-414 says, but
    // re-establishing call from ON-HOLD situation is quite complicated as no audio passes through
    // and propably a new ZRTP would be needed. For this both sides need to support it, probably, even android.
    //
    // For now we use dedicated PJSIP Error code for this.
    WEAKSELF;
    [self pjExecName:@"onCelularCall" async:YES block:^{
        NSArray * activeCalls = [weakSelf getActiveCalls];
        if (numOfActive == 0 || activeCalls == nil || [activeCalls count] == 0){
            return;
        }

        // Active GSM call, hangup all calls.
        for(PEXPjCall * pjCall in activeCalls){
            DDLogVerbose(@"Disconnecting call: %d", pjCall.callId);
            [weakSelf endCallWithId:pjCall.callId async:YES code:PJSIP_SC_GSM_BUSY];
        }

        // IPH-414 code:
//        // On hold.
//        if (numOfActive <= 0){
//            // Num of active = 0 -> is there something on hold? If yes, show notification to user.
//            for(PEXPjCall * pjCall in activeCalls){
//                if (pjCall.onHoldStatus == nil){
//                    DDLogVerbose(@"Call not on hold: %d", pjCall.callId);
//                    continue;
//                }
//
//                DDLogVerbose(@"Reinviting on hold: %d", pjCall.callId);
//                pj_status_t reinviteStatus = pjsua_call_reinvite(pjCall.callId, PJSUA_CALL_UNHOLD | PJSUA_CALL_UPDATE_CONTACT, NULL);
//                DDLogVerbose(@"Reinviting call on hold: %d, status: %d", pjCall.callId, reinviteStatus);
//                if (reinviteStatus == PJ_SUCCESS){
//                    PEXPjCall * callInfo = [self updateCallInfoHoldStatus:pjCall.callId holdStatus:nil];
//                    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_UN_HOLD callInfo:callInfo event:NULL];
//                }
//            }
//
//        } else {
//            // Active GSM call, set voip on hold.
//            for(PEXPjCall * pjCall in activeCalls){
//                DDLogVerbose(@"Putting call on hold: %d", pjCall.callId);
//                pj_status_t holdStatus = pjsua_call_set_hold2(pjCall.callId, 0, NULL);
//                DDLogVerbose(@"Putting call on hold: %d, status: %d", pjCall.callId, holdStatus);
//                if (holdStatus == PJ_SUCCESS){
//                    PEXPjCall * callInfo = [self updateCallInfoHoldStatus:pjCall.callId holdStatus:@(1)];
//                    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_ON_HOLD callInfo:callInfo event:NULL];
//                }
//            }
//        }
    }];
}

// ---------------------------------------------
#pragma mark - Keep-alive & connectivity
// ---------------------------------------------

- (void)keepAlive {
    [self keepAlive:YES completionBlock:nil];
}

- (void)keepAlive: (BOOL) async {
    [self keepAlive:async completionBlock:nil];
}

- (void)keepAlive: (BOOL) async completionBlock: (pj_completion_block) completionBlock {
    PEXService *svc = [PEXService instance];
    const BOOL inBack = [svc isInBackground];
    const BOOL connWorks = [svc isConnectivityWorking];
    DDLogVerbose(@"Keep-alive re-registration, async: %d, in background: %d, connectivityWorking: %d,"
            "stackStartedSince: %@", async, inBack, connWorks, _stackStartedTime);

    // Background connectivity check.
    if (connWorks) {
        [_bgConnectionStability update:_regStatus.registered ? 1.0 : 0.0];
    }

    // If in background (wakeups limits) and no connectivity -> do nothing.
    if (inBack && !connWorks){

        // Fire completion block in different thread - not to deadlock.
        if (completionBlock != nil) {
            [self pjExecName:@"noop" async:async block:^{
                if (completionBlock != nil) {
                    completionBlock(PJ_EIGNORED);
                }
            }];
        }

        DDLogVerbose(@"No action taken, connectivity is off");
        return;
    }

    // Do nothing if there is no connectivity...
    [self reregister:YES allowDuringCall:YES completionBlock:completionBlock];
}

-(pj_status_t) shutdownRegTransport {
    pj_status_t status = PJ_SUCCESS;

    [_regTransportLock lock];
    if (_regTransport != NULL) {
        DDLogVerbose(@"ip: Shutting down transport: %p", _regTransport);
        _regTransportShuttingDown = _regTransport;
        status = pjsip_transport_shutdown(_regTransport);
        if (status != PJ_SUCCESS) {
            DDLogError(@"pjsip_transport_shutdown() error");
        }

        DDLogVerbose(@"ip: Decrementing reference counter for transport: %p", _regTransport);
        pjsip_transport_dec_ref(_regTransport);
        _regTransport = NULL;
    }
    [_regTransportLock unlock];

    return status;
}

-(NSUInteger) getNumOfCalls {
    __block NSUInteger numCalls = 0;
    [self pjExecName:@"numCalls" async:NO block:^{
        numCalls = [self getNumOfCallsInternal];
    }];

    return numCalls;
}

-(NSUInteger) getNumOfCallsInternal {
    return pjsua_call_get_count();
}

- (BOOL)updateDNS {
    [self pjExecName:@"updateDNS" async:YES block:^{
        [self updateDNSInternal];
    }];
    return YES;
}

- (BOOL)setResolverDelay: (unsigned) delay retryCount: (unsigned) retryCount {
    [self pjExecName:@"updateResolver" async:YES block:^{
        [self setResolverDelayInternal:delay retryCount:retryCount];
    }];
    return YES;
}

- (BOOL)setResolverDelay: (BOOL) isConnectivityOn {
    [self pjExecName:@"updateResolver" async:YES block:^{
        [self setResolverDelayInternal:isConnectivityOn];
    }];
    return YES;
}

- (BOOL) updateDNSInternal {
    NSArray * dnsList = [PEXUtils getDNS:YES wantIpv6:YES];
    const unsigned dnsCnt = [dnsList count];
    if (dnsList == nil || dnsCnt == 0){
        DDLogError(@"DNS list is empty");
        return NO;
    }

    // Create a new temporary pool so we do not spoil general configuration pool
    // on each reconnection.
    pj_pool_t * pool = pjsua_pool_create("dns_servers", 72, 64);
    if (pool == NULL){
        DDLogError(@"Memory pool could not be obtained");
        return NO;
    }

    pj_status_t status = PJ_SUCCESS;
    {
        pj_str_t nameservers[4];
        unsigned nsCount = dnsCnt >= 4 ? 4u : dnsCnt;
        for (unsigned i = 0; i < dnsCnt && i < 4; i++) {
            NSString *curDns = dnsList[i];
            DDLogVerbose(@"Adding DNS server: %@, %u/%u", curDns, i, dnsCnt);
            pj_strdup2_with_null(pool, &nameservers[i], [curDns cStringUsingEncoding:NSUTF8StringEncoding]);
        }

        status = pjsua_reconfigure_dns(nsCount, nameservers);
        DDLogVerbose(@"DNS reconfiguration status: %d, nsCount: %u", status, nsCount);
    }

    pj_pool_release(pool);
    return status == PJ_SUCCESS;
}

- (pj_status_t) setResolverDelayInternal: (unsigned) delay retryCount: (unsigned) retryCount {
    DDLogVerbose(@"DNS reconfiguration delay: %u, retrycount: %u", delay, retryCount);
    pj_status_t status = pjsua_reconfigure_resolver(delay, retryCount);
    DDLogVerbose(@"DNS reconfiguration status: %d", status);

    return status;
}

- (pj_status_t) setResolverDelayInternal: (BOOL) connectivityIsOn {
    // Set resolver retry counts based on whether connectivity is on or not.
    if (connectivityIsOn){
        return [self setResolverDelayInternal:PJ_DNS_RESOLVER_QUERY_RETRANSMIT_DELAY retryCount:5];
    } else {
        return [self setResolverDelayInternal:250 retryCount:0];
    }
}

// ---------------------------------------------
#pragma mark - Registration
// ---------------------------------------------

-(void) ipChange{
    [self pjExecName:@"ipChange" async:YES block:^{
        [self ipChangeInternal];
    }];
}

-(void) ipChangeInternal {
    pj_status_t status;
    DDLogDebug(@"IP change");
    // Source: https://trac.pjsip.org/repos/wiki/IPAddressChange#iphone

    // DNS update.
    [self updateDNSInternal];

    if (_regTransport) {
        DDLogVerbose(@"Called to shutdown reg transport: %p", _regTransport);
        status = [self shutdownRegTransport];
    }

    DDLogDebug(@"Un-registration started");
    pjsua_acc_reset_reg_attempts(_acc_id);
    status = pjsua_acc_set_registration(_acc_id, PJ_FALSE);
    [self onSetRegistrationFinished:status];

    if (status != PJ_SUCCESS) {
        DDLogError(@"pjsua_acc_set_registration(0) error, %d, report: %@", status, [self regWatcherReport]);
        [PEXReport logEvent:PEX_EVENT_SIP_REGISTRATION_FAILED code:@(status)];

        // Probably not registered, try to re-register.
        [self reregister];
    } else {
        _regStatus.ipReregistrationInProgress = YES;
    }
}

-(void) reregister {
    [self reregister:YES];
}

-(void) reregister: (BOOL) async{
    [self reregister:async allowDuringCall:YES completionBlock:nil];
}

-(void)reregister:(BOOL)async allowDuringCall: (BOOL) allowCall{
    [self reregister:async allowDuringCall:allowCall completionBlock:nil];
}

- (void)reregister:(BOOL)async allowDuringCall:(BOOL)allowCall manual:(BOOL)manual {
    [self pjExecName:@"reregister-manual" async:async block:^{
        // Check if we have several consecutive set error count too high.
        if (manual && _numSetRegErrorsConsecutive > 15) {
            DDLogVerbose(@"Number of consecutive error counts for set register is over threshold, restarting stack");
            [self watchdogTrigger];

        } else {
            // Error count is acceptable low, default reregister.
            [self reregisterInternalAllowCall:allowCall];
        }
    }];
}

-(void)reregister:(BOOL)async allowDuringCall: (BOOL) allowCall completionBlock: (pj_completion_block) completionBlock{
    [self pjExecName:@"reregister" async:async block:^{
        pj_status_t status = [self reregisterInternalAllowCall: allowCall];
        if (completionBlock != nil) {
            completionBlock(status);
        }
    }];
}

-(void)unregister:(BOOL)async allowDuringCall: (BOOL) allowCall completionBlock: (pj_completion_block) completionBlock{
    [self pjExecName:@"unregister" async:async block:^{
        pj_status_t status = [self unregisterInternalAllowCall: allowCall];
        if (completionBlock != nil) {
            completionBlock(status);
        }
    }];
}

-(void) resetRegistrationBackoff:(BOOL) async {
    [self pjExecName:@"registerBackoffReset" async:async block:^{
        pjsua_acc_reset_reg_attempts(_acc_id);
    }];
}

-(pj_status_t) reregisterInternalAllowCall: (BOOL)allowDuringCall {
    return [self reregisterInternalAllowCall:allowDuringCall renew:YES];
}

-(pj_status_t) unregisterInternalAllowCall: (BOOL)allowDuringCall {
    return [self reregisterInternalAllowCall:allowDuringCall renew:NO];
}

-(pj_status_t) reregisterInternalAllowCall: (BOOL)allowDuringCall renew: (BOOL) renew {
    if (!self.created){
        DDLogError(@"Cannot reregister, not created");
        return PJ_EINVAL;
    }

    // Check for call in progress / incoming.
    if (!allowDuringCall){
        const NSUInteger callCnt = [self getNumOfCallsInternal];
        if (callCnt > 0){
            DDLogVerbose(@"Current number of calls: %u, cannot re-register", (unsigned int) callCnt);
            return PJ_SUCCESS;
        }
    }

    DDLogDebug(@"<set_registration>");
    pj_status_t status = pjsua_acc_set_registration(_acc_id, renew ? PJ_TRUE : PJ_FALSE);
    [self onSetRegistrationFinished:status];
    [self watchdogStatus:status];

    if (status != PJ_SUCCESS) {
        DDLogError(@"pjsua_acc_set_registration() error, %d, report: %@", status, [self regWatcherReport]);
        [PEXReport logEvent:PEX_EVENT_SIP_REGISTRATION_FAILED code:@(status)];
    }
    DDLogDebug(@"</set_registration>");

    return status;
}

/**
 * Starts SIP un-registration in the background task.
 * @param allowDuringCall
 */
- (void) unregisterBgTaskStartAllowCall: (BOOL) allowDuringCall {
    [_unregisterBgTask start];
    [self unregister:YES allowDuringCall:allowDuringCall completionBlock:^(pj_status_t status) {
        [_unregisterBgTask stop];
    }];
}

- (void)onRegistrationChange {
    DDLogVerbose(@"New registration state (will broadcast presence): %@", _regStatus);

    if ([PEXUtils isEmpty: self.privData.username]){
        DDLogError(@"Empty user name in priv data %p", self.privData.username);
    }

    PEXPresenceUpdateMsg * msg = [PEXPresenceUpdateMsg msgWithUser:self.privData.username];
    msg.sipRegistered = @(_regStatus.registered);

    // Send presence update message for given user to the presence center.
    PEXPresenceCenter * pc = [PEXPresenceCenter instance];
    [pc updatePresenceForLogged:msg];

    // Broadcast registration change to the notification center.
    NSNotificationCenter * notifs = [NSNotificationCenter defaultCenter];
    [notifs postNotificationName:PEX_ACTION_SIP_REGISTRATION object:nil userInfo:@{ PEX_EXTRA_SIP_REGISTRATION : [_regStatus copy] }];
}

-(void) onRegistrationWatchTimerFired:(NSTimer *)timer {
    NSTimeInterval drift = [[NSDate date] timeIntervalSince1970] - _regWatchTimerSet - _regWatchTimerLastDelay;
    DDLogDebug(@"Registration watch timer fired. %@, origDelay: %f, fire drift: %f", timer, _regWatchTimerLastDelay, drift);
    PEXService * svc = [PEXService instance];
    BOOL inBack = [svc isInBackground];
    BOOL connWork = [svc isConnectivityWorking];

    // In background mode && connectivity working -> re-register.
    if (inBack && connWork){
        DDLogVerbose(@"Registration timer fired in background -> re-register.");
        [self reregister:YES];
    }

    // Check if registration is gone.
    @synchronized (_regStatus) {
        if (_regStatus.registered && _regStatus.created != nil && _regStatus.expire > 0){
            // Check registration time.
            NSDate * dateOfExpiration = [NSDate dateWithTimeInterval:_regStatus.expire+5 sinceDate:_regStatus.created];

            // If date of expiration is after current date, everything is OK.
            if ([[NSDate date] compare:dateOfExpiration] == NSOrderedAscending){
                DDLogVerbose(@"Registration is valid now. Expiration=%@", dateOfExpiration);
                return;
            }
        }

        // If we are here, registration expired.
        _regStatus.registered = NO;
    }

    // Broadcast message with lost registration.
    [self pjExecName:@"on_reg_timer" async:YES block:^{
        [self onRegistrationChange];
    }];
}

// ---------------------------------------------
#pragma mark - Audio logic
// ---------------------------------------------

- (void) connectSound: (pjsua_call_id)call_id state: (int) state conf_slot: (int) conf_slot{
    if (state == PJSUA_CALL_MEDIA_ACTIVE || state == PJSUA_CALL_MEDIA_REMOTE_HOLD) {
        DDLogVerbose(@"Going to register a sound..., conf_slot=%d", conf_slot);
        // When media is active, connect call to sound device.
        pjsua_conf_connect(conf_slot, 0);
        pjsua_conf_connect(0, conf_slot);
        DDLogInfo(@"Connected audio slots, media active, slot=%d", conf_slot);

        // Conference calls - act as a mixer.
        // Connect new incoming call to other calls.
        if ([PEXPhonexSettings supportMultipleCalls] && [PEXPhonexSettings multipleCallsMixingAllowed]) {
            NSArray *activeCalls = [self getActiveCallsBesidesCallId:call_id];
            for (PEXPjCall *call in activeCalls) {
                pjsua_conf_connect(call.confPort, conf_slot);
                pjsua_conf_connect(conf_slot, call.confPort);
                DDLogInfo(@"Conference connected. Slot=%d", call.confPort);
            }
        }

    } else {
        DDLogWarn(@"Sound cannot be connected, state is not valid: %d", state);
    }
}

- (void) disconnectSound:(pjsua_call_id)call_id callInfo: (pjsua_conf_port_id) port{
    [self pjExecName:@"disconnect_sound" async:YES block:^{
        [self disconnectSoundInternal:call_id callInfo:port];
    }];
}

- (void) disconnectSoundInternal:(pjsua_call_id)call_id callInfo: (pjsua_conf_port_id) port{
    pjsua_conf_port_info pInfo;
    if (port < 0){
        DDLogWarn(@"Conference port is invalid: %d", port);
        return;
    }

    pj_status_t status = pjsua_conf_get_port_info(port, &pInfo);
    if (status != PJ_SUCCESS){
        DDLogInfo(@"Cannot get port [%d] info, no disconnect", port);
        return;
    }

    status = pjsua_conf_get_port_info(0, &pInfo);
    if (status != PJ_SUCCESS){
        DDLogInfo(@"Cannot get port [0] info, no disconnect");
        return;
    }

    pjsua_conf_disconnect(0, port);
    pjsua_conf_disconnect(port, 0);
    DDLogInfo(@"Sound was disconnected");
}

-(void) silenceSound: (pjsua_call_id)call_id callInfo: (pjsua_call_info *) ci {
    [self pjExecName:@"silence_sound" async:YES block:^{
        [self silenceSoundInternal:call_id callInfo:ci];
    }];
}

-(void) silenceSoundInternal: (pjsua_call_id)call_id callInfo: (pjsua_call_info *) ci {
    pjsua_conf_port_info pInfo;
    pj_status_t status = pjsua_conf_get_port_info(0, &pInfo);
    if (status != PJ_SUCCESS){
        DDLogWarn(@"Cannot silence, no port 0");
        return;
    }

    pjsua_conf_adjust_rx_level(0, 0);
    pjsua_conf_adjust_tx_level(0, 0);

    status = pjsua_conf_get_port_info(ci->conf_slot, &pInfo);
    if (status != PJ_SUCCESS){
        DDLogWarn(@"Cannot silence, no port %d", ci->conf_slot);
        return;
    }

    pjsua_conf_adjust_rx_level(ci->conf_slot, 0);
    pjsua_conf_adjust_tx_level(ci->conf_slot, 0);
}

-(pj_status_t) switchAudioRoutingToLoud: (BOOL) toLoudSpeaker async: (BOOL) async onFinished:(pj_completion_block) onFinished {
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:@"audio_route_switch" async:async block:^{
        pj_status_t status2 = [self switchAudioRoutingToLoudInternal:toLoudSpeaker];
        if (!async){
            status = status2;
        }
        if (onFinished){
            onFinished(status2);
        }
    }];

    return status;
}

-(pj_status_t) switchAudioRoutingToLoudInternal: (BOOL) toLoudSpeaker {
    pj_status_t status = !PJ_SUCCESS;
    NSError *error = nil;
    @try {
        _loudSpeakerActive = toLoudSpeaker;

        BOOL success;
        AVAudioSession *session = [AVAudioSession sharedInstance];

        // Source: http://stackoverflow.com/questions/24369008/ios-pjsip-2-2-loud-speaker-switch-fails
        AVAudioSessionPortOverride override = _loudSpeakerActive ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
        success = [session overrideOutputAudioPort:override error:&error];
        status = success ? PJ_SUCCESS : !PJ_SUCCESS;
    } @catch(NSException * e){
        status = !PJ_SUCCESS;
    }

    if (status != PJ_SUCCESS) {
        DDLogError(@"Error enabling loudspeaker, status=%d, error=%@", status, error);
    }

    return status;
}

-(pj_status_t) switchBluetooth: (BOOL) bluetoothEnabled async: (BOOL) async onFinished:(pj_completion_block) onFinished{
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:@"audio_bluetooth" async:async block:^{
        pj_status_t status2 = [self switchBluetoothInternal:bluetoothEnabled];
        if (!async){
            status = status2;
        }

        if (onFinished){
            onFinished(status2);
        }
    }];

    return status;
}

-(pj_status_t) switchBluetoothInternal: (BOOL) enableBluetooth {
    pj_status_t status = !PJ_SUCCESS;
    NSError * err = nil;
    BOOL success;

    // If already set to ambient, set bluetooth switch position on the audio start.
    if (_audioSetToAmbient){
        DDLogVerbose(@"Bluetooth set: in ambient, setting post switch: %d", enableBluetooth);
        _handsfreeEnableOnCall = enableBluetooth;
        return PJ_SUCCESS;
    }

    // If already in the position
    if (enableBluetooth == _handsfreeActive){
        DDLogVerbose(@"Bluetooth already set to desired value: %d", enableBluetooth);
        return EALREADY;
    }

    @try {
        AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers;
        if (enableBluetooth){
            options |= AVAudioSessionCategoryOptionAllowBluetooth;
        }

        AVAudioSession *session = [AVAudioSession sharedInstance];
        success = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:&err];
        if (success){
            _handsfreeActive = enableBluetooth;
            status = success ? PJ_SUCCESS : !PJ_SUCCESS;
        }

        // Setting bluetooth to ON disables loudspeaker
        if (success && enableBluetooth){
            if ([session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil]){
                _loudSpeakerActive = NO;
            }
        }

    } @catch(NSException *e){
        DDLogError(@"Exception in changing audio category: %@", e);
    }

    status = success ? PJ_SUCCESS : !PJ_SUCCESS;
    if (!success){
        DDLogError(@"Cannot set audio category, error=%@", err);

    } else {
        DDLogInfo(@"Audio category set to AVAudioSessionCategoryPlayAndRecord, bluetooth: %d", enableBluetooth);
    }

    return status;
}

-(pj_status_t) muteMicrophone: (BOOL) mute async: (BOOL) async onFinished:(pj_completion_block) onFinished {
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:@"mute_mic" async:async block:^{
        pj_status_t status2 = [self muteMicrophoneInternal: mute];
        if (!async){
            status = status2;
        }
        if (onFinished){
            onFinished(status2);
        }
    }];

    return status;
}

- (BOOL) micMuted { return _micMuted; }
- (BOOL) loudSpeakerActive { return _loudSpeakerActive; }
- (BOOL) handsfreeActive { return _handsfreeActive; }

-(pj_status_t) muteMicrophoneInternal: (BOOL) mute {
    pj_status_t status = !PJ_SUCCESS;
    @try {
        _micMuted = mute;
        status = [self adjustRxTxInternal];

    } @catch(NSException * e){
        status = !PJ_SUCCESS;
    }

    if (status != PJ_SUCCESS) {
        DDLogError(@"Error muting microphone, status=%d", status);
    }
    return status;
}

-(pj_status_t) adjustRxTxAsync: (BOOL) async {
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:@"adjustRxTx" async:async block:^{
        pj_status_t status2 = [self adjustRxTxInternal];
        if (!async){
            status = status2;
        }
    }];

    return status;
}

-(pj_status_t) adjustRxTxInternal {
    pj_status_t status = !PJ_SUCCESS;
    @try {
        pjsua_conf_port_info pInfo;
        status = pjsua_conf_get_port_info(0, &pInfo);
        if (status != PJ_SUCCESS){
            DDLogWarn(@"Cannot silence, no port 0.");
            return status;
        }

        status = pjsua_conf_adjust_tx_level(0, _soundLevelOut);
        if (status != PJ_SUCCESS){
            DDLogError(@"Cannot set RX level, status=%d", status);
            return status;
        }

        status = pjsua_conf_adjust_rx_level(0, _micMuted ? 0 : _soundLevelMic);
        if (status != PJ_SUCCESS){
            DDLogError(@"Cannot set TX level, status=%d", status);
            return status;
        }

        DDLogInfo(@"Sound levels set.");
    } @catch(NSException * e){
        status = !PJ_SUCCESS;
    }

    if (status != PJ_SUCCESS) {
        DDLogError(@"Error adjusting RX TX levels, status=%d", status);
    }

    return status;
}

-(void) resetAudioInternal: (BOOL) async {
    _micMuted = NO;
    _loudSpeakerActive = NO;
    _handsfreeActive = NO;
    _handsfreeEnableOnCall = NO;
    [self adjustRxTxAsync:async];
    [self switchAudioRoutingToLoud:_loudSpeakerActive async:async onFinished:nil];
}

-(void) setSoundToPlayAndRecord: (BOOL) async {
    if (!async){
        [self setSoundToPlayAndRecordInt];
        return;
    }

    WEAKSELF;
    [self pjExecName:@"setSndCategory" async:async block:^{
        [weakSelf setSoundToPlayAndRecordInt];
    }];
}

// ---------------------------------------------
#pragma mark - Delegate & handlers
// ---------------------------------------------

- (void)registerCallDelegate:(NSNumber *)callId delegate:(id <PEXPjCallCallbacks>)delegate {
    @synchronized (self.callDelegates) {
        id<NSCopying> regKey = callId == nil ? [NSNull null] : callId;
        NSMutableSet * set = [self.callDelegates get:regKey];
        if (set == nil){
            set = [[NSMutableSet alloc] init];
        }

        [set addObject:delegate];
        [self.callDelegates put:set key:regKey async:YES];
    }
}

- (void)unregisterCallDelegate:(NSNumber *)callId delegate:(id <PEXPjCallCallbacks>)delegate {
    @synchronized (self.callDelegates) {
        id<NSCopying> regKey = callId == nil ? [NSNull null] : callId;
        NSMutableSet * set = [self.callDelegates get:regKey];
        if (set == nil){
            return;
        }

        [set removeObject:delegate];
        [self.callDelegates put:set key:regKey async:YES];
    }
}

- (void)unregisterAllDelegatesForCall:(pjsua_call_id) callId {
    if (callId == PJSUA_INVALID_ID){
        DDLogWarn(@"Cannot unregister, invalid ID");
        return;
    }

    @synchronized (self.callDelegates) {
        id<NSCopying> regKey = @(callId);
        NSMutableSet * set = [self.callDelegates get:regKey];
        if (set == nil){
            return;
        }

        [set removeAllObjects];
        [self.callDelegates put:set key:regKey async:YES];
    }
}

-(void) notifyDelegates: (PEXCallCallbackUpdateType) type updateCode: (int) updateCode
               callInfo: (PEXPjCall *) callInfo event: (pjsip_event *) event{

    // Notify all null deleagtes + particular delegates for given call id.
    NSMutableSet * delegates = [[NSMutableSet alloc] init];
    @synchronized (self.callDelegates) {
        id<NSCopying> regKeyAll = [NSNull null];
        id<NSCopying> regKeyId = @(callInfo.callId);
        NSMutableSet * setAll= [self.callDelegates get:regKeyAll];
        NSMutableSet * setId= [self.callDelegates get:regKeyId];

        if (setAll != nil && [setAll count] > 0){
            [delegates addObjectsFromArray: [setAll allObjects]];
        }

        if (setId != nil && [setId count] > 0){
            [delegates addObjectsFromArray: [setId allObjects]];
        }
    }

    // Now iterate over delegates and notify about updates.
    [self pjExecName:@"call_delegate" async:YES block:^{
        for(id<PEXPjCallCallbacks> del in delegates){
            @try {
                // General notification at first.
                [del onCallUpdated:type updateCode:updateCode callInfo:callInfo event:event];

                // Fine grained callback.
                if (updateCode == PEX_CALL_UPDATE_CALL_INCOMING && [del respondsToSelector:@selector(onIncomingCall:)]){
                    [del onIncomingCall:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_CALL_STATE && [del respondsToSelector:@selector(onCallState:event:)]){
                    [del onCallState:callInfo event:event];
                }

                if (updateCode == PEX_CALL_UPDATE_MEDIA_STATE && [del respondsToSelector:@selector(onMediaState:)]){
                    [del onMediaState:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_ZRTP_SHOW_SAS && [del respondsToSelector:@selector(onZrtpShowSas:)]){
                    [del onZrtpShowSas:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_ZRTP_SECURE_ON && [del respondsToSelector:@selector(onZrtpSecureOn:)]){
                    [del onZrtpSecureOn:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_ZRTP_SECURE_OFF && [del respondsToSelector:@selector(onZrtpSecureOff:)]){
                    [del onZrtpSecureOff:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_ZRTP_GO_CLEAR && [del respondsToSelector:@selector(onZrtpGoClear:)]){
                    [del onZrtpGoClear:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_ON_HOLD && [del respondsToSelector:@selector(onOnHold:)]){
                    [del onOnHold:callInfo];
                }

                if (updateCode == PEX_CALL_UPDATE_UN_HOLD && [del respondsToSelector:@selector(onUnHold:)]){
                    [del onUnHold:callInfo];
                }

            } @catch(NSException * ex){
                DDLogError(@"Exception in call notification route, exception=%@", ex);
            }
        }
    }];
}

/**
* Separate call state handler, run in a pjThread - separated from pjsip callback thread.
*/
-(void) handleCallState: (PEXPjCall * ) callInfo state: (int) state {
    if (state == PJSIP_INV_STATE_DISCONNECTED){
        // CallLog
        PEXDbCallLog * cli = [PEXDbCallLog callogFromCall:callInfo];
        BOOL isNew = cli.isNew;
        if (isNew) {
            DDLogInfo(@"New missed call: %@", callInfo);
        }

        // Fill our own database
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

        PEXDbCallLog * prevCl = [PEXDbCallLog getLogByEventDescription:cli.remoteContactSip
                                                                  toId:cli.accountId
                                                               evtTime:cli.eventTimestamp
                                                              evtNonce:nil
                                                                callId:cli.sipCallId
                                                                    cr:cr];
        if (prevCl != nil){
            DDLogDebug(@"Given callog already inserted in db. From %@, toId %@ evtTime %@, evtNonce %@, callId: %@",
                    cli.remoteContactSip, cli.accountId, cli.eventTimestamp, nil, cli.sipCallId);

        } else {
            [PEXDbCallLog addToDatabase:cli cr:cr];
            [PEXDbCallLog probabilisticPrune:cr];
            DDLogVerbose(@"CallLog entry inserted: %@", cli);
        }

        [self onCallEnded: callInfo callLog: cli];
    }
}

-(void) onCallEnded: (PEXPjCall *) callInfo callLog: (PEXDbCallLog *) callLog {
    const int status = [callInfo.lastStatusCode integerValue];
    const int statusFamily = status / 100;
    if (statusFamily == 2){
        // Success termination, no missed call here.
        return;
    }

    // Reporting.
    if (status == 488){
        [PEXReport logEvent:PEX_EVENT_CALL_ERROR_488];
    } else if (status == 699){
        [PEXReport logEvent:PEX_EVENT_CALL_ERROR_699];
    } else if (status == PJSIP_SC_REQUEST_TIMEOUT){
        [PEXReport logEvent:PEX_EVENT_CALL_ERROR_TIMEOUT];
    } else if (status == PJSIP_SC_DECLINE || status == PJSIP_SC_REQUEST_TERMINATED) {
        // Nothing here, not an error.
    } else if (status == PJSIP_SC_GSM_BUSY) {
        // Nothing here, not an error.
    } else if (statusFamily == 3 || statusFamily == 4 || statusFamily == 5){
        [PEXReport logEvent:PEX_EVENT_CALL_ERROR_GENERIC code:@(status)];
    }

    if (callInfo.remoteSideAnswered || callInfo.isIncoming){
        // Remote side has own record for the call.
        return;
    }

    if (status == PJSIP_SC_FORBIDDEN
            || status == PJSIP_SC_BUSY_HERE
            || status == PJSIP_SC_BUSY_EVERYWHERE
            || status == PJSIP_SC_DECLINE
            || status == PJSIP_SC_GSM_BUSY)
    {
        // No right to notify or user already knows the missed call.
        return;
    }

    // TODO: prepare for multi-user. Acc_id contains PJSIP account id.
    [PEXAmpDispatcher dispatchMissedCallNotification:self.privData.username to:callLog.remoteContactSip callId:callInfo.sipCallId];
}

- (BOOL)isHandsfreeDefault {
    return [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_APPLICATION_DEFAULT_HANDSFREE
                                                  defaultValue:PEX_PREF_APPLICATION_DEFAULT_HANDSFREE_DEFAULT];
}

- (void)recoverMediaSessionOnDisconnectInt {
    AVAudioSession *session = [AVAudioSession sharedInstance];

    // Set back to ambient so MUTE works again.
    NSError * err = nil;
    BOOL success;
    success = [session setCategory:AVAudioSessionCategoryAmbient withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&err];
    if (!success){
        DDLogError(@"Cannot set audio category, error=%@", err);
    } else {
        DDLogInfo(@"Audio category set to ambient.");
    }

    // Reset loudspeaker routing.
    _loudSpeakerActive = NO;
    _audioSetToAmbient = YES;
    AVAudioSessionPortOverride override = AVAudioSessionPortOverrideNone;
    success = [session overrideOutputAudioPort:override error:&err];
    if (!success){
        DDLogError(@"Cannot set override port back.");
    }
}

-(BOOL) setSoundToPlayAndRecordInt {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError * err = nil;
    BOOL success;

    // Handsfree allowed?
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers;
    if (_handsfreeEnableOnCall){
        options |= AVAudioSessionCategoryOptionAllowBluetooth;
    }

    _audioSetToAmbient = NO;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:&err];
    if (!success){
        DDLogError(@"Cannot set audio category, error=%@", err);
        return NO;

    } else {
        DDLogInfo(@"Audio category set to AVAudioSessionCategoryPlayAndRecord.");
        _handsfreeActive = _handsfreeEnableOnCall;
        return YES;
    }
}

// ---------------------------------------------
#pragma mark - PJSUA callbacks
// ---------------------------------------------

- (void)on_call_state:(pjsua_call_id)call_id event:(pjsip_event *)e {
    DDLogVerbose(@"%@: %@, call_id=%d, e->type=%d", THIS_FILE, THIS_METHOD, call_id, e->type);

    pjsua_call_info ci;
    PJ_UNUSED_ARG(e);

    pjsua_call_get_info(call_id, &ci);

    // Get current infos now on same thread cause fix has been done on pj
    PEXPjCall * callInfo = [self updateCallInfoFromStack:call_id event:e updateCode:@(PEX_CALL_UPDATE_CALL_STATE)];
    int callState = (int) [callInfo.callState integerValue];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_CALL_STATE callInfo:callInfo event:e];

    // Handle ringing tone logic.
    [_ringTone on_call_state:call_id event:e call_info:&ci call_session:callInfo];
    [_busyTone on_call_state:call_id event:e call_info:&ci call_session:callInfo];
    [_errorTone on_call_state:call_id event:e call_info:&ci call_session:callInfo];
    [_byeTone on_call_state:call_id event:e call_info:&ci call_session:callInfo];

    // Handle call status of the user.
    if (callState == PJSIP_INV_STATE_DISCONNECTED || callState == PJSIP_INV_STATE_CONNECTING) {
        if ([PEXUtils isEmpty: self.privData.username]){
            DDLogError(@"Empty user name in priv data %p", self.privData.username);
        }

        PEXPresenceUpdateMsg *msg = [PEXPresenceUpdateMsg msgWithUser:self.privData.username];
        NSUInteger numActiveCalls = [[self getActiveCallsIds] count];
        msg.isCallingRightNow = @(numActiveCalls > 0);

        // Send presence update message for given user to the presence center.
        PEXPresenceCenter *pc = [PEXPresenceCenter instance];
        [pc updatePresenceForLogged:msg];

        // Reset back to normal
        if (callState == PJSIP_INV_STATE_DISCONNECTED && numActiveCalls <= 0){
            [self resetAudioInternal:YES];
        }
    }

    // If disconnected immediate stop required stuffs
    if (callState == PJSIP_INV_STATE_DISCONNECTED) {
        // Remove call observer from observers when call is finished... No more updates.
        [self unregisterAllDelegatesForCall:call_id];

        // When call is disconnected, check if app is in the background.
        // If it is, unregister SIP.
        PEXService *svc = [PEXService instance];
        const BOOL inBack = [svc isInBackground];
        if (inBack){
            DDLogVerbose(@"Call ended, in background -> unregister");
            [self unregisterBgTaskStartAllowCall:YES];
        }
    }

    // Handle this state change in our handler, in different async thread.
    [self pjExecName:@"on_call_state_handler" async:YES block:^{
        [self handleCallState:callInfo state:callState];
    }];

    DDLogInfo(@"Call %d state=%.*s", call_id, (int)ci.state_text.slen, ci.state_text.ptr);
}

- (void)on_incoming_call:(pjsua_acc_id)acc_id call_id :(pjsua_call_id)call_id rdata:(pjsip_rx_data *)rdata {
    DDLogVerbose(@"%@: %@, acc_id=%d, call_id=%d", THIS_FILE, THIS_METHOD, acc_id, call_id);

    pjsua_call_info ci;

    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);

    pjsua_call_get_info(call_id, &ci);

    // Consult service firewall.
    NSString * remoteFrom = [PEXPjUtils copyToString:&(ci.remote_info)];
    PEXService * svc = [PEXService instance];
    BOOL allowed = [svc.firewall isCallAllowedFromRemote:remoteFrom toLocal:self.privData.username];
    DDLogInfo(@"Incoming call from %@, allowed=%d, callId=%d", remoteFrom, allowed, call_id);

    if (!allowed){
        // Not found error code, hide.
        [self pjExecName:@"answer_404" async:YES block:^{
            // Ring and inform remote about ringing with 180/RINGING.
            pjsua_call_answer(call_id, 404, NULL, NULL);
        }];

        // TODO: signalize rejection of incoming call to IDS.
        // ...

        return;
    }

    // If there are some cellular calls in progress, signalize busy state.
    // As the cellular call center is not invoked while app is in the background, to be sure, recompute cellular calls
    // again, even if it has some overhead.
    NSUInteger activeCellularCalls = [svc recheckCellularCallsAsync:NO completionBlock:nil];
    DDLogInfo(@"Number of active cellular calls: %lu", (unsigned long)activeCellularCalls);
    if ([PEXPhonexSettings takeCellularCallsToBusyState] && activeCellularCalls > 0) {
        [self pjExecName:@"answer_busy_cellular" async:YES block:^{
            // Ring and inform remote about ringing with 486/BUSY.
            pjsua_call_answer(call_id, 486, NULL, NULL);
        }];

        return;
    }

    // Only one call supported at time.
    if (![PEXPhonexSettings supportMultipleCalls]){
        NSArray * activeCalls = [self getActiveCallsBesidesCallId:call_id];
        if ([activeCalls count] > 0){
            DDLogInfo(@"Some call in progress, multiple calls in progress. Count=%d", (int)[activeCalls count]);
            [self pjExecName:@"answer_busy" async:YES block:^{
                // Ring and inform remote about ringing with 486/BUSY.
                pjsua_call_answer(call_id, 486, NULL, NULL);
            }];

            return;
        }
    }

    PEXPjCall * callInfo = [self updateCallInfoFromStack:call_id event:NULL updateCode:@(PEX_CALL_UPDATE_CALL_INCOMING)];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_CALL_INCOMING callInfo:callInfo event:NULL];

    [self pjExecName:@"answer_ringing" async:YES block:^{
        // Ring and inform remote about ringing with 180/RINGING.
        pjsua_call_answer(call_id, 180, NULL, NULL);
    }];

    // Notify incoming call.
    [PEXService executeWithName:@"notify_call" async:YES block:^{
        PEXGuiCallManager * callMgr = [PEXGuiCallManager instance];
        [callMgr showCall: callInfo];
    }];
}

- (void)on_call_media_state:(pjsua_call_id)call_id {
    DDLogVerbose(@"%@: %@, call_id=%d", THIS_FILE, THIS_METHOD, call_id);

    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);

    PEXPjCall * callInfo = [self updateCallInfoFromStack:call_id event:NULL updateCode:@(PEX_CALL_UPDATE_MEDIA_STATE)];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_MEDIA updateCode:PEX_CALL_UPDATE_MEDIA_STATE callInfo:callInfo event:NULL];

    // Handle ringing tone logic.
    [_ringTone on_call_media_state:call_id call_info:&ci];
    [_busyTone on_call_media_state:call_id call_info:&ci];
    [_errorTone on_call_media_state:call_id call_info:&ci];
    [_byeTone on_call_media_state:call_id call_info:&ci];
}

- (void)on_call_tsx_state:(pjsua_call_id)call_id tsx:(pjsip_transaction *)tsx e:(pjsip_event *)e {
    DDLogVerbose(@"%@: %@, e->type=%d", THIS_FILE, THIS_METHOD, e->type);
}

- (void)on_call_sdp_created:(pjsua_call_id)call_id sdp:(pjmedia_sdp_session *)sdp pool:(pj_pool_t *)pool rem_sdp:(const pjmedia_sdp_session *)rem_sdp {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_stream_created:(pjsua_call_id)call_id strm:(pjmedia_stream *)strm stream_idx:(unsigned)stream_idx t:(pjmedia_port **)p_port {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_stream_destroyed:(pjsua_call_id)call_id strm:(pjmedia_stream *)strm stream_idx:(unsigned)stream_idx {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_call_transfer_request:(pjsua_call_id)call_id dst:(const pj_str_t *)dst code:(pjsip_status_code *)code {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_call_transfer_status:(pjsua_call_id)call_id st_code:(int)st_code st_text:(const pj_str_t *)st_text final_:(pj_bool_t)final_ p_cont:(pj_bool_t *)p_cont {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_call_replace_request:(pjsua_call_id)call_id rdata:(pjsip_rx_data *)rdata st_code:(int *)st_code st_text:(pj_str_t *)st_text {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_call_replaced:(pjsua_call_id)old_call_id new_call_id:(pjsua_call_id)new_call_id {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_reg_started:(pjsua_acc_id)acc_id renew:(pj_bool_t)renew {
    DDLogVerbose(@"%@: %@, acc=%d, renew=%d", THIS_FILE, THIS_METHOD, acc_id, renew);
}

- (void)on_reg_started2:(pjsua_acc_id)acc_id info:(pjsua_reg_info *)info {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    _lstRegStarted = [NSDate date];
    _numRegStarted += 1;

    // If stopwatch is not started, start a new one.
    if (_lstUnregisteredPeriodSw == nil){
        _lstUnregisteredPeriodSw = [[PEXStopwatch alloc] initAndStartIf: [[PEXService instance] isConnectivityWorking]];
    }
}

- (void)on_reg_state:(pjsua_acc_id)acc_id {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_reg_state2:(pjsua_acc_id)acc_id info:(pjsua_reg_info *)info {
    if(info == NULL || info->cbparam == NULL){
        DDLogError(@"%@: %@, acc=%d, NULL info!", THIS_FILE, THIS_METHOD, acc_id);
        return;
    }

    const BOOL registered = info->cbparam->code / 100 == 2 && info->cbparam->expiration > 0 && info->cbparam->contact_cnt > 0;
    DDLogVerbose(@"%@: %@, acc=%d, code=%d, expire=%d, status=%d, registered=%d", THIS_FILE, THIS_METHOD,
            acc_id, info->cbparam->code, info->cbparam->expiration, info->cbparam->status, registered);

    // Update internal account in-memory state from this registration information.
    @synchronized (_regStatus) {
        _regStatus.created = [NSDate date];
        _regStatus.registered = registered;
        _regStatus.expire = info->cbparam->expiration;
        _regStatus.lastStatusCode = info->cbparam->code;
        _regStatus.lastStatusText = [PEXPjUtils copyToString:&(info->cbparam->reason)];
    }

    // If unregistration in re-registration process is reached, start a new registration.
    if (!registered && _regStatus.ipReregistrationInProgress){
        DDLogVerbose(@"on_reg_state2: Not registered, iprereg in progress");
        [self reregister];
    }

    // New registration cancels reregistration process.
    if (registered && _regStatus.ipReregistrationInProgress){
        DDLogDebug(@"re-registration stopped, registered && iprereg in progress");
        _regStatus.ipReregistrationInProgress = NO;
    }

    // Stopwatch for unregistered period tracking. Registration watchdog metric candidate.
    if (!registered){
        // If stopwatch is not started, start a new one as we lost the registration.
        if (_lstUnregisteredPeriodSw == nil){
            _lstUnregisteredPeriodSw = [[PEXStopwatch alloc] initAndStartIf: [[PEXService instance] isConnectivityWorking]];
        }

    } else {
        // Registration succeeded, determine how long we were without registration.
        _lstUnregisteredPeriod = _lstUnregisteredPeriodSw == nil ? 0.0 : [_lstUnregisteredPeriodSw stop];
        [_unregisteredPeriodsAvg update:_lstUnregisteredPeriod];
        [_unregisteredAttemptsAvg update:_lstUnregisteredAttempts];

        // Compute Now - last registration expiration to determine for how long we have been without registration.
        if (_lstRegistrationExpiration > 0 && _regStatus.expire > 0){
            _lstUnregisteredExpiration = [[NSDate date] timeIntervalSince1970] - _lstRegistrationExpiration;
            [_unregisteredDueExpirationAvg update:_lstUnregisteredExpiration];
            _lstRegistrationExpiration = -1.0;
        }

        // Reset stopwatch to nil, registration is finished. Not to extend other reg times.
        _lstUnregisteredPeriodSw = nil;
        _lstUnregisteredAttempts = 0;

        DDLogVerbose(@"Registration done, unregistered period: %.3f, avg: %.5f, attempts: %d, avg: %.3f",
                _lstUnregisteredPeriod, _unregisteredPeriodsAvg.current, (int)_lstUnregisteredAttempts, _unregisteredAttemptsAvg.current);
    }

    // Registration watchdog
    [self onRegistrationFinished:acc_id info:info registered:registered];

    // If new registration is set, start new timer for registration count down. Notify when registration is gone.
    if (registered && _regStatus.expire > 0) {
        // If there is a running timer, destroy it, we need to re-schedule.
        if (_regWatchTimer != nil){
            [_regWatchTimer invalidate];
            _regWatchTimer = nil;
        }

        // Expected registration expiration.
        _lstRegistrationExpiration = [[NSDate date] timeIntervalSince1970] + _regStatus.expire;

        // 5 seconds as a fail-safe interval, if internal timer is from some reason blocked,
        // this watchdog timer wakes up - runs on the main runloop.
        NSTimeInterval timerOffset = 5.0;
        PEXService * svc = [PEXService instance];
        if ([svc isInBackground]){
            timerOffset = _regStatus.expire * (-0.1); // Reduce by 10%
            DDLogVerbose(@"Timer offset set to %f, in background.", timerOffset);
        }

        // Schedule a new timer for registration watching.
        NSTimeInterval timerInterval = MAX(_regStatus.expire + timerOffset, 5.0);
        _regWatchTimer = [NSTimer timerWithTimeInterval:timerInterval
                                                          target:self
                                                        selector:@selector(onRegistrationWatchTimerFired:)
                                                        userInfo:_regStatus
                                                         repeats:NO];

        [[NSRunLoop mainRunLoop] addTimer:_regWatchTimer forMode:NSRunLoopCommonModes];
        _regWatchTimerLastDelay = timerInterval;
        _regWatchTimerSet = [[NSDate date] timeIntervalSince1970];
        DDLogVerbose(@"New registration watch timer scheduled, delay: %f tolerance: %f, timer: %@", timerInterval, _regWatchTimer.tolerance, _regWatchTimer);
    }

    // Connectivity change handling.
    // Has to be executed in pjWork thread so the access to regTransport is synchronized.
    if (acc_id == _acc_id) {
        pjsip_transport * newTransport = [self getNewTransport:info];
        [self pjExecName:@"transportSave" async:YES block:^{
            [_regTransportLock lock];
            if (registered) {
                /* Registration success */
                if (_regTransport != NULL && _regTransport != newTransport && newTransport != NULL) {
                    DDLogVerbose(@"ip: Releasing transport %p", _regTransport);
                    pjsip_transport_dec_ref(_regTransport);
                    _regTransport = NULL;
                }

                /* Save transport instance so that we can close it later when
                 * new IP address is detected.
                 */
                if (newTransport != NULL && _regTransport != newTransport) {
                    DDLogVerbose(@"ip: Saving transport %p, old %p", newTransport, _regTransport);
                    _regTransport = newTransport;
                    pjsip_transport_add_ref(_regTransport);
                }
            } else {
                if (_regTransport != NULL) {
                    DDLogVerbose(@"ip: Releasing transport %p", _regTransport);
                    pjsip_transport_dec_ref(_regTransport);
                    _regTransport = NULL;
                }
            }
            [_regTransportLock unlock];
        }];
    }

    [self pjExecName:@"on_reg_change" async:YES block:^{
        [self onRegistrationChange];
    }];
}

-(pjsip_transport *) getNewTransport:(pjsua_reg_info *)info{
    if (info == NULL
            || info->cbparam == NULL
            || info->cbparam->rdata == NULL
            || info->cbparam->rdata->tp_info.transport == NULL)
    {
        return NULL;
    }

    return info->cbparam->rdata->tp_info.transport;
}

- (void)on_pager:(pjsua_call_id)call_id from:(const pj_str_t *)from to:(const pj_str_t *)to contact:(const pj_str_t *)contact mime_type:(const pj_str_t *)mime_type body:(const pj_str_t *)body {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_pager2:(pjsua_call_id)call_id from:(const pj_str_t *)from to:(const pj_str_t *)to contact:(const pj_str_t *)contact mime_type:(const pj_str_t *)mime_type body:(const pj_str_t *)body rdata:(pjsip_rx_data *)rdata acc_id:(pjsua_acc_id)acc_id {
    NSString * fromStr = [PEXPjUtils copyToString:from];
    NSString * toStr = [PEXPjUtils copyToString:to];
    NSString * mimeStr = [PEXPjUtils copyToString:mime_type];
    NSString * bodyStr = [PEXPjUtils copyToString:body];
    NSString * offlineFlag = nil;
    NSString * offlineDump = nil;

    // Search for offline header.
    if (rdata != NULL && rdata->msg_info.msg != NULL){
        offlineFlag = [PEXPjUtils searchForHeader:@"X-Offline" inMessage:rdata->msg_info.msg];
        offlineDump = [PEXPjUtils searchForHeader:@"X-OfflineDump" inMessage:rdata->msg_info.msg];
    }

    DDLogVerbose(@"%@: %@; callId=%d, accid=%d, from=%@, to=%@, mime: %@, offline: %@, ofDump: %@, body=%@", THIS_FILE, THIS_METHOD,
            call_id, acc_id, fromStr, toStr, mimeStr, offlineFlag, offlineDump, bodyStr);

    // Pass it to the message dispatcher.
    [self pjExecName:@"on_pager2" async:YES block:^{
        [[PEXMessageDispatcher instance] dispatchIncomingSipMessageFrom:fromStr to:toStr mime:mimeStr body:bodyStr
                                                                pjsuaId:acc_id
                                                                accName:self.privData.username
                                                                 callId:call_id
                                                            offlineFlag: offlineFlag
                                                            offlineDump: offlineDump];
    }];
}

- (void)on_pager_status:(pjsua_call_id)call_id to:(const pj_str_t *)to body:(const pj_str_t *)body user_data:(void *)user_data status:(pjsip_status_code)status reason:(const pj_str_t *)reason {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);


    BOOL success = status == PJSIP_SC_OK || status == PJSIP_SC_ACCEPTED;
    NSString * toStr = [PEXSipUri getCanonicalSipContact:[PEXPjUtils copyToString:to] includeScheme:NO];
    NSString * reasonStr = [PEXPjUtils copyToString:reason];
    NSString * bodyStr = [PEXPjUtils copyToString:body];

    [self pjExecName:@"on_pager_status" async:YES block:^{
        [[PEXMessageDispatcher instance] acknowledgmentFromPjSip:toStr returnedFinalMessage:bodyStr statusOk:success
                                                 reasonErrorText:reasonStr
                                                 statusErrorCode:status];
    }];
}

- (void)on_pager_status2:(pjsua_call_id)call_id to:(const pj_str_t *)to body:(const pj_str_t *)body user_data:(void *)user_data status:(pjsip_status_code)status reason:(const pj_str_t *)reason tdata:(pjsip_tx_data *)tdata rdata:(pjsip_rx_data *)rdata acc_id:(pjsua_acc_id)acc_id {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_typing:(pjsua_call_id)call_id from:(const pj_str_t *)from to:(const pj_str_t *)to contact:(const pj_str_t *)contact is_typing:(pj_bool_t)is_typing {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_typing2:(pjsua_call_id)call_id from:(const pj_str_t *)from to:(const pj_str_t *)to contact:(const pj_str_t *)contact is_typing:(pj_bool_t)is_typing rdata:(pjsip_rx_data *)rdata acc_id:(pjsua_acc_id)acc_id {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_nat_detect:(const pj_stun_nat_detect_result *)res {
    DDLogVerbose(@"%@: %@, type=%d, name=%s", THIS_FILE, THIS_METHOD, res->nat_type, res->nat_type_name);
}

- (pjsip_redirect_op)on_call_redirected:(pjsua_call_id)call_id target:(const pjsip_uri *)target e:(const pjsip_event *)e {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return [super on_call_redirected:call_id target:target e:e];
}

- (void)on_mwi_info:(pjsua_acc_id)acc_id mwi_info:(pjsua_mwi_info *)mwi_info {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (pj_status_t)on_validate_audio_clock_rate:(int)clock_rate {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return [super on_validate_audio_clock_rate:clock_rate];
}

- (void)on_setup_audio:(pj_bool_t)before_init {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_teardown_audio {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (int)on_set_micro_source {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    return 0;
}

- (pj_status_t)on_call_media_transport_state:(pjsua_call_id)call_id info:(const pjsua_med_tp_state_info *)info {
    if (info == NULL){
        DDLogError(@"%@: %@, call=%d. Null info.", THIS_FILE, THIS_METHOD, call_id);
    } else {
        DDLogVerbose(@"%@: %@, call=%d, mediaIdx=%d, state=%d", THIS_FILE, THIS_METHOD, call_id, info->med_idx, info->state);
    }

    [_ringTone on_call_media_transport_state:call_id info:info];
    [_busyTone on_call_media_transport_state:call_id info:info];
    [_errorTone on_call_media_transport_state:call_id info:info];
    [_byeTone on_call_media_transport_state:call_id info:info];
    return PJ_SUCCESS;
}

- (void)on_transport_state:(pjsip_transport *)tp state:(pjsip_transport_state)state info:(const pjsip_transport_state_info *)info {
    DDLogVerbose(@"%@: %@, tp: %p, reg: %p, state: %d, code: %d",
            THIS_FILE, THIS_METHOD, tp, _regTransport, state, info != NULL ? info->status : -1);

    // Here release transport according to: https://trac.pjsip.org/repos/wiki/IPAddressChange
    // Do it in pjWork thread so it is synchronized with other logic on same data.
    if (state != PJSIP_TP_STATE_DISCONNECTED){
        return;
    }

    [self pjExecName:@"releaseTransport" async:YES block:^{
        BOOL wasRegTransport = NO;
        [_regTransportLock lock];
        if (state == PJSIP_TP_STATE_DISCONNECTED && _regTransport != NULL && _regTransport == tp) {
            DDLogVerbose(@"ip: Releasing registration transport %p", _regTransport);
            wasRegTransport = YES;
            pjsip_transport_dec_ref(_regTransport);
            _regTransport = NULL;
        }
        [_regTransportLock unlock];

        // If was a sudden drop, need to re-register fast.
        if (wasRegTransport && tp != _regTransportShuttingDown){
            _numRegTpFail += 1;
            _lstRegTpFail = [NSDate date];

            DDLogVerbose(@"Seems like sudden reg transport drop, re-register");
            [self reregister];
        }
    }];
}

- (void)on_ice_transport_error:(int)index op:(pj_ice_strans_op)op status:(pj_status_t)status param:(void *)param {
    DDLogVerbose(@"%@: %@, idx=%d, op=%d, status=%d", THIS_FILE, THIS_METHOD, index, op, status);
}

- (void)on_call_media_event:(pjsua_call_id)call_id med_idx:(unsigned)med_idx event:(pjmedia_event *)event {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (pj_status_t) on_snd_dev_operation:(int)operation {
    DDLogVerbose(@"%@: %@, op=%d", THIS_FILE, THIS_METHOD, operation);

    // Revert media session if there are no more calls.
    // Fixes IPH-51.
    if (operation == 0) {
        [self recoverMediaSessionOnDisconnectInt];
    } else if (operation == 1){
        [self setSoundToPlayAndRecord:NO];
    }

    return PJ_SUCCESS;
}

- (void)on_stun_resolved:(const pj_stun_resolve_result *)result {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)on_reregistration_compute_backoff:(pjsua_acc_id)acc_id attempt_cnt:(unsigned *)attempt_cnt delay:(pj_time_val *)delay {
    if (attempt_cnt == NULL || delay == NULL){
        DDLogError(@"Null pointer not expected");
        return;
    }

    PEXService const * svc = [PEXService instance];
    const BOOL inBg = [svc isInBackground];
    const BOOL connected = [svc isConnectivityWorking];
    const BOOL xmppWorked = [svc wasXMPPRegisteredLastTime];
    const NSUInteger numCalls = [self getNumOfCallsInternal];

    // Delay parameters.
    long delayBase = 60000;
    long delayRandom = 10000;

    // do-while(0) for using break statement.
    do {
        // If internet connection is off, it makes no sense to do re-registration.
        if (!connected){
            delayBase = 1000l*60l*10l;
            delayRandom = 1000;
            break;
        }

        // In background + no XMPP -> maybe high packet loss?
        // Only in debug so we can test with link conditioner.
        if ([PEXUtils isDebug] && inBg && !xmppWorked){
            if (*attempt_cnt >=0 && *attempt_cnt <= 2){
                delayBase = 5000;
                delayRandom = 1000;
            } else if (*attempt_cnt <= 4){
                delayBase = 10000;
                delayRandom = 2000;
            } else {
                delayBase = 80000;
                delayRandom = 10000;
            }

            break;
        }

        // Background mode - special treating. Not to get killed too often.
        if (inBg){
            if (*attempt_cnt >=0 && *attempt_cnt <= 2){
                // When running in background we don't get too much time to do something usefull.
                // iOS will stop us in the middle of processing the backoff so better make backoff shorter.
                delayBase = 2000;
                delayRandom = 1000;
            } else if (*attempt_cnt <= 3){
                delayBase = 4000;
                delayRandom = 2000;
            } else if ((*attempt_cnt % 2) == 0){
                delayBase = 90000;
                delayRandom = 10000;
            }  else {
                // Fast reconnect
                delayBase = 5000;
                delayRandom = 2000;
            }

            break;
        }

        // Foreground mode for now on.
        // When call is active, do it more aggressively.
        if (numCalls > 0) {
            if (*attempt_cnt >= 0 && *attempt_cnt < 15) {
                delayBase = 2000;
                delayRandom = 1000;
            } else if (*attempt_cnt < 25) {
                delayBase = 6000;
                delayRandom = 3000;
            } else if ((*attempt_cnt % 3) == 0){
                delayBase = 60000;
                delayRandom = 10000;
            } else {
                // Fast reconnect
                delayBase = 5000;
                delayRandom = 2000;
            }

            break;
        }

        // Normal foreground operation. Do it quite quickly.
        if (*attempt_cnt >= 0 && *attempt_cnt < 10){
            delayBase = 3000;
            delayRandom = 1000;
        } else if (*attempt_cnt < 25) {
            delayBase = 6000;
            delayRandom = 3000;
        } else if ((*attempt_cnt % 3) == 0){
            delayBase = 90000;
            delayRandom = 10000;
        } else {
            // Fast reconnect
            delayBase = 5000;
            delayRandom = 2000;
        }

    } while(0);

    _lstUnregisteredAttempts = *attempt_cnt;
    [self setRegistrationDelayParameters:delayBase delayRandom:delayRandom delay:delay];
    DDLogDebug(@"Re-registration backoff called for id: %d, attempt: %u, delay: %ld s. inBg: %d, connected: %d, xmppOn: %d, activeCalls: %u. "
            "DelayBase: %ld, delayRandom: %ld, curDelay: %ld.%ld",
            acc_id, *attempt_cnt, delay->sec, inBg, connected, xmppWorked, (unsigned) numCalls,
            delayBase, delayRandom, delay->sec, delay->msec);
}

-(void) setRegistrationDelayParameters: (long) delayBase delayRandom: (long) delayRandom delay:(pj_time_val *)delay {
    // Time computation.
    delay->sec = delayBase/1000;
    delay->msec = delayBase%1000;

    // Randomizing part.
    if (delay->sec >= delayRandom/1000) {
        delay->msec += -delayRandom + (pj_rand() % (delayRandom * 2));
    } else {
        delay->msec += (pj_rand() % (delay->sec * 1000 + delayRandom));
        delay->sec = 0;
    }
}

// ---------------------------------------------
#pragma mark - ZRTP callbacks
// ---------------------------------------------
- (void)zrtpShowSas:(PEXPjZrtpInfo *)zrtp sas:(NSString *)sas verified:(int)verified {
    PEXPjCall * callInfo = [self updateCallInfoFromStack:zrtp.call_id event:NULL updateCode:@(PEX_CALL_UPDATE_ZRTP_SHOW_SAS)];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_ZRTP_SHOW_SAS callInfo:callInfo event:NULL];
}

- (void)zrtpSecureOn:(PEXPjZrtpInfo *)zrtp cipher:(NSString *)cipher {
    PEXPjCall * callInfo = [self updateCallInfoFromStack:zrtp.call_id event:NULL updateCode:@(PEX_CALL_UPDATE_ZRTP_SECURE_ON)];

    // Enable sound, now we are secure.
    pjsua_call_info ci;
    pjsua_call_get_info(zrtp.call_id, &ci);

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_ZRTP_SECURE_ON callInfo:callInfo event:NULL];

    // Connect sound port & play a sound to indicate connection is secured.
    __weak __typeof(self) weakSelf = self;
    [PEXService executeDelayedWithName:@"zrtp_sound_ok" timeout:0.25 block:^{
        PEXPjManager * mgr = weakSelf;
        if (mgr == nil || !mgr.created) {
            return;
        }

        // Connect sound.
        [mgr pjExecName:@"connect_sound" async:NO block:^{
            [mgr connectSound:zrtp.call_id state:ci.media_status conf_slot:ci.conf_slot];
        }];

        // Play ZRTP OK sound.
        // ZRTP sound - using tone generator now.
        [_zrtpOkTone tone_schedule_start:100];

//        [NSThread sleepForTimeInterval:0.1];
//        NSString * soundZrtpOk = [PEXResSounds getZrtpOkSound];
//        [mgr playSoundDuringCall:soundZrtpOk async:YES];
    }];
}

- (void)zrtpSecureOff:(PEXPjZrtpInfo *)zrtp {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    PEXPjCall * callInfo = [self updateCallInfoFromStack:zrtp.call_id event:NULL updateCode:@(PEX_CALL_UPDATE_ZRTP_SECURE_OFF)];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_ZRTP_SECURE_OFF callInfo:callInfo event:NULL];

    // Disconnect sound - not secure anymore.
    // If call is disconnected, makes no sense.
    if (![callInfo hasCallState:PJSIP_INV_STATE_DISCONNECTED] && ![callInfo hasCallState:PJSIP_INV_STATE_NULL]){
        pjsua_call_info ci;
        pjsua_call_get_info(zrtp.call_id, &ci);
        [PEXService executeDelayedWithName:@"disable_sound" timeout:0.05 block:^{
            [self disconnectSound:zrtp.call_id callInfo:ci.conf_slot];
        }];
    }
}

- (void)confirmGoClear:(PEXPjZrtpInfo *)zrtp {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    PEXPjCall * callInfo = [self updateCallInfoFromStack:zrtp.call_id event:NULL updateCode:@(PEX_CALL_UPDATE_ZRTP_GO_CLEAR)];

    // Notify observers.
    [self notifyDelegates:PEX_CALL_UPDATE_CALL updateCode:PEX_CALL_UPDATE_ZRTP_GO_CLEAR callInfo:callInfo event:NULL];

    // Disconnect sound - not secure anymore.
    // If call is disconnected, makes no sense.
    if (![callInfo hasCallState:PJSIP_INV_STATE_DISCONNECTED] && ![callInfo hasCallState:PJSIP_INV_STATE_NULL]){
        pjsua_call_info ci;
        pjsua_call_get_info(zrtp.call_id, &ci);
        [PEXService executeDelayedWithName:@"disable_sound" timeout:0.05 block:^{
            [self disconnectSound:zrtp.call_id callInfo:ci.conf_slot];
        }];
    }
}

- (void)showMessage:(PEXPjZrtpInfo *)zrtp sev:(int32_t)sev subCode:(int32_t)subCode {
    DDLogVerbose(@"%@: %@, sev=%d, subCode=%d", THIS_FILE, THIS_METHOD, sev, subCode);
}

- (void)zrtpNegotiationFailed:(PEXPjZrtpInfo *)zrtp severity:(int32_t)severity subcode:(int32_t)subCode {
    DDLogVerbose(@"%@: %@, sev=%d, subCode=%d", THIS_FILE, THIS_METHOD, severity, subCode);
}

- (void)zrtpNotSuppOther:(PEXPjZrtpInfo *)zrtp {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)zrtpAskEnrollment:(PEXPjZrtpInfo *)zrtp info:(int32_t)info {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)zrtpInformEnrollment:(PEXPjZrtpInfo *)zrtp info:(int32_t)info {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)signSAS:(PEXPjZrtpInfo *)zrtp sas:(uint8_t *)sas {
    DDLogVerbose(@"%@: %@, sas=%s", THIS_FILE, THIS_METHOD, sas);
}

- (int32_t)checkSASSignature:(PEXPjZrtpInfo *)zrtp sas:(uint8_t *)sas {
    return 0;
}

- (int32_t)checkZrtpHashMatch:(PEXPjZrtpInfo *)zrtp matchResult:(int32_t)matchResult {
    PEXPjCall * callInfo = [self updateCallInfoFromStack:zrtp.call_id event:NULL];
    PJ_UNUSED_ARG(callInfo); // CallInfo is needed to be updated, updates also internal stack state.
    // TODO: notify observers.
    return 0;
}

// ---------------------------------------------
#pragma mark - Sound playback logic
// ---------------------------------------------

-(pj_status_t)playSoundDuringCall: (NSString *) sound_file_str {
    [self playSoundDuringCall:sound_file_str async:YES];
    return PJ_SUCCESS;
}

-(pj_status_t)playSoundDuringCall: (NSString *) sound_file_str async: (BOOL) async {
    __block pj_status_t status = async ? PJ_SUCCESS : !PJ_SUCCESS;
    [self pjExecName:@"playSoundDuringCall" async:async block:^{
        pj_status_t statusInt = [self play_sound_during_call_internal:sound_file_str];
        if (!async){
            status = statusInt;
        }
    }];
    return status;
}

-(pj_status_t)play_sound_during_call_internal: (NSString *) sound_file_str {
    pjsua_player_id player_id;
    pj_status_t status;
    pj_str_t sound_file;
    [PEXPjUtils assignToPjString:sound_file_str pjstr:&sound_file];
    [self.configuration preparePool];

//    PJSUA_LOCK();
    status = pjsua_player_create(&sound_file, 0, &player_id);
    if (status != PJ_SUCCESS) {
//        PJSUA_UNLOCK();
        DDLogError(@"Cannot create pjsua player, status=%d", status);
        return status;
    }

    pjmedia_port *player_media_port;
    status = pjsua_player_get_port(player_id, &player_media_port);
    if (status != PJ_SUCCESS) {
//        PJSUA_UNLOCK();
        DDLogError(@"Cannot acquire pjsua port, status=%d", status);
        return status;
    }

    DDLogVerbose(@"Creating pool");
    pj_pool_t *pool = pjsua_pool_create("sound_file_data", 512, 512);
    struct pjsua_player_eof_data *eof_data = PJ_POOL_ZALLOC_T(pool, struct pjsua_player_eof_data);
    eof_data->pool = pool;
    eof_data->player_id = player_id;

    pjmedia_wav_player_set_eof_cb(player_media_port, eof_data, &on_pjsua_wav_file_end_callback);
    status = pjsua_conf_connect(pjsua_player_get_conf_port(player_id), 0);

//    PJSUA_UNLOCK();
    return status;
}

-(pj_status_t) sound_play_callback:(pjmedia_port*) media_port args: (void*) args{
    pj_status_t status;

    struct pjsua_player_eof_data *eof_data = (struct pjsua_player_eof_data *)args;
    status = pjsua_player_destroy(eof_data->player_id);

    // Release pool anyway.
    pj_pool_release(eof_data->pool);
    DDLogDebug(@"End of Wav File, media_port: %p", media_port);
    if (status == PJ_SUCCESS){
        //Here it is important to return value other than PJ_SUCCESS.
        return !PJ_SUCCESS;
    }

    return PJ_SUCCESS;
}

@end

static PJ_DEF(pj_status_t) on_pjsua_wav_file_end_callback(pjmedia_port* media_port, void* args){
    return [[PEXPjManager instance] sound_play_callback:media_port args:args];
}

