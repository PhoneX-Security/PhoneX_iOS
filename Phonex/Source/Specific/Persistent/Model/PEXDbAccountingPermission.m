//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbAccountingPermission.h"


NSString *PEX_DBAP_TABLE_NAME = @"PEXDbAccountingPermission";
NSString *PEX_DBAP_FIELD_ID = @"id";
NSString *PEX_DBAP_FIELD_PERM_ID = @"permId";
NSString *PEX_DBAP_FIELD_LIC_ID = @"licId";
NSString *PEX_DBAP_FIELD_NAME = @"name";
NSString *PEX_DBAP_FIELD_LOCAL_VIEW = @"localView";
NSString *PEX_DBAP_FIELD_SPENT = @"spent";
NSString *PEX_DBAP_FIELD_AMOUNT = @"value";
NSString *PEX_DBAP_FIELD_AREF = @"aref";
NSString *PEX_DBAP_FIELD_DATE_CREATED = @"dateCreated";
NSString *PEX_DBAP_FIELD_DATE_MODIFIED = @"dateModified";
NSString *PEX_DBAP_FIELD_ACTION_ID_FIRST = @"actionIdFirst";
NSString *PEX_DBAP_FIELD_ACTION_CTR_FIRST = @"actionCtrFirst";
NSString *PEX_DBAP_FIELD_ACTION_ID_LAST = @"actionIdLast";
NSString *PEX_DBAP_FIELD_ACTION_CTR_LAST = @"actionCtrLast";
NSString *PEX_DBAP_FIELD_AGGREGATION_COUNT = @"aggregationCount";
NSString *PEX_DBAP_FIELD_SUBSCRIPTION = @"subscription";
NSString *PEX_DBAP_FIELD_VALID_FROM = @"validFrom";
NSString *PEX_DBAP_FIELD_VALID_TO = @"validTo";

@implementation PEXDbAccountingPermission {

}
+ (NSString *)getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER PRIMARY KEY AUTOINCREMENT, "//  				 PEX_DBAP_FIELD_ID
                    "  %@  INTEGER DEFAULT -1, "//  				 PEX_DBAP_FIELD_PERM_ID
                    "  %@  INTEGER DEFAULT -1, "//  				 PEX_DBAP_FIELD_LIC_ID
                    "  %@  TEXT, "//  				 PEX_DBAP_FIELD_NAME
                    "  %@  INTEGER DEFAULT 1, "//  				 PEX_DBAP_FIELD_LOCAL_VIEW
                    "  %@  INTEGER DEFAULT 0, "//  				 PEX_DBAP_FIELD_SPENT
                    "  %@  INTEGER DEFAULT 0, "//  				 PEX_DBAP_FIELD_AMOUNT
                    "  %@  TEXT, "//  				 PEX_DBAP_FIELD_AREF
                    "  %@  NUMERIC DEFAULT 0,  "//  				 PEX_DBAP_FIELD_DATE_CREATED
                    "  %@  NUMERIC DEFAULT 0,  "//  				 PEX_DBAP_FIELD_DATE_MODIFIED
                    "  %@  INTEGER DEFAULT 0,  "//  				 PEX_DBAP_FIELD_ACTION_ID_FIRST
                    "  %@  INTEGER DEFAULT -1, "//  				 PEX_DBAP_FIELD_ACTION_CTR_FIRST
                    "  %@  INTEGER DEFAULT 0,  "//  				 PEX_DBAP_FIELD_ACTION_ID_LAST
                    "  %@  INTEGER DEFAULT -1, "//  				 PEX_DBAP_FIELD_ACTION_CTR_LAST
                    "  %@  INTEGER DEFAULT 0,  "//  				 PEX_DBAP_FIELD_AGGREGATION_COUNT
                    "  %@  INTEGER DEFAULT 0,  "//  				 PEX_DBAP_FIELD_SUBSCRIPTION
                    "  %@  NUMERIC DEFAULT 0,  "//  				 PEX_DBAP_FIELD_VALID_FROM
                    "  %@  NUMERIC DEFAULT 0   "//  				 PEX_DBAP_FIELD_VALID_TO
                    " );",
            PEX_DBAP_TABLE_NAME,
            PEX_DBAP_FIELD_ID,
            PEX_DBAP_FIELD_PERM_ID,
            PEX_DBAP_FIELD_LIC_ID,
            PEX_DBAP_FIELD_NAME,
            PEX_DBAP_FIELD_LOCAL_VIEW,
            PEX_DBAP_FIELD_SPENT,
            PEX_DBAP_FIELD_AMOUNT,
            PEX_DBAP_FIELD_AREF,
            PEX_DBAP_FIELD_DATE_CREATED,
            PEX_DBAP_FIELD_DATE_MODIFIED,
            PEX_DBAP_FIELD_ACTION_ID_FIRST,
            PEX_DBAP_FIELD_ACTION_CTR_FIRST,
            PEX_DBAP_FIELD_ACTION_ID_LAST,
            PEX_DBAP_FIELD_ACTION_CTR_LAST,
            PEX_DBAP_FIELD_AGGREGATION_COUNT,
            PEX_DBAP_FIELD_SUBSCRIPTION,
            PEX_DBAP_FIELD_VALID_FROM,
            PEX_DBAP_FIELD_VALID_TO
    ];
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                PEX_DBAP_FIELD_ID,
                PEX_DBAP_FIELD_PERM_ID,
                PEX_DBAP_FIELD_LIC_ID,
                PEX_DBAP_FIELD_NAME,
                PEX_DBAP_FIELD_LOCAL_VIEW,
                PEX_DBAP_FIELD_SPENT,
                PEX_DBAP_FIELD_AMOUNT,
                PEX_DBAP_FIELD_AREF,
                PEX_DBAP_FIELD_DATE_CREATED,
                PEX_DBAP_FIELD_DATE_MODIFIED,
                PEX_DBAP_FIELD_ACTION_ID_FIRST,
                PEX_DBAP_FIELD_ACTION_CTR_FIRST,
                PEX_DBAP_FIELD_ACTION_ID_LAST,
                PEX_DBAP_FIELD_ACTION_CTR_LAST,
                PEX_DBAP_FIELD_AGGREGATION_COUNT,
                PEX_DBAP_FIELD_SUBSCRIPTION,
                PEX_DBAP_FIELD_VALID_FROM,
                PEX_DBAP_FIELD_VALID_TO];
    });
    return fullProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBAP_TABLE_NAME];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBAP_TABLE_NAME isBase:YES];
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
        if ([PEX_DBAP_FIELD_ID isEqualToString:colname]) {
            _id = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_PERM_ID isEqualToString:colname]) {
            _permId = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_LIC_ID isEqualToString:colname]) {
            _licId = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_NAME isEqualToString:colname]) {
            _name = [c getString:i];
        } else if ([PEX_DBAP_FIELD_LOCAL_VIEW isEqualToString:colname]) {
            _localView = [c getInt:i];
        } else if ([PEX_DBAP_FIELD_SPENT isEqualToString:colname]) {
            _spent = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_AMOUNT isEqualToString:colname]) {
            _value = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_AREF isEqualToString:colname]) {
            _aref = [c getString:i];
        } else if ([PEX_DBAP_FIELD_DATE_CREATED isEqualToString:colname]) {
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBAP_FIELD_DATE_MODIFIED isEqualToString:colname]) {
            _dateModified = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBAP_FIELD_ACTION_ID_FIRST isEqualToString:colname]) {
            _actionIdFirst = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_ACTION_CTR_FIRST isEqualToString:colname]) {
            _actionCtrFirst = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_ACTION_ID_LAST isEqualToString:colname]) {
            _actionIdLast = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_ACTION_CTR_LAST isEqualToString:colname]) {
            _actionCtrLast = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_AGGREGATION_COUNT isEqualToString:colname]) {
            _aggregationCount = [c getInt64:i];
        } else if ([PEX_DBAP_FIELD_SUBSCRIPTION isEqualToString:colname]) {
            _subscription = [c getInt:i];
        } else if ([PEX_DBAP_FIELD_VALID_FROM isEqualToString:colname]) {
            _validFrom = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBAP_FIELD_VALID_TO isEqualToString:colname]) {
            _validTo = [PEXDbModelBase getDateFromCursor:c idx:i];
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
        [cv put:PEX_DBAP_FIELD_ID NSNumberAsLongLong:_id];
    }
    if (_permId != nil)
        [cv put:PEX_DBAP_FIELD_PERM_ID number:_permId];
    if (_licId != nil)
        [cv put:PEX_DBAP_FIELD_LIC_ID number:_licId];
    if (_name != nil)
        [cv put:PEX_DBAP_FIELD_NAME string:_name];
    if (_localView != nil)
        [cv put:PEX_DBAP_FIELD_LOCAL_VIEW number:_localView];
    if (_spent != nil)
        [cv put:PEX_DBAP_FIELD_SPENT number:_spent];
    if (_value != nil)
        [cv put:PEX_DBAP_FIELD_AMOUNT number:_value];
    if (_aref != nil)
        [cv put:PEX_DBAP_FIELD_AREF string:_aref];
    if (_dateCreated != nil)
        [cv put:PEX_DBAP_FIELD_DATE_CREATED date:_dateCreated];
    if (_dateModified != nil)
        [cv put:PEX_DBAP_FIELD_DATE_MODIFIED date:_dateModified];
    if (_actionIdFirst != nil)
        [cv put:PEX_DBAP_FIELD_ACTION_ID_FIRST number:_actionIdFirst];
    if (_actionCtrFirst != nil)
        [cv put:PEX_DBAP_FIELD_ACTION_CTR_FIRST number:_actionCtrFirst];
    if (_actionIdLast != nil)
        [cv put:PEX_DBAP_FIELD_ACTION_ID_LAST number:_actionIdLast];
    if (_actionCtrLast != nil)
        [cv put:PEX_DBAP_FIELD_ACTION_CTR_LAST number:_actionCtrLast];
    if (_aggregationCount != nil)
        [cv put:PEX_DBAP_FIELD_AGGREGATION_COUNT number:_aggregationCount];
    if (_subscription != nil)
        [cv put:PEX_DBAP_FIELD_SUBSCRIPTION number:_subscription];
    if (_validFrom != nil)
        [cv put:PEX_DBAP_FIELD_VALID_FROM date:_validFrom];
    if (_validTo != nil)
        [cv put:PEX_DBAP_FIELD_VALID_TO date:_validTo];

    return cv;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}

+ (instancetype)accountingPermissionWithCursor:(PEXDbCursor *)cursor {
    return [[self alloc] initWithCursor:cursor];
}

- (instancetype)initWithCursor:(PEXDbCursor *)cursor {
    self = [self init];
    if (self) {
        [self createFromCursor:cursor];
    }

    return self;
}

- (BOOL)isDefaultPermission {
    return [@(0) isEqualToNumber:self.licId];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.actionCtrFirst = [coder decodeObjectForKey:@"self.actionCtrFirst"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.permId = [coder decodeObjectForKey:@"self.permId"];
        self.licId = [coder decodeObjectForKey:@"self.licId"];
        self.name = [coder decodeObjectForKey:@"self.name"];
        self.localView = [coder decodeObjectForKey:@"self.localView"];
        self.spent = [coder decodeObjectForKey:@"self.spent"];
        self.value = [coder decodeObjectForKey:@"self.value"];
        self.aref = [coder decodeObjectForKey:@"self.aref"];
        self.dateCreated = [coder decodeObjectForKey:@"self.dateCreated"];
        self.dateModified = [coder decodeObjectForKey:@"self.dateModified"];
        self.actionIdFirst = [coder decodeObjectForKey:@"self.actionIdFirst"];
        self.actionIdLast = [coder decodeObjectForKey:@"self.actionIdLast"];
        self.actionCtrLast = [coder decodeObjectForKey:@"self.actionCtrLast"];
        self.aggregationCount = [coder decodeObjectForKey:@"self.aggregationCount"];
        self.subscription = [coder decodeObjectForKey:@"self.subscription"];
        self.validFrom = [coder decodeObjectForKey:@"self.validFrom"];
        self.validTo = [coder decodeObjectForKey:@"self.validTo"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.actionCtrFirst forKey:@"self.actionCtrFirst"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.permId forKey:@"self.permId"];
    [coder encodeObject:self.licId forKey:@"self.licId"];
    [coder encodeObject:self.name forKey:@"self.name"];
    [coder encodeObject:self.localView forKey:@"self.localView"];
    [coder encodeObject:self.spent forKey:@"self.spent"];
    [coder encodeObject:self.value forKey:@"self.value"];
    [coder encodeObject:self.aref forKey:@"self.aref"];
    [coder encodeObject:self.dateCreated forKey:@"self.dateCreated"];
    [coder encodeObject:self.dateModified forKey:@"self.dateModified"];
    [coder encodeObject:self.actionIdFirst forKey:@"self.actionIdFirst"];
    [coder encodeObject:self.actionIdLast forKey:@"self.actionIdLast"];
    [coder encodeObject:self.actionCtrLast forKey:@"self.actionCtrLast"];
    [coder encodeObject:self.aggregationCount forKey:@"self.aggregationCount"];
    [coder encodeObject:self.subscription forKey:@"self.subscription"];
    [coder encodeObject:self.validFrom forKey:@"self.validFrom"];
    [coder encodeObject:self.validTo forKey:@"self.validTo"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbAccountingPermission *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.actionCtrFirst = self.actionCtrFirst;
        copy.id = self.id;
        copy.permId = self.permId;
        copy.licId = self.licId;
        copy.name = self.name;
        copy.localView = self.localView;
        copy.spent = self.spent;
        copy.value = self.value;
        copy.aref = self.aref;
        copy.dateCreated = self.dateCreated;
        copy.dateModified = self.dateModified;
        copy.actionIdFirst = self.actionIdFirst;
        copy.actionIdLast = self.actionIdLast;
        copy.actionCtrLast = self.actionCtrLast;
        copy.aggregationCount = self.aggregationCount;
        copy.subscription = self.subscription;
        copy.validFrom = self.validFrom;
        copy.validTo = self.validTo;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToPermission:other];
}

- (BOOL)isEqualToPermission:(PEXDbAccountingPermission *)permission {
    if (self == permission)
        return YES;
    if (permission == nil)
        return NO;
    if (self.actionCtrFirst != permission.actionCtrFirst && ![self.actionCtrFirst isEqualToNumber:permission.actionCtrFirst])
        return NO;
    if (self.id != permission.id && ![self.id isEqualToNumber:permission.id])
        return NO;
    if (self.permId != permission.permId && ![self.permId isEqualToNumber:permission.permId])
        return NO;
    if (self.licId != permission.licId && ![self.licId isEqualToNumber:permission.licId])
        return NO;
    if (self.name != permission.name && ![self.name isEqualToString:permission.name])
        return NO;
    if (self.localView != permission.localView && ![self.localView isEqualToNumber:permission.localView])
        return NO;
    if (self.spent != permission.spent && ![self.spent isEqualToNumber:permission.spent])
        return NO;
    if (self.value != permission.value && ![self.value isEqualToNumber:permission.value])
        return NO;
    if (self.aref != permission.aref && ![self.aref isEqualToString:permission.aref])
        return NO;
    if (self.dateCreated != permission.dateCreated && ![self.dateCreated isEqualToDate:permission.dateCreated])
        return NO;
    if (self.dateModified != permission.dateModified && ![self.dateModified isEqualToDate:permission.dateModified])
        return NO;
    if (self.actionIdFirst != permission.actionIdFirst && ![self.actionIdFirst isEqualToNumber:permission.actionIdFirst])
        return NO;
    if (self.actionIdLast != permission.actionIdLast && ![self.actionIdLast isEqualToNumber:permission.actionIdLast])
        return NO;
    if (self.actionCtrLast != permission.actionCtrLast && ![self.actionCtrLast isEqualToNumber:permission.actionCtrLast])
        return NO;
    if (self.aggregationCount != permission.aggregationCount && ![self.aggregationCount isEqualToNumber:permission.aggregationCount])
        return NO;
    if (self.subscription != permission.subscription && ![self.subscription isEqualToNumber:permission.subscription])
        return NO;
    if (self.validFrom != permission.validFrom && ![self.validFrom isEqualToDate:permission.validFrom])
        return NO;
    if (self.validTo != permission.validTo && ![self.validTo isEqualToDate:permission.validTo])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.actionCtrFirst hash];
    hash = hash * 31u + [self.id hash];
    hash = hash * 31u + [self.permId hash];
    hash = hash * 31u + [self.licId hash];
    hash = hash * 31u + [self.name hash];
    hash = hash * 31u + [self.localView hash];
    hash = hash * 31u + [self.spent hash];
    hash = hash * 31u + [self.value hash];
    hash = hash * 31u + [self.aref hash];
    hash = hash * 31u + [self.dateCreated hash];
    hash = hash * 31u + [self.dateModified hash];
    hash = hash * 31u + [self.actionIdFirst hash];
    hash = hash * 31u + [self.actionIdLast hash];
    hash = hash * 31u + [self.actionCtrLast hash];
    hash = hash * 31u + [self.aggregationCount hash];
    hash = hash * 31u + [self.subscription hash];
    hash = hash * 31u + [self.validFrom hash];
    hash = hash * 31u + [self.validTo hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.actionCtrFirst=%@", self.actionCtrFirst];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.permId=%@", self.permId];
    [description appendFormat:@", self.licId=%@", self.licId];
    [description appendFormat:@", self.name=%@", self.name];
    [description appendFormat:@", self.localView=%@", self.localView];
    [description appendFormat:@", self.spent=%@", self.spent];
    [description appendFormat:@", self.value=%@", self.value];
    [description appendFormat:@", self.aref=%@", self.aref];
    [description appendFormat:@", self.dateCreated=%@", self.dateCreated];
    [description appendFormat:@", self.dateModified=%@", self.dateModified];
    [description appendFormat:@", self.actionIdFirst=%@", self.actionIdFirst];
    [description appendFormat:@", self.actionIdLast=%@", self.actionIdLast];
    [description appendFormat:@", self.actionCtrLast=%@", self.actionCtrLast];
    [description appendFormat:@", self.aggregationCount=%@", self.aggregationCount];
    [description appendFormat:@", self.subscription=%@", self.subscription];
    [description appendFormat:@", self.validFrom=%@", self.validFrom];
    [description appendFormat:@", self.validTo=%@", self.validTo];
    [description appendString:@">"];
    return description;
}


@end