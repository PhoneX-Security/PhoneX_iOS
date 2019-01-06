//
// Created by Dusan Klinec on 23.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXVersionChecker.h"
#import "PEXJsonFetchOperation.h"
#import "PEXCanceller.h"
#import "USAdditions.h"
#import "PEXService.h"
#import "PEXApplicationStateChange.h"
#import "PEXConnectivityChange.h"
#import "PEXAppVersionUtils.h"
#import "PEXGuiTimeUtils.h"

NSString  * PEXVCheckErrorDomain                = @"net.phonex.vcheck.error";
const NSInteger   PEXVcheckGenericError         = 6001;
const NSInteger   PEXVcheckNotConnectedError    = 6002;
const NSInteger   PEXVcheckInvalidResponseError = 6003;
const NSInteger   PEXVcheckCancelledError       = 6004;
const NSInteger   PEXVcheckTimedOutError        = 6005;

NSString * PEX_URL_PHONEX_UPDATE        = @"https://www.phone-x.net/get";
NSString * PEX_URL_PHONEX_VERSION_CHECK = @"https://system.phone-x.net:444/api/version-check";
NSString * PEX_VCHECK_PARAMETER_TYPE    = @"ios";
NSString * PEX_VCHECK_AFTER_UPDATE      = @"afterUpdate";

// Required preferences settings
NSString * PEX_VCHECK_PREF_LAST_CHECK_TIMESTAMP = @"net.phonex.ui.versionUpdate.last_check_timestamp";
NSString * PEX_VCHECK_PREF_IGNORE_VERSION_CODE  = @"net.phonex.ui.versionUpdate.ignore_version_code";
NSString * PEX_VCHECK_PREF_UPDATE_NOW_TIMESTAMP = @"net.phonex.ui.versionUpdate.update_now_timestamp";
NSString * PEX_VCHECK_PREF_RELEASE_NOTES_SHOWN  = @"net.phonex.ui.versionUpdate.release_notes_shown";

NSString * PEX_VCHECK_PREF_LAST_LATER_VERSION  = @"net.phonex.ui.versionUpdate.last_later_version";
NSString * PEX_VCHECK_PREF_LAST_LATER_CLICK  = @"net.phonex.ui.versionUpdate.last_later_click";
NSString * PEX_VCHECK_PREF_LAST_LATER_SAME_DAY_CLICK  = @"net.phonex.ui.versionUpdate.last_later_same_day_click";
NSString * PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY  = @"net.phonex.ui.versionUpdate.later_click_same_day";

#ifdef PEX_BUILD_DEBUG
const double PEX_VCHECK_CHECK_THRESHOLD     = 60 * 5.0;  // 5 mins
const double PEX_VCHECK_SHOW_NEWS_THRESHOLD = 60 * 3.0;  // 3 mins.
#else
const double PEX_VCHECK_CHECK_THRESHOLD     = 60 * 60 * 8.0;  // 8 hours.
const double PEX_VCHECK_SHOW_NEWS_THRESHOLD = 60 * 15.0;     // 15 mins.
#endif

@interface PEXVersionChecker () {}
@property(nonatomic) NSOperationQueue * opQueue;
@property(nonatomic, weak) PEXService * svc;
@property(nonatomic) BOOL registered;
@property(nonatomic) BOOL invokeOnConnectionRecovered;
@end

@implementation PEXVersionChecker {
}

+ (NSString *) getNewestVersionCodeUri {
    return [NSString stringWithFormat:@"%@?action=getNewestVersion", PEX_URL_PHONEX_VERSION_CHECK];
}

+ (NSString *) getVersionCodeUri {
    return [NSString stringWithFormat:@"%@?action=getVersion", PEX_URL_PHONEX_VERSION_CHECK];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.versionName = [PEXAppVersionUtils fullVersionString];
        self.opQueue = [[NSOperationQueue alloc] init];
        self.opQueue.name = @"vcheckQueue";
        DDLogVerbose(@"VersionChecker initialized, current version %@, code: %llu",
                self.versionName, [PEXAppVersionUtils fullVersionStringToCode:self.versionName]
        );

        _registered = NO;
        _invokeOnConnectionRecovered = NO;
    }

    return self;
}

-(void) checkVersion{
    // Connectivity is OK?
    if (![_svc isConnectivityWorking]){
        _invokeOnConnectionRecovered = YES;
        DDLogInfo(@"Version check postponed until there is valid internet connection.");
        return;
    }

    if (![self showWhatsNewInCurrentVersion]){
        [self checkNewVersion];
    }
}

-(void) doRegister{
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        _svc = [PEXService instance];

        // Register for connectivity notification.
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onConnectivityChangeNotification:) name:PEX_ACTION_CONNECTIVITY_CHANGE object:nil];

        // Register on app state changes - on app becomes active.
        [center addObserver:self selector:@selector(onAppState:) name:PEX_ACTION_APPSTATE_CHANGE object:nil];

        DDLogDebug(@"VersionChecker registered");
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

-(void) quit {
    [self.opQueue cancelAllOperations];
}

-(void)onAppState:(NSNotification *)notification {
    if (notification == nil || notification.userInfo == nil || notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE] == nil){
        return;
    }

    PEXApplicationStateChange * change = notification.userInfo[PEX_EXTRA_APPSTATE_CHANGE];
    if (change.stateChange == PEX_APPSTATE_DID_BECOME_ACTIVE){
        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:@"checkVersion" async:YES block:^{
            [weakSelf checkVersion];
        }];
    }
}

-(void)onConnectivityChangeNotification:(NSNotification *)notification {
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
    if (recovered && _invokeOnConnectionRecovered){
        __weak __typeof(self) weakSelf = self;
        [PEXService executeWithName:@"checkVersion" async:YES block:^{
            [weakSelf checkVersion];
        }];
    }
}

+(void) openUpdateWindow {
    NSURL * const url = [NSURL URLWithString:PEX_URL_PHONEX_UPDATE];
    [[UIApplication sharedApplication] openURL:url];
}

+(void) updateLater: (uint64_t) vcode {
    PEXAppPreferences *prefs = [PEXAppPreferences instance];

    // If later was clicked for the older version, reset counters and exit.
    NSNumber * oldLater = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_VERSION defaultValue:@(0)];
    if ([oldLater longLongValue] < vcode){
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_VERSION value:@(vcode)];
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_CLICK value:@([[NSDate date] timeIntervalSince1970])];
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_SAME_DAY_CLICK value:@([[NSDate date] timeIntervalSince1970])];
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY value:@(1)];
        return;
    }

    // Later was clicked for the same version
    // Get last later click date
    NSDate * cDate = [NSDate date];
    [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_CLICK value:@([cDate timeIntervalSince1970])];

    NSNumber * lastClickSameDay = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_SAME_DAY_CLICK defaultValue:@(0)];
    if (([cDate timeIntervalSince1970]-[lastClickSameDay doubleValue]) <= 60.0*60.0*24.0){
        // Last click happened in the 24 hour window, not updating last click, but counter.
        NSNumber * lastClickCount = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY defaultValue:@(0)];
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY value:@([lastClickCount integerValue]+1)];

    } else {
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_SAME_DAY_CLICK value:@([cDate timeIntervalSince1970])];
        [prefs setNumberPrefForKey:PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY value:@(1)];
    }
}

+(void) ignoreThisVersion: (uint64_t) vcode {
    PEXAppPreferences *prefs = [PEXAppPreferences instance];
    [prefs setNumberPrefForKey:PEX_VCHECK_PREF_IGNORE_VERSION_CODE value:@(vcode)];
}

+(void) setUpdateTime {
    PEXAppPreferences *prefs = [PEXAppPreferences instance];
    [prefs setNumberPrefForKey:PEX_VCHECK_PREF_UPDATE_NOW_TIMESTAMP value:@([[NSDate date] timeIntervalSince1970])];
}

-(void) checkNewVersion {
    if (_versionName == nil){
        DDLogError(@"Cannot check version, empty versionName");
        return;
    }

    PEXAppPreferences *prefs = [PEXAppPreferences instance];
    double lastCheckTimeDb = [prefs getDoublePrefForKey:PEX_VCHECK_PREF_LAST_CHECK_TIMESTAMP defaultValue:0.0];
    NSDate * lastCheckTime = [NSDate dateWithTimeIntervalSince1970:lastCheckTimeDb];
    double curTimestamp = [[NSDate date] timeIntervalSince1970];
    DDLogVerbose(@"checkNewVersion; lastCheckTime [%@]", lastCheckTime);

    if ((curTimestamp - lastCheckTimeDb) > PEX_VCHECK_CHECK_THRESHOLD) {
        DDLogVerbose(@"checkNewVersion; last check is older than threshold, initiating check task");
        [prefs setDoublePrefForKey:PEX_VCHECK_PREF_LAST_CHECK_TIMESTAMP value:curTimestamp];

        @try {
            [self triggerCheckNewVersionTask];
        } @catch (NSException * e) {
            DDLogError(@"Cannot initiate new check task, exception=%@", e);
        }
    }
}

/**
*
* @return true if release notes haven't been shown for current version yet (in this case, checkNewVersion() should NOT follow up)
* otherwise false, which means checkNewVersion() should follow up
*/
-(BOOL) showWhatsNewInCurrentVersion{
    PEXAppPreferences *prefs = [PEXAppPreferences instance];
    BOOL notesAlreadyShown = [prefs getBoolPrefForKey:PEX_VCHECK_PREF_RELEASE_NOTES_SHOWN defaultValue:NO];
    DDLogVerbose(@"showWhatsNewInCurrentVersion; notesAlreadyShown [%d]", notesAlreadyShown);

    // 1. show release notes only once
    if (notesAlreadyShown){
        return NO;
    }

    [prefs setBoolPrefForKey:PEX_VCHECK_PREF_RELEASE_NOTES_SHOWN value:YES];
    [prefs setDoublePrefForKey:PEX_VCHECK_PREF_LAST_CHECK_TIMESTAMP value:[[NSDate date] timeIntervalSince1970]];

    // 2. special case - if update happens within SHOW_NEWS_THRESHOLD from PREF_UPDATE_NOW_TIMESTAMP click, skip showing release notes (user has seen it while ago)
    double updateNowClickTimestamp = [prefs getDoublePrefForKey:PEX_VCHECK_PREF_UPDATE_NOW_TIMESTAMP defaultValue:0.0];
    double nowTimestamp = [[NSDate date] timeIntervalSince1970];
    if ((nowTimestamp - updateNowClickTimestamp) <= PEX_VCHECK_SHOW_NEWS_THRESHOLD){
        DDLogInfo(@"showWhatsNewInCurrentVersion; do not show release notes, app presumably updated manually by 'Update now'");

        return YES; // true = do not check new version after
    }

    // 3. retrieve and show news
    @try {
        NSArray * langs = [NSLocale preferredLanguages];
        NSString * language = langs == nil || langs.count == 0 ? @"en" : langs[0];
        uint64_t versionCode = [PEXAppVersionUtils fullVersionStringToCode:_versionName];

        [self triggerGetVersionInfoTask:versionCode locale:language afterUpdate:YES];
    } @catch (NSException * e) {
        DDLogError(@"showWhatsNewInCurrentVersion; cannot retrieve version [%@] information, exception=%@", _versionName, e);
    } @finally {
        return true;
    }
}

-(void) onVersionInfoRetrieved: (NSDictionary *) responseJson afterUpdate: (BOOL) afterUpdate {
    uint64_t newVersionCode;
    NSString * newVersionName;
    NSString * newReleaseNotes;
    BOOL availableAtMarket;
    PEXAppPreferences *prefs = [PEXAppPreferences instance];

    @try {
        newVersionCode = (uint64_t) [responseJson[@"versionCode"] longLongValue];
        newVersionName = responseJson[@"versionName"];
        newReleaseNotes = responseJson[@"releaseNotes"];
        availableAtMarket = [responseJson[@"availableAtMarket"] boolValue];
    } @catch (NSException * e) {
        DDLogError(@"onVersionInfoRetrieved; Error retrieving values from JSON, exception=%@", e);
        return;
    }

    if (!availableAtMarket){
        DDLogWarn(@"onVersionInfoRetrieved; version %llu is still not available on the market, delaying update info dialog", newVersionCode);

        // Delay next check to CHECK_THRESHOLD/2
        [prefs setDoublePrefForKey:PEX_VCHECK_PREF_LAST_CHECK_TIMESTAMP value:[[NSDate date] timeIntervalSince1970] - PEX_VCHECK_CHECK_THRESHOLD/2];
        return;
    }

    // Show UI notification.
    DDLogInfo(@"NEW version available, vcode: %llu, vname: %@, notes: %@, afterUpdate: %d", newVersionCode, newVersionName, newReleaseNotes, afterUpdate);
    if (self.onNewVersionBlock != nil){
        self.onNewVersionBlock(afterUpdate, newVersionCode, newVersionName, newReleaseNotes, self);
    }
}

- (void) onCheckNewVersionCompleted: (PEXJsonFetchOperation *) op {
    if (op == nil || op.opError != nil){
        DDLogError(@"Response error-ed: %@", op.opError);
        return;
    }

    _invokeOnConnectionRecovered = NO;
    @try {
        NSDictionary * dict = op.response;
        NSString * vCodeString = dict[@"versionCode"];
        if (vCodeString == nil){
            return;
        }

        uint64_t vCode = (uint64_t) [vCodeString longLongValue];
        uint64_t curVcode = [PEXAppVersionUtils fullVersionStringToCode:self.versionName];
        DDLogVerbose(@"CheckNewVersionTask; Retrieved version code [%llu]; current version code [%llu]", vCode, curVcode);
        if (vCode > curVcode){
            DDLogInfo(@"Newer version exists, get info");
            if ([self shouldPostponeNewVersionNotification:vCode]){
                DDLogInfo(@"This version is ignored, do not update");
                return;
            }

            NSArray * langs = [NSLocale preferredLanguages];
            NSString * language = langs == nil || langs.count == 0 ? @"en" : langs[0];
            [self triggerGetVersionInfoTask:vCode locale:language afterUpdate:NO];
        }
    } @catch (NSException * e1) {
        DDLogError(@"Exception in processing answer: %@", e1);
    }
}

- (void) onGetVersionInfoCompleted: (PEXJsonFetchOperation *) op {
    if (op == nil || op.opError != nil){
        DDLogError(@"Response error-ed: %@", op.opError);
        return;
    }

    _invokeOnConnectionRecovered = NO;
    DDLogInfo(@"GetVersionInfoTask; Correct response received [%@]", op.response);
    [self onVersionInfoRetrieved: op.response afterUpdate:[op.userInfo[PEX_VCHECK_AFTER_UPDATE] boolValue]];
}

- (void) triggerCheckNewVersionTask {
    __weak __typeof(self) weakSelf = self;
    PEXJsonFetchOperation * remoteOp = [[PEXJsonFetchOperation alloc] init];
    remoteOp.blockingOp = YES;
    remoteOp.canceller = self.canceller;
    remoteOp.privData = self.privData;
    remoteOp.url = PEX_URL_PHONEX_VERSION_CHECK; //[PEXVersionChecker getNewestVersionCodeUri];
    remoteOp.params = @{ @"action" : @"getNewestVersion", @"type" : PEX_VCHECK_PARAMETER_TYPE };
    __weak PEXJsonFetchOperation *wOp = remoteOp;

    remoteOp.finishBlock = ^{
        PEXVersionChecker * vchecker = weakSelf;
        if (vchecker == nil){
            return;
        }

        [vchecker onCheckNewVersionCompleted: wOp];
    };

    [self.opQueue addOperation:remoteOp];
}

- (void) triggerGetVersionInfoTask: (uint64_t) versionCode locale: (NSString *) locale afterUpdate: (BOOL) afterUpdate {
    __weak __typeof(self) weakSelf = self;
    NSString * versionCodeStr = [NSString stringWithFormat:@"%llu", versionCode];

    PEXJsonFetchOperation * remoteOp = [[PEXJsonFetchOperation alloc] init];
    remoteOp.blockingOp = YES;
    remoteOp.canceller = self.canceller;
    remoteOp.privData = self.privData;
    remoteOp.url = PEX_URL_PHONEX_VERSION_CHECK; //[PEXVersionChecker getVersionCodeUri];
    remoteOp.params = @{@"action" : @"getVersion", @"type" : PEX_VCHECK_PARAMETER_TYPE, @"versionCode" : versionCodeStr, @"locale" : locale};
    remoteOp.userInfo = @{PEX_VCHECK_AFTER_UPDATE : @(afterUpdate)};
    __weak PEXJsonFetchOperation *wOp = remoteOp;

    remoteOp.finishBlock = ^{
        PEXVersionChecker * vchecker = weakSelf;
        if (vchecker == nil){
            return;
        }

        [vchecker onGetVersionInfoCompleted: wOp];
    };

    [self.opQueue addOperation:remoteOp];
}

-(uint64_t) getIgnoredVersionCode{
    PEXAppPreferences *prefs = [PEXAppPreferences instance];
    return (uint64_t) [[prefs getNumberPrefForKey:PEX_VCHECK_PREF_IGNORE_VERSION_CODE defaultValue:@(-1)] longLongValue];
}

-(BOOL) shouldPostponeNewVersionNotification: (uint64_t) forVersion {
    PEXAppPreferences *prefs = [PEXAppPreferences instance];

    // Ignore this particular version ?
    const uint64_t ignoredVersion = (uint64_t) [[prefs getNumberPrefForKey:PEX_VCHECK_PREF_IGNORE_VERSION_CODE defaultValue:@(-1)] longLongValue];
    if (ignoredVersion == forVersion){
        DDLogVerbose(@"Version %llu is ignored", forVersion);
        return YES;
    }

    // Processing "Later" button click logic.
    // If later was clicked for older version, do not postpone notification.
    NSNumber * lastLaterVersion = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_VERSION defaultValue:@(0)];
    if ([lastLaterVersion longLongValue] < forVersion){
        return NO;
    }

    // Later logic - time postponing.
    NSDate * cDate = [NSDate date];
    NSNumber * lastClick = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_CLICK defaultValue:@(0)];
    NSNumber * lastClickCount = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LATER_CLICKS_SAME_DAY defaultValue:@(0)];
    NSNumber * lastClickSameDay = [prefs getNumberPrefForKey:PEX_VCHECK_PREF_LAST_LATER_SAME_DAY_CLICK defaultValue:@(0)];

    // If the last
    NSTimeInterval firstDayClickToNowDiff = [cDate timeIntervalSince1970]-[lastClickSameDay doubleValue];
    if (firstDayClickToNowDiff <= 60.0*60.0*24.0){
        // Last click happened in the 24 hour window, not updating last click, but counter.
        NSInteger clickCount = [lastClickCount integerValue];
        DDLogVerbose(@"Later logic - same day, clickCount: %ld, diff: %f, lastClick: %@, sameDay: %@",
                (long int) clickCount, firstDayClickToNowDiff, lastClick, lastClickSameDay);

        if (clickCount <= 0){
            // Immediately, invalid click count.
            return NO;
        } else if (clickCount == 1){
            // If gap from first click in the same day is smaller than 3 hours, do postpone.
            return firstDayClickToNowDiff <= 60.0*60.0*3.0;
        } else {
            // Second click to later in the same day means postpone for next 24 hours.
            return YES;
        }
    }

    return NO;
}

@end