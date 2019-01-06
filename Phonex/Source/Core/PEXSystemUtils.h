//
// Created by Dusan Klinec on 14.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum tWaitResult {
    kWAIT_RESULT_FINISHED = 0,
    kWAIT_RESULT_CANCELLED = 1,
    kWAIT_RESULT_TIMEOUTED = 2
} tWaitResult;

@interface PEXSystemUtils : NSObject
+(NSString *) getDefaultSupportDirectory;
+(NSString *) getDefaultDocsDirectory;
+(NSString *) getDefaultCacheDirectory;
+(NSString *) getDefaultTempDirectory;
+(void)executeOnMain:(dispatch_block_t)block;
+(void)executeOnMainAsync:(BOOL)async block: (dispatch_block_t)block;
+(NSString *) getCurrentThreadKey;
+(NSString *) getCurrentThreadKey: (mach_port_t *) tid;
@end