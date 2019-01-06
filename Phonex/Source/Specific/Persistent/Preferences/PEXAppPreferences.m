//
// Created by Matej Oravec on 08/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAppPreferences.h"
#import "PEXUser.h"
#import "openssl/x509.h"
#import "PEXAppVersionUtils.h"
#import "PEXPreferenceChangedListener.h"

// Type of the preference entry.
typedef enum PEXPrefEntryType {
    PEX_PREF_ENTRY_TYPE_STRING=1,
    PEX_PREF_ENTRY_TYPE_NUMBER,
    PEX_PREF_ENTRY_TYPE_BOOL,
    PEX_PREF_ENTRY_TYPE_INT,
    PEX_PREF_ENTRY_TYPE_DOUBLE
} PEXPrefEntryType;

// Represents one preference entry.
@interface PEXPrefEntry : NSObject {}
@property(nonatomic) NSString * key;
@property(nonatomic) id defaultValue;
@property(nonatomic) PEXPrefEntryType type;
- (instancetype)initWithKey:(NSString *)key defaultValue:(id)defaultValue type:(PEXPrefEntryType)type;
+ (instancetype)entryWithKey:(NSString *)key defaultValue:(id)defaultValue type:(PEXPrefEntryType)type;
@end

@implementation PEXPrefEntry
- (instancetype)initWithKey:(NSString *)key defaultValue:(id)defaultValue type:(PEXPrefEntryType)type {
    self = [super init];
    if (self) {
        self.key = key;
        self.defaultValue = defaultValue;
        self.type = type;
    }

    return self;
}

+ (instancetype)entryWithKey:(NSString *)key defaultValue:(id)defaultValue type:(PEXPrefEntryType)type {
    return [[self alloc] initWithKey:key defaultValue:defaultValue type:type];
}
@end

@interface PEXAppPreferences ()

@property (nonatomic) NSUserDefaults * data;
@property (nonatomic) NSMutableDictionary * entries;

@property (nonatomic) NSMutableArray * listeners;
@property (nonatomic) NSLock * listenersLock;

@end

@implementation PEXAppPreferences

- (id)init
{
    self = [super init];

    self.listeners = [[NSMutableArray alloc] init];
    self.listenersLock = [[NSLock alloc] init];

    self.data = [NSUserDefaults standardUserDefaults];
    self.entries = [[NSMutableDictionary alloc] init];
    [self checkInstance];

    return self;
}

- (void) checkInstance
{
    [self createDefaults];
}

// TODO move to PEXUserAppPreferences WHEN ALL USERS HAVE VERSION 1.1.6+
/****************************
*
* USER
*
*****************************/

NSString * const PEX_PREF_WANTED_PRESENCE_KEY = @"wanted_presence";
NSString * const PEX_PREF_PIN_LOCK_PIN_KEY = @"pin_lock_pin";
NSString * const PEX_PREF_INVALID_PASSWORD_ENTRIES = @"invalid_password_entries";
NSString * const PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY = @"pin_lock_time";
NSString * const PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY = @"pin_lock_time_seconds";
NSString * const PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY = @"show_sip_in_contact_list";

const int PEX_PREF_WANTED_PRESENCE_DEFAULT = PEX_GUI_PRESENCE_ONLINE;
NSString * const PEX_PREF_PIN_LOCK_PIN_DEFAULT = nil;
const int PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT = 0;
const int PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT = 0;
const bool PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_DEFAULT = true;


/****************************
*
* GLOBAL
*
*****************************/

NSString * const PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY = @"rememberLoginUsernameKey";
BOOL const PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT = YES;
NSString * const PEX_PREF_GUI_THEME_KEY = @"gui_theme";
NSString * const PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY = @"loginAttemptUsername";
NSString * const PEX_PREF_APPLICATION_LANGUAGE_KEY = @"application_language";

NSString * const PEX_PREF_APP_WAS_LAUNCHED_BEFORE_KEY = @"appWasLaunchedBefore";
const bool PEX_PREF_APP_WAS_LAUNCHED_BEFORE_DEFAULT = false;

static NSString * const DeviceTokenKey = @"DeviceToken";
NSString * const PEX_PREF_MESSAGE_MAX_RESEND_ATTEMPTS = @"message_max_resend_attemts";

NSString * const PEX_PREF_APP_UPDATED_TO_1_1_6 = @"updated_to_1.1.6";

- (void)createDefaults
{
    // Init preference entries with defaults.
    [self prepareEntries];

    // Iterate over entries, if default value is defined, set it.
    DDLogDebug(@"Creating defaults");
    for (NSString * key in self.entries){
        PEXPrefEntry * entry = self.entries[key];
        if (entry.defaultValue == nil){
            continue;
        }

        if (![self hasKey: key]){
            [self.data setObject:entry.defaultValue forKey:key];
        }
    }

    [self.data synchronize];
}

// TODO: GENERALIZE USING setString...?
- (NSString*)deviceToken {
    return [self.data stringForKey:DeviceTokenKey];
}
+ (NSString*)deviceToken {
    return [[self instance] deviceToken];
}
- (void)setDeviceToken:(NSString*)token {
    [self.data setObject:token forKey:DeviceTokenKey];
}
+ (void)setDeviceToken:(NSString*)token {
    [[self instance] setDeviceToken:token];
}

// Register of default values.
- (void) prepareEntries {
    // Common entries.
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_REMEMBER_LOGIN_USERNAME_KEY
                                   defaultValue:@(PEX_PREF_REMEMBER_LOGIN_USERNAME_DEFAULT) type:PEX_PREF_ENTRY_TYPE_BOOL]];
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_LOGIN_ATTEMPT_USERNAME_KEY defaultValue:nil type:PEX_PREF_ENTRY_TYPE_STRING]];
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_GUI_THEME_KEY defaultValue:@(PEX_THEME_LIGHT) type:PEX_PREF_ENTRY_TYPE_INT]];
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_APPLICATION_LANGUAGE_KEY defaultValue:PEX_LANGUAGE_SYSTEM type:PEX_PREF_ENTRY_TYPE_STRING]];
    [self setDefault:[PEXPrefEntry entryWithKey:DeviceTokenKey             defaultValue:nil type:PEX_PREF_ENTRY_TYPE_STRING]];

    // Module entries.
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_MESSAGE_MAX_RESEND_ATTEMPTS defaultValue:@(3) type:PEX_PREF_ENTRY_TYPE_INT]];
    DDLogVerbose(@"Preference entries initialized, count=%lu", (unsigned long)self.entries.count);

    // TODO: DEPRECATED ... REMOVE WHEN ALL USERS HAVE VERSION 1.1.6+
    // Still here because of backward compatible update process
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_WANTED_PRESENCE_KEY
                                   defaultValue:@(PEX_PREF_WANTED_PRESENCE_DEFAULT)
                                           type:PEX_PREF_ENTRY_TYPE_INT]];

    // TODO: DEPRECATED ... REMOVE WHEN ALL USERS HAVE VERSION 1.1.6+
    // Still here because of backward compatible update process
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_PIN_LOCK_PIN_KEY
                                   defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT
                                           type:PEX_PREF_ENTRY_TYPE_STRING]];

    // TODO: DEPRECATED ... REMOVE WHEN ALL USERS HAVE VERSION 1.1.6+
    // Still here because of backward compatible update process
    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY
                                   defaultValue:@(PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT)
                                           type:PEX_PREF_ENTRY_TYPE_INT]];

    [self setDefault:[PEXPrefEntry entryWithKey:PEX_PREF_APP_UPDATED_TO_1_1_6
                                   defaultValue:@false
                                           type:PEX_PREF_ENTRY_TYPE_BOOL]];
}

/****************************
*
* COMMON
*
*****************************/

// prefix when needed for user / without prefix for global
NSString * const PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING = @"app_full_version_string";

// singleton
+ (void) initInstance
{
    [PEXAppPreferences instance];
}

+ (PEXAppPreferences *) instance
{
    static PEXAppPreferences * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXAppPreferences alloc] init];
    });

    return instance;
}

-(BOOL) hasKey: (NSString *) key {
    return [self.data objectForKey:key] != nil;
}

-(void) removeKey: (NSString *) key {
    [self.data removeObjectForKey:key];
}

- (NSString *) getStringPrefForKey: (NSString *) key defaultValue: (NSString *) defaultValue {
    if (![self hasKey:key]) {
        return defaultValue;
    }

    return [self.data objectForKey:key];
}

- (NSNumber *) getNumberPrefForKey: (NSString *) key defaultValue: (NSNumber *) defaultValue {
    if (![self hasKey:key]) {
        return defaultValue;
    }

    return (NSNumber *) [self.data objectForKey:key];
}

- (BOOL) getBoolPrefForKey: (NSString *) key defaultValue: (BOOL) defaultValue {
    if (![self hasKey:key]) {
        return defaultValue;
    }

    NSNumber * n = [self.data objectForKey:key];
    return [n boolValue];
}

- (NSInteger) getIntPrefForKey: (NSString *) key defaultValue: (NSInteger) defaultValue {
    if (![self hasKey:key]){
        return defaultValue;
    }

    NSNumber * n = [self.data objectForKey:key];
    return [n integerValue];
}

- (double) getDoublePrefForKey: (NSString *) key defaultValue: (double) defaultValue {
    if (![self hasKey:key]){
        return defaultValue;
    }

    NSNumber * n = [self.data objectForKey:key];
    return [n doubleValue];
}

- (void) setStringPrefForKey: (NSString *) key value: (NSString *) value {
    [self.data setObject:value forKey:key];
    [self notifyListenersForKeyAsync:key];
}

- (void) setNumberPrefForKey: (NSString *) key value: (NSNumber *) value {
    [self.data setObject:value forKey:key];
    [self notifyListenersForKeyAsync:key];
}

- (void) setBoolPrefForKey: (NSString *) key value: (BOOL) value {
    [self.data setObject:@(value) forKey:key];
    [self notifyListenersForKeyAsync:key];
}

- (void) setIntPrefForKey: (NSString *) key value: (NSInteger) value {
    [self.data setObject:@(value) forKey:key];
    [self notifyListenersForKeyAsync:key];
}

- (void) setDoublePrefForKey: (NSString *) key value: (double) value {
    [self.data setObject:@(value) forKey:key];
    [self notifyListenersForKeyAsync:key];
}

- (void) setDefault: (PEXPrefEntry *) entry {
    self.entries[entry.key] = entry;
}

- (void) addListener: (id<PEXPreferenceChangedListener>) listener
{
    [self.listenersLock lock];
    [self.listeners addObject:listener];
    [self.listenersLock unlock];
}

- (void) removeListener: (id<PEXPreferenceChangedListener>) listener
{
    [self.listenersLock lock];
    [self.listeners removeObject:listener];
    [self.listenersLock unlock];
}

- (void) notifyListenersForKeyAsync:(NSString * const) key
{
    WEAKSELF;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf notifyListenersForKey:key];
    });
}

- (void) notifyListenersForKey:(NSString * const) key
{
    NSArray * copy;

    [self.listenersLock lock];
    copy = [[NSArray alloc] initWithArray:self.listeners];
    [self.listenersLock unlock];

    for (id<PEXPreferenceChangedListener>listener in copy )
    {
        [listener preferenceChangedForKey:key];
    }
}

@end