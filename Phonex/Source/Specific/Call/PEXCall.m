//
//  PEXCall.m
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXCall.h"
#import "PEXCall_Protected.h"

#import "PEXPjCallCallbacks.h"
#import "PEXDbContact.h"

@interface PEXCall ()

@property (nonatomic) const PEXDbContact * contact;
@property (nonatomic) NSMutableArray * listeners;

@end

@implementation PEXCall

- (const PEXDbContact *) contact
{
    return _contact;
}

- (id) initWithContact: (const PEXDbContact * const) contact
{
    self = [super init];

    self.contact = contact;
    self.listeners = [[NSMutableArray alloc] initWithCapacity:1];
    _endCallPressedCount = 0;

    return self;
}

- (void) pickUp {/* abstract for incomming */}
- (void) reject{/* abstract */}

- (void) preDisconnected { /* not implemented */ }
- (void) postConnected { /* not implemented */ }

- (void) endInternal
{
    [[PEXANFC instance] hideOngoingCallNotification];
    [self ended];
}

// TODO consider multiple method calls at once
- (void) start { /*abstract*/ }

- (void) addListener: (id<PEXCallListener>) listener
{
    [self.listeners addObject:listener];
}

- (void)onCallUpdated:(PEXCallCallbackUpdateType)type updateCode:(int)updateCode callInfo:(PEXPjCall *)callInfo event:(pjsip_event *)event {
    // We use fine grained.
}

- (void)end {
    // Terminate call in PJ library.
    if (_callId != PJSUA_INVALID_ID && _endCallPressedCount == 0) {
        PEXService *svc = [PEXService instance];
        [svc.pjManager endCallWithId:_callId];
    }

    _endCallPressedCount += 1;

    // If call cannot be destroyed, dismiss dialog after few button presses.
    // If error was indicated to the user, he may want to dismiss dialog manually.
    if (_endCallPressedCount >= 3 || _callDisconnected){
        // Try to terminate call in - last try.
        if (!_callDisconnected && _callId != PJSUA_INVALID_ID){
            DDLogDebug(@"Going to terminate call: %d", _callId);

            // Do not use terminate call now. It is too drastic.
            // May cause inconsistencies in stack. Better wait for expiration of the BYE transaction.
            PEXService *svc = [PEXService instance];
            [svc.pjManager terminateCallWithId:_callId async:YES completionBlock:nil];
        }

        [self endInternal];
    }
}

- (void)onCallState:(PEXPjCall *)callInfo event:(pjsip_event *)event {
    if (callInfo.callState == nil){
        return;
    }

    const long callState = [callInfo.callState integerValue];
    switch (callState) {
        case PJSIP_INV_STATE_INCOMING:
        case PJSIP_INV_STATE_CALLING:
            // Dialing...
            [self dialling];
            break;

        case PJSIP_INV_STATE_EARLY:
            [self ringing];
            break;

        case PJSIP_INV_STATE_CONNECTING:
            [self encrypting];
            [[PEXANFC instance] showOngoingCallNotification];
            break;

        case PJSIP_INV_STATE_CONFIRMED:
            [self connected];
            [self postConnected];  // IPH-362, make sure notification is dismissed.
            break;

        case PJSIP_INV_STATE_DISCONNECTED: {
            [self preDisconnected];

            DDLogVerbose(@"Disconnected %@", callInfo);
            NSNumber * code = callInfo.lastStatusCode;
            const BOOL gsm_busy_remote = callInfo.byeCauseCode != nil && [@(PJSIP_SC_GSM_BUSY) isEqualToNumber:callInfo.byeCauseCode];
            const BOOL gsm_busy_local = callInfo.localByeCode != nil && [@(PJSIP_SC_GSM_BUSY) isEqualToNumber:callInfo.localByeCode];

            // Call ended normally.
            if (!gsm_busy_remote && !gsm_busy_local && (code == nil || [code integerValue] == PEX_CALL_CODE_OK)){
                [self disconnected];
                [PEXService executeDelayedWithName:@"call_disconnected" timeout:3.0 block:^{
                    [self endInternal];
                }];

            } else {
                const int intCode = (int) [code integerValue];
                _lastStatusCode = code;

                BOOL doEndCallView = YES;
                DDLogInfo(@"Call ended unexpectedly: %@", code);

                // Block to be invoked to finish call..
                WEAKSELF;
                dispatch_block_t finishBlock = ^{
                    [weakSelf endInternal];
                };

                if (gsm_busy_local || intCode == PJSIP_SC_GSM_BUSY) {
                    DDLogVerbose(@"Local GSM busy");
                    doEndCallView = NO;
                    [self gsmBusyLocal: finishBlock];

                } else if (gsm_busy_remote){
                    DDLogVerbose(@"Remote GSM busy");
                    doEndCallView = NO;
                    [self gsmBusyRemote: finishBlock];

                } else if (intCode == PEX_CALL_CODE_DECLINE) {
                    [self declined];

                } else if (intCode == PEX_CALL_CODE_REQUEST_TERMINATED || intCode == 407) {
                    [self hangUp];

                } else {
                    _lastStatusCode = code;
                    [self errorred:code];

                }

                // TODO: inspect code here. if 404 or another error state, report it to the user.
                // TODO: reason=603 (Decline)
                // TODO: show error / beep / vibrate, dismiss after 3 seconds or button press.
                if (doEndCallView) {
                    [PEXService executeDelayedWithName:@"call_disconnected_err" timeout:3.0 block:^{
                        finishBlock();
                    }];
                }
            }
        }
            break;

        default:
            break;
    }
}

- (void)onZrtpShowSas:(PEXPjCall *)callInfo {
    DDLogInfo(@"SAS: %@", callInfo);

    // Show ZRTP confirmation dialog only is SAS was not confirmed from previous run.
    if (callInfo != nil && callInfo.zrtpInfo != nil && callInfo.zrtpInfo.sas_verified){
        DDLogVerbose(@"ZRTP verified, not showing dialog. SAS=%@", callInfo.zrtpInfo.sas);
        return;
    }

    // Show ZRTP confirmation dialog.
    [self showSas:callInfo];
}

- (void)onZrtpSecureOn:(PEXPjCall *)callInfo {
    DDLogInfo(@"SecureOn: %@", callInfo);
    // lock phonex logo
    [self callIsSecure];
}

- (void)onZrtpSecureOff:(PEXPjCall *)callInfo {
    DDLogInfo(@"SecureOff: %@", callInfo);
    [self callIsInsecure];
    // 10 phonex logo
    // mic muted
}

-(void) showSas:(PEXPjCall * const)callInfo
{
    for (const id<PEXCallListener> listener in self.listeners)
    {
        [listener showSas: callInfo];
    }
}

- (void) errorred: (NSNumber * const) errorCode
{
    for (const id<PEXCallListener> listener in self.listeners)
    {
        [listener errorred:errorCode];
    }
}

- (void) gsmBusyLocal: (dispatch_block_t) finishBlock
{
    for (const id<PEXCallListener> listener in self.listeners)
    {
        if (listener != nil && [listener respondsToSelector:@selector(gsmBusyLocal:)])
        {
            [listener gsmBusyLocal:finishBlock];
        }
    }
}

- (void) gsmBusyRemote: (dispatch_block_t) finishBlock
{
    for (const id<PEXCallListener> listener in self.listeners)
    {
        if (listener != nil && [listener respondsToSelector:@selector(gsmBusyRemote:)])
        {
            [listener gsmBusyRemote:finishBlock];
        }
    }
}

#define PEX_GEN_NOTIFY_DEF(x) -(void) x \
{ for (const id<PEXCallListener> l in self.listeners) [l x]; }
PEX_GEN_NOTIFY_DEF(started)
PEX_GEN_NOTIFY_DEF(dialling)
PEX_GEN_NOTIFY_DEF(ended)
PEX_GEN_NOTIFY_DEF(ringing)
PEX_GEN_NOTIFY_DEF(connected)
PEX_GEN_NOTIFY_DEF(encrypting)
PEX_GEN_NOTIFY_DEF(callIsSecure)
PEX_GEN_NOTIFY_DEF(callIsInsecure)
PEX_GEN_NOTIFY_DEF(disconnected)
PEX_GEN_NOTIFY_DEF(declined)
PEX_GEN_NOTIFY_DEF(hangUp)
@end
