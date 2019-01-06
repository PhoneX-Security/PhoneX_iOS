//
// Created by Dusan Klinec on 18.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXPjCall;
@class PEXDbContentProvider;

FOUNDATION_EXPORT NSString *PEX_DBCLOG_TABLE;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_ID;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_DATE;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_DURATION;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_NEW;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_NUMBER;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_TYPE;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_CACHED_NAME;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE;

FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_ACCOUNT_ID;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_STATUS_CODE;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_STATUS_TEXT;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_SEEN_BY_USER;

FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_EVENT_TIMESTAMP;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_EVENT_NONCE;
FOUNDATION_EXPORT NSString *PEX_DBCLOG_FIELD_SIP_CALL_ID;

extern const NSInteger PEX_DBCLOG_TYPE_OUTGOING;
extern const NSInteger PEX_DBCLOG_TYPE_INCOMING;
extern const NSInteger PEX_DBCLOG_TYPE_MISSED;
extern const NSInteger PEX_DBCLOG_TYPE_VOICEMAIL;

@class PEXDbContact;

@interface PEXDbCallLog : PEXDbModelBase
/**
* Unique ID.
*/
@property(nonatomic)NSNumber * id;

/**
* The type of the call (incoming, outgoing or missed).
*/
@property(nonatomic) NSNumber * type;

/**
* Whether or not the call has been acknowledged
*/
@property(nonatomic) BOOL isNew;

/**
* The duration of the call in seconds
*/
@property(nonatomic) NSNumber * duration;

/**
* UTC timestamp of the call start.
*/
@property(nonatomic) NSDate * callStart;

/**
* Account ID (in contact list) of a remote contact.
*/
@property(nonatomic) NSNumber * remoteAccountId;

/**
* Remote contact as user entered it.
*/
@property(nonatomic) NSString *remoteUserEnteredNumber;

/**
* Remote contact SIP address.
*/
@property(nonatomic) NSString *remoteContactSip;

/**
* Remote contact address.
*/
@property(nonatomic) NSString *remoteContact;

/**
* Remote contact name.
*/
@property(nonatomic) NSString *remoteContactName;

/**
* Remote number type.
*/
@property(nonatomic) NSNumber * numberType;

/**
* Remote number label.
*/
@property(nonatomic) NSString *numberLabel;

/**
* Account ID of a local account that answered/dialed this call.
*/
@property(nonatomic) NSNumber * accountId;

/**
* Finihsing status code of the SIP call.
*/
@property(nonatomic) NSNumber * statusCode;

/**
* Status text representation of the SIP call.
*/
@property(nonatomic)NSString *statusText;

/**
* By default user has to see the notification
*/
@property(nonatomic, assign) BOOL seenByUser;

/**
* Timestamp of the notification message.
*/
@property(nonatomic, assign) NSDate * eventTimestamp;

/**
* Nonce value for the notification message.
*/
@property(nonatomic, assign) NSNumber * eventNonce;

/**
* SIP Call ID value assigned to the particular call. Unique for each call.
*/
@property(nonatomic) NSString * sipCallId;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getLightProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
+(NSString *) getDefaultSortOrder;

+(NSString * const) getWhereForId;
+(NSArray*) getWhereForIdArgs: (const NSNumber * const) id;
+(NSString * const) getWhereForContact;
+(NSArray*) getWhereForContactArgs: (const PEXDbContact * const) contact;

- (instancetype)initWithCursor:(PEXDbCursor *)cursor;
+ (instancetype)callLogFromCursor:(PEXDbCursor *)cursor;
- (instancetype)initWithCall:(PEXPjCall *)call;
+ (instancetype)callogFromCall:(PEXPjCall *)call;

+(PEXUri *) addToDatabase: (PEXDbCallLog *) callLog cr: (PEXDbContentProvider *) cr;
+(BOOL) pruneRecords: (PEXDbContentProvider *) cr;
+(BOOL) probabilisticPrune: (PEXDbContentProvider *) cr;
+ (int)removeCallLogsFor:(NSString const *)remote cr: (PEXDbContentProvider *) cr;
+ (PEXDbCallLog *)getLogByEventDescription:(NSString *)from
                                      toId:(NSNumber *)toId
                                   evtTime:(NSDate *)time
                                  evtNonce:(NSNumber *)nonce
                                    callId:(NSString *)callId
                                        cr: (PEXDbContentProvider *) cr;

- (BOOL)isEqualToCallLog:(const PEXDbCallLog * const)callLog;

- (bool) isIncoming;

- (NSString *)description;
@end