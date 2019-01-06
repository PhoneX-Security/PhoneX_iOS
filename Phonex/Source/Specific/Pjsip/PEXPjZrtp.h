//
// Created by Dusan Klinec on 08.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pjsua-lib/pjsua.h"

@class PEXPjConfig;
@protocol PEXZrtpProtocol;
@class PEXPjZrtpStateInfo;

@interface PEXPjZrtp : NSObject
@property(nonatomic, weak) PEXPjConfig * configuration;
@property(nonatomic) id<PEXZrtpProtocol> delegate;

+ (PEXPjZrtp *)instance;
-(pjmedia_transport*) on_zrtp_transport_created: (pjsua_call_id) call_id
                                      media_idx: (unsigned) media_idx
                                        base_tp: (pjmedia_transport *) base_tp
                                          flags: (unsigned) flags;

-(PEXPjZrtpStateInfo *) getInfoFromTransport: (pjmedia_transport*) tp;
-(PEXPjZrtpStateInfo *)getInfoFromCall: (pjsua_call_id) call_id;

-(void)sasVerified: (pjsua_call_id) call_id;
-(void)sasRevoked: (pjsua_call_id) call_id;

-(void)addEntropy:(const uint8_t *)entropyBuffer entropyBufferLen: (size_t) entropyBufferLen;
-(NSString *)zrtp_call_dump:(pjsua_call_id)call_id indent: (const char *) indent;
@end

/**
* Static C callbacks for ZRTP engine.
*/
static void zrtpShowSas(void* data, char* sas, int verified);
static void zrtpSecureOn(void* data, char* cipher);
static void zrtpSecureOff(void* data);
static void confirmGoClear(void* data);
static void showMessage(void* data, int32_t sev, int32_t subCode);
static void zrtpNegotiationFailed(void* data, int32_t severity, int32_t subCode);
static void zrtpNotSuppOther(void* data);
static void zrtpAskEnrollment(void* data, int32_t info);
static void zrtpInformEnrollment(void* data, int32_t info);
static void signSAS(void* data, uint8_t* sas);
static int32_t checkSASSignature(void* data, uint8_t* sas);
static int32_t checkZrtpHashMatch(void* data, int32_t matchResult);
static void transportDestroy(void* data);