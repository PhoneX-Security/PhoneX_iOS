//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbContactNotification.h"
#import "PEXModelHelper.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbContentProvider.h"

NSString * const PEX_DBCONTACTNOTIFICATION_TABLE = @"contactNotification";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_ID = @"_id";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID = @"server_id";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME = @"username";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_TYPE = @"type";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_DATE = @"date";
NSString * const PEX_DBCONTACTNOTIFICATION_FIELD_SEEN = @"seen";

@implementation PEXDbContactNotification {

}

+(NSString *) getCreateTable
{
    static dispatch_once_t once;
    static NSString *result;
    dispatch_once(&once, ^{
        result = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
                        "  %@  INTEGER PRIMARY KEY AUTOINCREMENT,"//  FIELD_ID
                        "  %@  INTEGER DEFAULT 0,"//  	  FIELD_SERVER_ID
                        "  %@  TEXT,"//  				 FIELD_USERNAME
                        "  %@  INTEGER,"//                FIELD_TYPE
                        "  %@  NUMERIC,"//                 FIELD_DATE
                        "  %@  INTEGER"//                 FIELD_SEEN
                        ");",

                        PEX_DBCONTACTNOTIFICATION_TABLE,
                        PEX_DBCONTACTNOTIFICATION_FIELD_ID,
                        PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID,
                        PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME,
                        PEX_DBCONTACTNOTIFICATION_FIELD_TYPE,
                        PEX_DBCONTACTNOTIFICATION_FIELD_DATE,
                        PEX_DBCONTACTNOTIFICATION_FIELD_SEEN
        ];
    });
    return result;
}

+(NSArray *) getFullProjection
{
    static dispatch_once_t once;
    static NSArray *result;
    dispatch_once(&once, ^{
        result = @[
                PEX_DBCONTACTNOTIFICATION_FIELD_ID,
                PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID,
                PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME,
                PEX_DBCONTACTNOTIFICATION_FIELD_TYPE,
                PEX_DBCONTACTNOTIFICATION_FIELD_DATE,
                PEX_DBCONTACTNOTIFICATION_FIELD_SEEN
        ];
    });
    return result;
}

+(const PEXDbUri *) getURI
{
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBCONTACTNOTIFICATION_TABLE];
    });
    return uri;
}

+(const PEXDbUri *) getURIBase
{
    static dispatch_once_t once;
    static PEXUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBCONTACTNOTIFICATION_TABLE isBase:YES];
    });
    return uriBase;
}

+(NSString *) getDefaultSortOrder
{
    return [NSString stringWithFormat:@"ORDER BY %@ DESC", PEX_DBCONTACTNOTIFICATION_FIELD_ID];
}

-(PEXDbContentValues *) getDbContentValues
{
    PEXDbContentValues * const args = [[PEXDbContentValues alloc] init];

    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_ID NSNumberAsLongLong:_id];
    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID NSNumberAsLongLong:self.serverId];
    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME string:self.username];
    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_TYPE NSNumberAsInt:self.type];
    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_DATE date:self.date];
    [args putIfNotNil:PEX_DBCONTACTNOTIFICATION_FIELD_SEEN NSNumberAsBoolean:self.seen];

    return args;
}

-(void) createFromCursor: (PEXDbCursor *) c
{
    const int colCount = [c getColumnCount];

    for (int i = 0; i < colCount; ++i)
    {
        const PEXModelHelper * const helper = [[PEXModelHelper alloc] initWithCursor:c index:i];
        NSString * const colname = [c getColumnName:i];

        if ([helper assignInt64To:&_id ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_ID]) {}
        else if ([helper assignInt64To:&_serverId ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_SERVER_ID]) {}
        else if ([helper assignStringTo:&_username ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME]) {}
        else if ([helper assignIntTo:&_type ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_TYPE]) {}
        else if ([helper assignDateTo:&_date ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_DATE]) {}
        else if ([helper assignIntTo:&_seen ifMatchesColumn:PEX_DBCONTACTNOTIFICATION_FIELD_SEEN]) {}

        else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

+ (instancetype) contactNotificationFromCursor: (PEXDbCursor * const) c
{
    PEXDbContactNotification * const result = [[PEXDbContactNotification alloc] init];

    [result createFromCursor:c];

    return result;
}

+ (BOOL)deleteRequestsFromUser:(NSString *)username cr:(PEXDbContentProvider *)cr {
    return [cr delete:[self getURI]
            selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBCONTACTNOTIFICATION_FIELD_USERNAME]
        selectionArgs:@[username]];
}

#pragma GENERATED

- (id)copyWithZone:(NSZone *)zone {
    PEXDbContactNotification *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.date = self.date;
        copy.id = self.id;
        copy.serverId = self.serverId;
        copy.username = self.username;
        copy.type = self.type;
        copy.seen = self.seen;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToNotification:other];
}

- (BOOL)isEqualToNotification:(PEXDbContactNotification *)notification {
    if (self == notification)
        return YES;
    if (notification == nil)
        return NO;
    if (self.id != notification.id && ![self.id isEqualToNumber:notification.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.date=%@", self.date];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.serverId=%@", self.serverId];
    [description appendFormat:@", self.username=%@", self.username];
    [description appendFormat:@", self.type=%@", self.type];
    [description appendFormat:@", self.seen=%@", self.seen];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.date = [coder decodeObjectForKey:@"self.date"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.serverId = [coder decodeObjectForKey:@"self.serverId"];
        self.username = [coder decodeObjectForKey:@"self.username"];
        self.type = [coder decodeObjectForKey:@"self.type"];
        self.seen = [coder decodeObjectForKey:@"self.seen"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.date forKey:@"self.date"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.serverId forKey:@"self.serverId"];
    [coder encodeObject:self.username forKey:@"self.username"];
    [coder encodeObject:self.type forKey:@"self.type"];
    [coder encodeObject:self.seen forKey:@"self.seen"];
}


@end