//
//  PEXCall.m
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXOutgoingCall.h"
#import "PEXCall_Protected.h"
#import "PEXService.h"
#import "PEXPjManager.h"
#import "PEXDbContact.h"
#import "PEXPjCall.h"

// TODO listen to some communication layer of the call

// TODO consider inheriting the PEXTAsk

typedef enum PEX_OUTGOING_CALL_STATE {
    PEX_OUTGOING_STATE_PREPARING = 0,
    PEX_OUTGOING_STATE_DIALING,
    PEX_OUTGOING_STATE_CONNECTING,
    PEX_OUTGOING_STATE_CANCELLED,
} PEX_OUTGOING_CALL_STATE;

@interface PEXOutgoingCall () {
    volatile PEX_OUTGOING_CALL_STATE _dialState;
    volatile BOOL _endPressed;
    NSLock * _dialLock;
}
@end

@implementation PEXOutgoingCall

// TODO consider multiple method calls at once
- (id)initWithContact:(const PEXDbContact *const)contact {
    self = [super initWithContact:contact];
    if (self) {
        _callId = PJSUA_INVALID_ID;
        _endCallPressedCount = 0;
        _callDisconnected = NO;
        _dialState = PEX_OUTGOING_STATE_PREPARING;
        _dialLock = [[NSLock alloc] init];
        _endPressed = NO;
    }

    return self;
}

// i.e. start dialing and ringing
- (void) start
{
    [self started];
    _dialState = PEX_OUTGOING_STATE_DIALING;

    // TODO prepare for ringing
    [_dialLock lock];
    _callId = PJSUA_INVALID_ID;
    _endCallPressedCount = 0;
    _callDisconnected = NO;
    PEXService * svc = [PEXService instance];

    // Cancelled meanwhile?
    if (_endPressed){
        _dialState = PEX_OUTGOING_STATE_CANCELLED;
        [_dialLock unlock];
        return;
    }

    // Make call to given contact, it may take a while.
    pj_status_t status = [svc.pjManager makeCallTo:self.contact.sip callId:&_callId];
    if (status != PJ_SUCCESS || _callId == PJSUA_INVALID_ID){
        DDLogWarn(@"Error: cannot make a call, status=%d", status);

        // TODO: display in a nice way, somehow...
        _dialState = PEX_OUTGOING_STATE_CANCELLED;
        [_dialLock unlock];

        // Error happened, connection cannot be made.
        [self errorred: [NSNumber numberWithInt:PEX_CALL_CODE_TEMPORARILY_UNAVAILABLE]];
        return;
    }

    // Register for new callbacks.
    [svc.pjManager registerCallDelegate:@(_callId) delegate:self];

    // Reset end call counter, new call started.
    _endCallPressedCount = 0;
    _dialState = PEX_OUTGOING_STATE_CONNECTING;
    [_dialLock unlock];
}

- (void)end {
    _endPressed = YES;

    // If state is dialing, we cannot cancel the call right now, have to wait for lock.
    if (_dialState == PEX_OUTGOING_STATE_DIALING){
        DDLogDebug(@"<wait_for_dial>");
        [_dialLock lock];   // Thread blocks here until dialing is finished.
        [_dialLock unlock];
        DDLogDebug(@"</wait_for_dial>");

        // TODO: maybe enqueue so UI thread is not blocked.
    }

    // If call was cancelled, dismiss this dialog.
    if (_dialState == PEX_OUTGOING_STATE_CANCELLED){
        _endCallPressedCount = 0;
        [self endInternal];
        return;
    }

    [super end];
}

- (void) dialling
{
    [[PEXANFC instance] showOutgoingCallNotification];

    [super dialling];
}

- (void) encrypting
{
    [[PEXANFC instance] hideOutgoingCallNotification];

    [super encrypting];
}

- (void) preDisconnected
{
    [[PEXANFC instance] hideOutgoingCallNotification];
}

@end
