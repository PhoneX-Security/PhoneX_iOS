//
// Created by Matej Oravec on 11/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbExpiredLicenceLog.h"
#import "PEXModelHelper.h"
#import "PEXDbAppContentProvider.h"
#import "PEXChatAccountingManager.h"

NSString * const PEX_DBEXPIRED_TABLE = @"expiredInfo";
NSString * const PEX_DBEXPIRED_FIELD_ID = @"_id";
NSString * const PEX_DBEXPIRED_FIELD_TYPE = @"type";
NSString * const PEX_DBEXPIRED_FIELD_DATE = @"date";

const NSInteger PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE  = 1;

@implementation PEXDbExpiredLicenceLog {

}

+(NSString *) getCreateTable
{
    static dispatch_once_t once;
    static NSString *createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
                        "  %@  INTEGER PRIMARY KEY AUTOINCREMENT,"//  FIELD_ID
                        "  %@  INTEGER,"//  				 FIELD_TYPE
                        "  %@  NUMERIC"//  				 FIELD_DATE
                        ");",

                        PEX_DBEXPIRED_TABLE,
                        PEX_DBEXPIRED_FIELD_ID,
                        PEX_DBEXPIRED_FIELD_TYPE,
                        PEX_DBEXPIRED_FIELD_DATE
                ];
    });
    return createTable;
}

+(NSArray *) getFullProjection
{
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                PEX_DBEXPIRED_FIELD_ID,
                PEX_DBEXPIRED_FIELD_TYPE,
                PEX_DBEXPIRED_FIELD_DATE
        ];
    });
    return fullProjection;
}

+(const PEXDbUri *) getURI
{
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBEXPIRED_TABLE];
    });
    return uri;
}

+(const PEXDbUri *) getURIBase
{
    static dispatch_once_t once;
    static PEXUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBEXPIRED_TABLE isBase:YES];
    });
    return uriBase;
}

+(NSString *) getDefaultSortOrder
{
    return [NSString stringWithFormat:@"%@ DESC", PEX_DBEXPIRED_FIELD_DATE];
}

-(PEXDbContentValues *) getDbContentValues
{
    PEXDbContentValues * const args = [[PEXDbContentValues alloc] init];

    [args putIfNotNil:PEX_DBEXPIRED_FIELD_ID NSNumberAsLongLong:_id];
    [args putIfNotNil:PEX_DBEXPIRED_FIELD_TYPE NSNumberAsInt:self.type];
    [args putIfNotNil:PEX_DBEXPIRED_FIELD_DATE date:self.date];

    return args;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.type = [coder decodeObjectForKey:@"self.type"];
        self.date = [coder decodeObjectForKey:@"self.date"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.type forKey:@"self.type"];
    [coder encodeObject:self.date forKey:@"self.date"];
}

-(void) createFromCursor: (PEXDbCursor *) c
{
    const int colCount = [c getColumnCount];

    for (int i = 0; i < colCount; ++i)
    {
        const PEXModelHelper * const helper = [[PEXModelHelper alloc] initWithCursor:c index:i];
        NSString * const colname = [c getColumnName:i];

        if ([helper assignInt64To:&_id ifMatchesColumn:PEX_DBEXPIRED_FIELD_ID]) {}
        else if ([helper assignIntTo:&_type ifMatchesColumn:PEX_DBEXPIRED_FIELD_TYPE]) {}
        else if ([helper assignDateTo:&_date ifMatchesColumn:PEX_DBEXPIRED_FIELD_DATE]) {}

        else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

+ (instancetype) expiredInfoFromCursor: (PEXDbCursor * const) c
{
    PEXDbExpiredLicenceLog * const result = [[PEXDbExpiredLicenceLog alloc] init];

    [result createFromCursor:c];

    return result;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToInfo:other];
}

- (BOOL)isEqualToInfo:(PEXDbExpiredLicenceLog *)info {
    if (self == info)
        return YES;
    if (info == nil)
        return NO;
    if (self.id != info.id && ![self.id isEqualToNumber:info.id])
        return NO;
    if (self.type != info.type && ![self.type isEqualToNumber:info.type])
        return NO;
    if (self.date != info.date && ![self.date isEqualToDate:info.date])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.id hash];
    hash = hash * 31u + [self.type hash];
    hash = hash * 31u + [self.date hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.id=%@", self.id];
    [description appendFormat:@", self.type=%@", self.type];
    [description appendFormat:@", self.date=%@", self.date];
    [description appendString:@">"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbExpiredLicenceLog *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.id = self.id;
        copy.type = self.type;
        copy.date = self.date;
    }

    return copy;
}


@end