//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pjsua-lib/pjsua.h"

@class PEXDbMessageQueue;

/**
* Lower level of messaging logic. Called from PJ manager of by message manager.
*/
@interface PEXMessageDispatcher : NSObject
+ (PEXMessageDispatcher *)instance;
- (void) dispatchIncomingSipMessageFrom: (NSString *) from to: (NSString *) to mime: (NSString *) mimeType
                                   body: (NSString *) body pjsuaId: (pjsua_acc_id) pjsuaId accName: (NSString *) accName
                                 callId: (pjsua_call_id) callId
                            offlineFlag: (NSString *) offlineFlag offlineDump: (NSString *) offlineDump;

- (void) acknowledgmentFromPjSip: (NSString *) to
            returnedFinalMessage: (NSString *) returnedFinalMessage
                        statusOk: (BOOL) statusOk
                 reasonErrorText: (NSString *) reasonErrorText
                 statusErrorCode: (int) statusErrorCode;


- (void)sendMessageImpl:(NSString *)message
              msg2store:(NSString *)msg2store
                 callee:(NSString *)callee
              accountId:(NSNumber *)accountId
                   mime:(NSString *)mime
              messageId:(NSNumber *)messageId
               isResend:(BOOL)isResend
              dbMessage:(PEXDbMessageQueue *) dbMessage;
@end