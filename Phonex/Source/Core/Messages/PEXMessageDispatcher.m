//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMessageDispatcher.h"
#import "PEXMessageManager.h"
#import "PEXDBUserProfile.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbContact.h"
#import "PEXService.h"
#import "PEXMessageProtocolEnvelope.h"
#import "PEXPjManager.h"
#import "PEXMessageManager.h"
#import "PEXUtils.h"
#import "PEXReport.h"
#import "PEXDatabase.h"
#import "PEXDbWatchdog.h"
#import "PEXDbMessageQueue.h"
#import "PEXPjMsgSendAux.h"


@implementation PEXMessageDispatcher {

}
+ (PEXMessageDispatcher *)instance {
    static PEXMessageDispatcher *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (void)dispatchIncomingSipMessageFrom:(NSString *)from to:(NSString *)to mime:(NSString *)mimeType
                                   body:(NSString *)body pjsuaId:(pjsua_acc_id)pjsuaId accName: (NSString *) accName
                                 callId:(pjsua_call_id)callId
                           offlineFlag: (NSString *) offlineFlag offlineDump: (NSString *) offlineDump {

    [PEXService executeWithName:@"dispatchIncomingMessage" block:^{
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        PEXDbUserProfile *acc = [PEXDbUserProfile getProfileWithName:accName cr:cr projection:nil];
        if (acc == nil) {
            PEXUserPrivate * privData = [PEXService instance].privData;
            DDLogError(@"Account is nil for [%@], privData uname: [%@], privData ptr %p", accName, privData.username, privData);
            [PEXReport logEvent:PEX_EVENT_DB_ACC_NOT_FOUND];

            // IPH-319: Generate DB report.
            DDLogError(@"IPH-319 error, dbReport: (%@). DbreadTest: (%d)",
                    [[PEXDatabase instance] genDbLogReport],
                    [PEXDbWatchdog dbReadCheck:privData]);

            // This is a symptom for IPH-319, if acc matches priv data user name, try to continue so message is not lost.
            if (privData != nil && ![PEXUtils isEmpty:privData.username] && ![accName isEqualToString: privData.username]){
                DDLogError(@"Account name differs from private data name, message not for me");
                return;
            }

            [DDLog flushLog];
        }

        NSString * from2 = [PEXSipUri getCanonicalSipContact:from includeScheme:NO];

        // Test for auto-rejecting here. If destination is not in contact list
        // then drop this message.
        PEXDbContact *contact = [PEXDbContact newProfileFromDbSip:cr sip:from2 projection:[PEXDbContact getFullProjection]];
        if (contact == nil) {
            DDLogInfo(@"Message dropped, contact [%@] not found in database.", from2);
            return;
        }

        // Fix for prepended offline text metadata (possibly (not always) added SipServer)
        NSString * body2 = [PEXMessageManager removeOfflineMessageMetadata:body];

        // Create message
        PEXDbMessageQueue * messageToQueue = [[PEXDbMessageQueue alloc] initWithFrom:from2 to:accName isOutgoing:@(NO)];
        messageToQueue.time = [NSDate date];
        messageToQueue.isProcessed = @(NO);
        messageToQueue.mimeType = mimeType;
        messageToQueue.isOffline = @(offlineFlag != nil && [@"1" isEqualToString:offlineFlag]);

        @try {
            PEXMessageProtocolEnvelope * envelope = [PEXMessageProtocolEnvelope createEnvelope:body2];
            messageToQueue.transportProtocolType = @([envelope getProtocolType]);
            messageToQueue.transportProtocolVersion = @([envelope getProtocolVersion]);
            messageToQueue.envelopePayload = [envelope getPayload];
        }
        @catch(NSException * e) {
            DDLogWarn(@"Cannot parse message body, probably old version of sip messages. Exception=%@", e);
            return;
        }

        // Insert the message to the DB.
        DDLogDebug(@"Inserting QueuedMessage in message queue [%@]", messageToQueue);
        [cr insert:[PEXDbMessageQueue getURI] contentValues:[messageToQueue getDbContentValues]];

        // Broadcast the message reception event.
        NSNotificationCenter * center = [NSNotificationCenter defaultCenter];

        // Post notification to the notification center.
        [center postNotificationName:PEX_ACTION_MESSAGE_RECEIVED object:nil userInfo:@{
            PEX_MSGQ_FIELD_FROM : messageToQueue.from,
            PEX_MSGQ_FIELD_IS_OUTGOING : messageToQueue.isOutgoing,
            PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE : messageToQueue.transportProtocolType,
            PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION : messageToQueue.transportProtocolVersion
        }];
    }];
}

- (void)acknowledgmentFromPjSip:(NSString *)to
           returnedFinalMessage:(NSString *)returnedFinalMessage
                       statusOk:(BOOL)statusOk
                reasonErrorText:(NSString *)reasonErrorText
                statusErrorCode:(int)statusErrorCode
{
    [PEXService executeWithName:@"dispatchIncomingMessage" block:^{
        PEXMessageManager * msgMgr = [PEXMessageManager instance];
        [msgMgr acknowledgmentFromPjSip:to returnedFinalMessage:returnedFinalMessage statusOk:statusOk
                        reasonErrorText:reasonErrorText statusErrorCode:statusErrorCode];
    }];
}

- (void)sendMessageImpl:(NSString *)message
              msg2store:(NSString *)msg2store
                 callee:(NSString *)callee
              accountId:(NSNumber *)accountId
                   mime:(NSString *)mime
              messageId:(NSNumber *)messageId
               isResend:(BOOL)isResend
              dbMessage:(PEXDbMessageQueue *) dbMessage

{
    [PEXService executeWithName:@"sendMessage" block:^{
        DDLogDebug(@"will %d message %@", isResend, callee);

        // Calls pjService, which calls underlying c code.
        // Performs actual message send.
        // TODO: refactor to multi user. Use register/central service or something.
        int sendingStatus = PJ_SUCCESS;
        PEXPjMsgSendAux * msgSendAux = [PEXPjMsgSendAux auxWithMsgType:dbMessage.messageProtocolType msgSubType:dbMessage.messageProtocolSubType];
        PEXToCall * result = [[PEXPjManager instance] sendMessage:callee
                                                          message:message
                                                        accountId:accountId
                                                             mime:mime
                                                        msgTypeId:msgSendAux
                                                           status:&sendingStatus
                                                            error:nil];

        PEXMessageSentDescriptor * mDesc = [PEXMessageSentDescriptor descriptorWithMessageId:[messageId longLongValue]
                                                                                   accountId:[accountId longLongValue]
                                                                                     message:message
                                                                                   msg2store:msg2store
                                                                                   recipient:callee
                                                                                    isResend:isResend
                                                                                  sendResult:result];
        mDesc.stackSendStatus = sendingStatus;

        @try {
            [[PEXService instance].msgManager onMessageSent:mDesc];
        } @catch (NSException * t) {
            DDLogError(@"Exception in sendMessage, exception=%@", t);
        }
    }];
}


@end