//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTransportProtocolDispatcher.h"
#import "PEXUserPrivate.h"
#import "PEXCertificate.h"
#import "PEXUtils.h"
#import "PEXStp.h"
#import "PEXStpSimple.h"
#import "PEXStpSimpleAuth.h"
#import "PEXDecryptedTransportPacket.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"
#import "PEXDbContact.h"
#import "PEXDBMessage.h"
#import "PEXMessageProtocolEnvelope.h"
#import "PEXMessageDispatcher.h"
#import "PEXMessageManager.h"
#import "PEXFtTransferManager.h"
#import "PEXReport.h"

@implementation PEXTransportProtocolDispatcher {

}

- (instancetype)initWithRemoteCert:(PEXCertificate *)remoteCert userIdentity:(PEXUserPrivate *)userIdentity {
    self = [super init];
    if (self) {
        self.remoteCert = remoteCert;
        self.userIdentity = userIdentity;
        self.ampDispatcher = [[PEXAmpDispatcher alloc] init];
    }

    return self;
}

+ (instancetype)dispatcherWithRemoteCert:(PEXCertificate *)remoteCert userIdentity:(PEXUserPrivate *)userIdentity {
    return [[self alloc] initWithRemoteCert:remoteCert userIdentity:userIdentity];
}

/*
 * Transmit data stored in transport payload of QueuedMessage
 * @param msg
 */
-(void) transmit: (PEXDbMessageQueue *) msg{
    DDLogInfo(@"Transmitting queuedMessage id: [%@], sndCt: %@, txProto: %@", msg.id, msg.sendCounter, msg.transportProtocolType);

    // sendCounter is number of trials that happened before
    int sendCounter = msg.sendCounter != nil ? [msg.sendCounter intValue] : 0;
    NSString * finalMessage = msg.finalMessage;

    if (![PEXUtils isEmpty:finalMessage]){ // resend
        DDLogInfo(@"Resending message, trial number [%d]", sendCounter + 1);
        [self sendMessageToPjSip:msg finalMsg:finalMessage];

    } else if (msg.transportProtocolType != nil) {
        PEXProtocolType ptype = [msg.transportProtocolType integerValue];
        switch (ptype) {
            case PEX_STP_SIMPLE:
            case PEX_STP_SIMPLE_AUTH:
                [self transmitStpSimple:msg];
                break;
            case PEX_STP_FTRANSFER:
                [self transmitFtransfer:msg];
                break;
            default:
                DDLogError(@"Error, unknown transport protocol type for data [%@]", msg);
                break;
        }
    }
}

-(void) transmitStpSimple: (PEXDbMessageQueue *) msg{
    if (![self checkSupportedStpType:msg.transportProtocolType stpVersion:msg.transportProtocolVersion]){
        DDLogError(@"Error, unsupported STP_SIMPLE transport protocol version for data [%@]", msg);
        if (self.messageQueueListener != nil){
            [self.messageQueueListener deleteAndReportToAppLayer:msg state:[PEXSendingState getGenericFail]];
        }
        return;
    }

    @try {
        id<PEXStp> stp = nil;
        PEXProtocolType ptype = [msg.transportProtocolType integerValue];
        PEXProtocolVersion pver = [msg.transportProtocolVersion integerValue];

        PEXPrivateKey * pk = [[PEXPrivateKey alloc] init];
        pk.key = self.userIdentity.privKey;

        if (ptype == PEX_STP_SIMPLE){
            stp = [[PEXStpSimple alloc] initWithSender:msg.from pk:pk remoteCert:self.remoteCert];
        } else if (ptype == PEX_STP_SIMPLE_AUTH) {
            stp = [[PEXStpSimpleAuth alloc] initWithSender:msg.from pk:pk remoteCert:self.remoteCert];
        } else {
            DDLogError(@"Unknown protocol type=%ld", (long)ptype);
            return;
        }

        [stp setVersion:pver];

        NSError * err = nil;
        PEXProtocolType mtype = [msg.messageProtocolType integerValue];
        PEXProtocolVersion mver = [msg.messageProtocolVersion integerValue];

        // Backward compatibility with chat notifications.
        if (mtype == PEX_AMP_NOTIFICATION_CHAT){
            mtype = PEX_AMP_NOTIFICATION;
            mver = PEX_AMP_NOTIFICATION_VERSION_GENERAL_MSG_NOTIFICATION;
        }

        NSData * payload = [stp buildMessage:msg.transportPayload destination:msg.to ampType:mtype ampVersion:mver error:&err];
        if (err != nil){
            DDLogError(@"Error during building a message for sending. Error=%@", err);
            [NSException raise:@"RuntimeException" format:@"Error in message build: %@", err];
        }

        PEXMessageProtocolEnvelope * envelope = [PEXMessageProtocolEnvelope createEnvelope:payload
                                                                              protocolType:ptype
                                                                           protocolVersion:pver];
        NSString * finalMsg = [envelope getBase64EncodedSerialized];
        if (self.messageQueueListener != nil && msg.id != nil){
            [self.messageQueueListener storeFinalMessageWithHash:[msg.id longValue] finalMessage:finalMsg];
        }

        [self sendMessageToPjSip:msg finalMsg:finalMsg];

    } @catch (NSException * e) {
        DDLogError(@"Error while creating StpSimple data [%@], exception=%@", msg, e);
        if (self.messageQueueListener != nil){
            [self.messageQueueListener deleteAndReportToAppLayer:msg state:[PEXSendingState getGenericFail]];
        }
        return;
    }
}

-(void) transmitFtransfer: (PEXDbMessageQueue *) msg{
    @try {
        [self.ampDispatcher transmitTransfer:msg];
    } @catch (NSException * e) {
        DDLogError(@"Error while creating Ftransfer object data [%@], exception=%@", msg, e);
        if (self.messageQueueListener != nil){
            [self.messageQueueListener deleteAndReportToAppLayer:msg state:[PEXSendingState getGenericFail]];
        }
        return;
    }
}

// send message via PJSIP (it consumes text payloads)
-(void) sendMessageToPjSip: (PEXDbMessageQueue *) msg finalMsg: (NSString *) finalMsg{
    PEXDbContact * sender = [PEXDbContact newProfileFromDbSip:[PEXDbAppContentProvider instance] sip:msg.from projection:[PEXDbContact getNormalProjection]];

    // currently all messages share same MIME
    NSString * mimeToSend = PEXDBMessage_SECURE_MSG_MIME;

    @try {
        [[PEXMessageDispatcher instance] sendMessageImpl:finalMsg
                                               msg2store:finalMsg
                                                  callee:msg.getRemoteContact
                                               accountId:sender.id
                                                    mime:mimeToSend
                                               messageId:msg.id
                                                isResend:NO
                                               dbMessage:msg];

    } @catch (NSException * e) {
        DDLogError(@"Error reported by pjsip layer while sending message [%@], exception=%@", msg, e);
        if (self.messageQueueListener != nil){
            [self.messageQueueListener deleteAndReportToAppLayer:msg state:[PEXSendingState getGenericFail]];
        }
    }
}

-(void) receive: (PEXDbMessageQueue *) msg{
    DDLogVerbose(@"receive() msg.id=%@, proto=%@", msg.id, msg.transportProtocolType);
    if (msg.transportProtocolType == nil){
        DDLogError(@"Null protocol type");
        [PEXReport logEvent:PEX_EVENT_MSG_NULL_PROTOCOL];
        return;
    }

    PEXProtocolType ptype = [msg.transportProtocolType integerValue];
    switch (ptype) {
        case PEX_STP_SIMPLE:
        case PEX_STP_SIMPLE_AUTH: // variant of STP_SIMPLE with authentication only
            [self receiveStpSimple:msg];
            break;
        case PEX_STP_FTRANSFER:
            [self receiveFtransfer:msg];
            break;
        default:
            [PEXReport logEvent:PEX_EVENT_MSG_UNKNOWN_TRANSPORT_PROTOCOL];
            DDLogError(@"Receive() error: unknown transport protocol type for msg [%@]", msg);
            break;
    }
}

-(void) receiveStpSimple: (PEXDbMessageQueue *) msg {
    if (![self checkSupportedStpType:msg.transportProtocolType stpVersion:msg.transportProtocolVersion]){
        DDLogError(@"Receive()  Error: unsupported STP version for msg [%@]", msg);
        [PEXReport logEvent:PEX_EVENT_MSG_UNSUPPORTED_STP];
        return;
    }

    @try {
        id<PEXStp> stp = nil;
        PEXProtocolType ptype = [msg.transportProtocolType integerValue];
        PEXProtocolVersion pver = [msg.transportProtocolVersion integerValue];

        PEXPrivateKey * pk = [[PEXPrivateKey alloc] init];
        pk.key = self.userIdentity.privKey;

        if (ptype == PEX_STP_SIMPLE){
            stp = [[PEXStpSimple alloc] initWithPk:pk remoteCert:self.remoteCert];
        } else if (ptype == PEX_STP_SIMPLE_AUTH) {
            stp = [[PEXStpSimpleAuth alloc] initWithPk:pk remoteCert:self.remoteCert];
        } else {
            [PEXReport logEvent:PEX_EVENT_MSG_UNKNOWN_PROTOCOL];
            DDLogError(@"Unknown protocol type=%ld", (long)ptype);
            return;
        }

        PEXStpProcessingResult * processingResult = [stp readMessage:msg.envelopePayload stpType:ptype stpVersion:pver];
        PEXDecryptedTransportPacket * packet = [PEXDecryptedTransportPacket initFrom:processingResult];

        // For msg identification in SipMessage table.
        NSString * payloadHash = [PEXMessageManager computeMessageHashData: msg.envelopePayload];
        packet.transportPacketHash = payloadHash;
        packet.isOffline = msg.isOffline;

        [self.ampDispatcher receive:packet];

    } @catch (NSException * e){
        DDLogError(@"Error while creating StpSimple message for data [%@], exception=%@", msg, e);
        return;
    }

}

-(void) receiveFtransfer: (PEXDbMessageQueue *) msg {
    @try {
        [self.ampDispatcher receiveTransfer:msg];
    } @catch (NSException * e){
        DDLogError(@"Error while creating StpSimple message for data [%@], exception=%@", msg, e);
        return;
    }
}

-(BOOL) checkSupportedStpType: (NSNumber *) stpTypeObj stpVersion: (NSNumber *) stpVersionObj {
    if (stpTypeObj == nil || stpVersionObj == nil){
        return NO;
    }

    PEXProtocolType stpType = [stpTypeObj integerValue];
    PEXProtocolVersion stpVersion = [stpVersionObj integerValue];
    if (stpType == PEX_STP_SIMPLE && (stpVersion == PEX_STP_SIMPLE_VERSION_3)){
        return YES;
    } else if (stpType == PEX_STP_SIMPLE_AUTH && stpVersion == PEX_STP_SIMPLE_AUTH_VERSION_2){
        return YES;
    } else {
        return NO;
    }
}

@end