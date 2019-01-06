//
// Created by Dusan Klinec on 02.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbUri;
@class PEXDbCursor;
@class PEXDbAppContentProvider;
@class PEXDbContentProvider;

typedef enum {
    PEX_FT_FILEDOWN_TYPE_NONE=0,        // Stage not reached yet.
    PEX_FT_FILEDOWN_TYPE_STARTED=1,     // Stage started, not yet finished, maybe interrupted during progress.
    PEX_FT_FILEDOWN_TYPE_DONE=2,        // Stage finished (either finished of skipped).
} PEX_FT_FILEDOWN_TYPE;

extern NSString *PEX_DBFT_TABLE_NAME;
extern NSString *PEX_DBFT_FIELD_ID;
extern NSString *PEX_DBFT_FIELD_MESSAGE_ID;
extern NSString *PEX_DBFT_FIELD_IS_OUTGOING;
extern NSString *PEX_DBFT_FIELD_NONCE2;
extern NSString *PEX_DBFT_FIELD_NONCE1;
extern NSString *PEX_DBFT_FIELD_NONCEB;
extern NSString *PEX_DBFT_FIELD_SALT1;
extern NSString *PEX_DBFT_FIELD_SALTB;
extern NSString *PEX_DBFT_FIELD_C;
extern NSString *PEX_DBFT_FIELD_U_KEY_DATA;
extern NSString *PEX_DBFT_FIELD_META_FILE;
extern NSString *PEX_DBFT_FIELD_META_HASH;
extern NSString *PEX_DBFT_FIELD_META_STATE;
extern NSString *PEX_DBFT_FIELD_META_SIZE;
extern NSString *PEX_DBFT_FIELD_META_PREP_REC;
extern NSString *PEX_DBFT_FIELD_PACK_FILE;
extern NSString *PEX_DBFT_FIELD_PACK_HASH;
extern NSString *PEX_DBFT_FIELD_PACK_STATE;
extern NSString *PEX_DBFT_FIELD_PACK_SIZE;
extern NSString *PEX_DBFT_FIELD_PACK_PREP_REC;
extern NSString *PEX_DBFT_FIELD_META_DATE;
extern NSString *PEX_DBFT_FIELD_NUM_OF_FILES;
extern NSString *PEX_DBFT_FIELD_TITLE;
extern NSString *PEX_DBFT_FIELD_DESCR;
extern NSString *PEX_DBFT_FIELD_THUMB_DIR;
extern NSString *PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER;
extern NSString *PEX_DBFT_FIELD_DELETED_FROM_SERVER;
extern NSString *PEX_DBFT_FIELD_DATE_CREATED;
extern NSString *PEX_DBFT_FIELD_DATE_FINISHED;
extern NSString *PEX_DBFT_FIELD_STATUS_CODE;

@interface PEXDbFileTransfer : PEXDbModelBase
@property(nonatomic) NSNumber * id;
@property(nonatomic) NSNumber * messageId;
@property(nonatomic) NSNumber * isOutgoing; // boolean redundant informative flag to avoid join.

@property(nonatomic) NSString * nonce2;
@property(nonatomic) NSString * nonce1;
@property(nonatomic) NSString * nonceb;
@property(nonatomic) NSString * salt1;
@property(nonatomic) NSString * saltb;
@property(nonatomic) NSString * c;
@property(nonatomic) NSData   * uKeyData;   // Required for upload.

@property(nonatomic) NSString * metaFile;
@property(nonatomic) NSString * metaHash;
@property(nonatomic) NSNumber * metaState;
@property(nonatomic) NSNumber * metaSize;
@property(nonatomic) NSData   * metaPrepRec; // Required for upload.

@property(nonatomic) NSString * packFile;
@property(nonatomic) NSString * packHash;
@property(nonatomic) NSNumber * packState;
@property(nonatomic) NSNumber * packSize;
@property(nonatomic) NSData   * packPrepRec; // Required for upload

@property(nonatomic) NSDate   * metaDate;
@property(nonatomic) NSNumber * numOfFiles;
@property(nonatomic) NSString * title;
@property(nonatomic) NSString * descr;

@property(nonatomic) NSString * thumb_dir;
@property(nonatomic) NSNumber * shouldDeleteFromServer;
@property(nonatomic) NSNumber * deletedFromServer;

@property(nonatomic) NSDate * dateCreated;
@property(nonatomic) NSDate * dateFinished;
@property(nonatomic) NSNumber * statusCode;

- (instancetype)initWithCursor: (PEXDbCursor *) c;
+ (NSString *)getCreateTable;

+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
+(NSArray *) getFullProjection;
- (instancetype)initWithNonce2:(NSString *)nonce2 msgId:(int64_t) msgId cr:(PEXDbContentProvider *)cr;

-(BOOL) isMarkedToDeleteFromServer;
-(BOOL) isMetaDone;
-(BOOL) isPackDone;
-(BOOL) isKeyComputingDone;
-(void) clearCryptoMaterial;

/**
* Deletes transfer record based on the ID of associated DbMessage.
*/
+ (void)deleteByDbMessageId:(int64_t)msgId cr:(PEXDbContentProvider *)cr;

/**
* Deletes all temporary files related to the transfer associated with given DbMessage.
*/
+ (PEXDbFileTransfer *)deleteTempFileByDbMessageId:(int64_t)msgId cr:(PEXDbContentProvider *)cr;

/**
* Removes temporary files created during upload process.
*/
- (void) removeTempFiles;

- (void)createFromCursor:(PEXDbCursor *)c;
- (PEXDbContentValues *)getDbContentValues;
@end
