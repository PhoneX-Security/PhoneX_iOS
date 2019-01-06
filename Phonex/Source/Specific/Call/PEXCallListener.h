//
//  PEXOutgoingCallListener.h
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXPjCall.h"

@protocol PEXCallListener <NSObject>

- (void) started;
- (void) ringing;
- (void) dialling;
- (void) connected;
- (void) ended;
- (void) encrypting;
- (void) callIsSecure;
- (void) callIsInsecure;
- (void) showSas: (PEXPjCall * const)callInfo;

- (void) disconnected;
- (void) declined;
- (void) hangUp;
- (void) errorred: (NSNumber * const) errorCode;

@optional
- (void) onHold;
- (void) unHold;
- (void) gsmBusyLocal: (dispatch_block_t) finishBlock;
- (void) gsmBusyRemote: (dispatch_block_t) finishBlock;
@end
