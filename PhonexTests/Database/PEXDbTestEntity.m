//
// Created by Matej Oravec on 27/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbTestEntity.h"

@interface PEXDbTestEntity()

@end

@implementation PEXDbTestEntity {

}

+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString * createTable;
    dispatch_once(&once, ^{
        createTable =
                @"CREATE TABLE IF NOT EXISTS " TESTENTITY_TABLE_NAME " ("
                            TESTENTITY_TFIELD_ID " INTEGER PRIMARY KEY AUTOINCREMENT,"
                        " " TESTENTITY_TFIELD_TEXT " TEXT,"
                        " " TESTENTITY_TFIELD_LONG " INTEGER,"
                        " " TESTENTITY_TFIELD_DOUBLE " REAL,"
                        " " TESTENTITY_TFIELD_BLOB " BLOB"
                        ");";

    });

    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                @TESTENTITY_TFIELD_ID,
                @TESTENTITY_TFIELD_TEXT,
                @TESTENTITY_TFIELD_LONG,
                @TESTENTITY_TFIELD_DOUBLE,
                @TESTENTITY_TFIELD_BLOB];
    });

    return fullProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:@TESTENTITY_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:@TESTENTITY_TABLE_NAME isBase:YES];
    });
    return uriBase;
}

- (void)createFromCursor:(PEXDbCursor *)c
{
    int colCount = [c getColumnCount];
    for(int i=0; i<colCount; i++) {
        NSString *colname = [c getColumnName:i];

        if ([colname isEqualToString:@TESTENTITY_TFIELD_ID]) {
            self.idField = [c getInt64:i];
        } else if ([colname isEqualToString:@TESTENTITY_TFIELD_TEXT]) {
            self.textField = [c getString:i];
        } else if ([colname isEqualToString:@TESTENTITY_TFIELD_LONG]) {
            self.fieldInt64 = [c getInt64:i];
        } else if ([colname isEqualToString:@TESTENTITY_TFIELD_DOUBLE]) {
            self.doubleField = [c getDouble:i];
        } else if ([colname isEqualToString:@TESTENTITY_TFIELD_BLOB]) {
            self.blobField = [c getBlob:i];
        } else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }

}

-(PEXDbContentValues *) getDbContentValues {

    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];

    //[cv put:@TESTENTITY_TFIELD_ID NSNumberAsLong:self.idField];
    [cv put:@TESTENTITY_TFIELD_TEXT string:self.textField];
    [cv put:@TESTENTITY_TFIELD_LONG NSNumberAsLongLong:self.fieldInt64];
    [cv put:@TESTENTITY_TFIELD_DOUBLE NSNumberAsDouble:self.doubleField];
    [cv put:@TESTENTITY_TFIELD_BLOB data:self.blobField];

    return cv;
}


@end