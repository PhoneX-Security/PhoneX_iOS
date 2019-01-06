//
// Created by Dusan Klinec on 14.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <pthread.h>
#import "PEXSystemUtils.h"
#import "PEXUtils.h"


@implementation PEXSystemUtils {

}

+ (NSString *)getDefaultSupportDirectory {
    NSArray *dirPaths;
    NSString *docsDir;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([PEXUtils isEmptyArr:dirPaths]){
        DDLogError(@"Cannot get support directory");
        return nil;
    }

    docsDir = dirPaths[0];
    return docsDir;
}

+ (NSString *)getDefaultDocsDirectory {
    NSArray *dirPaths;
    NSString *docsDir;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([PEXUtils isEmptyArr:dirPaths]){
        DDLogError(@"Cannot get docs directory");
        return nil;
    }

    docsDir = dirPaths[0];
    return docsDir;
}

+ (NSString *)getDefaultCacheDirectory {
    NSArray *dirPaths;
    NSString *docsDir;
    dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([PEXUtils isEmptyArr:dirPaths]){
        DDLogError(@"Cannot get caches directory");
        return nil;
    }

    docsDir = dirPaths[0];
    return docsDir;
}

+ (NSString *)getDefaultTempDirectory {
    NSString *tmpDir = NSTemporaryDirectory();
    return tmpDir;
}

+ (void)executeOnMain:(dispatch_block_t)block {
    [self executeOnMainAsync:YES block:block];
}

+ (void)executeOnMainAsync:(BOOL)async block: (dispatch_block_t)block {
    if (!block) {
        return;
    } else if ([NSThread isMainThread]) {
        block();
    } else if (async) {
        dispatch_async(dispatch_get_main_queue(), block);
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (NSString *)getCurrentThreadKey {
    return [self getCurrentThreadKey:NULL];
}

+ (NSString *)getCurrentThreadKey:(mach_port_t *)tid {
    NSThread * curThread = [NSThread currentThread];
    NSString * threadName = [curThread name];
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());

    NSString * key = [NSString stringWithFormat:@"t_%@_%d", threadName, machTID];
    if (tid != NULL){
        *tid = machTID;
    }

    return key;
}


@end