//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbContentProvider;

// For PEX_DBRF_FIELD_RECORD_TYPE.
typedef enum  {
    PEX_RECV_FILE_META = 0,
    PEX_RECV_FILE_FULL = 1
} PEXReceivedFileRecordType;

FOUNDATION_EXPORT NSString * PEX_DBRF_TABLE_NAME;

extern NSString *PEX_DBRF_FIELD_ID;
extern NSString *PEX_DBRF_FIELD_NONCE2;
extern NSString *PEX_DBRF_FIELD_MSG_ID;
extern NSString *PEX_DBRF_FIELD_TRANSFER_ID;
extern NSString *PEX_DBRF_FIELD_IS_ASSET;
extern NSString *PEX_DBRF_FIELD_FILE_NAME;
extern NSString *PEX_DBRF_FIELD_MIME_TYPE;
extern NSString *PEX_DBRF_FIELD_FILE_HASH;
extern NSString *PEX_DBRF_FIELD_FILE_META_HASH;
extern NSString *PEX_DBRF_FIELD_PATH;
extern NSString *PEX_DBRF_FIELD_TITLE;
extern NSString *PEX_DBRF_FIELD_DESC;
extern NSString *PEX_DBRF_FIELD_SIZE;
extern NSString *PEX_DBRF_FIELD_PREF_ORDER;
extern NSString *PEX_DBRF_FIELD_DATE_RECEIVED;
extern NSString *PEX_DBRF_FIELD_THUMB_FILE_NAME;
extern NSString *PEX_DBRF_FIELD_RECORD_TYPE;

@interface PEXDbReceivedFile : PEXDbModelBase

// <ATTRIBUTES>
@property (nonatomic) NSNumber * id;
@property (nonatomic) NSString * nonce2;
@property (nonatomic) NSNumber * msgId;      // Message / notification ID associated to this record.
@property (nonatomic) NSNumber * transferId; // FileTransfer ID associated to this record.
@property (nonatomic) NSNumber * isAsset;    // Indicator whether uploaded file comes from assets library.
@property (nonatomic) NSString * fileName;
@property (nonatomic) NSString * mimeType;
@property (nonatomic) NSString * fileHash;
@property (nonatomic) NSString * fileMetaHash; // Hash for the file parsed from meta file
@property (nonatomic) NSString * path;
@property (nonatomic) NSString * title;
@property (nonatomic) NSString * desc;
@property (nonatomic) NSNumber * size;
@property (nonatomic) NSNumber * prefOrder;
@property (nonatomic) NSDate   * dateReceived;
@property (nonatomic) NSString * thumbFileName;
@property (nonatomic) NSNumber * recordType;    // meta / full.
// </ATTRIBUTES>

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
- (instancetype)initWithCursor: (PEXDbCursor *) c;
- (void)createFromCursor:(PEXDbCursor *)c;
- (PEXDbContentValues *)getDbContentValues;

- (instancetype)initWithId:(NSNumber *)id cr:(PEXDbContentProvider *)cr;
- (instancetype)initWithMsgId:(NSNumber *)id fileName: (NSString *) fname cr:(PEXDbContentProvider *)cr;

/**
* Deletes all file records associated to the given DbMessage.
*/
+ (void) deleteByDbMessageId: (int64_t) msgId cr:(PEXDbContentProvider *)cr;

/**
* Delete all potential thumbnails associated with the message id.
* @param cr
* @param msgId
* @return
*/
+ (void) deleteThumbs: (int64_t)msgId thumbDir: (NSString *) thumbDir cr:(PEXDbContentProvider *)cr;

/**
* Deletes all file records associated to the given transport record.
*/
+ (void) deleteByFtRecordId: (int64_t) ftId cr:(PEXDbContentProvider *)cr;

- (NSString *)description;

+ (NSString *) getWhereForMessage;
+ (NSArray*) getWhereForMessageArgs: (const PEXDbMessage * const) message;
@end