//
// Created by Matej Oravec on 25/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAppVersionUtils.h"
#import "PEXUtils.h"


@implementation PEXAppVersionUtils {

}

+ (NSString *)fullVersionStringToShow
{
    return [PEXUtils isDebug] ? [NSString stringWithFormat:@"%@ %@", [self fullVersionString], @"BETA"] : [self fullVersionString];
}

+ (NSString *)fullVersionString
{
    return [NSString stringWithFormat:@"%@.%@", [self versionString], [self buildString]];
}

+ (NSString *) bundleIdentifier
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}
+ (NSString *) buildString
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (NSString *) versionString
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}


/**
*
* 1.2.3
*
* 76543.2.10
*
*/
+ (uint64_t)fullVersionStringToCode: (NSString *)fullVersionString
{
    if (fullVersionString == nil || fullVersionString.length == 0){
        return 0;
    }

    NSArray * parts = [fullVersionString componentsSeparatedByString:@"."];
    const NSUInteger plen = parts.count;
    uint64_t retNum = 0ull;
    if (plen == 0){
        return retNum;
    }

    if (plen >= 1){
        retNum |= ((uint64_t) [parts[0] integerValue]) << 24;
    }

    if (plen >= 2){
        retNum |= ((uint64_t) [parts[1] integerValue]) << 16;
    }

    if (plen >= 3){
        retNum |= ((uint64_t) [parts[2] integerValue]);
    }

    return retNum;
}

+ (NSString *)codeToFullVersionString: (const uint64_t) versionCode
{
    const uint64_t builSubNumber = versionCode & 0x000000000000FFFF;
    const uint64_t buildNumber = (versionCode >> 16) & 0x00000000000000FF;
    const uint64_t appNumber = (versionCode >> 24) & 0x000000FFFFFFFFFF;

    // follow fullVersionString !!!!
    return [NSString stringWithFormat:@"%llu.%llu.%llu", appNumber, buildNumber, builSubNumber];
}

@end