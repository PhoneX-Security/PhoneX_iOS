//
// Created by Dusan Klinec on 02.09.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#if PEX_GAI_TRACKING
#import <Google/Analytics.h>
#endif

#if PEX_GAI_TRACKING
@interface PEXGAILogger : NSObject<GAILogger>
#else
@interface PEXGAILogger : NSObject
#endif

#if PEX_GAI_TRACKING
+(GAILogLevel) getGAILogLevelFromDDLogLevel: (int) logLevel;
#endif
@end