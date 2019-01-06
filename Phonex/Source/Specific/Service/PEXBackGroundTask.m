//
// Created by Dusan Klinec on 02.11.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXBackGroundTask.h"


@implementation PEXBackGroundTask {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.name = nil;
        self.expirationHandler = nil;
        self.backgroundTaskId = UIBackgroundTaskInvalid;
        self.backgroundTaskStart = nil;
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name {
    self = [self init];
    if (self) {
        self.name = name;
    }

    return self;
}

+ (instancetype)taskWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}


- (instancetype)initWithName:(NSString *)name expirationHandler:(dispatch_block_t)expirationHandler {
    self = [self init];
    if (self) {
        self.name = name;
        self.expirationHandler = expirationHandler;
    }

    return self;
}

+ (instancetype)taskWithName:(NSString *)name expirationHandler:(dispatch_block_t)expirationHandler {
    return [[self alloc] initWithName:name expirationHandler:expirationHandler];
}

- (BOOL) start {
    return [self start:nil];
}

- (BOOL) start: (dispatch_block_t) expirationHandler {
    if (_backgroundTaskId != UIBackgroundTaskInvalid){
        DDLogDebug(@"Already have background task running");
        return NO;
    }

    UIApplication * app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)])
    {
        DDLogVerbose(@"Starting background task %@", self.name);
        _backgroundTaskStart = [NSDate date];
        _backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                DDLogDebug(@"Expiration handler, total background run time: %.1fs", [[NSDate date] timeIntervalSince1970] - [_backgroundTaskStart timeIntervalSince1970]);
                if (expirationHandler != nil){
                    expirationHandler();

                } else if (self.expirationHandler != nil){
                    self.expirationHandler();

                } else if (_backgroundTaskId != UIBackgroundTaskInvalid) {
                    DDLogVerbose(@"Ending background task from expiration handler.");
                    [app endBackgroundTask:_backgroundTaskId];
                    _backgroundTaskId = UIBackgroundTaskInvalid;
                }
            });
        }];

        return _backgroundTaskId != UIBackgroundTaskInvalid;
    }

    return NO;
}

- (BOOL) stop {
    if (_backgroundTaskId == UIBackgroundTaskInvalid){
        return YES;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(endBackgroundTask:)])
    {
        if (_backgroundTaskId != UIBackgroundTaskInvalid)
        {
            DDLogVerbose(@"Ending background task from stop command");
            [app endBackgroundTask:_backgroundTaskId];
            _backgroundTaskId = UIBackgroundTaskInvalid;
            return YES;
        }
    }

    return NO;
}

@end