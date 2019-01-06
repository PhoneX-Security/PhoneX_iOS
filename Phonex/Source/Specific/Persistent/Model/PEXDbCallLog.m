//
// Created by Dusan Klinec on 18.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbCallLog.h"
#import "PEXPjCall.h"
#import "PEXStringUtils.h"
#import "PEXDbContact.h"
#import "pjsip/sip_msg.h"
#import "PEXDbContentProvider.h"
#import "PEXUtils.h"

NSString *PEX_DBCLOG_TABLE = @"calllog";
NSString *PEX_DBCLOG_FIELD_ID = @"_id";
NSString *PEX_DBCLOG_FIELD_DATE = @"cdate";
NSString *PEX_DBCLOG_FIELD_DURATION = @"duration";
NSString *PEX_DBCLOG_FIELD_NEW = @"newCall";
NSString *PEX_DBCLOG_FIELD_NUMBER = @"cnumber";
NSString *PEX_DBCLOG_FIELD_TYPE = @"ctype";
NSString *PEX_DBCLOG_FIELD_CACHED_NAME = @"cached_name";
NSString *PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL = @"cached_label";
NSString *PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE = @"cached_type";

NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID = @"remoteId";
NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME = @"remoteName";
NSString *PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS = @"remoteAddress";
NSString *PEX_DBCLOG_FIELD_ACCOUNT_ID = @"accountId";
NSString *PEX_DBCLOG_FIELD_STATUS_CODE = @"statusCode";
NSString *PEX_DBCLOG_FIELD_STATUS_TEXT = @"statusText";
NSString *PEX_DBCLOG_FIELD_SEEN_BY_USER = @"seenByUser";

NSString *PEX_DBCLOG_FIELD_EVENT_TIMESTAMP = @"eventTimestamp";
NSString *PEX_DBCLOG_FIELD_EVENT_NONCE = @"eventNonce";
NSString *PEX_DBCLOG_FIELD_SIP_CALL_ID = @"sipCallId";

const NSInteger PEX_DBCLOG_TYPE_OUTGOING  = 2;
const NSInteger PEX_DBCLOG_TYPE_INCOMING  = 1;
const NSInteger PEX_DBCLOG_TYPE_MISSED    = 3;
const NSInteger PEX_DBCLOG_TYPE_VOICEMAIL = 4;

@implementation PEXDbCallLog {

}

// SQL Create command for call log table.
+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString *createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
                        "  %@  INTEGER PRIMARY KEY AUTOINCREMENT,"//  PEX_DBCLOG_FIELD_ID
                        "  %@  NUMERIC,"//  				 PEX_DBCLOG_FIELD_DATE
                        "  %@  NUMERIC,"//  				 PEX_DBCLOG_FIELD_DURATION
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_NEW
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_NUMBER
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_TYPE
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_CACHED_NAME
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_ACCOUNT_ID
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_STATUS_CODE
                        "  %@  INTEGER,"//  				 PEX_DBCLOG_FIELD_SEEN_BY_USER
                        "  %@  TEXT,"//  				     PEX_DBCLOG_FIELD_STATUS_TEXT
                        "  %@  NUMERIC DEFAULT 0,"//  		 PEX_DBCLOG_FIELD_EVENT_TIMESTAMP
                        "  %@  INTEGER DEFAULT 0,"//  		 PEX_DBCLOG_FIELD_EVENT_NONCE
                        "  %@  TEXT"//  		             PEX_DBCLOG_FIELD_SIP_CALL_ID
                        ");",

                PEX_DBCLOG_TABLE,
                PEX_DBCLOG_FIELD_ID,
                PEX_DBCLOG_FIELD_DATE,
                PEX_DBCLOG_FIELD_DURATION,
                PEX_DBCLOG_FIELD_NEW,
                PEX_DBCLOG_FIELD_NUMBER,
                PEX_DBCLOG_FIELD_TYPE,
                PEX_DBCLOG_FIELD_CACHED_NAME,
                PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL,
                PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS,
                PEX_DBCLOG_FIELD_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_STATUS_CODE,
                PEX_DBCLOG_FIELD_SEEN_BY_USER,
                PEX_DBCLOG_FIELD_STATUS_TEXT,
                PEX_DBCLOG_FIELD_EVENT_TIMESTAMP,
                PEX_DBCLOG_FIELD_EVENT_NONCE,
                PEX_DBCLOG_FIELD_SIP_CALL_ID
        ];
    });
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
        PEX_DBCLOG_FIELD_ID,
                PEX_DBCLOG_FIELD_DATE,
                PEX_DBCLOG_FIELD_DURATION,
                PEX_DBCLOG_FIELD_NEW,
                PEX_DBCLOG_FIELD_NUMBER,
                PEX_DBCLOG_FIELD_TYPE,
                PEX_DBCLOG_FIELD_CACHED_NAME,
                PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL,
                PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS,
                PEX_DBCLOG_FIELD_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_STATUS_CODE,
                PEX_DBCLOG_FIELD_STATUS_TEXT,
                PEX_DBCLOG_FIELD_SEEN_BY_USER,
                PEX_DBCLOG_FIELD_EVENT_TIMESTAMP,
                PEX_DBCLOG_FIELD_EVENT_NONCE,
                PEX_DBCLOG_FIELD_SIP_CALL_ID];
    });
    return fullProjection;
}

+(NSArray *) getLightProjection {
    static dispatch_once_t once;
    static NSArray * lightProjection;
    dispatch_once(&once, ^{
        lightProjection = @[
        PEX_DBCLOG_FIELD_ID,
                PEX_DBCLOG_FIELD_DATE,
                PEX_DBCLOG_FIELD_DURATION,
                PEX_DBCLOG_FIELD_NEW,
                PEX_DBCLOG_FIELD_NUMBER,
                PEX_DBCLOG_FIELD_TYPE,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME,
                PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS,
                PEX_DBCLOG_FIELD_ACCOUNT_ID,
                PEX_DBCLOG_FIELD_SEEN_BY_USER,
                PEX_DBCLOG_FIELD_EVENT_TIMESTAMP,
                PEX_DBCLOG_FIELD_EVENT_NONCE,
                PEX_DBCLOG_FIELD_SIP_CALL_ID];
    });
    return lightProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBCLOG_TABLE];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBCLOG_TABLE isBase:YES];
    });
    return uriBase;
}

+(NSString *) getDefaultSortOrder {
    return [NSString stringWithFormat:@"%@ DESC", PEX_DBCLOG_FIELD_DATE];
}

+(NSString * const) getWhereForId
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBCLOG_FIELD_ID];
    });
    return result;
}

+(NSArray*) getWhereForIdArgs: (const NSNumber * const) id
{
    return @[[id stringValue]];
}

+(NSString * const) getWhereForContact
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS];
    });
    return result;
}

+(NSArray*) getWhereForContactArgs: (const PEXDbContact * const) contact
{
    return @[contact.sip];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isNew = YES;
        self.seenByUser = NO;
    }

    return self;
}

- (PEXDbContentValues *)getDbContentValues {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
    if (_id != nil){
        [args put:PEX_DBCLOG_FIELD_ID NSNumberAsLongLong:_id];
    }

    [args put:PEX_DBCLOG_FIELD_NUMBER string:self.remoteContact];
    [args put:PEX_DBCLOG_FIELD_DATE date:self.callStart];
    [args put:PEX_DBCLOG_FIELD_TYPE NSNumberAsInt:self.type];
    [args put:PEX_DBCLOG_FIELD_NEW boolean:self.isNew];
    [args put:PEX_DBCLOG_FIELD_DURATION NSNumberAsLongLong:self.duration];
    [args put:PEX_DBCLOG_FIELD_CACHED_NAME string:self.remoteUserEnteredNumber];
    [args put:PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL string:self.numberLabel];
    [args put:PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE NSNumberAsInt:self.numberType];

    // Additional to classic call log.
    [args put:PEX_DBCLOG_FIELD_ACCOUNT_ID NSNumberAsLongLong:self.accountId];
    [args put:PEX_DBCLOG_FIELD_STATUS_CODE NSNumberAsInt:self.statusCode];
    [args put:PEX_DBCLOG_FIELD_STATUS_TEXT string:self.statusText];
    [args put:PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID NSNumberAsLongLong:self.remoteAccountId];
    [args put:PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS string:self.remoteContactSip];
    [args put:PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME string:self.remoteContactName];
    [args put:PEX_DBCLOG_FIELD_ACCOUNT_ID NSNumberAsLongLong:self.accountId];
    [args put:PEX_DBCLOG_FIELD_SEEN_BY_USER boolean:self.seenByUser];

    if (self.eventTimestamp != nil){
        [args put:PEX_DBCLOG_FIELD_EVENT_TIMESTAMP date:self.eventTimestamp];
    }

    if (self.eventNonce != nil) {
        [args put:PEX_DBCLOG_FIELD_EVENT_NONCE NSNumberAsLongLong:self.eventNonce];
    }

    if (self.sipCallId != nil){
        [args put:PEX_DBCLOG_FIELD_SIP_CALL_ID string:self.sipCallId];
    }

    return args;
}

- (void)createFromCursor:(PEXDbCursor *)c {
    int colCount = [c getColumnCount];
    for(int i=0; i<colCount; i++){
        NSString * colname = [c getColumnName:i];

        if ([PEX_DBCLOG_FIELD_ID isEqualToString: colname]){
            _id = [c getInt64:i];
        } else if ([PEX_DBCLOG_FIELD_DATE isEqualToString: colname]){
            _callStart = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBCLOG_FIELD_DURATION isEqualToString: colname]){
            _duration = [c getInt64:i];
        } else if ([PEX_DBCLOG_FIELD_NEW isEqualToString: colname]){
            _isNew = [[c getInt:i] boolValue];
        } else if ([PEX_DBCLOG_FIELD_NUMBER isEqualToString: colname]){
            _remoteContact = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_TYPE isEqualToString: colname]){
            _type = [c getInt:i];
        } else if ([PEX_DBCLOG_FIELD_CACHED_NAME isEqualToString: colname]){
            _remoteUserEnteredNumber = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_CACHED_NUMBER_LABEL isEqualToString: colname]){
            _numberLabel = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_CACHED_NUMBER_TYPE isEqualToString: colname]){
            _numberType = [c getInt:i];
        } else if ([PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ID isEqualToString: colname]){
            _remoteAccountId = [c getInt64:i];
        } else if ([PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_NAME isEqualToString: colname]){
            _remoteContactName = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS isEqualToString: colname]){
            _remoteContactSip = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_ACCOUNT_ID isEqualToString: colname]){
            _accountId = [c getInt64:i];
        } else if ([PEX_DBCLOG_FIELD_STATUS_CODE isEqualToString: colname]){
            _statusCode = [c getInt:i];
        } else if ([PEX_DBCLOG_FIELD_STATUS_TEXT isEqualToString: colname]){
            _statusText = [c getString:i];
        } else if ([PEX_DBCLOG_FIELD_SEEN_BY_USER isEqualToString: colname]){
            _seenByUser = [[c getInt:i] boolValue];
        } else if ([PEX_DBCLOG_FIELD_EVENT_TIMESTAMP isEqualToString: colname]){
            _eventTimestamp = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBCLOG_FIELD_EVENT_NONCE isEqualToString: colname]){
            _eventNonce = [c getInt64:i];
        }  else if ([PEX_DBCLOG_FIELD_SIP_CALL_ID isEqualToString: colname]){
            _sipCallId = [c getString:i];
        } else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

- (instancetype)initWithCursor:(PEXDbCursor *)cursor {
    if (self = [super init]) {
        [self createFromCursor:cursor];
    }

    return self;
}

+ (instancetype)callLogFromCursor:(PEXDbCursor *)cursor {
    PEXDbCallLog * clog = [[PEXDbCallLog alloc] initWithCursor:cursor];
    return clog;
}

- (instancetype)initWithCall:(PEXPjCall *)call {
    if (self = [super init]) {
        self.remoteContact = call.remoteContact;
        self.remoteContactSip = call.remoteSip;

        // Try to load contactlist details.
        NSString *displayName = self.remoteContactSip;
        if (![PEXStringUtils isEmpty:self.remoteContactSip]) {
            PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
            PEXDbContact * clist = [PEXDbContact newProfileFromDbSip:cr sip:self.remoteContactSip
                                                          projection:[PEXDbContact getFullProjection]];

            if (clist != nil) {
                if (![PEXStringUtils isEmpty:clist.displayName]){
                    displayName = clist.displayName;
                }

                self.remoteAccountId = clist.id;
            }
        }

        self.remoteContactName = displayName;

        // Date extract.
        NSDate * callStart = call.callStart;
        self.callStart = (callStart != nil) ? callStart : [NSDate date];

        int type = PEX_DBCLOG_TYPE_OUTGOING;
        BOOL isNew = NO;
        if (call.isIncoming) {
            type = PEX_DBCLOG_TYPE_MISSED;
            isNew = YES;

            if (callStart != nil) {
                // Has started on the remote side, so not missed call
                type = PEX_DBCLOG_TYPE_INCOMING;
                isNew = NO;

            } else if ([call hasStatusCode:PJSIP_SC_DECLINE]) {
                // We have intentionally declined this call
                type = PEX_DBCLOG_TYPE_INCOMING;
                isNew = NO;
            }
        }

        self.type = @(type);
        self.isNew = isNew;
        self.accountId = @(call.accId);
        self.statusCode = call.lastStatusCode;
        self.statusText = call.lastStatusComment;
        self.seenByUser = NO;

        self.remoteUserEnteredNumber = call.remoteSip;
        self.numberLabel = self.remoteContactName;
        self.numberType = @(1);
        self.duration = @(0);

        self.sipCallId = call.sipCallId;
        self.eventTimestamp = call.callStart;
        self.eventNonce = nil;

        if (callStart != nil){
            self.duration = @([[NSDate date] timeIntervalSince1970] - [callStart timeIntervalSince1970]);
        }
    }

    return self;
}


+ (instancetype)callogFromCall:(PEXPjCall *)call {
    PEXDbCallLog * clog = [[PEXDbCallLog alloc] initWithCall:call];
    return clog;
}

/**
* Insets current call log information to the database.
* @param ctxt
*/
+(PEXUri *) addToDatabase: (PEXDbCallLog *) callLog cr: (PEXDbContentProvider *) cr {
    @try {
        return [cr insert:[PEXDbCallLog getURI] contentValues:[callLog getDbContentValues]];
    } @catch(NSException * ex){
        DDLogError(@"Cannot insert callog info to DB, %@, exception=%@", callLog, ex);
    }

    return nil;
}

/**
* Keeps last 500 records in the call log database.
* Requires direct access to the database, used in helper.
* @param db
*/
+(BOOL) pruneRecords: (PEXDbContentProvider *) cr {
    @try {
        return [cr delete:[PEXDbCallLog getURI]
                 selection:[NSString stringWithFormat:@" WHERE %@ IN (SELECT %@ FROM %@ ORDER BY %@ LIMIT -1 OFFSET 500)",
                 PEX_DBCLOG_FIELD_ID, PEX_DBCLOG_FIELD_ID, PEX_DBCLOG_TABLE, [self getDefaultSortOrder]]
             selectionArgs:@[]];
    } @catch(NSException *e){
        DDLogError(@"Cannot prune old call log details. exception=%@", e);
    }

    return NO;
}

+(BOOL) probabilisticPrune: (PEXDbContentProvider *) cr {
    uint32_t rnd = arc4random_uniform(400);
    if (rnd != 0){
        return NO;
    }

    DDLogInfo(@"Probabilistic prune records hit!");
    return [self pruneRecords:cr];
}

+ (int)removeCallLogsFor:(NSString const *)remote cr: (PEXDbContentProvider *) cr {
    @try {
        return [cr delete:[PEXDbCallLog getURI]
                selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS]
            selectionArgs:@[remote]];
    } @catch(NSException *e){
        DDLogError(@"Cannot prune old call log details. exception=%@", e);
    }

    return 0;
}

+ (PEXDbCallLog *)getLogByEventDescription:(NSString *)from
                                      toId:(NSNumber *)toId
                                   evtTime:(NSDate *)time
                                  evtNonce:(NSNumber *)nonce
                                    callId:(NSString *)callId
                                        cr: (PEXDbContentProvider *) cr {
    PEXDbCursor * c = nil;
    @try {
        NSMutableString * selection = [[NSMutableString alloc] init];
        NSMutableArray * selectionArgs = [[NSMutableArray alloc] init];

        [selection appendFormat:@"WHERE %@=? AND %@=? AND (0 ",
                        PEX_DBCLOG_FIELD_REMOTE_ACCOUNT_ADDRESS,
                        PEX_DBCLOG_FIELD_ACCOUNT_ID];
        [selectionArgs addObject:from];
        [selectionArgs addObject:toId];

        if (time != nil && [time timeIntervalSince1970] > 100){
            [selection appendFormat:@" OR %@=?", PEX_DBCLOG_FIELD_EVENT_TIMESTAMP];
            [selectionArgs addObject:@([time timeIntervalSince1970])];
        }

        if (callId != nil && ![PEXUtils isEmpty:callId]){
            [selection appendFormat:@" OR %@=?", PEX_DBCLOG_FIELD_SIP_CALL_ID];
            [selectionArgs addObject:callId];
        }

        // Nonce only if callId is empty
        if (nonce != nil && [nonce longValue] != 0 && [PEXUtils isEmpty:callId]){
            [selection appendFormat:@" OR %@=?", PEX_DBCLOG_FIELD_EVENT_NONCE];
            [selectionArgs addObject:nonce];
        }

        [selection appendString:@" ) "];

        c = [cr query:[self getURI]
           projection:[self getLightProjection]
            selection:selection
        selectionArgs:selectionArgs
            sortOrder:nil];

        if (c == nil || ![c moveToFirst]) {
            return nil;
        }

        return [self callLogFromCursor:c];

    } @catch(NSException *e){
        DDLogError(@"Cannot fetch existing log. exception=%@", e);
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    return nil;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToCallLog:other];
}

- (BOOL)isEqualToCallLog:(const PEXDbCallLog * const)callLog {
    if (self == callLog)
        return YES;
    if (callLog == nil)
        return NO;
    if (self.id != callLog.id && ![self.id isEqualToNumber:callLog.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

- (bool)isIncoming
{
    return [self.type integerValue] != PEX_DBCLOG_TYPE_OUTGOING;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.accountId=%@", self.accountId];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.type=%@", self.type];
    [description appendFormat:@", self.isNew=%d", self.isNew];
    [description appendFormat:@", self.duration=%@", self.duration];
    [description appendFormat:@", self.callStart=%@", self.callStart];
    [description appendFormat:@", self.remoteAccountId=%@", self.remoteAccountId];
    [description appendFormat:@", self.remoteUserEnteredNumber=%@", self.remoteUserEnteredNumber];
    [description appendFormat:@", self.remoteContactSip=%@", self.remoteContactSip];
    [description appendFormat:@", self.remoteContact=%@", self.remoteContact];
    [description appendFormat:@", self.remoteContactName=%@", self.remoteContactName];
    [description appendFormat:@", self.numberType=%@", self.numberType];
    [description appendFormat:@", self.numberLabel=%@", self.numberLabel];
    [description appendFormat:@", self.statusCode=%@", self.statusCode];
    [description appendFormat:@", self.statusText=%@", self.statusText];
    [description appendFormat:@", self.seenByUser=%d", self.seenByUser];
    [description appendFormat:@", self.eventTimestamp=%@", self.eventTimestamp];
    [description appendFormat:@", self.eventNonce=%@", self.eventNonce];
    [description appendFormat:@", self.sipCallId=%@", self.sipCallId];
    [description appendString:@">"];
    return description;
}


@end