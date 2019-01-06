//
// Created by Dusan Klinec on 12.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Flurry.h"

/**
 * System actions. Monitoring of fails.
 */
FOUNDATION_EXPORT NSString * const PEX_EVENT_DB_RELOADED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_DB_RELOAD_FAILED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_DB_WATCHDOG_ERROR;
FOUNDATION_EXPORT NSString * const PEX_EVENT_DB_WATCHDOG_THRESHOLD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_DB_ACC_NOT_FOUND;
FOUNDATION_EXPORT NSString * const PEX_EVENT_AUTOLOGIN_STARTED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_AUTOLOGIN_FINISHED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_AUTOLOGIN_FAILED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_APP_TERMINATED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_LOGIN_TASK_STARTED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_LOGIN_TASK_FINISHED_SUCC;
FOUNDATION_EXPORT NSString * const PEX_EVENT_LOGIN_TASK_FINISHED_FAIL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_LOGOUT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MEMORY_WARNING;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SIP_RESTART;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SIP_RESTART_FAILED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SIP_REGISTRATION_FAILED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_ERROR_488;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_ERROR_699;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_ERROR_TIMEOUT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_ERROR_GENERIC;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_UNSUPPORTED_STP;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_UNKNOWN_PROTOCOL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_UNKNOWN_TRANSPORT_PROTOCOL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_NULL_PROTOCOL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_UNKNOWN_AMP;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_TEXT_INVALID_SIGNATURE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_MSG_NOTIF_INVALID_SIGNATURE;

/**
 * User actions. Privacy sensitive.
 */
FOUNDATION_EXPORT NSString * const PEX_EVENT_USER_ADDED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_USER_DELETED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_USER_RENAMED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_PASS_CHANGED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_NEW_ACCOUNT_SCREEN;
FOUNDATION_EXPORT NSString * const PEX_EVENT_NEW_ACCOUNT_CREATED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALLED_SOMEONE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_ANSWERED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CALL_REJECTED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SENT_FILE_SOMEONE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_CANCEL_UPLOAD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_FILE_DOWNLOAD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SENT_TEXT_MESSAGE;

FOUNDATION_EXPORT NSString * const PEX_EVENT_PIN_OK;
FOUNDATION_EXPORT NSString * const PEX_EVENT_PIN_FAIL;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_ANSWER_CALL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_REJECT_CALL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_END_CALL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CLEAR_ALL_CALLLOGS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_COMPOSE_BROADCAST_MESSAGE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACTS_ADD_CONTACT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_SHOW_CONTACT_NOTIFICATIONS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_ACTION_CALL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_ACTION_MESSAGE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_ACTION_FILE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_ACTION_SETTINGS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_ADD_CONTACT_ALIAS_CLICKED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_DETAILS_RENAME_CONTACT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_REMEMBER_USERNAME;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGIN_DETAILS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PRODUCT_CODE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_SHOW_PREFERENCES;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHOOSE_PRESENCE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGOUT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_CHOOSE_LANGUAGE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_CHOOSE_THEME;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_TOUCH_ID;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_MESSAGE_ARCHIVE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_SHOW_USER_NAME;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_ENABLE_GOOGLE_ANALYTICS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_CHANGE_PASSWORD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_RECOVERY_MAIL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_TERMS_CONDITIONS;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_SAS_CONFIRM;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_SAS_REJECT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_DELETE_CALLOG_ENTRY;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILE_SELECT_DELETE_FILES;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGOUT_CONFIRM;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGOUT_CANCEL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHANGE_STATUS_CONFIRM;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHANGE_STATUS_CANCEL;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_TAB_CONTACTS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_TAB_CHATS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_TAB_CALLLOG;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_TAB_PROFILE;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_ADD_CONTACT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_RENAME_CONTACT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_RECHECK_CERTIFICATE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGIN;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGIN_CREATE_ACCOUNT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOGS_START_SENDING;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHANGE_PASSWORD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREMIUM_WEB;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREMIUM_SUPPORT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_GET_PREMIUM;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_SEND_LOGS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PROFILE_INVITE_USERS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK_ENABLE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PREFS_PIN_LOCK_DISABLE;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MUTE_MIC;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_LOUDSPEAKER;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_BLUETOOTH;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_KEYBOARD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_SEND;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_SCROLL_DOWN;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_COUNTER;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_CLICKABLE_AREA;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CALLLOG_ACTION;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CALLLOG_REMOVE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHAT_CALL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHAT_FILE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHATS_ACTION;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CHATS_REMOVE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_BCAST_CONTACTS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILE_ACCEPT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILE_CANCEL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILE_REJECT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_POPUP;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_DELETE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PAIRING_ACCEPT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PAIRING_DELETE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_SELECT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_SELECT_CLEAR;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CONTACT_SELECT_NEXT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_PHONEX;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_PHOTOS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_SELECTED;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_NEW_PHOTO;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_UP;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_ACTION;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_SELECTION_CLEAR;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_SELECTION_DELETE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_SELECTION_NEXT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_FILES_CHECK;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_HAS_PRODUCT_CODE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CREATE_ACCOUNT;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CAPTCHA_RELOAD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MAIN_FILE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PIN_NUM;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PIN_DELETE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PIN_DISMISS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PRESENCE_DETAILS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_PRESENCE_STATUS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_NAVIGATION_BACK;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_CLOSE;

FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_POPUP_DETAIL;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_POPUP_COPY;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_POPUP_REMOVE;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_POPUP_FORWARD;
FOUNDATION_EXPORT NSString * const PEX_EVENT_BTN_MSG_POPUP_PREVIEW;

FOUNDATION_EXPORT NSString * const PEX_EVENT_SCREEN_CONTACTS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SCREEN_CHATS;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SCREEN_CALLLOG;
FOUNDATION_EXPORT NSString * const PEX_EVENT_SCREEN_PROFILE;


@interface PEXReport : NSObject
@property (nonatomic) BOOL includeAppVersion;
@property (nonatomic) BOOL includeUsername;
@property (nonatomic) NSString * uName;
@property (nonatomic) NSMutableDictionary * custom;
@property (nonatomic, readonly) BOOL googleAnalyticsInitialized;

+ (PEXReport *)sharedInstance;
- (instancetype)initAppVer:(BOOL)includeAppVersion incUname:(BOOL)includeUsername;
+ (instancetype)reportWith:(BOOL)includeAppVersion incUname:(BOOL)includeUsername;
- (instancetype)initAppVer:(BOOL)includeAppVersion;
+ (instancetype)reportWith:(BOOL)includeAppVersion;
- (instancetype)initAppVersion:(BOOL)includeAppVersion uName:(NSString *)uName;
+ (instancetype)reportWith:(BOOL)includeAppVersion uName:(NSString *)uName;

+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;
- (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;

/**
 * Common event logging. Uses both Flurry and Google Analytics.
 */
+ (FlurryEventRecordStatus)logEvent:(NSString *)eventName;
+ (FlurryEventRecordStatus)logEvent:(NSString *)eventName code: (NSNumber *)code;

+ (void)logEventAsync:(NSString *)eventName;

/*!
 *  @brief Records an app error.
 *  @since 2.7
 *
 *  This method captures an error for reporting to Flurry.
 *
 *  @see #logError:message:exception: for details on capturing exceptions.
 *
 *  @code
 *  - (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
 {
 [Flurry logError:@"WebView No Load" message:[error localizedDescription] error:error];
 }
 *  @endcode
 *
 *  @param errorID Name of the error.
 *  @param message The message to associate with the error.
 *  @param error The error object to report.
 */
+ (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error;
- (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error;

/**
 * Logging of user events - sensitive events that may leak user privacy.
 * In the future we may consider blocking this reporting for some users, e.g., paying premium license.
 *
 * This logging is used for tracking system, user invoked actions, such as call answer, file transfer sending,
 * regardless the path user invoked this action (where he clicked & so on).
 *
 * Uses Google Analytics only, not Flurry (due to its limits for number of events in one session).
 */
+ (void) logUsrEvent:(NSString *)eventName;
+ (void)logUsrEvent:(NSString *)eventName code: (NSNumber *)code;
+ (void) logUsrEvent:(NSString *)eventName category: (NSString *) category label: (NSString *) label value: (NSNumber *) value;

/**
 * Log user pressed a button action
 */
+ (void) logUsrButton:(NSString *)eventName;

/**
 * Event logging wrapper for Google Analytics.
 */
+ (void) logEventCategory:(NSString *)category action: (NSString *) action label: (NSString *) label value: (NSNumber *) value;

/**
 * Logs current screen name to google analytics.
 */
+ (void) logScreenName: (NSString *) screenName;

/**
 * Check user preferences if google analytics is disabled or not.
 * Changes google analytics settings according to the current settings.
 */
+ (void) checkGoogleAnalyticsEnabledStatus;

/**
 * Returns YES if Google analytics is enabled.
 */
+ (BOOL)googleAnalyticsEnabledStatus;

/**
 * Returns YES if Google analytics is enabled by force - cannot be changed to false by user.
 */
+ (BOOL) googleAnalyticsForceEnabled;

/**
 * Disables / enables google analytics in settings.
 * Does not change currently running analytics. In order to apply this change user should also call
 * checkGoogleAnalyticsEnabledStatus.
 */
+ (void) setGoogleAnalyticsEnabledByUser: (BOOL) enabled;

/**
 * Initializes Flurry.
 */
-(void) flurryInit;

/**
 * Initializes google analytics, if enabled.
 * Otherwise does nothing.
 */
-(void) googleAnalyticsInit;

/**
 * Initializes Google analytics regardless it is enabled or disabled in preferences.
 */
-(void) googleAnalyticsInitInternal;
@end