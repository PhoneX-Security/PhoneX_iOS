//
//  PEXCore.h
//  Phonex
//
//  Created by Dusan Klinec on 15.09.16.
//  Copyright (c) 2016 PhoneX. All rights reserved.
//

#ifndef PEXCore_h
#define PEXCore_h 1

// Define custom macro because DEBUG can be set also to 0 so it is easier to check for debugging flag.
#if defined(DEBUG) && DEBUG==1
#  define PEX_BUILD_DEBUG 1
#  warning "Building in DEBUG mode"
#endif

#if defined(PEX_BUILD_ENT)
#  warning "Building for enterprise distribution"
#endif

#define LOG_LEVEL_DEF ddLogLevel

#ifdef PEX_SECURE_LOGGING
#  define LOG_ASYNC_ENABLED 1
#else
   // Synchronous logging can be enabled by the remote server
#  define LOG_ASYNC_ENABLED (!ddLogSync)
#endif

// Legacy macros
#define DD_LEGACY_MACROS 0

#define PEXDefaultStr (@"<default>")
#define PEXDefaultVal (1337)

// Define if you want to enable STP debugging.
// Warning! This leaks private data. Disable in production.
#define PEX_ENABLE_STP_DEBUG_LOG 0

#endif /* PEXCore_h */

// ---------------------------------------------------------------------------------------------------------------------
// All other imports
#include <assert.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

// Log level related settings
#ifdef PEX_SECURE_LOGGING
#  ifdef DEBUG
    static const DDLogLevel ddLogLevel = LOG_LEVEL_VERBOSE;
    static const int ddLogSync = 1;
#  else
    static const DDLogLevel ddLogLevel = LOG_LEVEL_ERROR;
    static const int ddLogSync = 0;
#  endif
#else
    // Log level is dynamic.
    extern DDLogLevel ddLogLevel;

    // Synchronous logging is dynamic.
    extern int ddLogSync;
#endif

// Base + rest
#import "PEXBase.h"

#import "PEXResStrings.h"
#import "PEXResValues.h"
#import "PEXResColors.h"
#import "PEXResImages.h"
#import "PEXTheme.h"
#import "PEXGuiViewUtils.h"

#import "PEXUserAppPreferences.h"
#import "PEXAppState.h"
#import "PEXDateUtils.h"
#import "PEXCodes.h"

// currently only for gui executors
#import "PEXUnmanagedObjectHolder.h"

#import "PEXGuiNotificationCenter.h"
#import "PEXAppNotificationCenter.h"

#import "PEXGuiAppUtils.h"

#import "pj/config_site.h"

