//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbAccountingLog.h"
#import "PEXDbCursor.h"
#import "PEXDbContentValues.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbContentProvider.h"


NSString *PEX_DBAL_TABLE_NAME = @"PEXDbAccountingLog";
NSString *PEX_DBAL_FIELD_ID = @"id";
NSString *PEX_DBAL_FIELD_TYPE = @"type";
NSString *PEX_DBAL_FIELD_RKEY = @"rkey";
NSString *PEX_DBAL_FIELD_DATE_CREATED = @"dateCreated";
NSString *PEX_DBAL_FIELD_DATE_MODIFIED = @"dateModified";
NSString *PEX_DBAL_FIELD_ACTION_ID = @"actionId";
NSString *PEX_DBAL_FIELD_ACTION_COUNTER = @"actionCounter";
NSString *PEX_DBAL_FIELD_AMOUNT = @"value";
NSString *PEX_DBAL_FIELD_AGGREGATED = @"aggregated";
NSString *PEX_DBAL_FIELD_AREF = @"aref";
NSString *PEX_DBAL_FIELD_PERM_ID = @"permId";
NSString *PEX_DBAL_FIELD_LIC_ID = @"licId";

@implementation PEXDbAccountingLog {

}

+ (NSString *)getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER PRIMARY KEY AUTOINCREMENT, "//  				 PEX_DBAL_FIELD_ID
                    "  %@  TEXT, "//  				 PEX_DBAL_FIELD_TYPE
                    "  %@  TEXT, "//  				 PEX_DBAL_FIELD_RKEY
                    "  %@  NUMERIC DEFAULT 0, "//  				 PEX_DBAL_FIELD_DATE_CREATED
                    "  %@  NUMERIC DEFAULT 0, "//  				 PEX_DBAL_FIELD_DATE_MODIFIED
                    "  %@  INTEGER, "//  				 PEX_DBAL_FIELD_ACTION_ID
                    "  %@  INTEGER, "//  				 PEX_DBAL_FIELD_ACTION_COUNTER
                    "  %@  INTEGER, "//  				 PEX_DBAL_FIELD_AMOUNT
                    "  %@  INTEGER, "//  				 PEX_DBAL_FIELD_AGGREGATED
                    "  %@  TEXT, "//  				 PEX_DBAL_FIELD_AREF
                    "  %@  INTEGER, "//  				 PEX_DBAL_FIELD_PERM_ID
                    "  %@  INTEGER "//  				 PEX_DBAL_FIELD_LIC_ID
                    " );",
            PEX_DBAL_TABLE_NAME,
            PEX_DBAL_FIELD_ID,
            PEX_DBAL_FIELD_TYPE,
            PEX_DBAL_FIELD_RKEY,
            PEX_DBAL_FIELD_DATE_CREATED,
            PEX_DBAL_FIELD_DATE_MODIFIED,
            PEX_DBAL_FIELD_ACTION_ID,
            PEX_DBAL_FIELD_ACTION_COUNTER,
            PEX_DBAL_FIELD_AMOUNT,
            PEX_DBAL_FIELD_AGGREGATED,
            PEX_DBAL_FIELD_AREF,
            PEX_DBAL_FIELD_PERM_ID,
            PEX_DBAL_FIELD_LIC_ID
    ];
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                PEX_DBAL_FIELD_ID,
                PEX_DBAL_FIELD_TYPE,
                PEX_DBAL_FIELD_RKEY,
                PEX_DBAL_FIELD_DATE_CREATED,
                PEX_DBAL_FIELD_DATE_MODIFIED,
                PEX_DBAL_FIELD_ACTION_ID,
                PEX_DBAL_FIELD_ACTION_COUNTER,
                PEX_DBAL_FIELD_AMOUNT,
                PEX_DBAL_FIELD_AGGREGATED,
                PEX_DBAL_FIELD_AREF,
                PEX_DBAL_FIELD_PERM_ID,
                PEX_DBAL_FIELD_LIC_ID];
    });
    return fullProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBAL_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBAL_TABLE_NAME isBase:YES];
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
        if ([PEX_DBAL_FIELD_ID isEqualToString:colname]) {
            _id = [c getInt64:i];
        } else if ([PEX_DBAL_FIELD_TYPE isEqualToString:colname]) {
            _type = [c getString:i];
        } else if ([PEX_DBAL_FIELD_RKEY isEqualToString:colname]) {
            _rkey = [c getString:i];
        } else if ([PEX_DBAL_FIELD_DATE_CREATED isEqualToString:colname]) {
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBAL_FIELD_DATE_MODIFIED isEqualToString:colname]) {
            _dateModified = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBAL_FIELD_ACTION_ID isEqualToString:colname]) {
            _actionId = [c getInt64:i];
        } else if ([PEX_DBAL_FIELD_ACTION_COUNTER isEqualToString:colname]) {
            _actionCounter = [c getInt64:i];
        } else if ([PEX_DBAL_FIELD_AMOUNT isEqualToString:colname]) {
            _amount = [c getInt64:i];
        } else if ([PEX_DBAL_FIELD_AGGREGATED isEqualToString:colname]) {
            _aggregated = [c getInt:i];
        } else if ([PEX_DBAL_FIELD_AREF isEqualToString:colname]) {
            _aref = [c getString:i];
        } else if ([PEX_DBAL_FIELD_PERM_ID isEqualToString:colname]) {
            _permId = [c getInt64:i];
        } else if ([PEX_DBAL_FIELD_LIC_ID isEqualToString:colname]) {
            _licId = [c getInt64:i];
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
        [cv put:PEX_DBAL_FIELD_ID NSNumberAsLongLong:_id];
    }
    if (_type != nil)
        [cv put:PEX_DBAL_FIELD_TYPE string:_type];
    if (_rkey != nil)
        [cv put:PEX_DBAL_FIELD_RKEY string:_rkey];
    if (_dateCreated != nil)
        [cv put:PEX_DBAL_FIELD_DATE_CREATED date:_dateCreated];
    if (_dateModified != nil)
        [cv put:PEX_DBAL_FIELD_DATE_MODIFIED date:_dateModified];
    if (_actionId != nil)
        [cv put:PEX_DBAL_FIELD_ACTION_ID number:_actionId];
    if (_actionCounter != nil)
        [cv put:PEX_DBAL_FIELD_ACTION_COUNTER number:_actionCounter];
    if (_amount != nil)
        [cv put:PEX_DBAL_FIELD_AMOUNT number:_amount];
    if (_aggregated != nil)
        [cv put:PEX_DBAL_FIELD_AGGREGATED number:_aggregated];
    if (_aref != nil)
        [cv put:PEX_DBAL_FIELD_AREF string:_aref];
    if (_permId != nil)
        [cv put:PEX_DBAL_FIELD_PERM_ID number:_permId];
    if (_licId != nil)
        [cv put:PEX_DBAL_FIELD_LIC_ID number:_licId];

    return cv;
}

+ (instancetype)accountingLogWithCursor:(PEXDbCursor *)cursor {
    return [[self alloc] initWithCursor:cursor];
}

- (instancetype)initWithCursor:(PEXDbCursor *)cursor {
    self = [super init];
    if (self) {
        [self createFromCursor:cursor];
    }

    return self;
}

+ (int)deleteRecordsOlderThan:(NSNumber *)actionId actionCtr:(NSNumber *)actionCtr cr:(PEXDbContentProvider *)cr {
    @try {
        return [cr deleteEx:[self getURI]
                  selection:[NSString stringWithFormat:@"WHERE %@<? OR (%@=? AND %@<=?) ",
                                  PEX_DBAL_FIELD_ACTION_ID,
                                  PEX_DBAL_FIELD_ACTION_ID,
                                  PEX_DBAL_FIELD_ACTION_COUNTER]
              selectionArgs:@[actionId, actionId, actionCtr]];

    } @catch (NSException * e){
        DDLogError(@"Exception when deleting %@", e);
    }

    return 0;
}

@end