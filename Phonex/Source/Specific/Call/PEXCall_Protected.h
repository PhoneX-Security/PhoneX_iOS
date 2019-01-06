//
//  PEXCall_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXService.h"
#import "PEXPjManager.h"
#import "PEXDbContact.h"
#import "PEXPjCall.h"

@interface PEXCall ()
{
@protected
    volatile BOOL _terminate;
    volatile BOOL _pickUp;
    pjsua_call_id _callId;
    int _endCallPressedCount;
    BOOL _callDisconnected;

    // Last status code of the session. If call errorred, here is the reason.
    NSNumber * _lastStatusCode;
}

- (void) endInternal;
- (void) preDisconnected;
- (void) postConnected;

- (void) showSas:(PEXPjCall * const)callInfo;
- (void) errorred: (NSNumber * const) errorCode;

#define PEX_GEN_NOTIFY(x) -(void) x
PEX_GEN_NOTIFY(started);
PEX_GEN_NOTIFY(ended);
PEX_GEN_NOTIFY(dialling);
PEX_GEN_NOTIFY(ringing);
PEX_GEN_NOTIFY(connected);
PEX_GEN_NOTIFY(encrypting);
PEX_GEN_NOTIFY(callIsSecure);
PEX_GEN_NOTIFY(callIsInsecure);
PEX_GEN_NOTIFY(disconnected);
PEX_GEN_NOTIFY(declined);
PEX_GEN_NOTIFY(hangUp);

@end
