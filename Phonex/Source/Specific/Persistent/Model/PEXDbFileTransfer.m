//
// Created by Dusan Klinec on 02.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbFileTransfer.h"
#import "PEXDbContentProvider.h"
#import "PEXUtils.h"
#import "PEXStringUtils.h"
#import "PEXDhKeyHelper.h"

NSString *PEX_DBFT_TABLE_NAME = @"fileTransfer";
NSString *PEX_DBFT_FIELD_ID = @"id";
NSString *PEX_DBFT_FIELD_MESSAGE_ID = @"messageId";
NSString *PEX_DBFT_FIELD_IS_OUTGOING = @"isOutgoing";
NSString *PEX_DBFT_FIELD_NONCE2 = @"nonce2";
NSString *PEX_DBFT_FIELD_NONCE1 = @"nonce1";
NSString *PEX_DBFT_FIELD_NONCEB = @"nonceb";
NSString *PEX_DBFT_FIELD_SALT1 = @"salt1";
NSString *PEX_DBFT_FIELD_SALTB = @"saltb";
NSString *PEX_DBFT_FIELD_C = @"c";
NSString *PEX_DBFT_FIELD_U_KEY_DATA = @"uKeyData";
NSString *PEX_DBFT_FIELD_META_FILE = @"metaFile";
NSString *PEX_DBFT_FIELD_META_HASH = @"metaHash";
NSString *PEX_DBFT_FIELD_META_STATE = @"metaState";
NSString *PEX_DBFT_FIELD_META_SIZE = @"metaSize";
NSString *PEX_DBFT_FIELD_META_PREP_REC = @"metaPrepRec";
NSString *PEX_DBFT_FIELD_PACK_FILE = @"packFile";
NSString *PEX_DBFT_FIELD_PACK_HASH = @"packHash";
NSString *PEX_DBFT_FIELD_PACK_STATE = @"packState";
NSString *PEX_DBFT_FIELD_PACK_SIZE = @"packSize";
NSString *PEX_DBFT_FIELD_PACK_PREP_REC = @"packPrepRec";
NSString *PEX_DBFT_FIELD_META_DATE = @"metaDate";
NSString *PEX_DBFT_FIELD_NUM_OF_FILES = @"numOfFiles";
NSString *PEX_DBFT_FIELD_TITLE = @"title";
NSString *PEX_DBFT_FIELD_DESCR = @"descr";
NSString *PEX_DBFT_FIELD_THUMB_DIR = @"thumb_dir";
NSString *PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER = @"shouldDeleteFromServer";
NSString *PEX_DBFT_FIELD_DELETED_FROM_SERVER = @"deletedFromServer";
NSString *PEX_DBFT_FIELD_DATE_CREATED = @"dateCreated";
NSString *PEX_DBFT_FIELD_DATE_FINISHED = @"dateFinished";
NSString *PEX_DBFT_FIELD_STATUS_CODE = @"statusCode";

@implementation PEXDbFileTransfer {}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                PEX_DBFT_FIELD_ID,
                PEX_DBFT_FIELD_MESSAGE_ID,
                PEX_DBFT_FIELD_IS_OUTGOING,
                PEX_DBFT_FIELD_NONCE2,
                PEX_DBFT_FIELD_NONCE1,
                PEX_DBFT_FIELD_NONCEB,
                PEX_DBFT_FIELD_SALT1,
                PEX_DBFT_FIELD_SALTB,
                PEX_DBFT_FIELD_C,
                PEX_DBFT_FIELD_U_KEY_DATA,
                PEX_DBFT_FIELD_META_FILE,
                PEX_DBFT_FIELD_META_HASH,
                PEX_DBFT_FIELD_META_STATE,
                PEX_DBFT_FIELD_META_SIZE,
                PEX_DBFT_FIELD_META_PREP_REC,
                PEX_DBFT_FIELD_PACK_FILE,
                PEX_DBFT_FIELD_PACK_HASH,
                PEX_DBFT_FIELD_PACK_STATE,
                PEX_DBFT_FIELD_PACK_SIZE,
                PEX_DBFT_FIELD_PACK_PREP_REC,
                PEX_DBFT_FIELD_META_DATE,
                PEX_DBFT_FIELD_NUM_OF_FILES,
                PEX_DBFT_FIELD_TITLE,
                PEX_DBFT_FIELD_DESCR,
                PEX_DBFT_FIELD_THUMB_DIR,
                PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER,
                PEX_DBFT_FIELD_DELETED_FROM_SERVER,
                PEX_DBFT_FIELD_DATE_CREATED,
                PEX_DBFT_FIELD_DATE_FINISHED,
                PEX_DBFT_FIELD_STATUS_CODE
        ];
    });
    return fullProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBFT_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBFT_TABLE_NAME isBase:YES];
    });
    return uriBase;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _nonce1 = nil;
        _nonce2 = nil;
        _nonceb = nil;
        _salt1  = nil;
        _saltb  = nil;
        _c      = nil;
        _metaState = @(PEX_FT_FILEDOWN_TYPE_NONE);
        _packState = @(PEX_FT_FILEDOWN_TYPE_NONE);
    }

    return self;
}

- (instancetype)initWithCursor: (PEXDbCursor *) c{
    self = [self init];
    if (self) {
        [self createFromCursor:c];
    }

    return self;
}

+ (NSString *)getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER PRIMARY KEY AUTOINCREMENT, "//  				 PEX_DBFT_FIELD_ID
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_MESSAGE_ID
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_IS_OUTGOING
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_NONCE2
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_NONCE1
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_NONCEB
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_SALT1
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_SALTB
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_C
                    "  %@  BLOB, "//  				 PEX_DBFT_FIELD_U_KEY_DATA
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_META_FILE
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_META_HASH
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_META_STATE
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_META_SIZE
                    "  %@  BLOB, "//  				 PEX_DBFT_FIELD_META_PREP_REC
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_PACK_FILE
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_PACK_HASH
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_PACK_STATE
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_PACK_SIZE
                    "  %@  BLOB, "//  				 PEX_DBFT_FIELD_PACK_PREP_REC
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_META_DATE
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_NUM_OF_FILES
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_TITLE
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_DESCR
                    "  %@  TEXT, "//  				 PEX_DBFT_FIELD_THUMB_DIR
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER
                    "  %@  INTEGER, "//  				 PEX_DBFT_FIELD_DELETED_FROM_SERVER
                    "  %@  NUMERIC, "//  				 PEX_DBFT_FIELD_DATE_CREATED
                    "  %@  NUMERIC, "//  				 PEX_DBFT_FIELD_DATE_FINISHED
                    "  %@  INTEGER "//  				 PEX_DBFT_FIELD_STATUS_CODE
                    " );",
            PEX_DBFT_TABLE_NAME,
            PEX_DBFT_FIELD_ID,
            PEX_DBFT_FIELD_MESSAGE_ID,
            PEX_DBFT_FIELD_IS_OUTGOING,
            PEX_DBFT_FIELD_NONCE2,
            PEX_DBFT_FIELD_NONCE1,
            PEX_DBFT_FIELD_NONCEB,
            PEX_DBFT_FIELD_SALT1,
            PEX_DBFT_FIELD_SALTB,
            PEX_DBFT_FIELD_C,
            PEX_DBFT_FIELD_U_KEY_DATA,
            PEX_DBFT_FIELD_META_FILE,
            PEX_DBFT_FIELD_META_HASH,
            PEX_DBFT_FIELD_META_STATE,
            PEX_DBFT_FIELD_META_SIZE,
            PEX_DBFT_FIELD_META_PREP_REC,
            PEX_DBFT_FIELD_PACK_FILE,
            PEX_DBFT_FIELD_PACK_HASH,
            PEX_DBFT_FIELD_PACK_STATE,
            PEX_DBFT_FIELD_PACK_SIZE,
            PEX_DBFT_FIELD_PACK_PREP_REC,
            PEX_DBFT_FIELD_META_DATE,
            PEX_DBFT_FIELD_NUM_OF_FILES,
            PEX_DBFT_FIELD_TITLE,
            PEX_DBFT_FIELD_DESCR,
            PEX_DBFT_FIELD_THUMB_DIR,
            PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER,
            PEX_DBFT_FIELD_DELETED_FROM_SERVER,
            PEX_DBFT_FIELD_DATE_CREATED,
            PEX_DBFT_FIELD_DATE_FINISHED,
            PEX_DBFT_FIELD_STATUS_CODE
    ];
    return createTable;
}

/**
* Create wrapper with content values pairs.
*
* @param args the content value to unpack.
*/
- (void)createFromCursor:(PEXDbCursor *)c {
    int colCount = [c getColumnCount];
    for (int i = 0; i < colCount; i++) {
        NSString *colname = [c getColumnName:i];
        if ([PEX_DBFT_FIELD_ID isEqualToString:colname]) {
            _id = [c getInt64:i];
        } else if ([PEX_DBFT_FIELD_MESSAGE_ID isEqualToString:colname]) {
            _messageId = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_IS_OUTGOING isEqualToString:colname]) {
            _isOutgoing = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_NONCE2 isEqualToString:colname]) {
            _nonce2 = [c getString:i];
        } else if ([PEX_DBFT_FIELD_NONCE1 isEqualToString:colname]) {
            _nonce1 = [c getString:i];
        } else if ([PEX_DBFT_FIELD_NONCEB isEqualToString:colname]) {
            _nonceb = [c getString:i];
        } else if ([PEX_DBFT_FIELD_SALT1 isEqualToString:colname]) {
            _salt1 = [c getString:i];
        } else if ([PEX_DBFT_FIELD_SALTB isEqualToString:colname]) {
            _saltb = [c getString:i];
        } else if ([PEX_DBFT_FIELD_C isEqualToString:colname]) {
            _c = [c getString:i];
        } else if ([PEX_DBFT_FIELD_U_KEY_DATA isEqualToString:colname]) {
            _uKeyData = [c getBlob:i];
        } else if ([PEX_DBFT_FIELD_META_FILE isEqualToString:colname]) {
            _metaFile = [c getString:i];
        } else if ([PEX_DBFT_FIELD_META_HASH isEqualToString:colname]) {
            _metaHash = [c getString:i];
        } else if ([PEX_DBFT_FIELD_META_STATE isEqualToString:colname]) {
            _metaState = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_META_SIZE isEqualToString:colname]) {
            _metaSize = [c getInt64:i];
        } else if ([PEX_DBFT_FIELD_META_PREP_REC isEqualToString:colname]) {
            _metaPrepRec = [c getBlob:i];
        } else if ([PEX_DBFT_FIELD_PACK_FILE isEqualToString:colname]) {
            _packFile = [c getString:i];
        } else if ([PEX_DBFT_FIELD_PACK_HASH isEqualToString:colname]) {
            _packHash = [c getString:i];
        } else if ([PEX_DBFT_FIELD_PACK_STATE isEqualToString:colname]) {
            _packState = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_PACK_SIZE isEqualToString:colname]) {
            _packSize = [c getInt64:i];
        } else if ([PEX_DBFT_FIELD_PACK_PREP_REC isEqualToString:colname]) {
            _packPrepRec = [c getBlob:i];
        } else if ([PEX_DBFT_FIELD_META_DATE isEqualToString:colname]) {
            _metaDate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBFT_FIELD_NUM_OF_FILES isEqualToString:colname]) {
            _numOfFiles = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_TITLE isEqualToString:colname]) {
            _title = [c getString:i];
        } else if ([PEX_DBFT_FIELD_DESCR isEqualToString:colname]) {
            _descr = [c getString:i];
        } else if ([PEX_DBFT_FIELD_THUMB_DIR isEqualToString:colname]) {
            _thumb_dir = [c getString:i];
        } else if ([PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER isEqualToString:colname]) {
            _shouldDeleteFromServer = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_DELETED_FROM_SERVER isEqualToString:colname]) {
            _deletedFromServer = [c getInt:i];
        } else if ([PEX_DBFT_FIELD_DATE_CREATED isEqualToString:colname]) {
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBFT_FIELD_DATE_FINISHED isEqualToString:colname]) {
            _dateFinished = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBFT_FIELD_STATUS_CODE isEqualToString:colname]) {
            _statusCode = [c getInt:i];
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
- (PEXDbContentValues *)getDbContentValues {
    PEXDbContentValues *cv = [[PEXDbContentValues alloc] init];
    if (_id != nil && [_id longLongValue] != -1ll) {
        [cv put:PEX_DBFT_FIELD_ID NSNumberAsLongLong:_id];
    }
    if (_messageId != nil)
        [cv put:PEX_DBFT_FIELD_MESSAGE_ID number:_messageId];
    if (_isOutgoing != nil)
        [cv put:PEX_DBFT_FIELD_IS_OUTGOING number:_isOutgoing];
    if (_nonce2 != nil)
        [cv put:PEX_DBFT_FIELD_NONCE2 string:_nonce2];
    if (_nonce1 != nil)
        [cv put:PEX_DBFT_FIELD_NONCE1 string:_nonce1];
    if (_nonceb != nil)
        [cv put:PEX_DBFT_FIELD_NONCEB string:_nonceb];
    if (_salt1 != nil)
        [cv put:PEX_DBFT_FIELD_SALT1 string:_salt1];
    if (_saltb != nil)
        [cv put:PEX_DBFT_FIELD_SALTB string:_saltb];
    if (_c != nil)
        [cv put:PEX_DBFT_FIELD_C string:_c];
    if (_uKeyData != nil)
        [cv put:PEX_DBFT_FIELD_U_KEY_DATA data:_uKeyData];
    if (_metaFile != nil)
        [cv put:PEX_DBFT_FIELD_META_FILE string:_metaFile];
    if (_metaHash != nil)
        [cv put:PEX_DBFT_FIELD_META_HASH string:_metaHash];
    if (_metaState != nil)
        [cv put:PEX_DBFT_FIELD_META_STATE number:_metaState];
    if (_metaSize != nil)
        [cv put:PEX_DBFT_FIELD_META_SIZE number:_metaSize];
    if (_metaPrepRec != nil)
        [cv put:PEX_DBFT_FIELD_META_PREP_REC data:_metaPrepRec];
    if (_packFile != nil)
        [cv put:PEX_DBFT_FIELD_PACK_FILE string:_packFile];
    if (_packHash != nil)
        [cv put:PEX_DBFT_FIELD_PACK_HASH string:_packHash];
    if (_packState != nil)
        [cv put:PEX_DBFT_FIELD_PACK_STATE number:_packState];
    if (_packSize != nil)
        [cv put:PEX_DBFT_FIELD_PACK_SIZE number:_packSize];
    if (_packPrepRec != nil)
        [cv put:PEX_DBFT_FIELD_PACK_PREP_REC data:_packPrepRec];
    if (_metaDate != nil)
        [cv put:PEX_DBFT_FIELD_META_DATE date:_metaDate];
    if (_numOfFiles != nil)
        [cv put:PEX_DBFT_FIELD_NUM_OF_FILES number:_numOfFiles];
    if (_title != nil)
        [cv put:PEX_DBFT_FIELD_TITLE string:_title];
    if (_descr != nil)
        [cv put:PEX_DBFT_FIELD_DESCR string:_descr];
    if (_thumb_dir != nil)
        [cv put:PEX_DBFT_FIELD_THUMB_DIR string:_thumb_dir];
    if (_shouldDeleteFromServer != nil)
        [cv put:PEX_DBFT_FIELD_SHOULD_DELETE_FROM_SERVER number:_shouldDeleteFromServer];
    if (_deletedFromServer != nil)
        [cv put:PEX_DBFT_FIELD_DELETED_FROM_SERVER number:_deletedFromServer];
    if (_dateCreated != nil)
        [cv put:PEX_DBFT_FIELD_DATE_CREATED date:_dateCreated];
    if (_dateFinished != nil)
        [cv put:PEX_DBFT_FIELD_DATE_FINISHED date:_dateFinished];
    if (_statusCode != nil)
        [cv put:PEX_DBFT_FIELD_STATUS_CODE number:_statusCode];

    return cv;
}

- (instancetype)initWithNonce2:(NSString *)nonce2 msgId:(int64_t) msgId cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    @try {
        NSArray   * args = nil;
        NSString * where = nil;
        if (nonce2 == nil){
            where = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBFT_FIELD_MESSAGE_ID];
            args  = @[[@(msgId) stringValue]];
        } else {
            where = [NSString stringWithFormat:@"WHERE %@=? AND %@=?", PEX_DBFT_FIELD_MESSAGE_ID, PEX_DBFT_FIELD_NONCE2];
            args  = @[[@(msgId) stringValue], nonce2];
        }

        c = [cr query:[PEXDbFileTransfer getURI]
           projection:[PEXDbFileTransfer getFullProjection]
            selection:where
        selectionArgs:args
            sortOrder:nil];

        if (c == nil || ![c moveToFirst]){
            return nil;
        }

        return [[PEXDbFileTransfer alloc] initWithCursor:c];
    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);
        return nil;
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}

- (BOOL)isMarkedToDeleteFromServer {
    return _shouldDeleteFromServer != nil && [_shouldDeleteFromServer boolValue];
}

- (BOOL)isMetaDone {
    return _metaState != nil && [_metaState integerValue] == PEX_FT_FILEDOWN_TYPE_DONE;
}

- (BOOL)isPackDone {
    return _packState != nil && [_packState integerValue] == PEX_FT_FILEDOWN_TYPE_DONE;
}

- (BOOL)isKeyComputingDone {
    return (_c != nil && [_c length] > 0) || [self isMetaDone] || [self isPackDone];
}

- (void)clearCryptoMaterial {
    _nonce1 = @"";
    _nonceb = @"";
    _salt1  = @"";
    _saltb  = @"";
    _c      = @"";
    _uKeyData    = [NSData data];
    _metaPrepRec = [NSData data];
    _packPrepRec = [NSData data];
}

+ (void)deleteByDbMessageId:(int64_t)msgId cr:(PEXDbContentProvider *)cr {
    @try {
        [cr delete:[PEXDbFileTransfer getURI]
         selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBFT_FIELD_MESSAGE_ID]
     selectionArgs:@[[@(msgId) stringValue]]];

    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);

    }
}

+ (PEXDbFileTransfer *) deleteTempFileByDbMessageId:(int64_t)msgId cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    @try {
        c = [cr query:[PEXDbFileTransfer getURI]
           projection:[PEXDbFileTransfer getFullProjection]
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBFT_FIELD_MESSAGE_ID]
        selectionArgs:@[[@(msgId) stringValue]]
            sortOrder:nil];

        if (c == nil || ![c moveToFirst]){
            return nil;
        }

        PEXDbFileTransfer * ft = [[PEXDbFileTransfer alloc] init];
        [ft createFromCursor:c];
        [ft removeTempFiles];
        return ft;

    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);

    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    return nil;
}

-(void) removeTempFtFile: (NSString *) path {
    @try {
        if (![PEXStringUtils isEmpty:path]) {
            NSString *pth = [PEXDhKeyHelper correctFTFile:path];
            [PEXUtils removeFile:pth];
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in tmpFile removal, exception=%@", e);
    }
}

-(void) removeDownloadFile: (NSUInteger) idx {
    NSString * path = [PEXDhKeyHelper getFileNameForDownload:idx nonce2:_nonce2];
    if ([PEXUtils fileExistsAndIsAfile:path]){
        DDLogVerbose(@"Deleting download file %@", path);
        [PEXUtils removeFile:path];
    }
}

- (void)removeTempFiles {
    [self removeTempFtFile:_metaFile];
    [self removeTempFtFile:_packFile];
    [self removeDownloadFile:PEX_FT_META_IDX];
    [self removeDownloadFile:PEX_FT_ARCH_IDX];
}

@end


