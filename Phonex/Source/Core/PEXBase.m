//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXBase.h"
#import "PEXUtils.h"

#ifndef PEX_SECURE_LOGGING
  // Log level is dynamic.
  DDLogLevel ddLogLevel = PEX_DEFAULT_LOG_LEVEL;

  // Synchronous logging is dynamic.
#  ifdef DEBUG
#    warning "Logging is synchronous by default"
     int ddLogSync = 1;
#  else
     int ddLogSync = 0;
#  endif
#endif

@implementation PEXBase {

}

+ (void)loadLogLevelFromPrefs {
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    if (prefs == nil){
        return;
    }

    @try {
        // At first try to load from user preferences.
        NSString *logLevel = [prefs getStringPrefForKey:PEX_PREF_LOG_LEVEL defaultValue:nil];
        if (logLevel != nil){
            [self setLogLevelFromString:logLevel];
            return;
        }

        // If user preferences is nil && private data is loaded, do nothing.
        // User is already logged in and memory & log files could contain sensitive information thus do not trust
        // NSUserDefaults storage.
        if ([[PEXAppState instance] getPrivateData] != nil){
            ddLogLevel = PEX_DEFAULT_LOG_LEVEL;
            return;
        }

        // User is not logged in, probably & user settings are not accessible. In order to be able to set log level
        // from very beginning, in the initialization phase of the application allow NSUSerDefaults settings.
        // But after user login this has to be re-configured from user settings.
        NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
        id logLevelObj = [defaults objectForKey:PEX_PREF_LOG_LEVEL];
        if (logLevelObj != nil && [logLevelObj isKindOfClass:[NSString class]]){
            logLevel = (NSString *) logLevelObj;
            [self setLogLevelFromString:logLevel];
        }

    } @catch(NSException * e){
        DDLogError(@"Exception in setting log level from preferences, %@", e);
    }
}

+ (void) setLogLevelFromString: (NSString *) logLevel {
    if ([PEXUtils isEmpty:logLevel]){
        return;
    }
#ifndef PEX_SECURE_LOGGING
    logLevel = [logLevel lowercaseString];
    if ([@"e" isEqualToString:logLevel]){
        ddLogLevel = DDLogLevelError;
    } else if ([@"w" isEqualToString:logLevel]){
        ddLogLevel = DDLogLevelWarning;
    } else if ([@"i" isEqualToString:logLevel]){
        ddLogLevel = DDLogLevelInfo;
    } else if ([@"d" isEqualToString:logLevel]){
        ddLogLevel = DDLogLevelDebug;
    } else if ([@"v" isEqualToString:logLevel]){
        ddLogLevel = DDLogLevelVerbose;
    } else {
        DDLogError(@"Log level unrecognized: %@", logLevel);
        return;
    }
#endif
}

+ (void) setLogSyncFromPrefs {
    PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
    if (prefs == nil){
        return;
    }

    @try {
        [self setLogSyncFromNumber:@([prefs getIntPrefForKey:PEX_PREF_LOG_SYNC defaultValue:ddLogSync])];
        DDLogInfo(@"Sync logging from prefs, sync: %d", ddLogSync);

    } @catch(NSException * e){
        DDLogError(@"Exception in setting log level from preferences, %@", e);
    }
}

+ (void) setLogSyncFromNumber: (NSNumber *) sync {
    if (sync == nil){
        return;
    }
#ifndef PEX_SECURE_LOGGING
    ddLogSync = [sync integerValue] == 0 ? 0 : 1;
#endif
}

@end
