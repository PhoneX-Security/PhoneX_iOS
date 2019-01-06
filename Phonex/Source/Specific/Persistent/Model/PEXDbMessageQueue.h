//
// Created by Dusan Klinec on 12.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbContentProvider;

// <FIELD_NAMES>
FOUNDATION_EXPORT NSString *PEX_MSGQ_TABLE_NAME;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_ID;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_TIME;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_FROM;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_TO;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_IS_OUTGOING;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_IS_OFFLINE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_IS_PROCESSED;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_SEND_COUNTER;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_LAST_SEND_CALL;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_MIME_TYPE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_FINAL_MESSAGE;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_REFERENCED_ID;
FOUNDATION_EXPORT NSString *PEX_MSGQ_FIELD_RESEND_TIME;
// </FIELD_NAMES>

@interface PEXDbMessageQueue : PEXDbModelBase

// <ATTRIBUTES>
@property(nonatomic) NSNumber * id; // Integer
@property(nonatomic) NSDate   * time; // Long
@property(nonatomic) NSString * from;
@property(nonatomic) NSString * to;
@property(nonatomic) NSNumber * isOutgoing;  // boolean
@property(nonatomic) NSNumber * isOffline;  // boolean
@property(nonatomic) NSNumber * isProcessed;  // boolean
@property(nonatomic) NSNumber * sendCounter; // Integer
@property(nonatomic) NSNumber * sendAttemptCounter; // Integer
@property(nonatomic) NSDate * lastSendCall; // Integer
@property(nonatomic) NSNumber * transportProtocolType; // Integer
@property(nonatomic) NSNumber * transportProtocolVersion; // Integer
@property(nonatomic) NSNumber * messageProtocolType; // Integer
@property(nonatomic) NSNumber * messageProtocolSubType; // Integer
@property(nonatomic) NSNumber * messageProtocolVersion; // Integer
@property(nonatomic) NSString * mimeType;
@property(nonatomic) NSData * transportPayload;
@property(nonatomic) NSData * envelopePayload;
@property(nonatomic) NSString * finalMessage;
@property(nonatomic) NSString * finalMessageHash;
@property(nonatomic) NSNumber * referencedId; // Integer
@property(nonatomic) NSDate * resendTime; // Long
// </ATTRIBUTES>

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getSendingAckProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
+(const PEXDbUri * const) getNewestPerRecipientURI;
+(const PEXDbUri * const) getOldestPerRecipientURI;

- (instancetype)initWithCursor: (PEXDbCursor *) c;
- (instancetype)initWithFrom:(NSString *)from to:(NSString *)to isOutgoing:(NSNumber *)isOutgoing;
+ (instancetype)queueWithFrom:(NSString *)from to:(NSString *)to isOutgoing:(NSNumber *)isOutgoing;

-(NSString *) getRemoteContact;
+(int) updateMessage: (PEXDbContentProvider *) cr messageId: (int64_t) messageId cv: (PEXDbContentValues *) cv;
+(int) loadSendCounter: (PEXDbContentProvider *) cr messageId: (int64_t) messageId;
+(int) updateLastSendCallTime: (PEXDbContentProvider *) cr messageId: (int64_t) messageId;

/**
* Loads message by ID.
* Uses file related projection.
*
* @param cr
* @param messageId
* @return
*/
+(PEXDbMessageQueue *) getById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId;

/**
* Loads message by ID.
* @param cr
* @param messageId
* @return
*/
+(PEXDbMessageQueue *) getById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId projection: (NSArray *) projection;
+(int) deleteOutgoingDuplicates: (PEXDbContentProvider *) cr msg: (PEXDbMessageQueue *) msg;

+(int) deleteQueuedMessages:(PEXDbContentProvider *) cr to: (NSString *) to;
+ (int)deleteQueuedMessage:(PEXDbContentProvider *)cr withId:(NSNumber * const) messageId;
+ (int)deleteQueuedMessages:(PEXDbContentProvider *)cr forIds: (NSArray * const) ids;
@end