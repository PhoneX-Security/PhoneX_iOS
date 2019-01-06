//
// Created by Matej Oravec on 27/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPreferencesManager.h"
#import "PEXGuiPresence.h"
#import "PEXAppPreferences.h"

extern NSString * const PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY;
extern NSString * const PEX_PREF_SHOW_THANK_YOU_KEY;
extern NSString * const PEX_PREF_SUPPORT_CONTACT_SIP_KEY;
//extern NSString * const PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY;
//extern NSString * const PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_KEY;
extern NSString * const PEX_PREF_USE_TOUCH_ID_KEY;

extern NSString * const PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY;
extern NSString * const PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_KEY;
extern NSString * const PEX_PREF_FIRST_TIME_KEY;
extern NSString * const PEX_PREF_DEBUG_VIEW;
extern const int PEX_PREF_DEBUG_VIEW_DEFAULT;
extern NSString * const PEX_PREF_LOG_LEVEL;
extern NSString * const PEX_PREF_LOG_SYNC;
extern NSString * const PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON;
extern NSString * const PEX_PREF_GOOGLE_ANALYTICS_DEFAULT_ON;
extern const BOOL PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON_DEFAULT;

extern NSString * const PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SHOWN;
extern NSString * const PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SEEN;

extern NSNumber * const PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT;
extern const bool PEX_PREF_SHOW_THANK_YOU_DEFAULT;
extern NSString * const PEX_PREF_SUPPORT_CONTACT_SIP_DEFAULT;
//extern const bool PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_DEFAULT;
//extern const int PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_DEFAULT;
extern const bool PEX_PREF_USE_TOUCH_ID_DEFAULT;
extern const bool PEX_PREF_GOOGLE_ANALYTICS_ENABLED_DEFAULT;
extern const bool PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_DEFAULT;
extern const bool PEX_PREF_FIRST_TIME_DEFAULT;

extern NSString * const PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND;
extern NSString * const PEX_PREF_APPLICATION_MUTE_SOUND_MILLISECOND;
extern NSString * const PEX_PREF_APPLICATION_MUTE_VIBRATIONS_MILLISECOND;
extern NSString * const PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION;
extern NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_MESSAGE;
extern NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_CALL;
extern NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_NOTIFICATION;

extern BOOL const PEX_PREF_APPLICATION_VIBRATE_ON_CALL_DEFAULT;
extern BOOL const PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION_DEFAULT;

extern NSString * const PEX_PREF_APPLICATION_CALL_TONE;
extern NSString * const PEX_PREF_APPLICATION_MESSAGE_TONE;
extern NSString * const PEX_PREF_APPLICATION_MISSED_TONE;
extern NSString * const PEX_PREF_APPLICATION_NOTIFICATION_TONE;

extern NSString * const PEX_PREF_APPLICATION_DEFAULT_HANDSFREE;
extern BOOL PEX_PREF_APPLICATION_DEFAULT_HANDSFREE_DEFAULT;

extern NSString * const PEX_PREF_APPLICATION_PHOTO_COUNTER;
extern NSInteger PEX_PREF_APPLICATION_PHOTO_COUNTER_DEFAULT;

// DEPRECATED See IPH-294
// extern NSString * const PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY;
// extern const bool PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT;

@interface PEXUserAppPreferences : NSObject<PEXPreferencesManager>

+ (PEXUserAppPreferences *) instance;

- (PEX_GUI_PRESENCE) getGuiWantedPresence;
- (void) setGuiWantedPresence:(const NSInteger) guiPresence;

// Generic preference access methods.
-(BOOL) hasKey: (NSString *) key;
-(void) removeKey: (NSString *) key;

+ (NSString*) userKeyFor: (NSString * const) key;
+ (NSString*) userKeyFor: (NSString * const) key user: (NSString * const) username;

// Fine grained properties.
- (BOOL) getDefaultBackupFlagForFiles;
- (BOOL) getDefaultBackupFlagForIdentity;
- (BOOL) getDefaultBackupFlagForDatabase;
@end