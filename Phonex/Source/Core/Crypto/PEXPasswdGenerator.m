//
// Created by Dusan Klinec on 21.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPasswdGenerator.h"
#import "PEXMessageDigest.h"
#import "PEXSipUri.h"
#import "PEXUtils.h"


@implementation PEXPasswdGenerator {

}

+ (NSString *)getHA1:(NSString *)sip password:(NSString *)password {
    NSArray * arr = [sip componentsSeparatedByString:@"@"];
    if (arr==nil || [arr count]!=2){
        DDLogWarn(@"Invalid string, arr=%p", arr);
        return nil;
    }

    return [self getHA1:[arr objectAtIndex:0] domain:[arr objectAtIndex:1] password:password];
}

+(NSString *) getHA1: (NSString*) sip domain: (NSString *) domain password:(NSString *) password {
    NSMutableString * sb = [[NSMutableString alloc] init];
    [sb appendFormat:@"%@:%@:%@", sip, domain, password];
    return [PEXMessageDigest bytes2hex: [PEXMessageDigest md5Message:sb]];
}

+ (NSString *)generateUserTokenBase:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken
                        serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset
                            curTime: (int64_t) curTime{
    // determine current time window
    curTime = curTime < 0 ? [@([[NSDate date] timeIntervalSince1970] * 1000.0) longLongValue] : curTime;
    int64_t curTimeSlot = (int64_t)(floor(curTime / (double)milliWindow)) + offset;

    NSMutableString * sb = [[NSMutableString alloc] init];
    [sb appendFormat:@"%@:%@:%@:%@:%lld:", sip, ha1, usrToken, serverToken, curTimeSlot];
    return sb;
}

+ (NSString *)generateUserAuthToken:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken
                        serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset
                            curTime: (int64_t) curTime{
    NSString * base = [self generateUserTokenBase:sip ha1:ha1 usrToken:usrToken serverToken:serverToken milliWindow:milliWindow offset:offset curTime:curTime];
    NSMutableString * mbase = [NSMutableString stringWithString:base];
    [mbase appendString:@"PHOENIX_AUTH"];

    return [PEXMessageDigest bytes2base64:
            [PEXMessageDigest iterativeHash:[mbase dataUsingEncoding:NSUTF8StringEncoding] iterations:3779 digest:HASH_SHA512]];
}

+ (NSString *)generateUserEncToken:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken
                       serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset
                           curTime: (int64_t) curTime{
    NSString * base = [self generateUserTokenBase:sip ha1:ha1 usrToken:usrToken serverToken:serverToken milliWindow:milliWindow offset:offset curTime:curTime];
    NSMutableString * mbase = [NSMutableString stringWithString:base];
    [mbase appendString:@"PHOENIX_ENC"];

    return [PEXMessageDigest bytes2base64:
            [PEXMessageDigest iterativeHash:[mbase dataUsingEncoding:NSUTF8StringEncoding] iterations:11 digest:HASH_SHA512]];
}

+ (NSString *)generateUserTokenBase:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset {
    return [self generateUserTokenBase:sip ha1:ha1 usrToken:usrToken serverToken:serverToken milliWindow:milliWindow offset:offset curTime:-1];
}

+ (NSString *)generateUserAuthToken:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset {
    return [self generateUserAuthToken:sip ha1:ha1 usrToken:usrToken serverToken:serverToken milliWindow:milliWindow offset:offset curTime:-1];
}

+ (NSString *)generateUserEncToken:(NSString *)sip ha1:(NSString *)ha1 usrToken:(NSString *)usrToken serverToken:(NSString *)serverToken milliWindow:(int64_t)milliWindow offset:(int)offset {
    return [self generateUserEncToken:sip ha1:ha1 usrToken:usrToken serverToken:serverToken milliWindow:milliWindow offset:offset curTime:-1];
}

+ (NSString *)generateXMPPPassword:(NSString *)username passwd:(NSString *)passwd {
    // Parse domain.
    PEXSIPURIParsedSipContact * parsed = [PEXSipUri parseSipContact:username];
    if (parsed == nil || [PEXUtils isEmpty:parsed.domain]){
        DDLogWarn(@"Cannot initialize account, empty domain [%@]", username);
        return @"";
    }

    NSString * ha1b = [self getHA1:username domain:parsed.domain password:passwd];
    return [PEXMessageDigest bytes2hex:[PEXMessageDigest sha256Message:ha1b]];
}

@end