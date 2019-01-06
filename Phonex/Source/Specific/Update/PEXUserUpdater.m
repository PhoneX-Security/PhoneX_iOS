//
// Created by Matej Oravec on 26/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXUserUpdater.h"
#import "PEXAppVersionUtils.h"


@implementation PEXUserUpdater

+ (void) updateIfNeeded
{
    NSString * const lastVersionString =
            [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING
                                                 defaultValue:nil];

    NSString * const currentVersionString = [PEXAppVersionUtils fullVersionString];

    // return if update is not needed
    if ([currentVersionString isEqualToString:lastVersionString])
        return;

    const uint64_t lastVersion =
            [PEXAppVersionUtils fullVersionStringToCode:lastVersionString];

    // ACTUAL UPDATE PROCESS
    if (lastVersion < [PEXAppVersionUtils fullVersionStringToCode:@"1.1.6"])
        [self updateTo_1_1_6];

    // at last save the last global version
    [[PEXUserAppPreferences instance] setStringPrefForKey:PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING
                                                value:currentVersionString];
}

+ (void) updateTo_1_1_6
{
    DDLogVerbose(@"Updating User to 1.1.6");
    // move global preferences to the
    // user may update, newly created, newly created (some other already exists)
    // update must preserve previous settings
    // only the first logged

    // newly installed:         general defaults are copied = user defaults
    // update:                  for the first logged in the new version globals are moved to his user preferences
    //                          for others logged before update user-defaults are used
    // new user after update:   moved from global if first logged;

    const bool firstLoggedUserAlreadyUpdated =
            [[PEXAppPreferences instance] getBoolPrefForKey:PEX_PREF_APP_UPDATED_TO_1_1_6 defaultValue:false];

    if (!firstLoggedUserAlreadyUpdated)
    {
        [self moveGlobalsToFristLoggedUser];
    }

    // previously the pinLock lock time was in minutes.
    // For a finer grain we convert it to seconds
    const int triggerTimeMinutes =
            [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY
                                                  defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT];

    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                                 value:triggerTimeMinutes * 60];
}

+ (void) moveGlobalsToFristLoggedUser
{
    // Wanted Presence
    [[PEXUserAppPreferences instance] setGuiWantedPresence:
            [[PEXAppPreferences instance] getIntPrefForKey:PEX_PREF_WANTED_PRESENCE_KEY
                                              defaultValue:PEX_PREF_WANTED_PRESENCE_DEFAULT]];

    [[PEXAppPreferences instance] setIntPrefForKey:PEX_PREF_WANTED_PRESENCE_KEY
                                             value:PEX_PREF_WANTED_PRESENCE_DEFAULT];

    // PIN LOCK key
    [[PEXUserAppPreferences instance] setStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY value:
            [[PEXAppPreferences instance] getStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY
                                                 defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT]];

    [[PEXAppPreferences instance] setStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY
                                                value:PEX_PREF_PIN_LOCK_PIN_DEFAULT];


    // PIN LOCK time
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY value:
            [[PEXAppPreferences instance] getIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY
                                              defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT]];

    [[PEXAppPreferences instance] setIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_KEY
                                             value:PEX_PREF_PIN_LOCK_TRIGGER_TIME_MINUTES_DEFAULT];

    // first logged after update was updated
    [[PEXAppPreferences instance] setBoolPrefForKey:PEX_PREF_APP_UPDATED_TO_1_1_6 value:true];
}

@end