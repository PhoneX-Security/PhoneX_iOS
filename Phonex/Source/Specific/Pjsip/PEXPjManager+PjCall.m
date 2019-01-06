//
// Created by Dusan Klinec on 12.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjManager+PjCall.h"
#import "PEXPjCall.h"
#import "PEXPjUtils.h"
#include "PEXPjQ850Parser.h"
#import "PEXPjZrtp.h"
#import "PEXPjZrtpStateInfo.h"
#import "PEXConcurrentHashMap.h"
#import "PEXSipUri.h"
#import "PEXPjCallCallbacks.h"
#import "pjsip/sip_event.h"
#import "pjsip/sip_transport.h"
#import "PEXUtils.h"


@implementation PEXPjManager (PjCall)

/**
* Update the call information from pjsip stack by calling pjsip primitives.
*
* @param callId The id to the call to update
* @param e the pjsip_even that raised the update request
*/
-(PEXPjCall *) updateCallInfoFromStack: (pjsua_call_id) callId event: (pjsip_event *)e {
    return [self updateCallInfoFromStack:callId event:e updateCode:nil];
}

/**
 * Atomic way for updating call info via provided block.
 */
-(PEXPjCall *) updateCallInfoInBlock: (pjsua_call_id) callId block: (PEXCallBlock) block {
    PEXPjCall * callInfo;
    if(callId == PJSUA_INVALID_ID){
        DDLogWarn(@"Invalid ID.");
        return nil;
    }

    NSNumber * callIdKey = @(callId);
    @synchronized (self.callRegister) {

        callInfo = [self.callRegister get:callIdKey];
        if (callInfo == nil || [callInfo isKindOfClass:[NSNull class]]){
            callInfo = [[PEXPjCall alloc] init];
            callInfo.callId = callId;
        }

        // We update session infos. callInfo is both in/out and will be updated
        callInfo = block(callInfo);
        [self.callRegister put:callInfo key:callIdKey async:NO];
    }

    return [callInfo copy];
}

-(PEXPjCall *) updateCallInfoFromStack: (pjsua_call_id) callId event: (pjsip_event *)e updateCode: (NSNumber *) updateCode {
    PEXPjCall * callInfo;
    if(callId == PJSUA_INVALID_ID){
        DDLogWarn(@"Invalid ID.");
        return nil;
    }

    callInfo = [self updateCallInfoInBlock:callId block:^PEXPjCall *(PEXPjCall *call) {
        [PEXPjManager updateSessionFromPj:call event:e svc:self updateCode:updateCode];
        return call;
    }];

    return callInfo == nil ? nil : [callInfo copy];
}

-(PEXPjCall *) updateCallInfoHoldStatus: (pjsua_call_id) callId holdStatus: (NSNumber *) holdStatus {
    PEXPjCall * callInfo;
    if(callId == PJSUA_INVALID_ID){
        DDLogWarn(@"Invalid ID.");
        return nil;
    }

    callInfo = [self updateCallInfoInBlock:callId block:^PEXPjCall *(PEXPjCall *call) {
        call.onHoldStatus = holdStatus;
        return call;
    }];

    return callInfo == nil ? nil : [callInfo copy];
}

-(PEXPjCall *) getCallInfo: (pjsua_call_id) callId {
    return [[self.callRegister get:@(callId)] copy];
}

-(void) setCallHangup: (pjsua_call_id) callId localByeCode: (NSNumber *) localByeCode {
    [self.callRegister updateAsync:NO key:@(callId) usingBlock:^(id <NSCopying> aKey, id anObject, BOOL *stop) {
        if (anObject == nil || ![anObject isKindOfClass:[PEXPjCall class]]){
            return;
        }

        PEXPjCall * callInfo = (PEXPjCall *) anObject;
        callInfo.hangupCalled = YES;
        callInfo.localByeCode = localByeCode;
    }];
}

-(void) setCallAnswered: (pjsua_call_id) callId {
    [self.callRegister updateAsync:NO key:@(callId) usingBlock:^(id <NSCopying> aKey, id anObject, BOOL *stop) {
        if (anObject == nil || ![anObject isKindOfClass:[PEXPjCall class]]){
            return;
        }

        PEXPjCall * callInfo = (PEXPjCall *) anObject;
        callInfo.answerCalled = YES;
    }];
}

-(NSArray *) getActiveCalls {
    NSMutableArray * toReturn = [[NSMutableArray alloc] init];
    NSDictionary * dict = [self.callRegister copyData];
    for(NSNumber * key in dict){
        id anObject = dict[key];
        if (![anObject isKindOfClass:[PEXPjCall class]]){
            continue;
        }

        PEXPjCall * call = (PEXPjCall *) anObject;
        if ([call hasCallState:PJSIP_INV_STATE_DISCONNECTED] ||
            [call hasCallState:PJSIP_INV_STATE_NULL]){
            continue;
        }

        [toReturn addObject:[call copy]];
    }

    return [NSArray arrayWithArray:toReturn];
}

-(NSArray *) getActiveCallsIds {
    NSMutableArray * toReturn = [[NSMutableArray alloc] init];
    NSDictionary * dict = [self.callRegister copyData];
    for(NSNumber * key in dict){
        id anObject = dict[key];
        if (![anObject isKindOfClass:[PEXPjCall class]]){
            continue;
        }

        PEXPjCall * call = (PEXPjCall *) anObject;
        if ([call hasCallState:PJSIP_INV_STATE_DISCONNECTED] ||
                [call hasCallState:PJSIP_INV_STATE_NULL]){
            continue;
        }

        [toReturn addObject:@([call callId])];
    }

    return [NSArray arrayWithArray:toReturn];
}

- (NSArray *)getActiveCallsBesidesCallId:(pjsua_call_id)callId {
    NSMutableArray * newActiveCalls = [[NSMutableArray alloc] init];
    NSArray * activeCalls = [self getActiveCalls];
    for(PEXPjCall * call in activeCalls){
        if (call.callId == callId){
            continue;
        }

        [newActiveCalls addObject:call];
    }

    return [NSArray arrayWithArray:newActiveCalls];
}

- (NSArray *)getActiveCallsIdsBesidesCallId:(pjsua_call_id)callId {
    NSMutableArray * newActiveCalls = [[NSMutableArray alloc] init];
    NSArray * activeCalls = [self getActiveCallsIds];
    for(NSNumber * curCallId in activeCalls){
        if ([curCallId isEqualToNumber: @(callId)]){
            continue;
        }

        [newActiveCalls addObject:curCallId];
    }

    return [NSArray arrayWithArray:newActiveCalls];
}

/**
* Update the call session infos
*
* @param session The session to update (input/output). Must have a correct
*                call id set
* @param service PjManager Sip service to retrieve pjsip accounts infos
* @throws SameThreadException
*/
+(void) updateSessionFromPj: (PEXPjCall *) session event: (pjsip_event *) e svc: (PEXPjManager *) service updateCode: (NSNumber *) updateCode {
    DDLogDebug(@"Update call %d", session.callId);
    if (session.callId == PJSUA_INVALID_ID){
        session.callState = @(PJSIP_INV_STATE_DISCONNECTED);
        return;
    }

    pjsua_call_info info;
    pj_status_t status = pjsua_call_get_info(session.callId, &info);
    if (status != PJ_SUCCESS){
        DDLogDebug(@"No call info present in stack. It is disconnected.");
        session.callState = @(PJSIP_INV_STATE_DISCONNECTED);
        return;
    }

    // Transform pjInfo into CallSession object
    [self updateSession:session pjCallInfo:&info];

    if (service != nil){
        session.accId = [service.privData.accountId longValue];
    }

    // Update state here because we have pjsip_event here and can get q.850 state
    if (e != NULL) {
        int status_code = [self get_event_status_code: e];
        if (status_code == 0) {
            status_code = info.last_status;
        }

        session.lastStatusCode = @(status_code);
        session.lastStatusComment = [PEXPjUtils copyToString:&(info.last_status_text)];
    }

    // Reset state information for new calls.
    if (updateCode != nil && (
            [@(PEX_CALL_UPDATE_CALL_INCOMING) isEqualToNumber:updateCode]
            || [@(PEX_CALL_UPDATE_MAKE_CALL) isEqualToNumber:updateCode]))
    {
        session.answerCalled = NO;
        session.hangupCalled = NO;
        session.callStart = nil;
        session.byeCauseCode = nil;
        session.localByeCode = nil;
        session.sipCallId = nil;
    }

    // If call is incoming, switch it.
    if (updateCode != nil && [@(PEX_CALL_UPDATE_CALL_INCOMING) isEqualToNumber:updateCode]){
        session.isIncoming = YES;
    } else if (updateCode != nil && [@(PEX_CALL_UPDATE_MAKE_CALL) isEqualToNumber:updateCode]) {
        session.isIncoming = NO;
    }

    // And now, about secure information.
    // session.setSignalisationSecure(Xvi.call_secure_sig_level(session.getCallId()));

    // ZRTP state info.
    PEXPjZrtp * zrtp = [PEXPjZrtp instance];
    PEXPjZrtpStateInfo * zrtpInfo = [zrtp getInfoFromCall:session.callId];
    session.zrtpSASVerified = zrtpInfo.sas_verified;
    session.hasZrtp = zrtpInfo.secure;
    session.zrtpInfo = zrtpInfo;

    // Media secure info.
    NSString * secureInfo = [service call_secure_media_info:session.callId];
    session.mediaSecureInfo = secureInfo;
    session.mediaSecure = session.hasZrtp && session.zrtpHashMatch != nil && [session.zrtpHashMatch integerValue] > 0;

    int callState = [session.callState integerValue];

    // Reset call start time for new calls as it may interfere with old records.
    if (callState == PJSIP_INV_STATE_INCOMING || callState == PJSIP_INV_STATE_EARLY){
        session.callStart = nil;
    }

    // Call start means call was answered and really started.
    if (callState == PJSIP_INV_STATE_CONFIRMED && session.callStart == nil){
        session.callStart = [NSDate date];
    }

    if (updateCode != nil && [@(PEX_CALL_UPDATE_CALL_STATE) isEqualToNumber:updateCode]){
        if (callState == PJSIP_INV_STATE_EARLY
                || callState == PJSIP_INV_STATE_CONFIRMED
                || callState == PJSIP_INV_STATE_CONNECTING)
        {
            session.remoteSideAnswered = YES;
        }
    }

    // CallID
    if (e != NULL && (callState == PJSIP_INV_STATE_CONNECTING
            || callState == PJSIP_INV_STATE_CONFIRMED
            || callState == PJSIP_INV_STATE_EARLY
            || callState == PJSIP_INV_STATE_CALLING
            || callState == PJSIP_INV_STATE_INCOMING))
    {
        NSString * callId = [PEXPjUtils getCallIdFromEvt:e];
        DDLogVerbose(@"SipCallId: %@, callState: %d, event: %p", callId, callState, e);

        if (![PEXUtils isEmpty:callId]){
            session.sipCallId = callId;
        }
    }

    // If call ended with BYE, try to determine bye cause.
    if (updateCode != nil && [@(PEX_CALL_UPDATE_CALL_STATE) isEqualToNumber:updateCode] && callState == PJSIP_INV_STATE_DISCONNECTED){
        if (e != NULL
                && e->type == PJSIP_EVENT_TSX_STATE
                && e->body.tsx_state.type == PJSIP_EVENT_RX_MSG
                && e->body.tsx_state.src.rdata != NULL
                && e->body.tsx_state.src.rdata->msg_info.msg != NULL)
        {
            NSString * byeCause = [PEXPjUtils searchForHeader:@PEX_HEADER_BYE_TERMINATION inMessage:e->body.tsx_state.src.rdata->msg_info.msg];
            if (![PEXUtils isEmpty:byeCause]){
                DDLogVerbose(@"Bye cause is non-empty: %@", byeCause);
                // Split on the first whitespace
                NSNumber * byeCauseCode = [PEXUtils getAsNumber:[byeCause componentsSeparatedByString:@" "][0]];
                session.byeCauseCode = byeCauseCode;
            }
        }
    }
}

/**
* Copy infos from pjsua call info object to SipCallSession object
*
* @param session    the session to copy info to (output)
* @param pjCallInfo the call info from pjsip
* @param context    PjManager Sip service to retrieve pjsip accounts infos
*/
+(void) updateSession: (PEXPjCall *) session pjCallInfo: (pjsua_call_info *) pjCallInfo {
    // Should be unecessary cause we usually copy infos from a valid.
    session.callId = pjCallInfo->id;

    // Nothing to think about here cause we have a
    // bijection between int / state
    session.callState = @(pjCallInfo->state);
    session.mediaState = @(pjCallInfo->media_status);
    session.remoteContact = [PEXPjUtils copyToString:&(pjCallInfo->remote_info)];
    session.remoteSip = [PEXSipUri getSipFromContact:session.remoteContact];
    session.confPort = pjCallInfo->conf_slot;

    // Try to retrieve sip account related to this call
    pjsua_acc_id pjAccId = pjCallInfo->acc_id;

    // TODO: should be resolved to account id.
    session.accId = (long)pjAccId;

    pj_time_val duration = pjCallInfo->connect_duration;
    session.connectStart = [NSDate dateWithTimeIntervalSinceNow:-(duration.sec + duration.msec/1000.1)];
    session.roleInitiator = pjCallInfo->role == PJSIP_ROLE_UAC;
}

/**
* Get event status code of an event. Including Q.850 processing
*/
+(int) get_event_status_code: (pjsip_event *)e {
    if (e == NULL || e->type != PJSIP_EVENT_TSX_STATE) {
        return 0;
    }

    int retval = get_q850_reason_code(e);
    if (retval > 0) {
        return retval;
    } else {
        return e->body.tsx_state.tsx->status_code;
    }
}

/**
* Get infos for this pjsip call
*
* @param callId pjsip call id
* @return Serialized information about this call
* @throws SameThreadException
*/
+(NSString *) dumpCallInfo: (pjsua_call_id) callId {
    return nil; // TODOL return call_dump.
}

/**
* Get ZRTP infos for this pjsip call
*
* @param callId pjsip call id
* @return Serialized information about this call
* @throws SameThreadException
*/
+(NSString *) dumpZRTPCallInfo: (pjsua_call_id) callId {
    PEXPjZrtp * zrtp = [PEXPjZrtp instance];
    return [zrtp zrtp_call_dump:callId indent:" "];
}

@end