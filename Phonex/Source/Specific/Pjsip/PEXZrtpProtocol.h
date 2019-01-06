//
// Created by Dusan Klinec on 10.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pexpj.h"
#import "PEXPjZrtpInfo.h"
#import "pjsua-lib/pjsua.h"

@protocol PEXZrtpProtocol <NSObject>
-(void) zrtpShowSas: (PEXPjZrtpInfo *) zrtp sas:(NSString *) sas verified:(int) verified;
-(void) zrtpSecureOn: (PEXPjZrtpInfo *) zrtp cipher: (NSString *) cipher;
-(void) zrtpSecureOff:(PEXPjZrtpInfo *) zrtp;
-(void) confirmGoClear:(PEXPjZrtpInfo *) zrtp;
-(void) showMessage:(PEXPjZrtpInfo *) zrtp sev: (int32_t) sev subCode: (int32_t) subCode;
-(void) zrtpNegotiationFailed:(PEXPjZrtpInfo *) zrtp severity: (int32_t) severity subcode: (int32_t) subCode;
-(void) zrtpNotSuppOther:(PEXPjZrtpInfo *) zrtp;
-(void) zrtpAskEnrollment:(PEXPjZrtpInfo *) zrtp info: (int32_t) info;
-(void) zrtpInformEnrollment:(PEXPjZrtpInfo *) zrtp info: (int32_t) info;
-(void) signSAS:(PEXPjZrtpInfo *) zrtp sas: (uint8_t*) sas;
-(int32_t) checkSASSignature:(PEXPjZrtpInfo *) zrtp sas: (uint8_t*) sas;
-(int32_t) checkZrtpHashMatch:(PEXPjZrtpInfo *) zrtp matchResult: (int32_t) matchResult;
@end