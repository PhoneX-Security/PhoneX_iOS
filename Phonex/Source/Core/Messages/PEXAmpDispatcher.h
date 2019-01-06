//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXProtocols.h"

@class PEXDbMessage;
@class PEXDbMessageQueue;
@class PEXSendingState;
@class PEXDecryptedTransportPacket;
@class PEXFtUploadParams;
@class PEXFtDownloadFileParams;

@interface PEXAmpDispatcher : NSObject

/**
* Put text message into MessageQueue
* @param ctx
* @param sipMessageId
*/
+(void) dispatchTextMessage: (int64_t) sipMessageId;

/**
* Put text message into MessageQueue
* @param ctx
* @param sipMessage
*/
+(void) dispatchTextMessageObj: (PEXDbMessage *) sipMessage;

+(PEXProtocolVersion) supportedStpSimpleVersion: (NSString *) remoteContact;

/**
* Put NewFile notification into MessageQueue. Nonce2 and filename is retrieved from SipMessage
* @param ctx
* @param sipMessageId
*/
+(void) dispatchNewFileNotificationWithID: (int64_t) sipMessageId;

/**
* * Put NewFile notification into MessageQueue. Nonce2 and filename is retrieved from SipMessage
* @param ctx
* @param sipMessage
*/
+(void) dispatchNewFileNotification: (PEXDbMessage *) sipMessage;

/**
* Acknowledge that user has read the message (or multiple messages at once)
* @param ctx
* @param from
* @param to
* @param nonces Messages are identified by their nonce-s (aka randNum in SipMessage)
*/
+(void) dispatchReadAckNotification:(NSString *) from to: (NSString *) to nonces: (NSArray *) nonces;

/**
* Enqueues message that handles file transfer logic. Download/upload itself.
*/
+(void) dispatchNewFileUpload: (PEXDbMessage *) sipMessage params: (PEXFtUploadParams *) params;
+(void) dispatchNewFileDownload:(PEXDbMessage *) sipMessage params: (PEXFtDownloadFileParams *) params;
+(void) dispatchMissedCallNotification: (NSString *) from to: (NSString *) to callId: (NSString *) callId;

/**
* Receive transport packet (containing incoming application message) from  transport layer, process
* @param packet
*/
-(void) receive: (PEXDecryptedTransportPacket *) packet;

/**
* Process request for file transfer, download.
*/
-(void) receiveTransfer: (PEXDbMessageQueue *) msg;

/**
* Process request for file transfer, upload.
*/
-(void) transmitTransfer: (PEXDbMessageQueue *) msg;

/**
* Report sending state of outgoing message
* @param queuedMessage
* @param sendingState
*/
-(void) reportState: (PEXDbMessageQueue *) queuedMessage sendingState: (PEXSendingState *) sendingState;
@end