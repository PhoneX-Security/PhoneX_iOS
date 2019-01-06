//
// Created by Dusan Klinec on 05.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDDLogToFile.h"
#import "PEXSecurityCenter.h"
#import "PEXOpenUDID.h"
#import "PEXUtils.h"


@implementation PEXDDLogToFile {

}

- (id)init {
    self = [super init];
    if (self) {
        self.rollingFrequency = 60 * 60 * 24;
        self.logFileManager.maximumNumberOfLogFiles = 7;
    }

    return self;
}

+ (PEXDDLogToFile *)instance {
    static PEXDDLogToFile *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            // set up file logger One to log to subdirectory "One"
            NSString * logDir = [PEXSecurityCenter getLogDirGeneral];
            DDLogFileManagerDefault *fmgr = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logDir];
            _instance = [[self alloc] initWithLogFileManager:fmgr];
            _instance.rollingFrequency = 60 * 60 * 24;
            _instance.maximumFileSize = 1024ull * 1024ull * 75ull;
            _instance.logFileManager.maximumNumberOfLogFiles = 7;
            DDLogInfo(@"Initialized file logger: %@, fakeUDID=%@, debug=%d", logDir, [PEXOpenUDID value], [PEXUtils isDebug]);
        }
    });

    return _instance;
}

@end