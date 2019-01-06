//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAmpDispatcher.h"
#import "PEXDBMessage.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbMessageQueue.h"
#import "PEXProtocols.h"
#import "PEXAmpSimple.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXPbMessage.pb.h"
#import "PEXUtils.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXDecryptedTransportPacket.h"
#import "PEXSendingState.h"
#import "PEXDbContact.h"
#import "PEXSipUri.h"
#import "PEXAppDelegate.h"
#import "PEXService.h"
#import "PEXFirewall.h"
#import "PEXFtUtils.h"
#import "PEXDhKeyGenManager.h"
#import "PEXFtTransferManager.h"
#import "PEXFtDownloadFileParams.h"
#import "PEXSecurityCenter.h"
#import "PEXGuiFileUtils.h"
#import "PEXFtUploadParams.h"
#import "PEXDBUserProfile.h"
#import "PEXDbCallLog.h"
#import "PEXLicenceManager.h"
#import "PEXLicenceInfo.h"
#import "PEXTrialEventTask.h"
#import "PEXDbExpiredLicenceLog.h"
#import "PEXChatAccountingManager.h"
#import "PEXCryptoUtils.h"
#import "PEXReport.h"
#import "pjsip/sip_msg.h"
#import "PEXDbFileTransfer.h"

@implementation PEXAmpDispatcher {

}

/**
* Put text message into MessageQueue
* @param ctx
* @param sipMessageId
*/
+(void) dispatchTextMessage: (int64_t) sipMessageId {
    PEXDbMessage * sipMessage = [PEXDbMessage initById:[PEXDbAppContentProvider instance] messageId:sipMessageId];
    [self dispatchTextMessageObj: sipMessage];
}

/**
* Put text message into MessageQueue
* @param ctx
* @param sipMessage
*/
+(void) dispatchTextMessageObj: (PEXDbMessage *) sipMessage{
    DDLogVerbose(@"Dispatching SipMessage [%@]", sipMessage);

    PEXDbMessageQueue * msg = [PEXDbMessageQueue queueWithFrom:sipMessage.from to:sipMessage.to isOutgoing:@(YES)];
    msg.referencedId = sipMessage.id;
    msg.isOutgoing = sipMessage.isOutgoing;
    msg.time = [NSDate date];

    msg.messageProtocolType = @(PEX_AMP_TEXT);
    msg.messageProtocolVersion = @(PEX_AMP_TEXT_VERSION_AMP_SIMPLE);

    msg.transportProtocolType = @(PEX_STP_SIMPLE);
    msg.transportProtocolVersion = @([self supportedStpSimpleVersion:sipMessage.to]);

    @try {
        NSData * dat = [PEXAmpSimple buildSerializedMessage:sipMessage.body nonce:[sipMessage getOrEstablishRandNum:[PEXDbAppContentProvider instance]]];
        msg.transportPayload = dat;
    } @catch (NSException * e) {
        DDLogError(@"Cannot build AmpSimple message with SipMessage [%@]", sipMessage);
        return;
    }

    [self enqueue:msg];
}

+(PEXProtocolVersion) supportedStpSimpleVersion: (NSString *) remoteContact {
    // No mercy for old devices. No backward compatibility.
    return PEX_STP_SIMPLE_VERSION_3;
}

/**
* Put NewFile notification into MessageQueue. Nonce2 and filename is retrieved from SipMessage
* @param ctx
* @param sipMessageId
*/
+(void) dispatchNewFileNotificationWithID: (int64_t) sipMessageId {
    PEXDbMessage * sipMessage = [PEXDbMessage initById:[PEXDbAppContentProvider instance]
                                             messageId:sipMessageId
                                            projection:[PEXDbMessage getFullProjection]];

    [self dispatchNewFileNotification:sipMessage];
}

/**
* * Put NewFile notification into MessageQueue. Nonce2 and filename is retrieved from SipMessage
* @param ctx
* @param sipMessage
*/
+(void) dispatchNewFileNotification: (PEXDbMessage *) sipMessage {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    if (![PEXDBMessage_MIME_FILE isEqualToString:sipMessage.mimeType]){
        DDLogError(@"Trying to send SipMessage as NewFile notification but its MIME type is different from [%@], msg [%@] ", PEXDBMessage_MIME_FILE, sipMessage);
        [PEXDbMessage setMessageError:cr messageId:[sipMessage.id longLongValue]
                          messageType:PEXDBMessage_MESSAGE_TYPE_ENCRYPT_FAIL
                              errCode:PEXDBMessage_ERROR_ENCRYPT_GENERIC errText:@""];
        return;
    }

    uint32_t sipMessageNonce = [sipMessage getOrEstablishRandNum:cr];

    // Body field stores filename
    PEXPbGeneralMsgNotification * notification = [PEXFtUtils createFileNotification:sipMessage.fileNonce filename:sipMessage.body msgNonce:sipMessageNonce];
    NSData * notificationData = [notification writeToCodedNSData];
    DDLogDebug(@"Dispatching Notification [%@] to user [%@]", notification, sipMessage.to);

    PEXDbMessageQueue * msg = [PEXDbMessageQueue queueWithFrom:sipMessage.from to:sipMessage.to isOutgoing:@(YES)];
    msg.referencedId = sipMessage.id;

    msg.messageProtocolType = @(PEX_AMP_NOTIFICATION_CHAT);
    msg.messageProtocolVersion = @(PEX_AMP_NOTIFICATION_CHAT_VERSION_GENERAL_MSG_NOTIFICATION);

    msg.transportPayload = notificationData;
    msg.transportProtocolType = @(PEX_STP_SIMPLE);
    msg.transportProtocolVersion = @(PEX_STP_SIMPLE_VERSION_3);

    [self enqueue:msg];
}

/**
* Acknowledge that user has read the message (or multiple messages at once)
* @param ctx
* @param from
* @param to
* @param nonces Messages are identified by their nonce-s (aka randNum in SipMessage)
*/
+(void) dispatchReadAckNotification:(NSString *) from to: (NSString *) to nonces: (NSArray *) nonces{
    DDLogDebug(@"Dispatching ReadAck notification for nonces [%@]", nonces);

    if (nonces == nil || nonces.count == 0){
        DDLogWarn(@"No nonces to acknowledge");
        return;
    }

    PEXPbGeneralMsgNotificationBuilder * notificationBuilder = [[PEXPbGeneralMsgNotificationBuilder alloc] init];
    [notificationBuilder setNotifType:PEXPbGeneralMsgNotificationPEXPbNotificationTypeMessageReadAck];
    [notificationBuilder setTimestamp:[PEXUtils currentTimeMillis]];
    [notificationBuilder setNonce:[PEXCryptoUtils secureRandomUInt32:NO]];
    for (NSNumber * num in nonces){
        [notificationBuilder addAckNonces: (uint32_t) [num longLongValue]];
    }

    PEXPbGeneralMsgNotification * notification = [notificationBuilder build];
    NSData * notificationData = [notification writeToCodedNSData];

    PEXDbMessageQueue * msg = [[PEXDbMessageQueue alloc] initWithFrom:from to:to isOutgoing:@(YES)]; // No reference id required
    [msg setMessageProtocolType: @(PEX_AMP_NOTIFICATION)];
    [msg setMessageProtocolVersion: @(PEX_AMP_NOTIFICATION_VERSION_GENERAL_MSG_NOTIFICATION)];
    [msg setMessageProtocolSubType:@((int)PEXPbGeneralMsgNotificationPEXPbNotificationTypeMessageReadAck)];

    // Only authentication is required in this case, use StpSimpleAuth instead of StpSimple
    [msg setTransportProtocolType: @(PEX_STP_SIMPLE_AUTH)];
    [msg setTransportProtocolVersion: @(PEX_STP_SIMPLE_AUTH_VERSION_2)];
    [msg setTransportPayload: notificationData];

    [self enqueue:msg];
}

+(void) dispatchNewFileDownload:(PEXDbMessage *) sipMessage params: (PEXFtDownloadFileParams *) params {
    [self dispatchNewTransfer:sipMessage params:params];
}

/**
* Enqueues message that handles file transfer logic. Download/upload itself.
*/
+(void) dispatchNewFileUpload: (PEXDbMessage *) sipMessage params: (PEXFtUploadParams *) params {
    [self dispatchNewTransfer:sipMessage params:params];
}

+(void) dispatchNewTransfer: (PEXDbMessage *) sipMessage params: (id<NSCoding, NSCopying>) params {
    DDLogDebug(@"Dispatching file transfer, nonce2: %@", sipMessage.fileNonce);

    PEXDbMessageQueue * msg = [[PEXDbMessageQueue alloc] initWithFrom:sipMessage.from to:sipMessage.to isOutgoing:sipMessage.isOutgoing]; // No reference id required
    [msg setReferencedId: sipMessage.id];
    [msg setMessageProtocolType: @(PEX_AMP_FTRANSFER)];
    [msg setMessageProtocolVersion:[sipMessage.isOutgoing boolValue] ? @(PEX_AMP_FTRANSFER_UPLOAD) : @(PEX_AMP_FTRANSFER_DOWNLOAD)];

    // Only authentication is required in this case, use StpSimpleAuth instead of StpSimple
    [msg setTransportProtocolType: @(PEX_STP_FTRANSFER)];
    [msg setTransportProtocolVersion: @(PEX_STP_FTRANSFER_VERSION_1)];

    // Serialize params to transport body.
    [msg setTransportPayload: [NSKeyedArchiver archivedDataWithRootObject:params]];
    [self enqueue:msg];
}

+(void) dispatchMissedCallNotification: (NSString *) from to: (NSString *) to callId: (NSString *) callId{
    DDLogDebug(@"Dispatching missedCall to: %@", to);

    PEXPbGeneralMsgNotificationBuilder * notificationBuilder = [[PEXPbGeneralMsgNotificationBuilder alloc] init];
    [notificationBuilder setNotifType:PEXPbGeneralMsgNotificationPEXPbNotificationTypeMissedCall];
    // Notification of the event + protection against duplicates (only one notification from same contact allowed in the given point in time).
    [notificationBuilder setTimestamp:[PEXUtils currentTimeMillis]];
    // Set nonce so this missed call notification is identified uniquely to avoid duplicate notifications on resends.
    [notificationBuilder setNonce:[PEXCryptoUtils secureRandomUInt32:NO]];
    [notificationBuilder setSipCallId:callId];

    PEXPbGeneralMsgNotification * notification = [notificationBuilder build];
    NSData * notificationData = [notification writeToCodedNSData];

    PEXDbMessageQueue * msg = [[PEXDbMessageQueue alloc] initWithFrom:from to:to isOutgoing:@(YES)]; // No reference id required
    [msg setMessageProtocolType: @(PEX_AMP_NOTIFICATION)];
    [msg setMessageProtocolVersion: @(PEX_AMP_NOTIFICATION_VERSION_GENERAL_MSG_NOTIFICATION)];
    [msg setMessageProtocolSubType:@((int)PEXPbGeneralMsgNotificationPEXPbNotificationTypeMissedCall)];

    // Only authentication is required in this case, use StpSimpleAuth instead of StpSimple
    [msg setTransportProtocolType: @(PEX_STP_SIMPLE_AUTH)];
    [msg setTransportProtocolVersion: @(PEX_STP_SIMPLE_AUTH_VERSION_2)];
    [msg setTransportPayload: notificationData];

    [self enqueue:msg];
}

/**
* Receive transport packet (containing incoming application message) from  transport layer, process
* @param packet
*/
-(void) receive: (PEXDecryptedTransportPacket *) packet{
    DDLogDebug(@"Receiving DecryptedTransportPacket [%@]", packet);

    // Firewall check.
    PEXService * svc = [PEXService instance];
    BOOL allowed = [svc.firewall isMessageAllowedFromRemote:packet.from toLocal:packet.to];
    if (!allowed){
        DDLogWarn(@"Message from [%@] is not allowed!", packet.from);
        return;
    }

    switch (packet.ampType) {
        case PEX_AMP_TEXT:
            [self receiveText:packet];
            break;
        case PEX_AMP_NOTIFICATION:
        case PEX_AMP_NOTIFICATION_CHAT:
            [self receiveNotification:packet];
            break;
        default:
            DDLogError(@"receive() error: unknown amp type for packet [%@]", packet);
            break;
    }
}

/**
* Report sending state of outgoing message
* @param queuedMessage
* @param sendingState
*/
-(void) reportState: (PEXDbMessageQueue *) queuedMessage sendingState: (PEXSendingState *) sendingState{
    DDLogDebug(@"Reporting state [%@] for queued message [%@]", sendingState, queuedMessage);
    if (queuedMessage.messageProtocolType == nil) {
        DDLogError(@"Null message proto type");
        return;
    }

    switch ([queuedMessage.messageProtocolType integerValue]){
        case PEX_AMP_TEXT:
            if (queuedMessage.referencedId != nil) {
                [self reportSipMessageState:[queuedMessage.referencedId longLongValue] sendingState:sendingState];
            } else {
                DDLogWarn(@"Cannot report notification state, no ref id");
            }

        break;
        case PEX_AMP_NOTIFICATION:
        case PEX_AMP_NOTIFICATION_CHAT:
            @try {
                // transport payload is either stored as Base64 encoded Protobuf msg + serialized to bytes (messaging v1)
                // or only as serialized Protobuf msg (messaging v2)
                // we can differentiate according to used S/MIME (v1 version uses S/MIME)
                NSData * transportPayload = queuedMessage.transportPayload;

                if (queuedMessage.referencedId != nil) {
                    PEXPbGeneralMsgNotification *notification = [PEXPbGeneralMsgNotification parseFromData:transportPayload];
                    [self reportNotificationState:[queuedMessage.referencedId longLongValue] notification:notification state:sendingState];
                } else {
                    DDLogWarn(@"Cannot report notification state, no ref id");
                }

            } @catch (NSException * e) {
                DDLogError(@"reportState: Cannot decode transport payload  from msg [%@], exception=%@", queuedMessage, e);
            }
        break;
    }
}

+(BOOL) hasMessagingCapability: (NSString *) remoteSip capability: (NSString *) capability{
    @try { // rather be defensive
        PEXDbContact * profile = [PEXDbContact newProfileFromDbSip:[PEXDbAppContentProvider instance] sip:remoteSip
                                                        projection:[PEXDbContact getFullProjection]];
        return [profile hasCapability:capability];
    } @catch (NSException * ex){
        DDLogError(@"Error while determining user messaging capabilities, exception=%@", ex);
        return false;
    }
}

-(void) reportNotificationState: (int64_t) messageId notification: (PEXPbGeneralMsgNotification *) notification state: (PEXSendingState *) state {
    switch (notification.notifType) {
        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeNewFile:
            // new file is reported back to SipMessage
            [self reportSipMessageState:messageId sendingState:state];
            break;
        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeMessageReadAck:
            // After sending Ack, we do not care anymore
            break;
        default:
            DDLogInfo(@"reportNotificationState: Currently unsupported notification type [%d]", (int)notification.notifType);
            break;
    }
}

-(void) reportSipMessageState: (int64_t) messageId sendingState: (PEXSendingState *) sendingState{
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    switch (sendingState.type){
        case PEX_STT_SENDING:
            [PEXDbMessage setMessageType:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_PENDING];
            break;

        case PEX_STT_ACK_POSITIVE:
        {
            [self outgoingMessageWasAcknowledged:messageId forState:sendingState];
            break;
        }

        case PEX_STT_ACK_NEGATIVE:
        {
            PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
            // store of what type of error happened
            [cv put:PEXDBMessage_FIELD_ERROR_CODE integer:sendingState.pjsipErrorCode];
            [cv put:PEXDBMessage_FIELD_ERROR_TEXT string:sendingState.pjsipErrorText];
            [PEXDbMessage updateMessage:cr messageId:messageId contentValues:cv];

            // do not update type, reason:
            // we do not change PENDING message type until we reach max num of resends, so user is not disturbed by seeing message resend repeatedly
            // update to MESSAGE_TYPE_FAILED happens only after FAILED_REACHED_MAX_NUM_OF_RESENDS is reached
            break;
        }

        case PEX_STT_FOR_BACKOFF:
        {
            PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
            [cv put:PEXDBMessage_FIELD_TYPE integer:PEXDBMessage_MESSAGE_TYPE_QUEUED_BACKOFF];
            [cv put:PEXDBMessage_FIELD_RESEND_DATE date:sendingState.resendTime];
            [PEXDbMessage updateMessage:cr messageId:messageId contentValues:cv];
            break;
        }

        case PEX_STT_FAILED_INVALID_DESTINATION:
            [PEXDbMessage setMessageError:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_ENCRYPT_FAIL errCode:0 errText:@""];
            break;

        case PEX_STT_FAILED_MISSING_REMOTE_CERT:
            [PEXDbMessage setMessageError:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_ENCRYPT_FAIL errCode:PEXDBMessage_ERROR_MISSING_CERT errText:@""];
            break;

        case PEX_STT_FAILED_REACHED_MAX_NUM_OF_RESENDS:
            [PEXDbMessage setMessageError:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_FAILED errCode:0 errText:@""];
            break;

        case PEX_STT_FAILED_CANNOT_SEND:
            [PEXDbMessage setMessageError:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_FAILED errCode:-10 errText:@""];
            break;

        case PEX_STT_FAILED_GENERIC:
            [PEXDbMessage setMessageError:cr messageId:messageId messageType:PEXDBMessage_MESSAGE_TYPE_ENCRYPT_FAIL errCode:PEXDBMessage_ERROR_ENCRYPT_GENERIC errText:@""];
            break;

        default:
            DDLogVerbose(@"Sending state [%@] is not propagated to SipMessage", sendingState);
            break;
    }
}

- (void) outgoingMessageWasAcknowledged: (const uint64_t) messageId
                               forState: (const PEXSendingState * const) sendingState
{
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_ERROR_CODE integer:sendingState.pjsipErrorCode];
    [cv put:PEXDBMessage_FIELD_ERROR_TEXT string:sendingState.pjsipErrorText];
    [cv put:PEXDBMessage_FIELD_TYPE integer:PEXDBMessage_MESSAGE_TYPE_SENT];

    if (sendingState.pjsipErrorCode == PJSIP_SC_ACCEPTED){
        [cv put:PEXDBMessage_FIELD_IS_OFFLINE boolean:YES];
    }

    PEXDbContentProvider * const dbProvider = [PEXDbAppContentProvider instance];

    [PEXDbMessage updateMessage:dbProvider messageId:messageId contentValues:cv];

    PEXAppState * const appState = [PEXAppState instance];

    PEXDbMessage * const message = [self getMesageWithId:messageId];

    // TODO on files
    if (message && ![self mesageWasSentToSupport:message])
    {
        if (message.isFile)
        {
            PEXDbCursor * const cursor = [dbProvider query:[PEXDbFileTransfer getURI]
           projection:[PEXDbFileTransfer getFullProjection]
            selection:[NSString stringWithFormat:@"WHERE %@ = ?", PEX_DBFT_FIELD_MESSAGE_ID]
        selectionArgs:@[@(messageId)]
            sortOrder:nil];

            if (cursor && [cursor moveToNext])
            {
                const PEXDbFileTransfer * const transfer = [[PEXDbFileTransfer alloc] initWithCursor:cursor];

                if (transfer)
                {
                    [[[PEXService instance] licenceManager] outgoingFilesAckedOn:message.sendDate withCount:[transfer.numOfFiles longLongValue]];
                }

            }
        }
        else
        {
            PEXTrialEventTask *const task = [[PEXTrialEventTask alloc] init];
            [task requestUserInfo:[[PEXAppState instance] getPrivateData]
                        eventType:PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE
                      cancelBlock:nil
                              res:nil];

            [[[PEXService instance] licenceManager] outgoingMessageInExpiredModeAckedOn:message.sendDate];
        }
    }

}

- (PEXDbMessage *) getMesageWithId: (const uint64_t) messageId {

    PEXDbMessage * result = nil;

    PEXDbCursor *const cursor = [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getLightProjection]
        selection:[PEXDbMessage getWhereForId]
    selectionArgs:[PEXDbMessage getWhereForIdArgs:@(messageId)]
        sortOrder:nil];

    if (cursor && cursor.moveToNext) {
        PEXDbMessage *const message = [PEXDbMessage messageFromCursor:cursor];

        result = message;
    }

    return result;
}

- (bool) mesageWasSentToSupport: (const PEXDbMessage * const) message
{
    bool result = false;
    NSString * const supportSip =
            [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_SUPPORT_CONTACT_SIP_KEY
                                                     defaultValue:PEX_PREF_SUPPORT_CONTACT_SIP_DEFAULT];



    if (supportSip && [message.to isEqualToString:supportSip])
    {
        result = true;
    }

    return result;
}


-(void) receiveNotification: (PEXDecryptedTransportPacket *) packet {
    DDLogDebug(@"receiving Notification packet [%@]", packet);

    switch (packet.ampVersion) {
        case PEX_AMP_NOTIFICATION_VERSION_GENERAL_MSG_NOTIFICATION: {
            PEXPbGeneralMsgNotification * notification = nil;
            @try {
                notification = [PEXPbGeneralMsgNotification parseFromData:packet.payload];
            } @catch (NSException * e) {
                DDLogError(@"Cannot parse GeneralMsgNotification, data [%@]", packet);
            }

            [self processGeneralMsgNotification:notification packet:packet];
            break;
        }
        default:
            DDLogError(@"receiveNotification() error: unknown amp version for data [%@]", packet);
            break;
    }
}

-(void) receiveText: (PEXDecryptedTransportPacket *) packet {
    DDLogDebug(@"receiving Text packet [%@]", packet);
    NSString * messagePlaintext;

    if ([self isSipMessageDuplicate:packet.transportPacketHash from:packet.from to:packet.to]){
        DDLogInfo(@"Message is already stored");
        return;
    }

    uint32_t msgNonceId;

    // process message itself
    switch (packet.ampVersion) {
        case PEX_AMP_TEXT_VERSION_PLAINTEXT:
            messagePlaintext = [[NSString alloc] initWithData: packet.payload encoding:NSUTF8StringEncoding];
            msgNonceId = packet.nonce == nil ? 0 : (uint32_t)[packet.nonce longLongValue]; // in case of plaintext, it stores no nonce-id, so we take nonce from lower transport layer (backward comp)
            break;

        case PEX_AMP_TEXT_VERSION_AMP_SIMPLE:
            @try {
                PEXAmpSimple * ampSimple = [PEXAmpSimple loadMessage:packet.payload];
                messagePlaintext = ampSimple.message;

                NSNumber * numNonce = (ampSimple.nonce != nil) ? ampSimple.nonce : packet.nonce; // if nonce is missing, take one from transport layer (backward comp)
                msgNonceId = numNonce == nil ? 0 : (uint32_t)[numNonce longLongValue];
            } @catch (NSException * e) {
                DDLogError(@"Cannot Decode AmpSimple message, data [%@]", packet);
                return;
            }
            break;
        default:
            [PEXReport logEvent:PEX_EVENT_MSG_UNKNOWN_AMP];
            DDLogError(@"ReceiveNotification() error: unknown amp version data [%@]", packet);
            return;
    }

    if ([PEXUtils isEmpty:messagePlaintext]){
        DDLogWarn(@"Received empty plaintext, suspicious, do not store such message.");
        return;
    }

    NSString * from = [PEXSipUri getCanonicalSipContact:packet.from includeScheme:NO];
    NSString * to = [PEXSipUri getCanonicalSipContact:packet.to includeScheme:NO];

    // Insert plaintext as SipMessage
    PEXDbMessage * sipMessage = [[PEXDbMessage alloc] initWithFrom:from
                                                                to:to
                                                           contact:from
                                                              body:messagePlaintext
                                                          mimeType:PEXDBMessage_SECURE_MSG_MIME
                                                              date:[NSDate date]
                                                              type:@(PEXDBMessage_MESSAGE_TYPE_INBOX)
                                                          fullFrom:from];

    [sipMessage setIsOffline:packet.isOffline];
    [sipMessage setBodyHash:packet.transportPacketHash];
    [sipMessage setSendDate:[PEXUtils dateFromMillis: (uint64_t)[packet.sendDate longLongValue]]];
    [sipMessage setRead: @(NO)];
    [sipMessage setIsOutgoing:@(NO)];
    [sipMessage setBodyDecrypted:messagePlaintext];
    [sipMessage setRandNum: @(msgNonceId)];

    // Security properties
    [sipMessage setSignatureOK:@(packet.macValid && packet.signatureValid)];

    if (!packet.isValid){
        DDLogWarn(@"Received SipMessage is not valid [%@]", packet);
        [sipMessage setDecryptionStatus:@(PEXDBMessage_DECRYPTION_STATUS_DECRYPTION_ERROR)];
        [sipMessage setErrorCode:@(PEXDBMessage_ERROR_DECRYPT_GENERIC)];
        [PEXReport logEvent:PEX_EVENT_MSG_TEXT_INVALID_SIGNATURE];

    } else {
        [sipMessage setDecryptionStatus:@(PEXDBMessage_DECRYPTION_STATUS_OK)];
    }

    DDLogDebug(@"Storing SipMessage in db [%@]", sipMessage);
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    [cr insert:[PEXDbMessage getURI] contentValues:[sipMessage getDbContentValues]];

    // Notify android OS of the new message - display in Notification bar
    [self notifyOfUnreadSipMessage:sipMessage];
}

-(void) receiveTransfer: (PEXDbMessageQueue *) msg {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    NSNumber * refId = msg.referencedId;
    int64_t    msgId = [refId longLongValue];
    if (refId == nil) {
        DDLogError(@"Referenced id is nil!");
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    // Try to fetch referenced message so we obtain nonce2 and additional transfer details.
    PEXDbMessage * dbMsg = [PEXDbMessage initById:cr messageId:msgId];
    if (dbMsg == nil){
        DDLogError(@"Referenced message could not be found, id=%lld", msgId);
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    // Deserialize upload parameters from transfer payload.
    PEXFtDownloadFileParams * params = nil;
    @try {
        params = [NSKeyedUnarchiver unarchiveObjectWithData:msg.transportPayload];
    } @catch(NSException * e){
        DDLogError(@"Could not deserialize upload parameters");
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    params.queueMsgId = msg.id;
    PEXFtTransferManager * mgr = [PEXFtTransferManager instance];
    [mgr enqueueFile2Download:params];
}

- (void)transmitTransfer:(PEXDbMessageQueue *)msg {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    NSNumber * refId = msg.referencedId;
    int64_t    msgId = [refId longLongValue];
    if (refId == nil) {
        DDLogError(@"Referenced id is nil!");
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    // Try to fetch referenced message so we obtain nonce2 and additional transfer details.
    PEXDbMessage * dbMsg = [PEXDbMessage initById:cr messageId:msgId];
    if (dbMsg == nil){
        DDLogError(@"Referenced message could not be found, id=%lld", msgId);
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    // Deserialize upload parameters from transfer payload.
    PEXFtUploadParams * params = nil;
    @try {
        params = [NSKeyedUnarchiver unarchiveObjectWithData:msg.transportPayload];
    } @catch(NSException * e){
        DDLogError(@"Could not deserialize upload parameters");
        PEXSendingState * state = [[PEXSendingState alloc] initWithType:PEX_STT_FAILED_GENERIC pjsipErrorCode:-1 pjsipErrorText:nil];
        [self reportState:msg sendingState:state];
        return;
    }

    params.queueMsgId = msg.id;
    PEXFtTransferManager * mgr = [PEXFtTransferManager instance];
    [mgr enqueueFile2Upload:params];
}

-(BOOL) isSipMessageDuplicate: (NSString *) transportPacketHash from: (NSString *) from to: (NSString *) to {
    // Feature: do not save duplicated messages.
    // Sometimes may happen server sends offline messages multiple times.
    @try {
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        PEXDbCursor * c = [cr query:[PEXDbMessage getURI]
                         projection:@[PEXDBMessage_FIELD_ID]
                          selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=? AND %@=?", PEXDBMessage_FIELD_BODY_HASH, PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO]
                      selectionArgs:@[transportPacketHash, from, to]
                          sortOrder:nil];
        if (c == nil){
            return NO;
        }


        BOOL exists = [c getCount] > 0;
        @try {
            [c close];
        } @catch(NSException * ex){
            DDLogError(@"Cannot close cursor, exception=%@", ex);
        }

        // Message is already in the database, do not store it again.
        return exists;

    } @catch (NSException * e){
        DDLogError(@"Cannot determine if message is already stored, exception=%@", e);
    }

    return false;
}

-(BOOL) isFileNotificationDuplicate: (NSString *) nonce2 outgoing: (BOOL) outgoing from: (NSString *) from to: (NSString *) to{
    // Feature: do not save duplicated messages.
    // Sometimes may happen server sends offline messages multiple times.
    @try {
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
        PEXDbCursor * c = [cr query:[PEXDbMessage getURI]
                         projection:@[PEXDBMessage_FIELD_ID]
                          selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=? AND %@=? AND %@=?",
                                          PEXDBMessage_FIELD_FILE_NONCE,
                                          PEXDBMessage_FIELD_IS_OUTGOING,
                                          PEXDBMessage_FIELD_FROM,
                                          PEXDBMessage_FIELD_TO]
                      selectionArgs:@[nonce2, [@(outgoing) stringValue], from, to]
                          sortOrder:nil];
        if (c == nil){
            return NO;
        }

        BOOL exists = [c getCount] > 0;
        @try {
            [c close];
        } @catch(NSException * ex){
            DDLogError(@"Cannot close cursor, exception=%@", ex);
        }

        // Message is already in the database, do not store it again.
        return exists;

    } @catch (NSException * e){
        DDLogError(@"Cannot determine if message is already stored, exception=%@", e);
    }

    return false;
}

-(void) processGeneralMsgNotification: (PEXPbGeneralMsgNotification *) notification packet: (PEXDecryptedTransportPacket *) packet{
    // Check for invalid signature for notifications. File processing has its own check.
    if (notification.notifType != PEXPbGeneralMsgNotificationPEXPbNotificationTypeNewFile && !packet.isValid){
        [PEXReport logEvent:PEX_EVENT_MSG_NOTIF_INVALID_SIGNATURE];
        DDLogError(@"Packet with invalid signature received. NotifType: %d", (int)notification.notifType);
        return;
    }

    switch (notification.notifType) {
        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeNewFile:
            [self processNewFileNotification:notification packet:packet];
            break;

        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeMessageReadAck:
            [self processMessageReadAckNotification:notification packet:packet];
            break;

        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeMissedCall:
            [self processMissedCallNotification:notification packet:packet];
            break;

        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeDhKeySyncRequest:
            DDLogInfo(@"Remote party is signalizing we have no keys left.");
            [PEXDhKeyGenManager triggerUserCheck];
            break;

        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeFullMailbox:
        case PEXPbGeneralMsgNotificationPEXPbNotificationTypeOther:
            DDLogWarn(@"Received currently unsupported GeneralMsgNotification type [%d]", (int)notification.notifType);
            break;

        default:
            DDLogError(@"Received unknown GeneralMsgNotification type [%d]", (int)notification.notifType);
            break;
    }
}

-(void) processNewFileNotification: (PEXPbGeneralMsgNotification *) notification packet: (PEXDecryptedTransportPacket *) packet{
    // Check for duplicate new file notification.
    NSString * from = [PEXSipUri getCanonicalSipContact:packet.from includeScheme:NO];
    NSString * to = [PEXSipUri getCanonicalSipContact:packet.to includeScheme:NO];
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    BOOL duplicate = [self isFileNotificationDuplicate:notification.fileTransferNonce outgoing:NO from:from to:to];
    if (duplicate){
        DDLogVerbose(@"Duplicate message detected with nonce: %@", notification.fileTransferNonce);
        return;
    }

    // New encrypted file notification.
    PEXDbMessage * sipMessage = [[PEXDbMessage alloc] initWithFrom:from to:to
                                                           contact:nil
                                                              body:notification.title
                                                          mimeType:PEXDBMessage_SECURE_FILE_NOTIFY_MIME
                                                              date:[NSDate date]
                                                              type:@(PEXDBMessage_MESSAGE_TYPE_FILE_READY)
                                                          fullFrom:to];

    sipMessage.isOffline = packet.isOffline;
    sipMessage.sendDate = [PEXUtils dateFromMillis: (uint64_t)[packet.sendDate longLongValue]];
    sipMessage.read     = @(NO);
    // before messaging v2, nonce was not present in notification message, therefore we retrieve the one present in lower transport layer (for backward compatibility)
    sipMessage.randNum = [notification hasNonce] ? @(notification.nonce) : packet.nonce;
    // nonce2 serves as unique file identifier
    sipMessage.fileNonce = notification.fileTransferNonce;
    // Security properties
    sipMessage.signatureOK = @(packet.macValid && packet.signatureValid);

    if (!packet.isValid){
        DDLogWarn(@"Received SipMessage is not valid [%@]", packet);
        sipMessage.decryptionStatus = @(PEXDBMessage_DECRYPTION_STATUS_DECRYPTION_ERROR);
        sipMessage.errorCode = @(PEXDBMessage_ERROR_DECRYPT_GENERIC);
        [PEXReport logEvent:PEX_EVENT_MSG_NOTIF_INVALID_SIGNATURE];

    } else {
        sipMessage.decryptionStatus = @(PEXDBMessage_DECRYPTION_STATUS_OK);
    }

    PEXDbUri const * const newUri = [cr insert:[PEXDbMessage getURI] contentValues:[sipMessage getDbContentValues]];
    DDLogDebug(@"Store to DB: NewFile GeneralMsgNotification [%@], insert uri: %@", notification, newUri);

    // Automatically fetch meta information about the file transfer.
    sipMessage.id = newUri.itemId;
    [PEXFtTransferManager dispatchDownloadTransfer:sipMessage accept:nil];

    // Notify android OS of the new message - display in Notification bar
    [self notifyOfUnreadSipMessage:sipMessage];
    [PEXDhKeyGenManager triggerUserCheck];
}

-(void) processMessageReadAckNotification: (PEXPbGeneralMsgNotification *) notification packet: (PEXDecryptedTransportPacket *) packet{
    if ([notification ackNonces] == nil || [notification ackNonces].count <= 0){
        DDLogError(@"Received MessageReadAck with 0 acknowledged nonces");
        return;
    }

    NSUInteger count = [notification ackNonces].count;
    NSMutableArray * noncesList = [NSMutableArray arrayWithCapacity:count];    // List<NSNumber*>
    for(NSUInteger i=0; i<count; ++i){
        noncesList[i] = [@((uint32_t)[notification ackNoncesAtIndex:i]) stringValue];
    }

    // create placeholders for IN statement
    NSString * inPlaceholders = [PEXUtils generateDbPlaceholders:count];

    // perform update - set Read to 1
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_READ boolean: YES];
    [cv put:PEXDBMessage_FIELD_READ_DATE date:[PEXUtils dateFromMillis:notification.timestamp]];

    NSString * where = [NSString stringWithFormat:@"WHERE %@ IN (%@) AND %@=0",
                                                  PEXDBMessage_FIELD_RANDOM_NUM, inPlaceholders, PEXDBMessage_FIELD_READ];

    const int updated = [[PEXDbAppContentProvider instance] updateEx:[PEXDbMessage getURI]
                                                ContentValues:cv
                                                    selection:where
                                                selectionArgs:noncesList];

    DDLogInfo(@"Receiving MessageReadAck notification for following nonces [%@], num of updated SipMessages in db [%d]", noncesList, updated);
}

-(void) processMissedCallNotification: (PEXPbGeneralMsgNotification *) notification packet: (PEXDecryptedTransportPacket *) packet{
    NSString * from = [PEXSipUri getCanonicalSipContact:packet.from includeScheme:NO];
    NSString * to = [PEXSipUri getCanonicalSipContact:packet.to includeScheme:NO];
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

    // Load profile associated to "to".
    PEXDbUserProfile * profile = [PEXDbUserProfile getProfileWithName:to cr:cr projection:[PEXDbUserProfile getAccProjection]];
    if (profile == nil){
        DDLogWarn(@"Profile for %@ not found", to);
        return;
    }

    // Load contact list entry for this user.
    PEXDbContact * contact = [PEXDbContact newProfileFromDbSip:cr sip:from projection:[PEXDbContact getNormalProjection]];
    if (contact == nil){
        DDLogWarn(@"Contact list entry not found for user %@", from);
        return;
    }

    // Verify this is not already inserted in DB. Avoid duplicate notifications for the same event.
    NSDate * evtTime = notification.hasTimestamp && notification.timestamp > 100
            ? [PEXUtils dateFromMillis:notification.timestamp] : nil;
    NSNumber * evtNonce = notification.hasNonce && notification.nonce != 0
            ? @(notification.nonce) : nil;
    NSString * callId = notification.hasSipCallId && ![PEXUtils isEmpty:notification.sipCallId]
            ? notification.sipCallId : nil;

    PEXDbCallLog * prevCl = [PEXDbCallLog getLogByEventDescription:from
                                                              toId:profile.id
                                                           evtTime:evtTime
                                                          evtNonce:evtNonce
                                                            callId:callId
                                                                cr:cr];
    if (prevCl != nil){
        DDLogDebug(@"Given callog already inserted in db. From %@, toId %@ evtTime %@, evtNonce %@, callId: %@",
                from, profile.id, evtTime, evtNonce, callId);
        return;
    }

    PEXDbCallLog * cli = [[PEXDbCallLog alloc] init];
    cli.remoteContact = from;
    cli.remoteContactSip = from;
    cli.remoteAccountId = contact.id;
    cli.remoteContactName = contact.displayName;

    // Date extract.
    cli.callStart = [PEXUtils dateFromMillis:(uint64_t)[packet.sendDate longLongValue]];
    cli.duration = @(0);

    // Missed call params
    cli.isNew = YES;
    cli.type = @(PEX_DBCLOG_TYPE_MISSED);
    cli.seenByUser = NO;
    cli.accountId = profile.id;
    cli.eventTimestamp = evtTime;
    cli.eventNonce = evtNonce;
    cli.sipCallId = callId;

    // Fill our own database
    [PEXDbCallLog addToDatabase:cli cr:cr];
    [PEXDbCallLog probabilisticPrune:cr];
    DDLogVerbose(@"CallLog entry inserted: %@", cli);
}

-(void) notifyOfUnreadSipMessage: (PEXDbMessage *) msg{
    // TODO implement.
//    try {
//        service.getNotificationManager().notifyUnreadMessage(msg);
//    } catch (Exception ex){
//        DDLogError(@"Cannot send notification to StatusbarNotifications manager", ex);
//    }
}

+(void) enqueue: (PEXDbMessageQueue *) msg{
    @try {
        PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];

        // Just in case of there are any duplicates in the queue (usually in the case of resend), we remove them
        int count = [PEXDbMessageQueue deleteOutgoingDuplicates:cr msg:msg];
        DDLogVerbose(@"Number of removed duplicates in the messagequeue [%d]", count);

        if (msg.time == nil){
            msg.time = [NSDate date];
        }

        // Insert a message to the queue.
        PEXDbUri const * dbUri = [cr insert:[PEXDbMessageQueue getURI] contentValues: [msg getDbContentValues]];
        if (dbUri == nil || dbUri.itemId == nil){
            DDLogError(@"Could not enqueue message queue");
            return;
        }

        DDLogDebug(@"New message added to the the messagequeue [%@], uri=%@", msg, dbUri);
    } @catch (NSException * ex){
        DDLogError(@"Error while putting GeneralMessage to queue, exception=%@", ex);
    }
}


@end