//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCore.h"

// Return type from methods.
typedef int pex_status;

// Block using for list enumeration.
typedef void (^list_enumerate_block)(id anObject, NSUInteger idx, BOOL *stop);
typedef void (^PEXEnumerateDataDetectorAction)(NSTextCheckingResult * __nullable result, NSMatchingFlags flags, BOOL *stop);

// Block for cancellation detection.
typedef BOOL (^cancel_block)();

// Block for reporting number of read/written blocks.
typedef void (^bytes_processed_block)(NSInteger bytes);

enum pex_status_type {
    PEX_SUCCESS = 0,
};

#ifndef SYSTEM_VERSION_EQUAL_TO
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#endif

#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif

#define WEAKSELF __weak __typeof(self) weakSelf = self

// Logger for RMStore module
#define RMStoreLog(...) DDLogVerbose(@"RMStore: %@", [NSString stringWithFormat:__VA_ARGS__]);

#define PEX_FLURRY_ID_ENTERPRISE "29GP4J4TGWHXG272RNWJ"
#define PEX_FLURRY_ID_APPSTORE "J2W62WXJDKJ3GS3QXBDX"
#define PEX_GAI_ID_PRODUCTION "UA-67027014-2"

#ifdef DEBUG
#define PEX_DEFAULT_LOG_LEVEL DDLogLevelVerbose
#else
#define PEX_DEFAULT_LOG_LEVEL DDLogLevelError
#endif

@interface PEXBase : NSObject
+ (void) loadLogLevelFromPrefs;
+ (void) setLogLevelFromString: (NSString *) logLevel;
+ (void) setLogSyncFromPrefs;
+ (void) setLogSyncFromNumber: (NSNumber *) sync;
@end
