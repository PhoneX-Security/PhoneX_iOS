//
// Created by Matej Oravec on 27/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUserAppPreferences.h"
#import "PEXStringUtils.h"

NSString * const PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY = @"message_archivation";
NSString * const PEX_PREF_SHOW_THANK_YOU_KEY = @"show_thank_you";
NSString * const PEX_PREF_SUPPORT_CONTACT_SIP_KEY = @"support_contact_sip";
//NSString * const PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY = @"licence_update_notification_seen";
//NSString * const PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_KEY = @"licence_epxires_soon_notified_days_before";
NSString * const PEX_PREF_USE_TOUCH_ID_KEY = @"use_touch_id";
NSString * const PEX_PREF_GOOGLE_ANALYTICS_ENABLED_KEY = @"analyticsEnabled";
NSString * const PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_KEY = @"analyticsInfoShown";
NSString * const PEX_PREF_FIRST_TIME_KEY = @"first_time";

NSString * const PEX_PREF_DEBUG_VIEW = @"phxDebugView";
const int PEX_PREF_DEBUG_VIEW_DEFAULT = 0;
NSString * const PEX_PREF_LOG_LEVEL = @"phxLogLevel";
NSString * const PEX_PREF_LOG_SYNC = @"phxLogSync";
NSString * const PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON = @"gaiForceOn";
NSString * const PEX_PREF_GOOGLE_ANALYTICS_DEFAULT_ON = @"gaiDefaultOn";
const BOOL PEX_PREF_GOOGLE_ANALYTICS_FORCE_ON_DEFAULT = NO;

NSString * const PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SHOWN = @"empty_recovery_mail_shown";
NSString * const PEX_PREF_EMPTY_RECOVERY_EMAIL_NOTIFICATION_SEEN = @"empty_recovery_mail_seen";

NSNumber * const PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT = nil;
const bool PEX_PREF_SHOW_THANK_YOU_DEFAULT = true;
NSString * const PEX_PREF_SUPPORT_CONTACT_SIP_DEFAULT = nil;
//const bool PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_DEFAULT = true;
//const int PEX_PREF_LICENCE_EXPIRES_SOON_NOTIFIED_DAYS_BEFORE_DEFAULT = INT_MAX;
const bool PEX_PREF_USE_TOUCH_ID_DEFAULT = false;
const bool PEX_PREF_GOOGLE_ANALYTICS_ENABLED_DEFAULT = false;
const bool PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_DEFAULT = false;
const bool PEX_PREF_FIRST_TIME_DEFAULT = true;

NSString * const PEX_PREF_APPLICATION_MUTE_UNTIL_MILLISECOND = @"mute_until";
NSString * const PEX_PREF_APPLICATION_MUTE_SOUND_MILLISECOND = @"mute_sound_until";
NSString * const PEX_PREF_APPLICATION_MUTE_VIBRATIONS_MILLISECOND = @"mute_vibrations_until";

NSString * const PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION = @"repeat_sound_notification";
NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_MESSAGE = @"vibrate_on_message";
NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_CALL = @"vibrate_on_call";
NSString * const PEX_PREF_APPLICATION_VIBRATE_ON_NOTIFICATION = @"vibrate_on_notification";

BOOL const PEX_PREF_APPLICATION_VIBRATE_ON_CALL_DEFAULT = YES;
BOOL const PEX_PREF_APPLICATION_REPEAT_SOUND_NOTIFICATION_DEFAULT = YES;

NSString * const PEX_PREF_APPLICATION_CALL_TONE = @"call_tone";
NSString * const PEX_PREF_APPLICATION_MESSAGE_TONE = @"message_tone";
NSString * const PEX_PREF_APPLICATION_MISSED_TONE = @"missed_tone";
NSString * const PEX_PREF_APPLICATION_NOTIFICATION_TONE = @"notification_tone";

NSString * const PEX_PREF_APPLICATION_DEFAULT_HANDSFREE = @"allow_handsfree";
BOOL PEX_PREF_APPLICATION_DEFAULT_HANDSFREE_DEFAULT = YES;

NSString * const PEX_PREF_APPLICATION_PHOTO_COUNTER = @"photo_counter";
NSInteger PEX_PREF_APPLICATION_PHOTO_COUNTER_DEFAULT = 0;

// DEPRECATED See IPH-294
// const bool PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT = true;
// NSString * const PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY = @"use_key_chain_for_password";

@implementation PEXUserAppPreferences {

}

+ (PEXUserAppPreferences *) instance
{
    static PEXUserAppPreferences * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXUserAppPreferences alloc] init];
    });

    return instance;
}

+ (NSString*) userKeyFor: (NSString * const) key
{
    return [self userKeyFor:key user:[[PEXAppState instance] getPrivateData].username];
}

+ (NSString*) userKeyFor: (NSString * const) key user: (NSString * const) username
{
    return (key && ![PEXStringUtils isEmpty:key]/* && username && ![PEXStringUtils isEmpty:username]*/) ?
            [NSString stringWithFormat:@"%@_%@", username, key] :
            nil;
}

// USE PEXGuiPresenceCenter to set and access
- (PEX_GUI_PRESENCE) getGuiWantedPresence
{
    return  (PEX_GUI_PRESENCE)
            [self getIntPrefForKey:PEX_PREF_WANTED_PRESENCE_KEY defaultValue:PEX_PREF_WANTED_PRESENCE_DEFAULT];
}

- (void) setGuiWantedPresence:(const NSInteger) guiPresence
{
    [self setIntPrefForKey:PEX_PREF_WANTED_PRESENCE_KEY
                                             value:guiPresence];
}

- (BOOL)hasKey:(NSString *)key {
    return [[PEXAppPreferences instance] hasKey:[PEXUserAppPreferences userKeyFor:key]];
}

- (void)removeKey:(NSString *)key {
    return [[PEXAppPreferences instance] removeKey:[PEXUserAppPreferences userKeyFor:key]];
}

/*******************
*
* setters and getters
*
*******************/

- (NSString *) getStringPrefForKey: (NSString *) key defaultValue: (NSString *) defaultValue {
    return [[PEXAppPreferences instance] getStringPrefForKey:[PEXUserAppPreferences userKeyFor:key] defaultValue:defaultValue];
}

- (NSNumber *) getNumberPrefForKey: (NSString *) key defaultValue: (NSNumber *) defaultValue {
    return [[PEXAppPreferences instance] getNumberPrefForKey:[PEXUserAppPreferences userKeyFor:key] defaultValue:defaultValue];
}

- (BOOL) getBoolPrefForKey: (NSString *) key defaultValue: (BOOL) defaultValue {
    return [[PEXAppPreferences instance] getBoolPrefForKey:[PEXUserAppPreferences userKeyFor:key] defaultValue:defaultValue];
}

- (NSInteger) getIntPrefForKey: (NSString *) key defaultValue: (NSInteger) defaultValue {
    return [[PEXAppPreferences instance] getIntPrefForKey:[PEXUserAppPreferences userKeyFor:key] defaultValue:defaultValue];
}

- (double) getDoublePrefForKey: (NSString *) key defaultValue: (double) defaultValue {
    return [[PEXAppPreferences instance] getDoublePrefForKey:[PEXUserAppPreferences userKeyFor:key] defaultValue:defaultValue];
}

- (void) setStringPrefForKey: (NSString *) key value: (NSString *) value {
    [[PEXAppPreferences instance] setStringPrefForKey:[PEXUserAppPreferences userKeyFor:key] value:value];
}

- (void) setNumberPrefForKey: (NSString *) key value: (NSNumber *) value {
    [[PEXAppPreferences instance] setNumberPrefForKey:[PEXUserAppPreferences userKeyFor:key] value:value];
}

- (void) setBoolPrefForKey: (NSString *) key value: (BOOL) value {
    [[PEXAppPreferences instance] setBoolPrefForKey:[PEXUserAppPreferences userKeyFor:key] value:value];
}

- (void) setIntPrefForKey: (NSString *) key value: (NSInteger) value {
    [[PEXAppPreferences instance] setIntPrefForKey:[PEXUserAppPreferences userKeyFor:key] value:value];
}

- (void) setDoublePrefForKey: (NSString *) key value: (double) value {
    [[PEXAppPreferences instance] setDoublePrefForKey:[PEXUserAppPreferences userKeyFor:key] value:value];
}

- (BOOL)getDefaultBackupFlagForDatabase {
    return NO;
}

- (BOOL)getDefaultBackupFlagForFiles {
    return NO;
}

- (BOOL)getDefaultBackupFlagForIdentity {
    return NO;
}


@end