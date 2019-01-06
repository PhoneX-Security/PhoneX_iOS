//
// Created by Dusan Klinec on 12.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXReport.h"
#import "Flurry.h"
#import "PEXFlurry.h"
#import "PEXUtils.h"
#import "NSError+PEX.h"
#import "PEXService.h"
#import "PEXGAILogger.h"

#if PEX_GAI_TRACKING
#  import <Google/Analytics.h>
#endif

NSString * const PEX_EVENT_DB_RELOADED = @"DBreloaded";
NSString * const PEX_EVENT_DB_RELOAD_FAILED = @"DBreload.failed";
NSString * const PEX_EVENT_DB_WATCHDOG_ERROR = @"DBwatchdog.error";
NSString * const PEX_EVENT_DB_WATCHDOG_THRESHOLD = @"DBwatchdog.threshold";
NSString * const PEX_EVENT_DB_ACC_NOT_FOUND = @"DB.accNotFound";
NSString * const PEX_EVENT_AUTOLOGIN_STARTED = @"autologin.started";
NSString * const PEX_EVENT_AUTOLOGIN_FINISHED = @"autologin.finished";
NSString * const PEX_EVENT_AUTOLOGIN_FAILED = @"autologin.failed";
NSString * const PEX_EVENT_APP_TERMINATED = @"app.terminated";
NSString * const PEX_EVENT_LOGIN_TASK_STARTED = @"login.started";
NSString * const PEX_EVENT_LOGIN_TASK_FINISHED_SUCC = @"login.finished";
NSString * const PEX_EVENT_LOGIN_TASK_FINISHED_FAIL = @"login.failed";
NSString * const PEX_EVENT_LOGOUT = @"logout";
NSString * const PEX_EVENT_MEMORY_WARNING = @"memoryWarning";
NSString * const PEX_EVENT_SIP_RESTART = @"sip.restart";
NSString * const PEX_EVENT_SIP_RESTART_FAILED = @"sip.restart.failed";
NSString * const PEX_EVENT_SIP_REGISTRATION_FAILED = @"sip.registration.failed";
NSString * const PEX_EVENT_CALL_ERROR_488 = @"callError.488";
NSString * const PEX_EVENT_CALL_ERROR_699 = @"callError.699";
NSString * const PEX_EVENT_CALL_ERROR_TIMEOUT = @"callError.timeout";
NSString * const PEX_EVENT_CALL_ERROR_GENERIC = @"callError.generic";
NSString * const PEX_EVENT_MSG_UNSUPPORTED_STP = @"msg.error.stp";
NSString * const PEX_EVENT_MSG_UNKNOWN_PROTOCOL = @"msg.error.unknown";
NSString * const PEX_EVENT_MSG_UNKNOWN_TRANSPORT_PROTOCOL = @"msg.error.unknownTransport";
NSString * const PEX_EVENT_MSG_NULL_PROTOCOL = @"msg.error.nullProtocol";
NSString * const PEX_EVENT_MSG_UNKNOWN_AMP = @"msg.error.unknownAmp";
NSString * const PEX_EVENT_MSG_TEXT_INVALID_SIGNATURE = @"msg.error.txt.invalidSignature";
NSString * const PEX_EVENT_MSG_NOTIF_INVALID_SIGNATURE = @"msg.error.notif.invalidSignature";

NSString * const PEX_EVENT_USER_ADDED = @"user.added";
NSString * const PEX_EVENT_USER_DELETED = @"user.deleted";
NSString * const PEX_EVENT_USER_RENAMED = @"user.renamed";
NSString * const PEX_EVENT_PASS_CHANGED = @"passchange.success";
NSString * const PEX_EVENT_NEW_ACCOUNT_SCREEN = @"newAccount.screen";
NSString * const PEX_EVENT_NEW_ACCOUNT_CREATED = @"newAccount.created";
NSString * const PEX_EVENT_CALLED_SOMEONE = @"called";
NSString * const PEX_EVENT_CALL_ANSWERED = @"callAnswered";
NSString * const PEX_EVENT_CALL_REJECTED = @"callRejected";
NSString * const PEX_EVENT_SENT_FILE_SOMEONE = @"sentFile";
NSString * const PEX_EVENT_CANCEL_UPLOAD = @"cancelUpload";
NSString * const PEX_EVENT_FILE_DOWNLOAD = @"downloadFile";
NSString * const PEX_EVENT_SENT_TEXT_MESSAGE = @"sentText";

NSString * const PEX_EVENT_PIN_OK = @"pinlock.correct";
NSString * const PEX_EVENT_PIN_FAIL = @"pinlock.incorrect";

NSString * const PEX_EVENT_BTN_ANSWER_CALL = @"btn.call.answer";
NSString * const PEX_EVENT_BTN_REJECT_CALL = @"btn.call.reject";
NSString * const PEX_EVENT_BTN_END_CALL = @"btn.call.end";
NSString * const PEX_EVENT_BTN_CLEAR_ALL_CALLLOGS = @"btn.clearAllCallLogs";
NSString * const PEX_EVENT_BTN_COMPOSE_BROADCAST_MESSAGE = @"btn.composeBroadcastMessage";
NSString * const PEX_EVENT_BTN_CONTACTS_ADD_CONTACT = @"btn.contacts.addContact";
NSString * const PEX_EVENT_BTN_SHOW_CONTACT_NOTIFICATIONS = @"btn.showContactNotifications";
NSString * const PEX_EVENT_BTN_CONTACT_ACTION_CALL = @"btn.contactAction.call";
NSString * const PEX_EVENT_BTN_CONTACT_ACTION_MESSAGE = @"btn.contactAction.message";
NSString * const PEX_EVENT_BTN_CONTACT_ACTION_FILE = @"btn.contactAction.file";
NSString * const PEX_EVENT_BTN_CONTACT_ACTION_SETTINGS = @"btn.contactAction.settings";
NSString * const PEX_EVENT_BTN_ADD_CONTACT_ALIAS_CLICKED = @"btn.addContact.alias";
NSString * const PEX_EVENT_BTN_CONTACT_DETAILS_RENAME_CONTACT = @"btn.contactDetails.renameContact";
NSString * const PEX_EVENT_BTN_REMEMBER_USERNAME = @"btn.rememberUserName";
NSString * const PEX_EVENT_BTN_LOGIN_DETAILS = @"btn.loginDetails";
NSString * const PEX_EVENT_BTN_PRODUCT_CODE = @"btn.productCode";
NSString * const PEX_EVENT_BTN_SHOW_PREFERENCES = @"btn.showPreferences";
NSString * const PEX_EVENT_BTN_CHOOSE_PRESENCE = @"btn.choosePresence";
NSString * const PEX_EVENT_BTN_LOGOUT = @"btn.logout";
NSString * const PEX_EVENT_BTN_PREFS_CHOOSE_LANGUAGE = @"btn.prefs.chooseLanguage";
NSString * const PEX_EVENT_BTN_PREFS_CHOOSE_THEME = @"btn.prefs.chooseTheme";
NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK = @"btn.prefs.pinLock";
NSString * const PEX_EVENT_BTN_PREFS_TOUCH_ID = @"btn.prefs.touchId";
NSString * const PEX_EVENT_BTN_PREFS_MESSAGE_ARCHIVE = @"btn.prefs.messageArchive";
NSString * const PEX_EVENT_BTN_PREFS_SHOW_USER_NAME = @"btn.prefs.showUserName";
NSString * const PEX_EVENT_BTN_PREFS_ENABLE_GOOGLE_ANALYTICS = @"btn.prefs.enableGoogleAnalytics";
NSString * const PEX_EVENT_BTN_PROFILE_CHANGE_PASSWORD = @"btn.profile.changePassword";
NSString * const PEX_EVENT_BTN_PROFILE_RECOVERY_MAIL = @"btn.profile.recoveryMail";
NSString * const PEX_EVENT_BTN_PROFILE_TERMS_CONDITIONS = @"btn.profile.termsConditions";

NSString * const PEX_EVENT_BTN_SAS_CONFIRM = @"btn.sas.confirm";
NSString * const PEX_EVENT_BTN_SAS_REJECT = @"btn.sas.reject";
NSString * const PEX_EVENT_BTN_DELETE_CALLOG_ENTRY = @"btn.deleteCallLogEntry";
NSString * const PEX_EVENT_BTN_FILE_SELECT_DELETE_FILES = @"btn.fileSelect.deleteFiles";
NSString * const PEX_EVENT_BTN_LOGOUT_CONFIRM = @"btn.logout.confirm";
NSString * const PEX_EVENT_BTN_LOGOUT_CANCEL = @"btn.logout.cancel";
NSString * const PEX_EVENT_BTN_CHANGE_STATUS_CONFIRM = @"btn.changeStatus.confirm";
NSString * const PEX_EVENT_BTN_CHANGE_STATUS_CANCEL = @"btn.changeStatus.cancel";

NSString * const PEX_EVENT_BTN_TAB_CONTACTS = @"btn.tab.contacts";
NSString * const PEX_EVENT_BTN_TAB_CHATS = @"btn.tab.chats";
NSString * const PEX_EVENT_BTN_TAB_CALLLOG = @"btn.tab.calllog";
NSString * const PEX_EVENT_BTN_TAB_PROFILE = @"btn.tab.profile";

NSString * const PEX_EVENT_BTN_ADD_CONTACT = @"btn.addContact";
NSString * const PEX_EVENT_BTN_RENAME_CONTACT = @"btn.renameContact";
NSString * const PEX_EVENT_BTN_RECHECK_CERTIFICATE = @"btn.recheckCertificate";
NSString * const PEX_EVENT_BTN_LOGIN = @"btn.login";
NSString * const PEX_EVENT_BTN_LOGIN_CREATE_ACCOUNT = @"btn.login.createAccount";
NSString * const PEX_EVENT_BTN_LOGS_START_SENDING = @"btn.logs.startSending";
NSString * const PEX_EVENT_BTN_CHANGE_PASSWORD = @"btn.changePassword";
NSString * const PEX_EVENT_BTN_PREMIUM_WEB = @"btn.premium.goToWeb";
NSString * const PEX_EVENT_BTN_PREMIUM_SUPPORT = @"btn.premium.contactSupport";
NSString * const PEX_EVENT_BTN_PROFILE_GET_PREMIUM = @"btn.profile.getPremium";
NSString * const PEX_EVENT_BTN_PROFILE_SEND_LOGS = @"btn.profile.sendLogs";
NSString * const PEX_EVENT_BTN_PROFILE_INVITE_USERS = @"btn.profile.inviteUsers";
NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK_ENABLE = @"btn.prefs.pinlock.enable";
NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK_DISABLE = @"btn.prefs.pinlock.disable";

NSString * const PEX_EVENT_BTN_MUTE_MIC = @"btn.call.muteMic";
NSString * const PEX_EVENT_BTN_LOUDSPEAKER = @"btn.call.loudspeaker";
NSString * const PEX_EVENT_BTN_BLUETOOTH = @"btn.call.bluetooth";
NSString * const PEX_EVENT_BTN_MSG_KEYBOARD = @"btn.msg.keyboard";
NSString * const PEX_EVENT_BTN_MSG_SEND = @"btn.msg.send";
NSString * const PEX_EVENT_BTN_MSG_SCROLL_DOWN = @"btn.msg.scrolldown";
NSString * const PEX_EVENT_BTN_MSG_COUNTER = @"btn.msg.counter";
NSString * const PEX_EVENT_BTN_MSG_CLICKABLE_AREA = @"btn.msg.clickableArea";
NSString * const PEX_EVENT_BTN_CALLLOG_ACTION = @"btn.calllog.action";
NSString * const PEX_EVENT_BTN_CALLLOG_REMOVE = @"btn.calllog.remove";
NSString * const PEX_EVENT_BTN_CHAT_CALL = @"btn.chat.call";
NSString * const PEX_EVENT_BTN_CHAT_FILE = @"btn.chat.file";
NSString * const PEX_EVENT_BTN_CHATS_ACTION = @"btn.chats.action";
NSString * const PEX_EVENT_BTN_CHATS_REMOVE = @"btn.chats.remove";
NSString * const PEX_EVENT_BTN_BCAST_CONTACTS = @"btn.bcast.contacts";
NSString * const PEX_EVENT_BTN_FILE_ACCEPT = @"btn.file.accept";
NSString * const PEX_EVENT_BTN_FILE_CANCEL = @"btn.file.cancel";
NSString * const PEX_EVENT_BTN_FILE_REJECT = @"btn.file.reject";
NSString * const PEX_EVENT_BTN_CONTACT_POPUP = @"btn.contact.popup";
NSString * const PEX_EVENT_BTN_CONTACT_DELETE = @"btn.contact.delete";
NSString * const PEX_EVENT_BTN_PAIRING_ACCEPT = @"btn.contactRequest.accept";
NSString * const PEX_EVENT_BTN_PAIRING_DELETE = @"btn.contactRequest.delete";
NSString * const PEX_EVENT_BTN_CONTACT_SELECT = @"btn.contact.select";
NSString * const PEX_EVENT_BTN_CONTACT_SELECT_CLEAR = @"btn.contact.select.clear";
NSString * const PEX_EVENT_BTN_CONTACT_SELECT_NEXT = @"btn.contact.select.next";
NSString * const PEX_EVENT_BTN_FILES_PHONEX = @"btn.files.byPhonex";
NSString * const PEX_EVENT_BTN_FILES_PHOTOS = @"btn.files.byPhotos";
NSString * const PEX_EVENT_BTN_FILES_SELECTED = @"btn.files.bySelected";
NSString * const PEX_EVENT_BTN_FILES_NEW_PHOTO = @"btn.files.newPhoto";
NSString * const PEX_EVENT_BTN_FILES_UP = @"btn.files.up";
NSString * const PEX_EVENT_BTN_FILES_ACTION = @"btn.files.action";
NSString * const PEX_EVENT_BTN_FILES_SELECTION_CLEAR = @"btn.files.selection.clear";
NSString * const PEX_EVENT_BTN_FILES_SELECTION_DELETE = @"btn.files.selection.delete";
NSString * const PEX_EVENT_BTN_FILES_SELECTION_NEXT = @"btn.files.selection.next";
NSString * const PEX_EVENT_BTN_FILES_CHECK = @"btn.files.check";
NSString * const PEX_EVENT_BTN_HAS_PRODUCT_CODE = @"btn.hasProductCode";
NSString * const PEX_EVENT_BTN_CREATE_ACCOUNT = @"btn.createAccount";
NSString * const PEX_EVENT_BTN_CAPTCHA_RELOAD = @"btn.reloadCaptcha";
NSString * const PEX_EVENT_BTN_MAIN_FILE = @"btn.main.file";
NSString * const PEX_EVENT_BTN_PIN_NUM = @"btn.pinlock.num";
NSString * const PEX_EVENT_BTN_PIN_DELETE = @"btn.pinlock.delete";
NSString * const PEX_EVENT_BTN_PIN_DISMISS = @"btn.pinlock.dismiss";
NSString * const PEX_EVENT_BTN_PRESENCE_DETAILS = @"btn.presence.details";
NSString * const PEX_EVENT_BTN_PRESENCE_STATUS = @"btn.presence.status";
NSString * const PEX_EVENT_BTN_NAVIGATION_BACK = @"btn.back";
NSString * const PEX_EVENT_BTN_CLOSE = @"btn.close";

NSString * const PEX_EVENT_BTN_MSG_POPUP_DETAIL = @"btn.msg.popup.detail";
NSString * const PEX_EVENT_BTN_MSG_POPUP_COPY = @"btn.msg.popup.copy";
NSString * const PEX_EVENT_BTN_MSG_POPUP_REMOVE = @"btn.msg.popup.remove";
NSString * const PEX_EVENT_BTN_MSG_POPUP_FORWARD = @"btn.msg.popup.forward";
NSString * const PEX_EVENT_BTN_MSG_POPUP_PREVIEW = @"btn.msg.popup.preview";

NSString * const PEX_EVENT_SCREEN_CONTACTS = @"tab.contacts";
NSString * const PEX_EVENT_SCREEN_CHATS = @"tab.chats";
NSString * const PEX_EVENT_SCREEN_CALLLOG = @"tab.calllog";
NSString * const PEX_EVENT_SCREEN_PROFILE = @"tab.profile";

@interface PEXReport() {}
@property(nonatomic) BOOL googleAnalyticsInitialized;
@property(nonatomic) BOOL flurryInitialized;
@end

@implementation PEXReport {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.includeAppVersion = NO;
        self.includeUsername = NO;
        self.custom = nil;
        self.googleAnalyticsInitialized = NO;
        self.flurryInitialized = NO;
    }

    return self;
}

+ (PEXReport *)sharedInstance {
    static PEXReport *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (instancetype)initAppVer:(BOOL)includeAppVersion incUname:(BOOL)includeUsername {
    self = [self init];
    if (self) {
        self.includeAppVersion = includeAppVersion;
        self.includeUsername = includeUsername;
    }

    return self;
}

- (instancetype)initAppVer:(BOOL)includeAppVersion {
    self = [self init];
    if (self) {
        self.includeAppVersion = includeAppVersion;
    }

    return self;
}

- (instancetype)initAppVersion:(BOOL)includeAppVersion uName:(NSString *)uName {
    self = [self init];
    if (self) {
        self.includeAppVersion = includeAppVersion;
        self.uName = uName;
    }

    return self;
}

+ (instancetype)reportWith:(BOOL)includeAppVersion uName:(NSString *)uName {
    return [[self alloc] initAppVersion:includeAppVersion uName:uName];
}

+ (instancetype)reportWith:(BOOL)includeAppVersion {
    return [[self alloc] initAppVer:includeAppVersion];
}

+ (instancetype)reportWith:(BOOL)includeAppVersion incUname:(BOOL)includeUsername {
    return [[self alloc] initAppVer:includeAppVersion incUname:includeUsername];
}

+ (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error {
    @try {
        [Flurry logError:errorID message:message error:error];
    } @catch(NSException * e){
        DDLogError(@"Could not report error with flurry, exception: %@", e);
    }
}

+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception {
    @try {
        [Flurry logError:errorID message:message exception:exception];
    } @catch(NSException * e){
        DDLogError(@"Could not report error with flurry, exception: %@", e);
    }

#if PEX_GAI_TRACKING
    @try {
        if (![PEXReport wasGaiInitialized]){
            return;
        }

        // May return nil if a tracker has not already been initialized with a
        // property ID.
        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder
                createExceptionWithDescription:[NSString stringWithFormat:@"Msg: %@. Exc: %@, %@", message, exception, exception.callStackSymbols]  // Exception description. May be truncated to 100 chars.
                                     withFatal:@NO] build]];  // isFatal (required). NO indicates non-fatal exception.
    } @catch(NSException * e){
        DDLogError(@"Could not report error with flurry, exception: %@", e);
    }
#endif
}

- (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error {
    @try {
        if (_includeAppVersion || _includeUsername || _custom != nil || _uName != nil) {
            NSMutableDictionary *toAdd = [[NSMutableDictionary alloc] init];

            // Application version in the error.
            if (_includeAppVersion) {
                NSString *appVersionData = [PEXUtils getUniversalApplicationCode];
                toAdd[@"E_appver"] = appVersionData;
            }

            // Defined user name
            if (![PEXUtils isEmpty:_uName]) {
                toAdd[@"E_uname"] = _uName;
            }

            // Custom fields in the error.
            if (_custom != nil && [_custom count] > 0) {
                [toAdd addEntriesFromDictionary:_custom];
            }

            if (error == nil) {
                error = [[NSError alloc] initWithDomain:@"PEXReport" code:-1 userInfo:toAdd];
            } else {
                error = [NSError errorWithDomain:@"PEXReport" code:-1 userInfo:toAdd subError:error];
            }
        }

        [Flurry logError:errorID message:message error:error];

#if PEX_GAI_TRACKING
        // May return nil if a tracker has not already been initialized with a
        // property ID.
        if (![PEXReport wasGaiInitialized]){
            return;
        }

        id tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder
                createExceptionWithDescription:[NSString stringWithFormat:@"ErrorId: %@, Msg: %@, error: %@", errorID, message, error]  // Exception description. May be truncated to 100 chars.
                                     withFatal:@NO] build]];  // isFatal (required). NO indicates non-fatal exception.
#endif
    } @catch(NSException * e){
        DDLogError(@"Could not report error with flurry, exception: %@", e);
    }

}

- (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception {
    [PEXReport logError:errorID message:message exception:exception];
}

+ (FlurryEventRecordStatus)logEvent:(NSString *)eventName {
    return [self logEvent:eventName code:nil];
}

+ (NSString *) getEventLabel: (NSString *) eventName code: (NSNumber *)code{
    return code == nil ? eventName : [NSString stringWithFormat:@"%@.c-%@", eventName, code];
}

+ (FlurryEventRecordStatus)logEvent:(NSString *)eventName code: (NSNumber *)code {
    FlurryEventRecordStatus ret = FlurryEventFailed;
    @try {
        ret = [Flurry logEvent:eventName];
    } @catch(NSException * e){
        DDLogError(@"Could not log event with flurry, exception: %@", e);
    }

    // Google Analytics event reporting.
    [self logEventCategory:@"event" action:eventName label:[self getEventLabel:eventName code:code] value:@(1)];
    return ret;
}

+ (void) logUsrEvent:(NSString *)eventName {
    // We may disable logging sensitive user events in the future to protect privacy of users who don't wish publishing of such events.
    [self logUsrEvent:eventName code:nil];
}

+ (void)logUsrEvent:(NSString *)eventName code: (NSNumber *)code {
    // We may disable logging sensitive user events in the future to protect privacy of users who don't wish publishing of such events.
    [self logUsrEvent:eventName category:@"usrEvent" label:[self getEventLabel:eventName code:code] value:@(2)];
}

+ (void)logUsrButton:(NSString *)eventName {
    // We may disable logging sensitive user events in the future to protect privacy of users who don't wish publishing of such events.
    [self logUsrEvent:eventName category:@"buttonClick" label:[self getEventLabel:eventName code:nil] value:@(3)];
}

+ (void) logUsrEvent:(NSString *)eventName category: (NSString *) category label: (NSString *) label value: (NSNumber *) value {
    // We may disable logging sensitive user events in the future to protect privacy of users who don't wish publishing of such events.
    [self logEventCategory:category action:eventName label:label value:value];
}

+ (void) logEventCategory:(NSString *)category action: (NSString *) action label: (NSString *) label value: (NSNumber *) value {
#if PEX_GAI_TRACKING
    @try {
        if (![self wasGaiInitialized]){
            return;
        }

        id <GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category         // Event category (required)
                                                              action:action           // Event action (required)
                                                               label:label            // Event label
                                                               value:value] build]];  // Event value
    } @catch(NSException * e){
        DDLogError(@"Exception in sending event with GAI. %@", e);
    }
#endif
}

+ (void)logScreenName:(NSString *)screenName {
    if ([PEXUtils isEmpty:screenName]){
        return;
    }

#if PEX_GAI_TRACKING
    @try {
        if (![self wasGaiInitialized]){
            return;
        }

        // May return nil if a tracker has not already been initialized with a
        // property ID.
        id tracker = [[GAI sharedInstance] defaultTracker];

        // This screen name value will remain set on the tracker and sent with
        // hits until it is set to a new value or to nil.
        [tracker set:kGAIScreenName value:screenName];

        // New SDK versions
        [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    } @catch(NSException * e){
        DDLogError(@"Exception in sending event with GAI. %@", e);
    }
#endif
}

+ (BOOL)googleAnalyticsEnabledStatus {
    // In an older versions analytics settings were stored in user settings.
    // Now we store it in app prefs so we can init analytics before user logs in, if allowed
    // or not to init at all if GAI is disabled.
    PEXAppPreferences * appPrefs = [PEXAppPreferences instance];
    PEXUserAppPreferences * usrPrefs = [PEXUserAppPreferences instance];

    // Should google analytics be enabled by default ? (if not changed by user explicitly).
    // This is server provided setting, enabling to set analytics by default to yes. For testers/friendly users.
    const BOOL defaultOn =      [appPrefs getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_DEFAULT_ON
                                               defaultValue:PEX_PREF_GOOGLE_ANALYTICS_ENABLED_DEFAULT];

    const BOOL userGaiEnabled = [usrPrefs getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY
                                               defaultValue:defaultOn];

    const BOOL appGaiEnabled =  [appPrefs getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY
                                               defaultValue:defaultOn];

    const BOOL forceOn =        [appPrefs getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON
                                               defaultValue:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON_DEFAULT];

    return forceOn || userGaiEnabled || appGaiEnabled;
}

+ (BOOL) googleAnalyticsForceEnabled {
    PEXAppPreferences * appPrefs = [PEXAppPreferences instance];
    return [appPrefs getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON
                          defaultValue:PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON_DEFAULT];
}

+ (void) setGoogleAnalyticsEnabledByUser: (BOOL) enabled {
    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY
                                                  value:enabled];
    [[PEXAppPreferences instance]     setBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY
                                                  value:enabled];
}

+ (void)checkGoogleAnalyticsEnabledStatus {
#if PEX_GAI_TRACKING
    PEXReport * report = [PEXReport sharedInstance];
    const BOOL analyticsShouldBeEnabled = [self googleAnalyticsEnabledStatus];

    // If GAI was not initialized, 2 cases: disable - already done. enable - initialize first.
    if (!report.googleAnalyticsInitialized){
        DDLogVerbose(@"Analytics is not initialized");

        // If was disabled and now turning to enabled -> initialize it first.
        if (analyticsShouldBeEnabled){
            [report googleAnalyticsInit];
        } else {
            return;
        }
    }

    // If was enabled before and is disabled now, opt out from sending reports. Can be un-initialized.
    [[GAI sharedInstance] setOptOut:!analyticsShouldBeEnabled];
#endif
}

+ (void)logEventAsync:(NSString *)eventName {
    [PEXService executeWithName:nil block:^{
        @try {
            [self logEvent:eventName];
        } @catch(NSException * e){
            DDLogError(@"Could not log event with flurry, exception: %@", e);
        }
    }];
}

+(BOOL) wasGaiInitialized {
    return [[PEXReport sharedInstance] googleAnalyticsInitialized];
}

-(void) flurryInit {
    @synchronized (self) {
        if (self.flurryInitialized){
            DDLogDebug(@"Google analytics already initialized");
            return;
        }

        // Callable only on the shared instance.
        PEXReport * shared = [PEXReport sharedInstance];
        if (shared != self){
            DDLogError(@"Calling analytics initialization outside shared instance!");
            return;
        }

        // IPH-309: Flurry init may cause uncaught exception crash.
        @try {
            BOOL flurryAppStore = ![PEXUtils isEnterprise] && ![PEXUtils isDebug];
            
            FlurrySessionBuilder* builder = [[[[FlurrySessionBuilder new]
                                                withLogLevel:FlurryLogLevelAll]
                                               withCrashReporting:YES]
                                              withSessionContinueSeconds:10];
            [builder withShowErrorInLog:YES];
            
            // Start session
            [Flurry startSession:flurryAppStore ? @PEX_FLURRY_ID_APPSTORE : @PEX_FLURRY_ID_ENTERPRISE withSessionBuilder:builder];
            
            // Use the flurry.
            [Flurry logEvent:@FLURRY_EVT_STATE_START];
            self.flurryInitialized = YES;
            DDLogInfo(@"Flurry initialized, id: %@, appstore Report: %d", [Flurry getSessionID], flurryAppStore);

        } @catch(NSException * ex){
            DDLogError(@"Failed to init flurry due to exception: %@", ex);
        }
    }
}

-(void) googleAnalyticsInit{
    // Check if enabled.
    if (![PEXReport googleAnalyticsEnabledStatus]){
        DDLogVerbose(@"Google analytics is disabled");
        return;
    }

    [self googleAnalyticsInitInternal];
}

-(void) googleAnalyticsInitInternal {
#if PEX_GAI_TRACKING
    @synchronized (self) {
        if (self.googleAnalyticsInitialized){
            DDLogVerbose(@"Google analytics already initialized");
            return;
        }

        // Callable only on the shared instance.
        PEXReport * shared = [PEXReport sharedInstance];
        if (shared != self){
            DDLogError(@"Calling analytics initialization outside shared instance!");
            return;
        }

        // Configure tracker from GoogleService-Info.plist.
        @try {
            NSError *configureError = nil;
            [[GGLContext sharedInstance] configureWithError:&configureError];
            if (configureError != nil) {
                DDLogError(@"Error configuring Google services: %@", configureError);
                return;
            }

            // Optional: configure GAI options.
            GAI *gai = [GAI sharedInstance];

            // In the release mode mode, switch default tracker to production app.
            if (![PEXUtils isDebug]) {
                id <GAITracker> t2 = [[GAI sharedInstance] trackerWithTrackingId:@PEX_GAI_ID_PRODUCTION];
                [[GAI sharedInstance] setDefaultTracker:t2];
                DDLogInfo(@"GAI Default tracker changed to production");
            }

            gai.trackUncaughtExceptions = YES;  // report uncaught exceptions
            gai.logger = [[PEXGAILogger alloc] init];

            // Correct opt out status.
            // May be initialized directly, without checking enabled status. If initialized
            // in disabled state, it should not send any logs -> set opt out.
            const BOOL analyticsShouldBeEnabled = [PEXReport googleAnalyticsEnabledStatus];
            [[GAI sharedInstance] setOptOut:!analyticsShouldBeEnabled];

            self.googleAnalyticsInitialized = YES;
            DDLogVerbose(@"Google analytics initialized, enabled: %d", analyticsShouldBeEnabled);

        } @catch(NSException * e){
            DDLogError(@"Exception when starting google analytics %@", e);
        }
    }
#endif
}

@end

