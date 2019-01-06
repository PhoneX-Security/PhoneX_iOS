//
// Created by Matej Oravec on 26/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGlobalUpdater.h"
#import "PEXAppVersionUtils.h"


@implementation PEXGlobalUpdater {

}

+ (void) updateIfNeeded
{
    NSString * const lastVersionString =
                    [[PEXAppPreferences instance] getStringPrefForKey:PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING
                                                         defaultValue:nil];

    NSString * const currentVersionString = [PEXAppVersionUtils fullVersionString];
    if ([currentVersionString isEqualToString:lastVersionString])
        return;

    const uint64_t lastVersion =
            [PEXAppVersionUtils fullVersionStringToCode:lastVersionString];

    // ACTUAL UPDATE PROCESS

    if (lastVersion < [PEXAppVersionUtils fullVersionStringToCode:@"1.1.6"])
    {
        DDLogVerbose(@"Updating Global to 1.1.6");
    }

    // at last save the last global version
    [[PEXAppPreferences instance] setStringPrefForKey:PEX_PREF_PREVIOUS_APP_FULL_VERSION_STRING
                                                value:currentVersionString];
}

@end