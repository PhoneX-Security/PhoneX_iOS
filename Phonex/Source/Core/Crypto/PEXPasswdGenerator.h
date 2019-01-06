//
// Created by Dusan Klinec on 21.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPasswdGenerator : NSObject
+(NSString *) getHA1: (NSString*) sip password:(NSString *) password;
+(NSString *) getHA1: (NSString*) sip domain: (NSString *) domain password:(NSString *) password;

+(NSString *) generateUserTokenBase: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                        serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset
                            curTime: (int64_t) curTime;

+(NSString *) generateUserAuthToken: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                        serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset
                            curTime: (int64_t) curTime;

+(NSString *) generateUserEncToken: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                       serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset
                        curTime: (int64_t) curTime;

+(NSString *) generateUserTokenBase: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                        serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset;

+(NSString *) generateUserAuthToken: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                        serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset;

+(NSString *) generateUserEncToken: (NSString*) sip ha1: (NSString*) ha1 usrToken: (NSString*) usrToken
                       serverToken: (NSString*) serverToken milliWindow: (int64_t) milliWindow offset: (int) offset;

+(NSString *) generateXMPPPassword: (NSString *) username passwd: (NSString *) passwd;
@end