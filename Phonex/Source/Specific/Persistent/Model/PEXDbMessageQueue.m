//
// Created by Dusan Klinec on 12.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbMessageQueue.h"
#import "PEXDbContentProvider.h"
#import "PEXDBMessage.h"


NSString *PEX_MSGQ_TABLE_NAME = @"message_queue";
NSString *PEX_MSGQ_NEWEST_PER_RECIPIENT_VIEW_NAME = @"message_queue_newest_pr";
NSString *PEX_MSGQ_OLDEST_PER_RECIPIENT_VIEW_NAME = @"message_queue_oldest_pr";

// <FIELD_NAMES>
NSString *PEX_MSGQ_FIELD_ID = @"_id";
NSString *PEX_MSGQ_FIELD_TIME = @"time";
NSString *PEX_MSGQ_FIELD_FROM = @"sender";
NSString *PEX_MSGQ_FIELD_TO = @"receiver";
NSString *PEX_MSGQ_FIELD_IS_OUTGOING = @"isOutgoing";
NSString *PEX_MSGQ_FIELD_IS_OFFLINE = @"isOffline";
NSString *PEX_MSGQ_FIELD_IS_PROCESSED = @"isProcessed";
NSString *PEX_MSGQ_FIELD_SEND_COUNTER = @"sendCounter";
NSString *PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER = @"sendAttemptCounter";
NSString *PEX_MSGQ_FIELD_LAST_SEND_CALL = @"lastSendCall";
NSString *PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE = @"transportProtocolType";
NSString *PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION = @"transportProtocolVersion";
NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE = @"messageProtocolType";
NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE = @"messageProtocolSubType";
NSString *PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION = @"messageProtocolVersion";
NSString *PEX_MSGQ_FIELD_MIME_TYPE = @"mimeType";
NSString *PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD = @"transportPayload";
NSString *PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD = @"envelopePayload";
NSString *PEX_MSGQ_FIELD_FINAL_MESSAGE = @"finalMessage";
NSString *PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH = @"finalMessageHash";
NSString *PEX_MSGQ_FIELD_REFERENCED_ID = @"referencedId";
NSString *PEX_MSGQ_FIELD_RESEND_TIME = @"resendTime";
// </FIELD_NAMES>

@implementation PEXDbMessageQueue {

}

+(NSString *) getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER DEFAULT 0 PRIMARY KEY AUTOINCREMENT, "//  				 PEX_MSGQ_FIELD_ID
                    "  %@  NUMERIC DEFAULT 0, "//  	 PEX_MSGQ_FIELD_TIME
                    "  %@  TEXT, "//  				 PEX_MSGQ_FIELD_FROM
                    "  %@  TEXT, "//  				 PEX_MSGQ_FIELD_TO
                    "  %@  INTEGER DEFAULT 0,  "//   PEX_MSGQ_FIELD_IS_OUTGOING
                    "  %@  INTEGER DEFAULT 0,  "//   PEX_MSGQ_FIELD_IS_OFFLINE
                    "  %@  INTEGER DEFAULT 0,  "//   PEX_MSGQ_FIELD_IS_PROCESSED
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_SEND_COUNTER
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER
                    "  %@  NUMERIC DEFAULT 0, "//  	 PEX_MSGQ_FIELD_LAST_SEND_CALL
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_SUB_TYPE
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE
                    "  %@  INTEGER DEFAULT 0, "//  	 PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION
                    "  %@  TEXT, "//  				 PEX_MSGQ_FIELD_MIME_TYPE
                    "  %@  BLOB, "//  				 PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD
                    "  %@  BLOB, "//  				 PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD
                    "  %@  TEXT, "//  				 PEX_MSGQ_FIELD_FINAL_MESSAGE
                    "  %@  TEXT, "//  				 PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH
                    "  %@  INTEGER DEFAULT 0,"//  	 PEX_MSGQ_FIELD_REFERENCED_ID
                    "  %@  NUMERIC DEFAULT 0"//  	 PEX_MSGQ_FIELD_RESEND_TIME
                    " );",
            PEX_MSGQ_TABLE_NAME,
            PEX_MSGQ_FIELD_ID,
            PEX_MSGQ_FIELD_TIME,
            PEX_MSGQ_FIELD_FROM,
            PEX_MSGQ_FIELD_TO,
            PEX_MSGQ_FIELD_IS_OUTGOING,
            PEX_MSGQ_FIELD_IS_OFFLINE,
            PEX_MSGQ_FIELD_IS_PROCESSED,
            PEX_MSGQ_FIELD_SEND_COUNTER,
            PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER,
            PEX_MSGQ_FIELD_LAST_SEND_CALL,
            PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE,
            PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION,
            PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
            PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE,
            PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION,
            PEX_MSGQ_FIELD_MIME_TYPE,
            PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD,
            PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD,
            PEX_MSGQ_FIELD_FINAL_MESSAGE,
            PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH,
            PEX_MSGQ_FIELD_REFERENCED_ID,
            PEX_MSGQ_FIELD_RESEND_TIME
    ];
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[PEX_MSGQ_FIELD_ID,
                PEX_MSGQ_FIELD_TIME,
                PEX_MSGQ_FIELD_FROM,
                PEX_MSGQ_FIELD_TO,
                PEX_MSGQ_FIELD_IS_OUTGOING,
                PEX_MSGQ_FIELD_IS_OFFLINE,
                PEX_MSGQ_FIELD_IS_PROCESSED,
                PEX_MSGQ_FIELD_SEND_COUNTER,
                PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER,
                PEX_MSGQ_FIELD_LAST_SEND_CALL,
                PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE,
                PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION,
                PEX_MSGQ_FIELD_MIME_TYPE,
                PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD,
                PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD,
                PEX_MSGQ_FIELD_FINAL_MESSAGE,
                PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH,
                PEX_MSGQ_FIELD_REFERENCED_ID,
                PEX_MSGQ_FIELD_RESEND_TIME
                ];
    });
    return fullProjection;
}

+(NSArray *) getSendingAckProjection {
    static dispatch_once_t once;
    static NSArray * ackProjection;
    dispatch_once(&once, ^{
        ackProjection = @[PEX_MSGQ_FIELD_ID,
                PEX_MSGQ_FIELD_TIME,
                PEX_MSGQ_FIELD_FROM,
                PEX_MSGQ_FIELD_TO,
                PEX_MSGQ_FIELD_IS_OUTGOING,
                PEX_MSGQ_FIELD_IS_OFFLINE,
                PEX_MSGQ_FIELD_IS_PROCESSED,
                PEX_MSGQ_FIELD_SEND_COUNTER,
                PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER,
                PEX_MSGQ_FIELD_LAST_SEND_CALL,
                PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE,
                PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE,
                PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION,
                PEX_MSGQ_FIELD_MIME_TYPE,
                PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD,
                PEX_MSGQ_FIELD_REFERENCED_ID,
                PEX_MSGQ_FIELD_RESEND_TIME
        ];
    });
    return ackProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_MSGQ_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_MSGQ_TABLE_NAME isBase:YES];
    });
    return uriBase;
}

+(const PEXDbUri * const) getNewestPerRecipientURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_MSGQ_NEWEST_PER_RECIPIENT_VIEW_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getOldestPerRecipientURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_MSGQ_OLDEST_PER_RECIPIENT_VIEW_NAME];
    });
    return uri;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sendCounter = @(0);
        self.isOffline = @(NO);
        self.isOutgoing = @(NO);
    }

    return self;
}

- (instancetype)initWithFrom:(NSString *)from to:(NSString *)to isOutgoing:(NSNumber *)isOutgoing {
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
        self.isOutgoing = isOutgoing;
        self.isOffline = @(NO);
        self.sendCounter = @(0);
        self.isProcessed = @(NO);
    }

    return self;
}

+ (instancetype)queueWithFrom:(NSString *)from to:(NSString *)to isOutgoing:(NSNumber *)isOutgoing {
    return [[self alloc] initWithFrom:from to:to isOutgoing:isOutgoing];
}

- (instancetype)initWithCursor: (PEXDbCursor *) c{
    self = [super init];
    if (self) {
        [self createFromCursor:c];
    }

    return self;
}

/**
* Create account wrapper with content values pairs.
*
* @param args the content value to unpack.
*/
-(void) createFromCursor: (PEXDbCursor *) c {
    int colCount = [c getColumnCount];
    for(int i=0; i<colCount; i++) {
        NSString *colname = [c getColumnName:i];
        if ([PEX_MSGQ_FIELD_ID isEqualToString: colname]){
            self.id = [c getInt64: i];
        } else if ([PEX_MSGQ_FIELD_TIME isEqualToString: colname]){
            self.time = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_MSGQ_FIELD_FROM isEqualToString: colname]){
            self.from = [c getString: i];;
        } else if ([PEX_MSGQ_FIELD_TO isEqualToString: colname]){
            self.to = [c getString: i];;
        } else if ([PEX_MSGQ_FIELD_IS_OUTGOING isEqualToString: colname]){
            self.isOutgoing = @([[c getInt: i] integerValue] == 1);
        } else if ([PEX_MSGQ_FIELD_IS_OFFLINE isEqualToString: colname]){
            self.isOffline = @([[c getInt: i] integerValue] == 1);
        } else if ([PEX_MSGQ_FIELD_IS_PROCESSED isEqualToString: colname]){
            self.isProcessed = @([[c getInt: i] integerValue] == 1);
        } else if ([PEX_MSGQ_FIELD_SEND_COUNTER isEqualToString: colname]){
            self.sendCounter = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER isEqualToString: colname]){
            self.sendAttemptCounter = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_LAST_SEND_CALL isEqualToString: colname]){
            self.lastSendCall = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE isEqualToString: colname]){
            self.transportProtocolType = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION isEqualToString: colname]){
            self.transportProtocolVersion = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE isEqualToString: colname]){
            self.messageProtocolType = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE isEqualToString: colname]){
            self.messageProtocolSubType = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION isEqualToString: colname]){
            self.messageProtocolVersion = [c getInt: i];;
        } else if ([PEX_MSGQ_FIELD_MIME_TYPE isEqualToString: colname]){
            self.mimeType = [c getString: i];;
        } else if ([PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD isEqualToString: colname]){
            self.transportPayload = [c getBlob: i];;
        } else if ([PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD isEqualToString: colname]){
            self.envelopePayload = [c getBlob: i];;
        } else if ([PEX_MSGQ_FIELD_FINAL_MESSAGE isEqualToString: colname]){
            self.finalMessage = [c getString: i];;
        } else if ([PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH isEqualToString: colname]){
            self.finalMessageHash = [c getString: i];;
        } else if ([PEX_MSGQ_FIELD_REFERENCED_ID isEqualToString: colname]){
            self.referencedId = [c getInt64:i];
        } else if ([PEX_MSGQ_FIELD_RESEND_TIME isEqualToString: colname]){
            self.resendTime = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else {
            DDLogWarn(@"Unknown column name %@", colname);
        }
    }
}

/**
* Pack the object content value to store
*
* @return The content value representing the message
*/
-(PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    if (_id!=nil && [_id longLongValue] != -1l) {
        [cv put:PEX_MSGQ_FIELD_ID NSNumberAsLongLong:_id];
    }

    [cv put:PEX_MSGQ_FIELD_TIME date: self.time];
    if (self.from != nil)
        [cv put:PEX_MSGQ_FIELD_FROM string: self.from];
    if (self.to != nil)
        [cv put:PEX_MSGQ_FIELD_TO string: self.to];
    [cv put:PEX_MSGQ_FIELD_IS_OUTGOING NSNumberAsInt: [PEXDbMessageQueue bool2int:self.isOutgoing]];
    [cv put:PEX_MSGQ_FIELD_IS_OFFLINE NSNumberAsInt: [PEXDbMessageQueue bool2int:self.isOffline]];
    [cv put:PEX_MSGQ_FIELD_IS_PROCESSED NSNumberAsInt: [PEXDbMessageQueue bool2int:self.isProcessed]];
    if (self.sendCounter != nil)
        [cv put:PEX_MSGQ_FIELD_SEND_COUNTER NSNumberAsInt: self.sendCounter];
    if (self.sendAttemptCounter != nil)
        [cv put:PEX_MSGQ_FIELD_SEND_ATTEMPT_COUNTER NSNumberAsInt: self.sendAttemptCounter];
    if (self.lastSendCall != nil)
        [cv put:PEX_MSGQ_FIELD_LAST_SEND_CALL date: self.lastSendCall];
    if (self.transportProtocolType != nil)
        [cv put:PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_TYPE NSNumberAsInt: self.transportProtocolType];
    if (self.transportProtocolVersion != nil)
        [cv put:PEX_MSGQ_FIELD_TRANSPORT_PROTOCOL_VERSION NSNumberAsInt: self.transportProtocolVersion];
    if (self.messageProtocolType != nil)
        [cv put:PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE NSNumberAsInt: self.messageProtocolType];
     if (self.messageProtocolSubType != nil)
        [cv put:PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_SUB_TYPE NSNumberAsInt: self.messageProtocolSubType];
    if (self.messageProtocolVersion != nil)
        [cv put:PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION NSNumberAsInt: self.messageProtocolVersion];
    if (self.mimeType != nil)
        [cv put:PEX_MSGQ_FIELD_MIME_TYPE string: self.mimeType];
    if (self.transportPayload != nil)
        [cv put:PEX_MSGQ_FIELD_TRANSPORT_PAYLOAD data: self.transportPayload];
    if (self.envelopePayload != nil)
        [cv put:PEX_MSGQ_FIELD_ENVELOPE_PAYLOAD data: self.envelopePayload];
    if (self.finalMessage != nil)
        [cv put:PEX_MSGQ_FIELD_FINAL_MESSAGE string: self.finalMessage];
    if (self.finalMessageHash != nil)
        [cv put:PEX_MSGQ_FIELD_FINAL_MESSAGE_HASH string: self.finalMessageHash];
    if (self.referencedId != nil)
        [cv put:PEX_MSGQ_FIELD_REFERENCED_ID NSNumberAsLongLong: self.referencedId];
    if (self.resendTime != nil)
        [cv put:PEX_MSGQ_FIELD_RESEND_TIME date: self.resendTime];
    return cv;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbMessageQueue *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.envelopePayload = self.envelopePayload;
        copy.id = self.id;
        copy.time = self.time;
        copy.from = self.from;
        copy.to = self.to;
        copy.isOutgoing = self.isOutgoing;
        copy.isOffline = self.isOffline;
        copy.isProcessed = self.isProcessed;
        copy.sendCounter = self.sendCounter;
        copy.sendAttemptCounter = self.sendAttemptCounter;
        copy.lastSendCall = self.lastSendCall;
        copy.transportProtocolType = self.transportProtocolType;
        copy.transportProtocolVersion = self.transportProtocolVersion;
        copy.messageProtocolType = self.messageProtocolType;
        copy.messageProtocolSubType = self.messageProtocolSubType;
        copy.messageProtocolVersion = self.messageProtocolVersion;
        copy.mimeType = self.mimeType;
        copy.transportPayload = self.transportPayload;
        copy.finalMessage = self.finalMessage;
        copy.finalMessageHash = self.finalMessageHash;
        copy.referencedId = self.referencedId;
        copy.resendTime = self.resendTime;
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.resendTime = [coder decodeObjectForKey:@"self.resendTime"];
        self.envelopePayload = [coder decodeObjectForKey:@"self.envelopePayload"];
        self.finalMessage = [coder decodeObjectForKey:@"self.finalMessage"];
        self.finalMessageHash = [coder decodeObjectForKey:@"self.finalMessageHash"];
        self.from = [coder decodeObjectForKey:@"self.from"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.isOutgoing = [coder decodeObjectForKey:@"self.isOutgoing"];
        self.isOffline = [coder decodeObjectForKey:@"self.isOffline"];
        self.isProcessed = [coder decodeObjectForKey:@"self.isProcessed"];
        self.lastSendCall = [coder decodeObjectForKey:@"self.lastSendCall"];
        self.messageProtocolType = [coder decodeObjectForKey:@"self.messageProtocolType"];
        self.messageProtocolSubType = [coder decodeObjectForKey:@"self.messageProtocolSubType"];
        self.messageProtocolVersion = [coder decodeObjectForKey:@"self.messageProtocolVersion"];
        self.mimeType = [coder decodeObjectForKey:@"self.mimeType"];
        self.referencedId = [coder decodeObjectForKey:@"self.referencedId"];
        self.sendAttemptCounter = [coder decodeObjectForKey:@"self.sendAttemptCounter"];
        self.sendCounter = [coder decodeObjectForKey:@"self.sendCounter"];
        self.time = [coder decodeObjectForKey:@"self.time"];
        self.to = [coder decodeObjectForKey:@"self.to"];
        self.transportPayload = [coder decodeObjectForKey:@"self.transportPayload"];
        self.transportProtocolType = [coder decodeObjectForKey:@"self.transportProtocolType"];
        self.transportProtocolVersion = [coder decodeObjectForKey:@"self.transportProtocolVersion"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.resendTime forKey:@"self.resendTime"];
    [coder encodeObject:self.envelopePayload forKey:@"self.envelopePayload"];
    [coder encodeObject:self.finalMessage forKey:@"self.finalMessage"];
    [coder encodeObject:self.finalMessageHash forKey:@"self.finalMessageHash"];
    [coder encodeObject:self.from forKey:@"self.from"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.isOutgoing forKey:@"self.isOutgoing"];
    [coder encodeObject:self.isOffline forKey:@"self.isOffline"];
    [coder encodeObject:self.isProcessed forKey:@"self.isProcessed"];
    [coder encodeObject:self.lastSendCall forKey:@"self.lastSendCall"];
    [coder encodeObject:self.messageProtocolType forKey:@"self.messageProtocolType"];
    [coder encodeObject:self.messageProtocolSubType forKey:@"self.messageProtocolSubType"];
    [coder encodeObject:self.messageProtocolVersion forKey:@"self.messageProtocolVersion"];
    [coder encodeObject:self.mimeType forKey:@"self.mimeType"];
    [coder encodeObject:self.referencedId forKey:@"self.referencedId"];
    [coder encodeObject:self.sendAttemptCounter forKey:@"self.sendAttemptCounter"];
    [coder encodeObject:self.sendCounter forKey:@"self.sendCounter"];
    [coder encodeObject:self.time forKey:@"self.time"];
    [coder encodeObject:self.to forKey:@"self.to"];
    [coder encodeObject:self.transportPayload forKey:@"self.transportPayload"];
    [coder encodeObject:self.transportProtocolType forKey:@"self.transportProtocolType"];
    [coder encodeObject:self.transportProtocolVersion forKey:@"self.transportProtocolVersion"];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.envelopePayload=%@", self.envelopePayload];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.time=%@", self.time];
    [description appendFormat:@", self.from=%@", self.from];
    [description appendFormat:@", self.to=%@", self.to];
    [description appendFormat:@", self.isOutgoing=%@", self.isOutgoing];
    [description appendFormat:@", self.isOffline=%@", self.isOffline];
    [description appendFormat:@", self.isProcessed=%@", self.isProcessed];
    [description appendFormat:@", self.sendCounter=%@", self.sendCounter];
    [description appendFormat:@", self.sendAttemptCounter=%@", self.sendAttemptCounter];
    [description appendFormat:@", self.lastSendCall=%@", self.lastSendCall];
    [description appendFormat:@", self.transportProtocolType=%@", self.transportProtocolType];
    [description appendFormat:@", self.transportProtocolVersion=%@", self.transportProtocolVersion];
    [description appendFormat:@", self.messageProtocolType=%@", self.messageProtocolType];
    [description appendFormat:@", self.messageProtocolSubType=%@", self.messageProtocolSubType];
    [description appendFormat:@", self.messageProtocolVersion=%@", self.messageProtocolVersion];
    [description appendFormat:@", self.mimeType=%@", self.mimeType];
    [description appendFormat:@", self.transportPayload=%@", self.transportPayload];
    [description appendFormat:@", self.finalMessage=%@", self.finalMessage];
    [description appendFormat:@", self.finalMessageHash=%@", self.finalMessageHash];
    [description appendFormat:@", self.referencedId=%@", self.referencedId];
    [description appendFormat:@", self.resendTime=%@", self.resendTime];
    [description appendString:@">"];
    return description;
}

-(NSString *) getRemoteContact {
    if (_isOutgoing.boolValue) {
        return self.to;
    }else {
        return self.from;
    }
}

+(int) updateMessage: (PEXDbContentProvider *) cr messageId: (int64_t) messageId cv: (PEXDbContentValues *) cv {
    return [cr update:[self getURI]
        ContentValues:cv
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]];
}

+(int) updateLastSendCallTime: (PEXDbContentProvider *) cr messageId: (int64_t) messageId {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEX_MSGQ_FIELD_LAST_SEND_CALL date: [NSDate date]];
    return [cr updateEx:[self getURI]
        ContentValues:cv
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]];
}

+(int) loadSendCounter: (PEXDbContentProvider *) cr messageId: (int64_t) messageId{
    // Load ID here
    PEXDbCursor * c = [cr query:[PEXDbMessageQueue getURI]
                     projection:@[PEX_MSGQ_FIELD_ID, PEX_MSGQ_FIELD_SEND_COUNTER]
                      selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
                  selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]
                      sortOrder:nil];

    if (c == nil || [c getCount] <= 0){
        return 0;
    }

    @try{
        if ([c moveToFirst]) {
            int counter = [[c getInt:[c getColumnIndex:PEX_MSGQ_FIELD_SEND_COUNTER]] intValue];
            return counter;
        }
    } @catch(NSException * e){
            DDLogError(@"Error while getting message ID %@", e);
    } @finally {
        [c close];
    }
    return 0;
}

/**
* Loads message by ID.
* Uses file related projection.
*
* @param cr
* @param messageId
* @return
*/
+(PEXDbMessageQueue *) getById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId {
    return [self getById:cr messageId:messageId projection:[PEXDbMessageQueue getFullProjection]];
}

/**
* Loads message by ID.
* @param cr
* @param messageId
* @return
*/
+(PEXDbMessageQueue *) getById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId projection: (NSArray *) projection {
    PEXDbCursor * c = [cr query:[PEXDbMessageQueue getURI]
                     projection:projection
                      selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_MSGQ_FIELD_ID]
                  selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]
                      sortOrder:nil];

    if (c == nil){
        return nil;
    }

    @try {
        if ([c moveToFirst]){
            PEXDbMessageQueue * msg = [[PEXDbMessageQueue alloc] initWithCursor:c];
            return msg;
        }
    } @catch (NSException * e) {
        DDLogError(@"Error while getting message ID %@", e);
        return nil;
    } @finally {
        [c close];
    }

    return nil;
}

+(int) deleteOutgoingDuplicates: (PEXDbContentProvider *) cr msg: (PEXDbMessageQueue *) msg {
    @try {
        // If reference id is not set (such as for ACKs), do not bother (receiving multiple ACKs is not `1a problem)
        if (msg.referencedId == nil){
            return 0;
        }

        NSString * where = [NSString stringWithFormat:@"WHERE %@=1 AND %@=? AND %@=? AND %@=? AND %@=? AND %@=?",
                        PEX_MSGQ_FIELD_IS_OUTGOING,
                        PEX_MSGQ_FIELD_TO,
                        PEX_MSGQ_FIELD_FROM,
                        PEX_MSGQ_FIELD_REFERENCED_ID,
                        PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_TYPE,
                        PEX_MSGQ_FIELD_MESSAGE_PROTOCOL_VERSION];

        return [cr delete:[self getURI] selection:where
            selectionArgs:@[msg.to, msg.from,
             msg.referencedId.stringValue,
             msg.messageProtocolType.stringValue,
             msg.messageProtocolVersion.stringValue]];

    } @catch (NSException * ex){
        DDLogError(@"Error deleting duplicates for message [%@], exception=%@", msg, ex);
        return 0;
    }
}

+ (int)deleteQueuedMessages:(PEXDbContentProvider *)cr to:(NSString *)to {
    return [cr delete:[self getURI]
            selection:[NSString stringWithFormat:@"WHERE %@=1 AND %@=?", PEX_MSGQ_FIELD_IS_OUTGOING, PEX_MSGQ_FIELD_TO]
        selectionArgs:@[to]];
}

+ (int)deleteQueuedMessage:(PEXDbContentProvider *)cr withId:(NSNumber * const) messageId
{
    return [cr delete:[self getURI]
            selection:[NSString stringWithFormat:@"WHERE %@=1 AND %@=?", PEX_MSGQ_FIELD_IS_OUTGOING, PEX_MSGQ_FIELD_REFERENCED_ID]
        selectionArgs:@[messageId]];
}

+ (int)deleteQueuedMessages:(PEXDbContentProvider *)cr forIds: (NSArray * const) ids
{
    if (!ids || (ids.count == 0))
        return false;

    return [cr delete:[self getURI]
            selection:[self getWhereForIds:ids]
        selectionArgs:[PEXDbMessage getWhereForIdsArgs:ids]];
}

+ (NSString *) getWhereForIds: (NSArray * const) ids
{
    if (!ids || (ids.count == 0))
        return nil;

    NSMutableString * const result = [[NSMutableString alloc]
            initWithFormat:@"WHERE %@=1 AND %@ IN (?",PEX_MSGQ_FIELD_IS_OUTGOING, PEX_MSGQ_FIELD_REFERENCED_ID];

    for (NSUInteger i = 1; i < ids.count; ++i)
        [result appendString:@",?"];

    [result appendString:@")"];

    return result;
}


@end