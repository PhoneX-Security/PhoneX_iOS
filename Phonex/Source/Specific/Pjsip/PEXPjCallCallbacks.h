//
// Created by Dusan Klinec on 12.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pexpj.h"

@class PEXPjCall;

typedef enum PEXCallCallbackUpdateType {
    PEX_CALL_UPDATE_CALL = 0,
    PEX_CALL_UPDATE_MEDIA, // ZRTP belongs here.
} PEXCallCallbackUpdateType;

typedef enum PEXCallCallbackUpdateCode {
    PEX_CALL_UPDATE_CALL_INCOMING = 0,
    PEX_CALL_UPDATE_MAKE_CALL,
    PEX_CALL_UPDATE_CALL_STATE,
    PEX_CALL_UPDATE_MEDIA_STATE,
    PEX_CALL_UPDATE_ZRTP_SHOW_SAS,
    PEX_CALL_UPDATE_ZRTP_SECURE_ON,
    PEX_CALL_UPDATE_ZRTP_SECURE_OFF,
    PEX_CALL_UPDATE_ZRTP_GO_CLEAR,
    PEX_CALL_UPDATE_ON_HOLD,
    PEX_CALL_UPDATE_UN_HOLD,

} PEXCallCallbackUpdateCode;

@protocol PEXPjCallCallbacks <NSObject>
@required
-(void) onCallUpdated: (PEXCallCallbackUpdateType) type updateCode: (int) updateCode
             callInfo: (PEXPjCall *) callInfo event: (pjsip_event *) event;

@optional
-(void) onIncomingCall: (PEXPjCall *) callInfo;
-(void) onCallState: (PEXPjCall *) callInfo event: (pjsip_event *) event;
-(void) onMediaState: (PEXPjCall *) callInfo;
-(void) onZrtpShowSas: (PEXPjCall *) callInfo;
-(void) onZrtpSecureOn: (PEXPjCall *) callInfo;
-(void) onZrtpSecureOff: (PEXPjCall *) callInfo;
-(void) onZrtpGoClear: (PEXPjCall *) callInfo;
-(void) onOnHold: (PEXPjCall *) callInfo;
-(void) onUnHold: (PEXPjCall *) callInfo;
@end