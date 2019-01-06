//
// Created by Matej Oravec on 08/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXUser.h"
#import "PEXGuiPresence.h"
#import "PEXPreferencesManager.h"

@protocol PEXPreferenceChangedListener;

// TODO move to PEXUserAppPreferences WHEN ALL USERS HAVE VERSION 1.1.6+
/****************************
*
* USER
*
*****************************/
extern NSString * const PEX_PREF_WANTED_PRESENCE_KEY;
extern NSString * const PEX_PREF_PIN_LOCK_PIN_KEY;
extern NSString * const PEX_PREF_INVALID_PASSWORD_ENTRIES;

// TODO DEPRECATED: remove WHEN ALL USERS HAVE VERSION 1.1.6+
// TODO see PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
extern NSString * const PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY;

extern NSString * const PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY;
extern NSString * const PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY;

/* DEFAULTS */

extern const int PEX_PREF_WANTED_PRESENCE_DEFAULT;
extern NSString * const PEX_PREF_PIN_LOCK_PIN_DEFAULT;

// TODO DEPRECATED: remove WHEN ALL USERS HAVE VERSION 1.1.6+
// TODO see PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT
extern const int PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT;
extern const int PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT;
extern const bool PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_DEFAULT;

/****************************
*
* GLOBAL
*
*****************************/

extern NSString * const PEX_PREF_MESSAGE_MAX_RESEND_ATTEMPTS;
extern NSString * const PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY;
extern BOOL const PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT;
extern NSString * const PEX_PREF_GUI_THEME_KEY;
extern NSString * const PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY;
extern NSString * const PEX_PREF_APPLICATION_LANGUAGE_KEY;

extern NSString * const PEX_PREF_APP_WAS_LAUNCHED_BEFORE_KEY;
extern const bool PEX_PREF_APP_WAS_LAUNCHED_BEFORE_DEFAULT;

// TODO REMOVE WHEN ALL USERS HAVE VERSION 1.1.6+
extern NSString * const PEX_PREF_APP_UPDATED_TO_1_1_6;

/****************************
*
* COMMON
*
*****************************/

// prefix when needed for user / without prefix for global
extern NSString * const PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING;


@interface PEXAppPreferences : NSObject<PEXPreferencesManager>

+ (void) initInstance;
+ (PEXAppPreferences *) instance;

// Generic preference access methods.
-(BOOL) hasKey: (NSString *) key;
-(void) removeKey: (NSString *) key;

- (void) addListener: (id<PEXPreferenceChangedListener>) listener;
- (void) removeListener: (id<PEXPreferenceChangedListener>) listener;

@end