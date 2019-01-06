//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbReceivedFile.h"
#import "PEXDbContentProvider.h"
#import "PEXUtils.h"
#import "PEXDBMessage.h"

NSString * PEX_DBRF_TABLE_NAME = @"ReceivedFile";

// <FIELD_NAMES>
NSString *PEX_DBRF_FIELD_ID = @"id";
NSString *PEX_DBRF_FIELD_NONCE2 = @"nonce2";
NSString *PEX_DBRF_FIELD_MSG_ID = @"msgId";
NSString *PEX_DBRF_FIELD_TRANSFER_ID = @"transferId";
NSString *PEX_DBRF_FIELD_IS_ASSET = @"isAsset";
NSString *PEX_DBRF_FIELD_FILE_NAME = @"fileName";
NSString *PEX_DBRF_FIELD_MIME_TYPE = @"mimeType";
NSString *PEX_DBRF_FIELD_FILE_HASH = @"fileHash";
NSString *PEX_DBRF_FIELD_FILE_META_HASH = @"fileMetaHash";
NSString *PEX_DBRF_FIELD_PATH = @"path";
NSString *PEX_DBRF_FIELD_TITLE = @"title";
NSString *PEX_DBRF_FIELD_DESC = @"desc";
NSString *PEX_DBRF_FIELD_SIZE = @"size";
NSString *PEX_DBRF_FIELD_PREF_ORDER = @"prefOrder";
NSString *PEX_DBRF_FIELD_DATE_RECEIVED = @"dateReceived";
NSString *PEX_DBRF_FIELD_THUMB_FILE_NAME = @"thumbFileName";
NSString *PEX_DBRF_FIELD_RECORD_TYPE = @"recordType";
// </FIELD_NAMES>

@implementation PEXDbReceivedFile {

}

+ (NSString *)getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER PRIMARY KEY AUTOINCREMENT, "//  				 PEX_DBRF_FIELD_ID
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_NONCE2
                    "  %@  INTEGER, "//  				 PEX_DBRF_FIELD_MSG_ID
                    "  %@  INTEGER, "//  				 PEX_DBRF_FIELD_TRANSFER_ID
                    "  %@  INTEGER, "//  				 PEX_DBRF_FIELD_IS_ASSET
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_FILE_NAME
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_MIME_TYPE
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_FILE_HASH
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_FILE_META_HASH
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_PATH
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_TITLE
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_DESC
                    "  %@  INTEGER, "//  				 PEX_DBRF_FIELD_SIZE
                    "  %@  INTEGER, "//  				 PEX_DBRF_FIELD_PREF_ORDER
                    "  %@  NUMERIC, "//  				 PEX_DBRF_FIELD_DATE_RECEIVED
                    "  %@  TEXT, "//  				 PEX_DBRF_FIELD_THUMB_FILE_NAME
                    "  %@  INTEGER "//  				 PEX_DBRF_FIELD_RECORD_TYPE
                    " );",
            PEX_DBRF_TABLE_NAME,
            PEX_DBRF_FIELD_ID,
            PEX_DBRF_FIELD_NONCE2,
            PEX_DBRF_FIELD_MSG_ID,
            PEX_DBRF_FIELD_TRANSFER_ID,
            PEX_DBRF_FIELD_IS_ASSET,
            PEX_DBRF_FIELD_FILE_NAME,
            PEX_DBRF_FIELD_MIME_TYPE,
            PEX_DBRF_FIELD_FILE_HASH,
            PEX_DBRF_FIELD_FILE_META_HASH,
            PEX_DBRF_FIELD_PATH,
            PEX_DBRF_FIELD_TITLE,
            PEX_DBRF_FIELD_DESC,
            PEX_DBRF_FIELD_SIZE,
            PEX_DBRF_FIELD_PREF_ORDER,
            PEX_DBRF_FIELD_DATE_RECEIVED,
            PEX_DBRF_FIELD_THUMB_FILE_NAME,
            PEX_DBRF_FIELD_RECORD_TYPE
    ];
    return createTable;
}


+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[PEX_DBRF_FIELD_ID,
                PEX_DBRF_FIELD_NONCE2,
                PEX_DBRF_FIELD_MSG_ID,
                PEX_DBRF_FIELD_TRANSFER_ID,
                PEX_DBRF_FIELD_IS_ASSET,
                PEX_DBRF_FIELD_FILE_NAME,
                PEX_DBRF_FIELD_MIME_TYPE,
                PEX_DBRF_FIELD_FILE_HASH,
                PEX_DBRF_FIELD_FILE_META_HASH,
                PEX_DBRF_FIELD_PATH,
                PEX_DBRF_FIELD_TITLE,
                PEX_DBRF_FIELD_DESC,
                PEX_DBRF_FIELD_SIZE,
                PEX_DBRF_FIELD_PREF_ORDER,
                PEX_DBRF_FIELD_DATE_RECEIVED,
                PEX_DBRF_FIELD_THUMB_FILE_NAME,
                PEX_DBRF_FIELD_RECORD_TYPE
        ];
    });
    return fullProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBRF_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBRF_TABLE_NAME isBase:YES];
    });
    return uriBase;
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
        if ([PEX_DBRF_FIELD_ID isEqualToString:colname]) {
            _id = [c getInt64:i];
        } else if ([PEX_DBRF_FIELD_NONCE2 isEqualToString:colname]) {
            _nonce2 = [c getString:i];
        } else if ([PEX_DBRF_FIELD_MSG_ID isEqualToString:colname]) {
            _msgId = [c getInt64:i];
        } else if ([PEX_DBRF_FIELD_TRANSFER_ID isEqualToString:colname]) {
            _transferId = [c getInt64:i];
        } else if ([PEX_DBRF_FIELD_IS_ASSET isEqualToString:colname]) {
            _isAsset = [c getInt:i];
        } else if ([PEX_DBRF_FIELD_FILE_NAME isEqualToString:colname]) {
            _fileName = [c getString:i];
        } else if ([PEX_DBRF_FIELD_MIME_TYPE isEqualToString:colname]) {
            _mimeType = [c getString:i];
        } else if ([PEX_DBRF_FIELD_FILE_HASH isEqualToString:colname]) {
            _fileHash = [c getString:i];
        } else if ([PEX_DBRF_FIELD_FILE_META_HASH isEqualToString:colname]) {
            _fileMetaHash = [c getString:i];
        } else if ([PEX_DBRF_FIELD_PATH isEqualToString:colname]) {
            _path = [c getString:i];
        } else if ([PEX_DBRF_FIELD_TITLE isEqualToString:colname]) {
            _title = [c getString:i];
        } else if ([PEX_DBRF_FIELD_DESC isEqualToString:colname]) {
            _desc = [c getString:i];
        } else if ([PEX_DBRF_FIELD_SIZE isEqualToString:colname]) {
            _size = [c getInt64:i];
        } else if ([PEX_DBRF_FIELD_PREF_ORDER isEqualToString:colname]) {
            _prefOrder = [c getInt:i];
        } else if ([PEX_DBRF_FIELD_DATE_RECEIVED isEqualToString:colname]) {
            _dateReceived = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBRF_FIELD_THUMB_FILE_NAME isEqualToString:colname]) {
            _thumbFileName = [c getString:i];
        } else if ([PEX_DBRF_FIELD_RECORD_TYPE isEqualToString:colname]) {
            _recordType = [c getInt:i];
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
        [cv put:PEX_DBRF_FIELD_ID NSNumberAsLongLong:_id];
    }
    if (_nonce2 != nil)
        [cv put:PEX_DBRF_FIELD_NONCE2 string:_nonce2];
    if (_msgId != nil)
        [cv put:PEX_DBRF_FIELD_MSG_ID number:_msgId];
    if (_transferId != nil)
        [cv put:PEX_DBRF_FIELD_TRANSFER_ID number:_transferId];
    if (_isAsset != nil)
        [cv put:PEX_DBRF_FIELD_IS_ASSET number:_isAsset];
    if (_fileName != nil)
        [cv put:PEX_DBRF_FIELD_FILE_NAME string:_fileName];
    if (_mimeType != nil)
        [cv put:PEX_DBRF_FIELD_MIME_TYPE string:_mimeType];
    if (_fileHash != nil)
        [cv put:PEX_DBRF_FIELD_FILE_HASH string:_fileHash];
    if (_fileMetaHash != nil)
        [cv put:PEX_DBRF_FIELD_FILE_META_HASH string:_fileMetaHash];
    if (_path != nil)
        [cv put:PEX_DBRF_FIELD_PATH string:_path];
    if (_title != nil)
        [cv put:PEX_DBRF_FIELD_TITLE string:_title];
    if (_desc != nil)
        [cv put:PEX_DBRF_FIELD_DESC string:_desc];
    if (_size != nil)
        [cv put:PEX_DBRF_FIELD_SIZE number:_size];
    if (_prefOrder != nil)
        [cv put:PEX_DBRF_FIELD_PREF_ORDER number:_prefOrder];
    if (_dateReceived != nil)
        [cv put:PEX_DBRF_FIELD_DATE_RECEIVED date:_dateReceived];
    if (_thumbFileName != nil)
        [cv put:PEX_DBRF_FIELD_THUMB_FILE_NAME string:_thumbFileName];
    if (_recordType != nil)
        [cv put:PEX_DBRF_FIELD_RECORD_TYPE number:_recordType];

    return cv;
}


- (instancetype)initWithCursor: (PEXDbCursor *) c{
    self = [super init];
    if (self) {
        [self createFromCursor:c];
    }

    return self;
}

- (instancetype)initWithId:(NSNumber *)id cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    if (id == nil){
        return nil;
    }

    @try {
        c = [cr query:[PEXDbReceivedFile getURI]
           projection:[PEXDbReceivedFile getFullProjection]
            selection:[NSString stringWithFormat:@"WHERE %@=? ", PEX_DBRF_FIELD_ID]
        selectionArgs:@[[id stringValue]]
            sortOrder:nil];

        if (c == nil|| ![c moveToFirst]){
            return nil;
        }

        return [[PEXDbReceivedFile alloc] initWithCursor:c];
    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);
        return nil;
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}

- (instancetype)initWithMsgId:(NSNumber *)id fileName: (NSString *) fname cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    if (id == nil){
        return nil;
    }

    @try {
        c = [cr query:[PEXDbReceivedFile getURI]
           projection:[PEXDbReceivedFile getFullProjection]
            selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=?", PEX_DBRF_FIELD_MSG_ID, PEX_DBRF_FIELD_FILE_NAME]
        selectionArgs:@[[id stringValue], fname]
            sortOrder:nil];

        if (c == nil|| ![c moveToFirst]){
            return nil;
        }

        return [[PEXDbReceivedFile alloc] initWithCursor:c];
    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);
        return nil;
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}

+ (void)deleteByDbMessageId:(int64_t)msgId cr:(PEXDbContentProvider *)cr {
    @try {
        [cr delete:[PEXDbReceivedFile getURI]
         selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBRF_FIELD_MSG_ID]
        selectionArgs:@[[@(msgId) stringValue]]];

    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);

    }
}

/**
* Delete all potential thumbnails associated with the message id.
* @param cr
* @param msgId
* @return
*/
+ (void) deleteThumbs: (int64_t)msgId thumbDir: (NSString *) thumbDir cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    @try {
        c = [cr query:[PEXDbReceivedFile getURI]
            projection:[PEXDbReceivedFile getFullProjection]
             selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBRF_FIELD_MSG_ID]
         selectionArgs:@[[NSString stringWithFormat:@"%lld", msgId]]
             sortOrder:nil];

        if (c == nil){
            return;
        }

        while([c moveToNext]){
            PEXDbReceivedFile * fl = [[PEXDbReceivedFile alloc] init];
            [fl createFromCursor:c];

            NSString * thumbName = fl.thumbFileName;
            if ([PEXUtils isEmpty: thumbName]){
                continue;
            }

            @try {
                NSString * thumbPath = [NSString pathWithComponents:@[thumbDir, thumbName]];
                [PEXUtils removeFile:thumbPath];

            } @catch(NSException * ex){
                DDLogError(@"Could not delete thumb file, exception=%@", ex);
            }
        }

    } @catch(NSException * e){
        DDLogError(@"Exception in deleting thumbnails, exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}

+ (void)deleteByFtRecordId:(int64_t)ftId cr:(PEXDbContentProvider *)cr {
    @try {
        [cr delete:[PEXDbReceivedFile getURI]
         selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBRF_FIELD_TRANSFER_ID]
     selectionArgs:@[[@(ftId) stringValue]]];

    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);

    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.dateReceived = [coder decodeObjectForKey:@"self.dateReceived"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.nonce2 = [coder decodeObjectForKey:@"self.nonce2"];
        self.msgId = [coder decodeObjectForKey:@"self.msgId"];
        self.transferId = [coder decodeObjectForKey:@"self.transferId"];
        self.isAsset = [coder decodeObjectForKey:@"self.isAsset"];
        self.fileName = [coder decodeObjectForKey:@"self.fileName"];
        self.mimeType = [coder decodeObjectForKey:@"self.mimeType"];
        self.fileHash = [coder decodeObjectForKey:@"self.fileHash"];
        self.fileMetaHash = [coder decodeObjectForKey:@"self.fileMetaHash"];
        self.path = [coder decodeObjectForKey:@"self.path"];
        self.title = [coder decodeObjectForKey:@"self.title"];
        self.desc = [coder decodeObjectForKey:@"self.desc"];
        self.size = [coder decodeObjectForKey:@"self.size"];
        self.prefOrder = [coder decodeObjectForKey:@"self.prefOrder"];
        self.thumbFileName = [coder decodeObjectForKey:@"self.thumbFileName"];
        self.recordType = [coder decodeObjectForKey:@"self.recordType"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.dateReceived forKey:@"self.dateReceived"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.nonce2 forKey:@"self.nonce2"];
    [coder encodeObject:self.msgId forKey:@"self.msgId"];
    [coder encodeObject:self.transferId forKey:@"self.transferId"];
    [coder encodeObject:self.isAsset forKey:@"self.isAsset"];
    [coder encodeObject:self.fileName forKey:@"self.fileName"];
    [coder encodeObject:self.mimeType forKey:@"self.mimeType"];
    [coder encodeObject:self.fileHash forKey:@"self.fileHash"];
    [coder encodeObject:self.fileMetaHash forKey:@"self.fileMetaHash"];
    [coder encodeObject:self.path forKey:@"self.path"];
    [coder encodeObject:self.title forKey:@"self.title"];
    [coder encodeObject:self.desc forKey:@"self.desc"];
    [coder encodeObject:self.size forKey:@"self.size"];
    [coder encodeObject:self.prefOrder forKey:@"self.prefOrder"];
    [coder encodeObject:self.thumbFileName forKey:@"self.thumbFileName"];
    [coder encodeObject:self.recordType forKey:@"self.recordType"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbReceivedFile *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.dateReceived = self.dateReceived;
        copy.id = self.id;
        copy.nonce2 = self.nonce2;
        copy.msgId = self.msgId;
        copy.transferId = self.transferId;
        copy.isAsset = self.isAsset;
        copy.fileName = self.fileName;
        copy.mimeType = self.mimeType;
        copy.fileHash = self.fileHash;
        copy.fileMetaHash = self.fileMetaHash;
        copy.path = self.path;
        copy.title = self.title;
        copy.desc = self.desc;
        copy.size = self.size;
        copy.prefOrder = self.prefOrder;
        copy.thumbFileName = self.thumbFileName;
        copy.recordType = self.recordType;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.dateReceived=%@", self.dateReceived];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.nonce2=%@", self.nonce2];
    [description appendFormat:@", self.msgId=%@", self.msgId];
    [description appendFormat:@", self.transferId=%@", self.transferId];
    [description appendFormat:@", self.isAsset=%@", self.isAsset];
    [description appendFormat:@", self.fileName=%@", self.fileName];
    [description appendFormat:@", self.mimeType=%@", self.mimeType];
    [description appendFormat:@", self.fileHash=%@", self.fileHash];
    [description appendFormat:@", self.fileMetaHash=%@", self.fileMetaHash];
    [description appendFormat:@", self.path=%@", self.path];
    [description appendFormat:@", self.title=%@", self.title];
    [description appendFormat:@", self.desc=%@", self.desc];
    [description appendFormat:@", self.size=%@", self.size];
    [description appendFormat:@", self.prefOrder=%@", self.prefOrder];
    [description appendFormat:@", self.thumbFileName=%@", self.thumbFileName];
    [description appendFormat:@", self.recordType=%@", self.recordType];
    [description appendString:@">"];
    return description;
}

+ (NSString *) getWhereForMessage
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBRF_FIELD_MSG_ID];
    });
    return result;
}

+ (NSArray*) getWhereForMessageArgs: (const PEXDbMessage * const) message
{
    return @[[message.id stringValue]];
}

@end