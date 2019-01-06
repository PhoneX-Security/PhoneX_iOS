//
// Created by Dusan Klinec on 02.09.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGAILogger.h"


@implementation PEXGAILogger {

}

#if PEX_GAI_TRACKING
+ (GAILogLevel)getGAILogLevelFromDDLogLevel:(int)logLevel {
    switch (logLevel) {
        default:
        case DDLogLevelError:
            return kGAILogLevelError;
        case DDLogLevelWarning:
            return kGAILogLevelWarning;
        case DDLogLevelInfo:
        case DDLogLevelDebug:
            return kGAILogLevelInfo;
        case DDLogLevelVerbose:
            return kGAILogLevelVerbose;
    }
}

- (GAILogLevel)logLevel {
    return kGAILogLevelInfo;
}

- (void)setLogLevel:(GAILogLevel)logLevel {
    DDLogVerbose(@"Log level set to: %lu", (unsigned long)logLevel);
}

- (void)verbose:(NSString *)message {
    if ([self logLevel] >= kGAILogLevelVerbose){
        DDLogVerbose(@"GAI: %@", message);
    }
}

- (void)info:(NSString *)message {
    if ([self logLevel] >= kGAILogLevelInfo) {
        DDLogInfo(@"GAI: %@", message);
    }
}

- (void)warning:(NSString *)message {
    if ([self logLevel] >= kGAILogLevelWarning) {
        DDLogWarn(@"GAI: %@", message);
    }
}

- (void)error:(NSString *)message {
    if ([self logLevel] >= kGAILogLevelError) {
        DDLogError(@"GAI: %@", message);
    }
}
#endif

@end