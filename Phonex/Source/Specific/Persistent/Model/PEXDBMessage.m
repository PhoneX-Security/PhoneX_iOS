//
// Created by Dusan Klinec on 26.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbMessage.h"
#import "PEXSipUri.h"
#import "PEXDbContentValues.h"
#import "PEXDbContentProvider.h"
#import "PEXDbUri.h"

#import "PEXDbContact.h"
#import "PEXCryptoUtils.h"
#import "PEXDbContentProvider.h"
#import "PEXUtils.h"

/**
* Holder for a sip message.<br/>
* It allows to prepare / unpack content values of a SIP message.
*/
@implementation PEXDbMessage { }

NSString * PEXDBMessage_FIELD_ID = @"id";
NSString * PEXDBMessage_FIELD_ID_FROM_THREADS_ALIAS = @"_id";
NSString * PEXDBMessage_FIELD_FROM = @"sender";
NSString * PEXDBMessage_FIELD_TO = @"receiver";
NSString * PEXDBMessage_FIELD_CONTACT = @"contact";
NSString * PEXDBMessage_FIELD_BODY = @"body";
NSString * PEXDBMessage_FIELD_BODY_HASH = @"bodyHash";
NSString * PEXDBMessage_FIELD_BODY_DECRYPTED = @"bodyDecrypted";
NSString * PEXDBMessage_FIELD_SIGNATURE_OK = @"signatureOK";
NSString * PEXDBMessage_FIELD_DECRYPTION_STATUS = @"decryptionStatus";
NSString * PEXDBMessage_FIELD_RANDOM_NUM = @"randNum";
NSString * PEXDBMessage_FIELD_SEND_DATE = @"sendDate";
NSString * PEXDBMessage_FIELD_RESEND_DATE = @"resendDate";
NSString * PEXDBMessage_FIELD_IS_OUTGOING = @"isOutgoing";
NSString * PEXDBMessage_FIELD_IS_OFFLINE = @"isOffline";
NSString * PEXDBMessage_FIELD_ERROR_CODE = @"msgErrorCode";
NSString * PEXDBMessage_FIELD_ERROR_TEXT = @"msgErrorText";
NSString * PEXDBMessage_FIELD_MIME_TYPE = @"mime_type";
NSString * PEXDBMessage_FIELD_TYPE = @"type";
NSString * PEXDBMessage_FIELD_DATE = @"date";
NSString * PEXDBMessage_FIELD_STATUS = @"status";
NSString * PEXDBMessage_FIELD_READ = @"read";
NSString * PEXDBMessage_FIELD_READ_DATE = @"read_date";
NSString * PEXDBMessage_FIELD_SEND_COUNTER = @"sendCounter";
NSString * PEXDBMessage_FIELD_FROM_FULL = @"full_sender";
NSString * PEXDBMessage_FIELD_FILE_NONCE = @"file_nonce";
NSString * PEXDBMessage_MIME_TEXT = @"text/plain";
NSString * PEXDBMessage_MIME_FILE = @"text/file";
NSString *PEXDBMessage_SECURE_MSG_MIME = @"application/x-phonex-mime";
NSString *PEXDBMessage_SECURE_FILE_NOTIFY_MIME = @"application/x-phonex-file-notification-mime";

NSString * PEXDBMessage_TABLE_NAME = @"messages";
NSString * PEXDBMessage_THREAD_ALIAS = @"thread";
NSString * PEXDBMessage_SELF = @"SELF";

+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString * createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
                        "  %@  INTEGER PRIMARY KEY AUTOINCREMENT,"//  				 PEXDBMessage_FIELD_ID
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_FROM
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_TO
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_CONTACT
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_BODY
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_BODY_HASH
                        "  %@  TEXT, "//  				 PEXDBMessage_FIELD_BODY_DECRYPTED
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_MIME_TYPE
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_ERROR_CODE
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_ERROR_TEXT
                        "  %@  INTEGER,"//  				 PEXDBMessage_FIELD_TYPE
                        "  %@  NUMERIC,"//  				 PEXDBMessage_FIELD_DATE
                        "  %@  NUMERIC,"//  				 PEXDBMessage_FIELD_SEND_DATE
                        "  %@  NUMERIC DEFAULT 0,"//  	     PEXDBMessage_FIELD_RESEND_DATE
                        "  %@  INTEGER,"//  				 PEXDBMessage_FIELD_STATUS
                        "  %@  INTEGER DEFAULT 0,"//         PEXDBMessage_FIELD_IS_OUTGOING
                        "  %@  INTEGER DEFAULT 0,"//         PEXDBMessage_FIELD_IS_OFFLINE
                        "  %@  INTEGER,"//  				 PEXDBMessage_FIELD_RANDOM_NUM
                        "  %@  BOOLEAN,"//  				 PEXDBMessage_FIELD_READ
                        "  %@  NUMERIC DEFAULT 0,"//		 PEXDBMessage_FIELD_READ_DATE
                        "  %@  INTEGER,"//  				 PEXDBMessage_FIELD_SIGNATURE_OK
                        "  %@  INTEGER,"//  				 PEXDBMessage_FIELD_DECRYPTION_STATUS
                        "  %@  TEXT,"//  				 PEXDBMessage_FIELD_FROM_FULL
                        "  %@  INTEGER, "//  			 PEXDBMessage_FIELD_SEND_COUNTER
                        "  %@  TEXT "//  				 PEXDBMessage_FIELD_FILE_NONCE
                        ");",
                PEXDBMessage_TABLE_NAME,
                PEXDBMessage_FIELD_ID,
                PEXDBMessage_FIELD_FROM,
                PEXDBMessage_FIELD_TO,
                PEXDBMessage_FIELD_CONTACT,
                PEXDBMessage_FIELD_BODY,
                PEXDBMessage_FIELD_BODY_HASH,
                PEXDBMessage_FIELD_BODY_DECRYPTED,
                PEXDBMessage_FIELD_MIME_TYPE,
                PEXDBMessage_FIELD_ERROR_CODE,
                PEXDBMessage_FIELD_ERROR_TEXT,
                PEXDBMessage_FIELD_TYPE,
                PEXDBMessage_FIELD_DATE,
                PEXDBMessage_FIELD_SEND_DATE,
                PEXDBMessage_FIELD_RESEND_DATE,
                PEXDBMessage_FIELD_STATUS,
                PEXDBMessage_FIELD_IS_OUTGOING,
                PEXDBMessage_FIELD_IS_OFFLINE,
                PEXDBMessage_FIELD_RANDOM_NUM,
                PEXDBMessage_FIELD_READ,
                PEXDBMessage_FIELD_READ_DATE,
                PEXDBMessage_FIELD_SIGNATURE_OK,
                PEXDBMessage_FIELD_DECRYPTION_STATUS,
                PEXDBMessage_FIELD_FROM_FULL,
                PEXDBMessage_FIELD_SEND_COUNTER,
                PEXDBMessage_FIELD_FILE_NONCE];
    });
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                PEXDBMessage_FIELD_ID,
                PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO,
                PEXDBMessage_FIELD_BODY,
                PEXDBMessage_FIELD_BODY_HASH, PEXDBMessage_FIELD_BODY_DECRYPTED,
                PEXDBMessage_FIELD_SIGNATURE_OK, PEXDBMessage_FIELD_DECRYPTION_STATUS,
                PEXDBMessage_FIELD_DATE,
                PEXDBMessage_FIELD_SEND_DATE, PEXDBMessage_FIELD_RANDOM_NUM,
                PEXDBMessage_FIELD_MIME_TYPE, PEXDBMessage_FIELD_STATUS,
                PEXDBMessage_FIELD_ERROR_CODE, PEXDBMessage_FIELD_ERROR_TEXT,
                PEXDBMessage_FIELD_FILE_NONCE, PEXDBMessage_FIELD_TYPE,
                PEXDBMessage_FIELD_IS_OUTGOING, PEXDBMessage_FIELD_IS_OFFLINE,
                PEXDBMessage_FIELD_RESEND_DATE,
                PEXDBMessage_FIELD_READ, PEXDBMessage_FIELD_READ_DATE];
    });
    return fullProjection;
}

+(NSArray *) getLightProjection {
    static dispatch_once_t once;
    static NSArray * lightProjection;
    dispatch_once(&once, ^{
        lightProjection = @[
                PEXDBMessage_FIELD_ID,
                PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO,
                PEXDBMessage_FIELD_DATE,
                PEXDBMessage_FIELD_SEND_DATE,
                PEXDBMessage_FIELD_MIME_TYPE, PEXDBMessage_FIELD_STATUS,
                PEXDBMessage_FIELD_ERROR_CODE, PEXDBMessage_FIELD_ERROR_TEXT,
                PEXDBMessage_FIELD_FILE_NONCE, PEXDBMessage_FIELD_TYPE,
                PEXDBMessage_FIELD_IS_OUTGOING, PEXDBMessage_FIELD_IS_OFFLINE,
                PEXDBMessage_FIELD_RESEND_DATE];
    });
    return lightProjection;
}

+(NSArray *) getFileRelatedProjection {
    static dispatch_once_t once;
    static NSArray * accProjection;
    dispatch_once(&once, ^{
        accProjection = @[PEXDBMessage_FIELD_ID, PEXDBMessage_FIELD_FILE_NONCE];
    });
    return accProjection;
}

// requires GROUP BY
+(NSArray *) getNewestMessageFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    static NSString * maxDate;
    dispatch_once(&once, ^{
        maxDate = [NSString stringWithFormat:@"MAX(%@) AS %@",
                   PEXDBMessage_FIELD_DATE, PEXDBMessage_FIELD_DATE];
        fullProjection = @[
                           PEXDBMessage_FIELD_ID,
                           PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO,
                           PEXDBMessage_FIELD_BODY,
                           PEXDBMessage_FIELD_BODY_HASH, PEXDBMessage_FIELD_BODY_DECRYPTED,
                           PEXDBMessage_FIELD_SIGNATURE_OK, PEXDBMessage_FIELD_DECRYPTION_STATUS,
                           maxDate,
                           PEXDBMessage_FIELD_SEND_DATE, PEXDBMessage_FIELD_RANDOM_NUM,
                           PEXDBMessage_FIELD_MIME_TYPE, PEXDBMessage_FIELD_STATUS,
                           PEXDBMessage_FIELD_ERROR_CODE, PEXDBMessage_FIELD_ERROR_TEXT,
                           PEXDBMessage_FIELD_FILE_NONCE, PEXDBMessage_FIELD_TYPE,
                           PEXDBMessage_FIELD_IS_OUTGOING, PEXDBMessage_FIELD_IS_OFFLINE,
                           PEXDBMessage_FIELD_RESEND_DATE,
                           PEXDBMessage_FIELD_READ, PEXDBMessage_FIELD_READ_DATE];
    });
    return fullProjection;
}

+(NSArray *) getOldestMessageFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    static NSString * maxDate;
    dispatch_once(&once, ^{
        maxDate = [NSString stringWithFormat:@"MIN(%@) AS %@",
                                             PEXDBMessage_FIELD_DATE, PEXDBMessage_FIELD_DATE];
        fullProjection = @[
                PEXDBMessage_FIELD_ID,
                PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO,
                PEXDBMessage_FIELD_BODY,
                PEXDBMessage_FIELD_BODY_HASH, PEXDBMessage_FIELD_BODY_DECRYPTED,
                PEXDBMessage_FIELD_SIGNATURE_OK, PEXDBMessage_FIELD_DECRYPTION_STATUS,
                maxDate,
                PEXDBMessage_FIELD_SEND_DATE, PEXDBMessage_FIELD_RANDOM_NUM,
                PEXDBMessage_FIELD_MIME_TYPE, PEXDBMessage_FIELD_STATUS,
                PEXDBMessage_FIELD_ERROR_CODE, PEXDBMessage_FIELD_ERROR_TEXT,
                PEXDBMessage_FIELD_FILE_NONCE, PEXDBMessage_FIELD_TYPE,
                PEXDBMessage_FIELD_IS_OUTGOING, PEXDBMessage_FIELD_RESEND_DATE,
                PEXDBMessage_FIELD_READ, PEXDBMessage_FIELD_READ_DATE];
    });
    return fullProjection;
}

+(NSString * const) getNewestMessageFullProjectionGroupBy
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"GROUP BY %@, %@",
                  PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO];
    });
    return result;
}

+(NSString * const) getSortByDateOldestFirst
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"ORDER BY %@", PEXDBMessage_FIELD_DATE];
    });
    return result;
}

+(NSString * const) getSortByDateNewestFirst
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"ORDER BY %@ DESC", PEXDBMessage_FIELD_DATE];
    });
    return result;
}

+(NSString * const)getSortByIdOldestFirst
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"ORDER BY %@", PEXDBMessage_FIELD_ID];
    });
    return result;
}

+(NSString * const) getWhereForOlderThan: (const int) hours
{
    /*
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?,
                                            PEXDBMessage_FIELD_DATE];
    });
    return result;
    */
    return nil;
}

+(NSString * const) getWhereForIncoming
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=0",
                        PEXDBMessage_FIELD_IS_OUTGOING];
    });
    return result;
}

+(NSString * const) getWhereForSelf
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=? AND %@=?",
                  PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO];
    });
    return result;
}

+(NSString * const) getWhereForIdAndContact
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=? AND (%@=? OR %@=?)",
                                            PEXDBMessage_FIELD_ID, PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO];
    });
    return result;
}

+(NSArray *) getWhereForId: (NSNumber * const) itemId
            AndContactArgs: (const PEXDbContact * const) contact
{
    return @[itemId, contact.sip, contact.sip];
}

+(NSString * const) getWhereForContact
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=? OR %@=?",
                                            PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_TO];
    });
    return result;
}

+(NSArray*) getWhereForContactArgs: (const PEXDbContact * const) contact
{
    return @[contact.sip, contact.sip];
}

+(NSString * const) getWhereForId
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?",
                  PEXDBMessage_FIELD_ID];
    });
    return result;
}

+(NSArray*) getWhereForIdArgs: (const NSNumber * const) IdValue
{
    return @[[IdValue description]];
}

// HOURS
+(NSString * const) getWhereForOlderThan
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@ < (strftime('%%s','now') - ?);",
                                            PEXDBMessage_FIELD_DATE];
    });
    return result;
}

+ (NSString *) getWhereForIds: (NSArray * const) ids
{
    if (!ids || (ids.count == 0))
        return nil;

    NSMutableString * const result = [[NSMutableString alloc]
            initWithFormat:@"WHERE %@ IN (?", PEXDBMessage_FIELD_ID];

    for (NSUInteger i = 1; i < ids.count; ++i)
        [result appendString:@",?"];

    [result appendString:@")"];

    return result;
}

+ (NSArray *) getWhereForIdsArgs: (NSArray * const) ids
{
    if (!ids || (ids.count == 0))
        return nil;

    NSMutableArray * const result = [[NSMutableArray alloc] init];

    for (const NSNumber * const n in ids)
        [result addObject:[NSString stringWithFormat:@"%lld", n.longLongValue]];

    return result;
}

+(NSString * const) getWhereForReadAllForSip
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=? AND %@=?",
                  PEXDBMessage_FIELD_FROM, PEXDBMessage_FIELD_IS_OUTGOING];
    });
    return result;
}

+(NSArray*) getWhereForReadAllForSipArgs: (NSString * const) sip
{
    return @[sip, @"0"];
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEXDBMessage_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEXDBMessage_TABLE_NAME isBase:YES];
    });
    return uriBase;
}

- (instancetype)initWithFrom:(NSString *)from to:(NSString *)to contact:(NSString *)contact body:(NSString *)body mimeType:(NSString *)mimeType date:(NSDate *)date type:(NSNumber *)type fullFrom:(NSString *)fullFrom {
    self = [super init];
    if (self) {
        self.from = from;
        self.to = to;
        self.contact = contact;
        self.body = body;
        self.mimeType = mimeType;
        self.date = date;
        self.type = type;
        self.fullFrom = fullFrom;

        _status = @(PEXDBMessage_STATUS_NONE);
        _read = @NO;
        _isOutgoing = @NO;
        _isOffline = @NO;
        _signatureOK = @NO;
        _decryptionStatus = @(PEXDBMessage_DECRYPTION_STATUS_NOT_DECRYPTED);
        _randNum = @(0);
        _sendDate = nil;
        _errorCode = @(0);
        _errorText = @"";
        _sendCounter = @(0);
        _readDate = nil;
    }

    return self;
}

+ (instancetype)messageWithFrom:(NSString *)from to:(NSString *)to contact:(NSString *)contact body:(NSString *)body mimeType:(NSString *)mimeType date:(NSDate *)date type:(NSNumber *)type fullFrom:(NSString *)fullFrom {
    return [[self alloc] initWithFrom:from to:to contact:contact body:body mimeType:mimeType date:date type:type fullFrom:fullFrom];
}

/**
* Pack the object content value to store
*
* @return The content value representing the message
*/
-(PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    if (_id!=nil && [_id longLongValue] != -1l) {
        [cv put:PEXDBMessage_FIELD_ID NSNumberAsLongLong:_id];
    }

    [cv put:PEXDBMessage_FIELD_FROM string: _from];
    [cv put:PEXDBMessage_FIELD_TO string: _to];
    [cv put:PEXDBMessage_FIELD_CONTACT string: _contact];
    [cv put:PEXDBMessage_FIELD_BODY_HASH string: _bodyHash];
    [cv put:PEXDBMessage_FIELD_BODY string: _body];
    [cv put:PEXDBMessage_FIELD_MIME_TYPE string: _mimeType];
    [cv put:PEXDBMessage_FIELD_TYPE NSNumberAsInt: _type];
    [cv put:PEXDBMessage_FIELD_DATE date:_date];
    [cv put:PEXDBMessage_FIELD_IS_OUTGOING NSNumberAsInt: [PEXDbMessage bool2int:_isOutgoing]];
    [cv put:PEXDBMessage_FIELD_IS_OFFLINE NSNumberAsInt: [PEXDbMessage bool2int:_isOffline]];
    [cv put:PEXDBMessage_FIELD_STATUS NSNumberAsInt: _status];
    [cv put:PEXDBMessage_FIELD_READ NSNumberAsInt: [PEXDbMessage bool2int:_read]];
    if (_readDate != nil) {
        [cv put:PEXDBMessage_FIELD_READ_DATE date:_readDate];
    }
    [cv put:PEXDBMessage_FIELD_FROM_FULL string: _fullFrom];
    [cv put:PEXDBMessage_FIELD_BODY_DECRYPTED string: _bodyDecrypted];
    [cv put:PEXDBMessage_FIELD_SIGNATURE_OK NSNumberAsInt: [PEXDbMessage bool2int:_signatureOK]];
    [cv put:PEXDBMessage_FIELD_DECRYPTION_STATUS NSNumberAsInt: _decryptionStatus];
    [cv put:PEXDBMessage_FIELD_RANDOM_NUM NSNumberAsLongLong: _randNum];
    [cv put:PEXDBMessage_FIELD_SEND_DATE date: _sendDate];
    if (_resendDate != nil) {
        [cv put:PEXDBMessage_FIELD_RESEND_DATE date:_resendDate];
    }
    [cv put:PEXDBMessage_FIELD_ERROR_CODE NSNumberAsInt: _errorCode];
    [cv put:PEXDBMessage_FIELD_ERROR_TEXT string: _errorText];
    [cv put:PEXDBMessage_FIELD_SEND_COUNTER NSNumberAsInt: _sendCounter];
    [cv put:PEXDBMessage_FIELD_FILE_NONCE string: _fileNonce];
    return cv;
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

        if ([PEXDBMessage_FIELD_ID isEqualToString:colname]) {
            _id = [c getInt64:i];
        } else if ([PEXDBMessage_FIELD_FROM isEqualToString:colname]) {
            _from = [c getString:i];
        } else if ([PEXDBMessage_FIELD_TO isEqualToString:colname]) {
            _to = [c getString:i];
        } else if ([PEXDBMessage_FIELD_CONTACT isEqualToString:colname]) {
            _contact = [c getString:i];
        } else if ([PEXDBMessage_FIELD_BODY isEqualToString:colname]) {
            _body = [c getString:i];
        } else if ([PEXDBMessage_FIELD_BODY_HASH isEqualToString:colname]) {
            _bodyHash = [c getString:i];
        } else if ([PEXDBMessage_FIELD_MIME_TYPE isEqualToString:colname]) {
            _mimeType = [c getString:i];
        } else if ([PEXDBMessage_FIELD_DATE isEqualToString:colname]) {
            _date = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEXDBMessage_FIELD_TYPE isEqualToString: colname]){
            _type = [c getInt: i];
        } else if ([PEXDBMessage_FIELD_STATUS isEqualToString: colname]){
            _status = [c getInt: i];
        } else if ([PEXDBMessage_FIELD_READ isEqualToString: colname]){
            _read = [PEXDbMessage int2bool:[c getInt:i]];
        } else if ([PEXDBMessage_FIELD_READ_DATE isEqualToString: colname]){
            _readDate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEXDBMessage_FIELD_FROM_FULL isEqualToString: colname]){
            _fullFrom= [c getString:i];
        } else if ([PEXDBMessage_FIELD_BODY_DECRYPTED isEqualToString: colname]){
            _bodyDecrypted= [c getString:i];
        } else if ([PEXDBMessage_FIELD_SIGNATURE_OK isEqualToString: colname]){
            _signatureOK = [PEXDbMessage int2bool:[c getInt:i]];
        } else if ([PEXDBMessage_FIELD_DECRYPTION_STATUS isEqualToString: colname]){
            _decryptionStatus = [c getInt: i];
        } else if ([PEXDBMessage_FIELD_RANDOM_NUM isEqualToString: colname]){
            _randNum = [c getInt64: i];
        } else if ([PEXDBMessage_FIELD_SEND_DATE isEqualToString: colname]){
            _sendDate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEXDBMessage_FIELD_RESEND_DATE isEqualToString: colname]){
            _resendDate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEXDBMessage_FIELD_ERROR_CODE isEqualToString: colname]){
            _errorCode = [c getInt: i];
        } else if ([PEXDBMessage_FIELD_ERROR_TEXT isEqualToString: colname]){
            _errorText= [c getString:i];
        } else if ([PEXDBMessage_FIELD_IS_OUTGOING isEqualToString: colname]){
            _isOutgoing = @([[c getInt: i] integerValue] == 1);
        } else if ([PEXDBMessage_FIELD_IS_OFFLINE isEqualToString: colname]){
            _isOffline = @([[c getInt: i] integerValue] == 1);
        } else if ([PEXDBMessage_FIELD_SEND_COUNTER isEqualToString: colname]){
            _sendCounter = [c getInt: i];
        } else if ([PEXDBMessage_FIELD_FILE_NONCE isEqualToString: colname]) {
            _fileNonce = [c getString:i];
        } else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

- (NSString *)getDisplayName {
    return [PEXSipUri getDisplayedSimpleContact:_fullFrom];
}

- (NSString *)getRemoteParty {
    if (_isOutgoing == nil){
        return nil;
    }

    if ([_isOutgoing boolValue]) {
        return _to;
    }
    else {
        return _from;
    }
}

- (NSString *)getPlainBody {
    return _body;
}

- (void)copyAllFieldsTo:(PEXDbMessage *)other {
    other.body = self.body;
    other.bodyDecrypted = self.bodyDecrypted;
    other.bodyHash = self.bodyHash;
    other.contact = self.contact;
    other.date = self.date;
    other.decryptionStatus = self.decryptionStatus;
    other.errorCode = self.errorCode;
    other.errorText = self.errorText;
    other.fileNonce = self.fileNonce;
    other.from = self.from;
    other.fullFrom = self.fullFrom;
    other.isOutgoing = self.isOutgoing;
    other.isOffline = self.isOffline;
    other.mimeType = self.mimeType;
    other.randNum = self.randNum;
    other.read = self.read;
    other.readDate = self.readDate;
    other.sendCounter = self.sendCounter;
    other.sendDate = self.sendDate;
    other.signatureOK = self.signatureOK;
    other.status = self.status;
    other.to = self.to;
    other.type = self.type;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.from = [coder decodeObjectForKey:@"self.from"];
        self.fullFrom = [coder decodeObjectForKey:@"self.fullFrom"];
        self.to = [coder decodeObjectForKey:@"self.to"];
        self.contact = [coder decodeObjectForKey:@"self.contact"];
        self.body = [coder decodeObjectForKey:@"self.body"];
        self.mimeType = [coder decodeObjectForKey:@"self.mimeType"];
        self.bodyHash = [coder decodeObjectForKey:@"self.bodyHash"];
        self.date = [coder decodeObjectForKey:@"self.date"];
        self.type = [coder decodeObjectForKey:@"self.type"];
        self.status = [coder decodeObjectForKey:@"self.status"];
        self.read = [coder decodeObjectForKey:@"self.read"];
        self.readDate = [coder decodeObjectForKey:@"self.readDate"];
        self.isOutgoing = [coder decodeObjectForKey:@"self.isOutgoing"];
        self.isOffline = [coder decodeObjectForKey:@"self.isOffline"];
        self.bodyDecrypted = [coder decodeObjectForKey:@"self.bodyDecrypted"];
        self.signatureOK = [coder decodeObjectForKey:@"self.signatureOK"];
        self.decryptionStatus = [coder decodeObjectForKey:@"self.decryptionStatus"];
        self.randNum = [coder decodeObjectForKey:@"self.randNum"];
        self.sendDate = [coder decodeObjectForKey:@"self.sendDate"];
        self.errorCode = [coder decodeObjectForKey:@"self.errorCode"];
        self.errorText = [coder decodeObjectForKey:@"self.errorText"];
        self.sendCounter = [coder decodeObjectForKey:@"self.sendCounter"];
        self.fileNonce = [coder decodeObjectForKey:@"self.fileNonce"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.from forKey:@"self.from"];
    [coder encodeObject:self.fullFrom forKey:@"self.fullFrom"];
    [coder encodeObject:self.to forKey:@"self.to"];
    [coder encodeObject:self.contact forKey:@"self.contact"];
    [coder encodeObject:self.body forKey:@"self.body"];
    [coder encodeObject:self.mimeType forKey:@"self.mimeType"];
    [coder encodeObject:self.bodyHash forKey:@"self.bodyHash"];
    [coder encodeObject:self.date forKey:@"self.date"];
    [coder encodeObject:self.type forKey:@"self.type"];
    [coder encodeObject:self.status forKey:@"self.status"];
    [coder encodeObject:self.read forKey:@"self.read"];
    [coder encodeObject:self.readDate forKey:@"self.readDate"];
    [coder encodeObject:self.isOutgoing forKey:@"self.isOutgoing"];
    [coder encodeObject:self.isOffline forKey:@"self.isOffline"];
    [coder encodeObject:self.bodyDecrypted forKey:@"self.bodyDecrypted"];
    [coder encodeObject:self.signatureOK forKey:@"self.signatureOK"];
    [coder encodeObject:self.decryptionStatus forKey:@"self.decryptionStatus"];
    [coder encodeObject:self.randNum forKey:@"self.randNum"];
    [coder encodeObject:self.sendDate forKey:@"self.sendDate"];
    [coder encodeObject:self.errorCode forKey:@"self.errorCode"];
    [coder encodeObject:self.errorText forKey:@"self.errorText"];
    [coder encodeObject:self.sendCounter forKey:@"self.sendCounter"];
    [coder encodeObject:self.fileNonce forKey:@"self.fileNonce"];
}

+(int) loadSendCounter: (PEXDbContentProvider *) cr messageId: (int64_t) messageId{
    PEXDbCursor * c = [cr query:[PEXDbMessage getURI]
                     projection:@[PEXDBMessage_FIELD_ID, PEXDBMessage_FIELD_SEND_COUNTER]
                      selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
                  selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]
                      sortOrder:@""];

    if (c != nil) {
        @try {
            if ([c moveToFirst]){
                int counter = (int)[[c getInt:[c getColumnIndex:PEXDBMessage_FIELD_SEND_COUNTER]] integerValue];
                return counter;
            }
        } @catch (NSException * e) {
            DDLogError(@"Error while getting message ID, exception: %@", e);
        } @finally {
            [c close];
        }
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
+(id) initById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId{
    return [self initById:cr messageId:messageId projection:[PEXDbMessage getFullProjection]];
}

/**
* Loads message by ID.
* @param cr
* @param messageId
* @return
*/
+(id) initById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId projection: (NSArray*) projection{
    PEXDbCursor * c = [cr query:[PEXDbMessage getURI]
                     projection:projection
                      selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
                  selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]
                      sortOrder:@""];

    if (c != nil) {
        @try {
            if ([c moveToFirst]){
                PEXDbMessage * msg = [[PEXDbMessage alloc] init];
                [msg createFromCursor:c];
                return msg;
            }
        } @catch (NSException * e) {
            DDLogError(@"Error while getting message ID, exception: %@", e);
            return nil;
        } @finally {
            [c close];
        }
    }

    return nil;
}

/**
* Deletes message by given message id.
* @param cr
* @param messageId
* @return
*/
+(int) deleteById: (PEXDbContentProvider *) cr messageId: (int64_t) messageId{
    @try {
        return [cr delete:[PEXDbMessage getURI]
         selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
     selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]] ? 1 : 0;
    } @catch (NSException * e){
        DDLogError(@"Exception: Cannot remove message id=%lld, exception=%@", messageId, e);
    }

    return -1;
}

/**
* set SipMessage Type property
* @param cr
* @param messageId
* @param messageType
*/
+(void) setMessageType: (PEXDbContentProvider *) cr messageId: (int64_t) messageId messageType: (int) messageType{
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    [cv put:PEXDBMessage_FIELD_TYPE       integer:messageType];

    int rowsUpdated = [cr   update:[PEXDbMessage getURI]
                     ContentValues:cv
                         selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
                     selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]] ? 1 : 0;
    if (rowsUpdated<=0){
        DDLogError(@"Msg with ID=[%lld] was not found in DB, cannot be set to [%d]", messageId, messageType);
    } else {
        DDLogDebug(@"Updated msg [id=%lld] property FIELD_TYPE to [%d]", messageId, messageType);
    }
}

/**
* Sets message type, error code and error text.
*
* @param cr
* @param msgid
* @param msgtype
* @param errCode
* @param errText
* @return
*/
+(int) setMessageError: (PEXDbContentProvider *) cr messageId: (int64_t) messageId messageType: (int) messageType
               errCode: (int) errCode errText: (NSString *) errText{
    @try {
        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEXDBMessage_FIELD_TYPE       integer:messageType];
        [cv put:PEXDBMessage_FIELD_ERROR_CODE integer:errCode];
        [cv put:PEXDBMessage_FIELD_ERROR_TEXT string:errText];

        return [cr   update:[PEXDbMessage getURI]
              ContentValues:cv
                  selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
              selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]] ? 1 : 0;
    } @catch (NSException * e){
        DDLogError(@"Cannot update message - store error code. exception=%@", e);
    }

    return -1;
}

+ (PEXDbMessage *) messageFromCursor: (PEXDbCursor * const) cursor
{
    PEXDbMessage * const result = [[PEXDbMessage alloc] init];
    [result createFromCursor: cursor];
    return result;
}

/**
* Updates message with given ID with provided content values.
*
* @param cr
* @param msgid
* @param cv
* @return
*/
+(int) updateMessage: (PEXDbContentProvider *) cr messageId: (int64_t) messageId contentValues: (PEXDbContentValues *) cv{
    return [cr update:[PEXDbMessage getURI] ContentValues:cv
     selection:[NSString stringWithFormat:@" WHERE %@=?", PEXDBMessage_FIELD_ID]
 selectionArgs:@[[NSString stringWithFormat:@"%lld", messageId]]] ? 1 : 0;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbMessage *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.id = self.id;
        copy.from = self.from;
        copy.fullFrom = self.fullFrom;
        copy.to = self.to;
        copy.contact = self.contact;
        copy.body = self.body;
        copy.mimeType = self.mimeType;
        copy.bodyHash = self.bodyHash;
        copy.date = self.date;
        copy.type = self.type;
        copy.status = self.status;
        copy.read = self.read;
        copy.readDate = self.readDate;
        copy.isOutgoing = self.isOutgoing;
        copy.isOffline = self.isOffline;
        copy.bodyDecrypted = self.bodyDecrypted;
        copy.signatureOK = self.signatureOK;
        copy.decryptionStatus = self.decryptionStatus;
        copy.randNum = self.randNum;
        copy.sendDate = self.sendDate;
        copy.errorCode = self.errorCode;
        copy.errorText = self.errorText;
        copy.sendCounter = self.sendCounter;
        copy.fileNonce = self.fileNonce;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToMessage:other];
}

- (BOOL)isEqualToMessage:(const PEXDbMessage * const)message {
    if (self == message)
        return YES;
    if (message == nil)
        return NO;
    if (self.id != message.id && ![self.id isEqualToNumber:message.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

- (bool) isFile
{
    return [self.mimeType isEqualToString:PEXDBMessage_MIME_FILE] ||
        [self.mimeType isEqualToString:PEXDBMessage_SECURE_FILE_NOTIFY_MIME];
}

- (BOOL)canBeForwarded {
    // Text messages can always be forwarded
    if (![self isFile]){
        return YES;
    }

    if (_type == nil){
        return NO;
    }

    switch ([_type integerValue]){
        // In some states, we do not have files ready to be forwarded
        case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOAD_FAIL:
        case PEXDBMessage_MESSAGE_TYPE_FILE_UPLOADING:
        case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING:
        case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADING_META:
        case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOADED_META:
        case PEXDBMessage_MESSAGE_TYPE_FILE_DOWNLOAD_FAIL:
        case PEXDBMessage_MESSAGE_TYPE_FILE_READY:
        case PEXDBMessage_MESSAGE_TYPE_FILE_REJECTED:
        case PEXDBMessage_MESSAGE_TYPE_FILE_ERROR_RECEIVING:
            return NO;
        default:
            return YES;
    }
}

/**
* return randNum or establish a new one for SipMessage
* @param cr
* @return
*/
-(uint32_t) getOrEstablishRandNum: (PEXDbContentProvider *) cr {
    if (self.randNum != nil && ![self.randNum isEqualToNumber:@(0)]){
        return (uint32_t)[self.randNum integerValue];
    } else {
        uint32_t tmp = [PEXCryptoUtils secureRandomUInt32:YES];

        PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
        [cv put:PEXDBMessage_FIELD_RANDOM_NUM NSNumberAsLongLong: @(tmp)];

        if (self.id != nil) {
            [PEXDbMessage updateMessage:cr messageId:[self.id longLongValue] contentValues:cv];
        }

        return tmp;
    }
}

+(NSArray *) getAllFileMsgIdsRelatedToUser: (NSString *) username cr: (PEXDbContentProvider *) cr {
    NSMutableArray * acc     = [[NSMutableArray alloc] init];
    PEXDbCursor    * cMerged = nil;

    @try {
        cMerged = [cr query:[PEXDbMessage getURI] projection:@[PEXDBMessage_FIELD_ID]
                   selection:[NSString stringWithFormat:@"WHERE (%@=1 AND %@=? AND %@=?) OR (%@=0 AND %@=? AND %@=?)",
                                   PEXDBMessage_FIELD_IS_OUTGOING,
                                   PEXDBMessage_FIELD_TO,
                                   PEXDBMessage_FIELD_MIME_TYPE,
                                   PEXDBMessage_FIELD_IS_OUTGOING,
                                   PEXDBMessage_FIELD_FROM,
                                   PEXDBMessage_FIELD_MIME_TYPE]
               selectionArgs:@[username, PEXDBMessage_MIME_FILE, username, PEXDBMessage_MIME_FILE] sortOrder:nil];

        if (cMerged == nil || [cMerged getCount] == 0){
            return [NSArray array];
        }

        while([cMerged moveToNext]){
            NSNumber * cId = [cMerged getInt64:0];
            [acc addObject:cId];
        }

    } @catch(NSException * e){
        DDLogError(@"Error during loading messages, exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:cMerged];
    }

    return [NSArray arrayWithArray:acc];
}

+ (instancetype)messageByNonce2:(NSString *)nonce2 isOutgoing:(NSNumber *) outgoing to:(NSString *)to from:(NSString *)from cr:(PEXDbContentProvider *)cr {
    PEXDbCursor * c = nil;
    @try {
        NSMutableArray * fieldsValues = [[NSMutableArray alloc] init];
        NSMutableArray * specs        = [[NSMutableArray alloc] init];

        if (nonce2 != nil) {
            [specs addObject:[NSString stringWithFormat:@"%@=?", PEXDBMessage_FIELD_FILE_NONCE]];
            [fieldsValues addObject:nonce2];
        }

        if (outgoing != nil){
            [specs addObject:[NSString stringWithFormat:@"%@=?", PEXDBMessage_FIELD_IS_OUTGOING]];
            [fieldsValues addObject:[@([outgoing integerValue]) stringValue]];
        }

        if (to != nil){
            [specs addObject:[NSString stringWithFormat:@"%@=?", PEXDBMessage_FIELD_TO]];
            [fieldsValues addObject: to];
        }

        if (from != nil){
            [specs addObject:[NSString stringWithFormat:@"%@=?", PEXDBMessage_FIELD_FROM]];
            [fieldsValues addObject: from];
        }

        if (fieldsValues.count == 0){
            DDLogWarn(@"Tried to load with empty criteria");
            return nil;
        }

        c = [cr query: [PEXDbMessage getURI]
           projection: [PEXDbMessage getFullProjection]
            selection: [NSString stringWithFormat:@"WHERE %@", [specs componentsJoinedByString:@" AND "]]
        selectionArgs: fieldsValues
            sortOrder: nil];

        if (c == nil|| ![c moveToFirst]){
            return nil;
        }

        return [PEXDbMessage messageFromCursor:c];
    } @catch(NSException * e){
        DDLogError(@"Exception in loading file, exception=%@", e);
        return nil;
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.id=%@", self.id];
    [description appendFormat:@", self.from=%@", self.from];
    [description appendFormat:@", self.fullFrom=%@", self.fullFrom];
    [description appendFormat:@", self.to=%@", self.to];
    [description appendFormat:@", self.contact=%@", self.contact];
    [description appendFormat:@", self.body=%@", self.body];
    [description appendFormat:@", self.mimeType=%@", self.mimeType];
    [description appendFormat:@", self.bodyHash=%@", self.bodyHash];
    [description appendFormat:@", self.date=%@", self.date];
    [description appendFormat:@", self.type=%@", self.type];
    [description appendFormat:@", self.status=%@", self.status];
    [description appendFormat:@", self.read=%@", self.read];
    [description appendFormat:@", self.readDate=%@", self.readDate];
    [description appendFormat:@", self.isOutgoing=%@", self.isOutgoing];
    [description appendFormat:@", self.isOffline=%@", self.isOffline];
    [description appendFormat:@", self.bodyDecrypted=%@", self.bodyDecrypted];
    [description appendFormat:@", self.signatureOK=%@", self.signatureOK];
    [description appendFormat:@", self.decryptionStatus=%@", self.decryptionStatus];
    [description appendFormat:@", self.randNum=%@", self.randNum];
    [description appendFormat:@", self.sendDate=%@", self.sendDate];
    [description appendFormat:@", self.errorCode=%@", self.errorCode];
    [description appendFormat:@", self.errorText=%@", self.errorText];
    [description appendFormat:@", self.sendCounter=%@", self.sendCounter];
    [description appendFormat:@", self.fileNonce=%@", self.fileNonce];
    [description appendString:@">"];
    return description;
}

+ (NSString *) getContactSipFromMessage: (const PEXDbMessage * const) message
{
    return (([message.isOutgoing integerValue] == 1) ? message.to : message.from);
}

+ (bool) messageIsSeenAndOutgoing: (const PEXDbMessage * const) message
{
    return (message.read.integerValue == 1) &&
            ((message.isOutgoing.integerValue == 1));
}

@end