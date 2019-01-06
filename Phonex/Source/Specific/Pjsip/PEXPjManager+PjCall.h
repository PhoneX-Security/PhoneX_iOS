//
// Created by Dusan Klinec on 12.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPjManager.h"

@class PEXPjCall;

typedef PEXPjCall * (^PEXCallBlock)(PEXPjCall *);

@interface PEXPjManager (PjCall)
-(PEXPjCall *) getCallInfo: (pjsua_call_id) callId;
-(void) setCallHangup: (pjsua_call_id) callId localByeCode: (NSNumber *) localByeCode;
-(void) setCallAnswered: (pjsua_call_id) callId;
-(NSArray *) getActiveCalls;
-(NSArray *) getActiveCallsIds;
-(NSArray *) getActiveCallsBesidesCallId: (pjsua_call_id) callId;
- (NSArray *)getActiveCallsIdsBesidesCallId:(pjsua_call_id)callId;
-(PEXPjCall *) updateCallInfoFromStack: (pjsua_call_id) callId event: (pjsip_event *)e;
-(PEXPjCall *) updateCallInfoFromStack: (pjsua_call_id) callId event: (pjsip_event *)e updateCode: (NSNumber *) updateCode;
-(PEXPjCall *) updateCallInfoHoldStatus: (pjsua_call_id) callId holdStatus: (NSNumber *) holdStatus;

+(void) updateSessionFromPj: (PEXPjCall *) session event: (pjsip_event *) e svc: (PEXPjManager *) service updateCode: (NSNumber *) updateCode;
@end