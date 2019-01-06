//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbDhKey.h"
#import "PEXDbContentProvider.h"
#import "PEXStringUtils.h"
#import "PEXUtils.h"

NSString * PEX_DBDH_TABLE = @"dh_offline";
NSString * PEX_DBDH_FIELD_ID = @"_id";
NSString * PEX_DBDH_FIELD_SIP = @"sip";
NSString * PEX_DBDH_FIELD_PUBLIC_KEY = @"publicKey";
NSString * PEX_DBDH_FIELD_PRIVATE_KEY = @"privateKey";
NSString * PEX_DBDH_FIELD_GROUP_NUMBER = @"groupNumber";
NSString * PEX_DBDH_FIELD_DATE_CREATED = @"dateCreated";
NSString * PEX_DBDH_FIELD_DATE_EXPIRE = @"dateExpire";
NSString * PEX_DBDH_FIELD_NONCE1 = @"nonce1";
NSString * PEX_DBDH_FIELD_NONCE2 = @"nonce2";
NSString * PEX_DBDH_FIELD_ACERT_HASH = @"aCertHash";

@implementation PEXDbDhKey {

}

+(NSString *) getCreateTable {
    NSString *createTable = [[NSString alloc] initWithFormat:
            @"CREATE TABLE IF NOT EXISTS %@ ("
                    "  %@  INTEGER PRIMARY KEY AUTOINCREMENT, "//  				 PEX_DBDH_FIELD_ID
                    "  %@  TEXT, "//  				 PEX_DBDH_FIELD_SIP
                    "  %@  TEXT, "//  				 PEX_DBDH_FIELD_PUBLIC_KEY
                    "  %@  TEXT, "//  				 PEX_DBDH_FIELD_PRIVATE_KEY
                    "  %@  INTEGER, "//  		     PEX_DBDH_FIELD_GROUP_NUMBER
                    "  %@  NUMERIC, "//  			 PEX_DBDH_FIELD_DATE_CREATED
                    "  %@  NUMERIC, "//  			 PEX_DBDH_FIELD_DATE_EXPIRE
                    "  %@  TEXT, "//  				 PEX_DBDH_FIELD_NONCE1
                    "  %@  TEXT, "//  				 PEX_DBDH_FIELD_NONCE2
                    "  %@  TEXT "//  				 PEX_DBDH_FIELD_ACERT_HASH
                    " );",
                    PEX_DBDH_TABLE,
                    PEX_DBDH_FIELD_ID,
                    PEX_DBDH_FIELD_SIP,
                    PEX_DBDH_FIELD_PUBLIC_KEY,
                    PEX_DBDH_FIELD_PRIVATE_KEY,
                    PEX_DBDH_FIELD_GROUP_NUMBER,
                    PEX_DBDH_FIELD_DATE_CREATED,
                    PEX_DBDH_FIELD_DATE_EXPIRE,
                    PEX_DBDH_FIELD_NONCE1,
                    PEX_DBDH_FIELD_NONCE2,
                    PEX_DBDH_FIELD_ACERT_HASH];
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[PEX_DBDH_FIELD_ID,
                PEX_DBDH_FIELD_SIP,
                PEX_DBDH_FIELD_PUBLIC_KEY,
                PEX_DBDH_FIELD_PRIVATE_KEY,
                PEX_DBDH_FIELD_GROUP_NUMBER,
                PEX_DBDH_FIELD_DATE_CREATED,
                PEX_DBDH_FIELD_DATE_EXPIRE,
                PEX_DBDH_FIELD_NONCE1,
                PEX_DBDH_FIELD_NONCE2,
                PEX_DBDH_FIELD_ACERT_HASH
        ];
    });
    return fullProjection;
}

+(NSArray *) getLightProjection {
    static dispatch_once_t once;
    static NSArray * ackProjection;
    dispatch_once(&once, ^{
        ackProjection = @[PEX_DBDH_FIELD_ID,
                PEX_DBDH_FIELD_SIP,
                PEX_DBDH_FIELD_DATE_CREATED,
                PEX_DBDH_FIELD_DATE_EXPIRE,
                PEX_DBDH_FIELD_NONCE1,
                PEX_DBDH_FIELD_NONCE2,
                PEX_DBDH_FIELD_ACERT_HASH
        ];
    });
    return ackProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_DBDH_TABLE];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_DBDH_TABLE isBase:YES];
    });
    return uriBase;
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
        if ([PEX_DBDH_FIELD_ID isEqualToString: colname]){
            _id = [c getInt64: i];
        } else if ([PEX_DBDH_FIELD_SIP isEqualToString: colname]){
            _sip = [c getString:i];
        } else if ([PEX_DBDH_FIELD_PUBLIC_KEY isEqualToString: colname]){
            _publicKey = [c getString:i];
        } else if ([PEX_DBDH_FIELD_PRIVATE_KEY isEqualToString: colname]){
            _privateKey = [c getString:i];
        } else if ([PEX_DBDH_FIELD_GROUP_NUMBER isEqualToString: colname]){
            _groupNumber = [c getInt:i];
        } else if ([PEX_DBDH_FIELD_DATE_CREATED isEqualToString: colname]){
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBDH_FIELD_DATE_EXPIRE isEqualToString: colname]){
            _dateExpire = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_DBDH_FIELD_NONCE1 isEqualToString: colname]){
            _nonce1 = [c getString:i];
        } else if ([PEX_DBDH_FIELD_NONCE2 isEqualToString: colname]){
            _nonce2 = [c getString:i];
        } else if ([PEX_DBDH_FIELD_ACERT_HASH isEqualToString: colname]){
            _aCertHash = [c getString:i];
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
-(PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * cv = [[PEXDbContentValues alloc] init];
    if (_id!=nil && [_id longLongValue] != -1l) {
        [cv put:PEX_DBDH_FIELD_ID NSNumberAsLongLong:_id];
    }

    [cv put:PEX_DBDH_FIELD_SIP string: self.sip];
    if (_publicKey != nil)
        [cv put:PEX_DBDH_FIELD_PUBLIC_KEY string: _publicKey];
    if (_privateKey != nil)
        [cv put:PEX_DBDH_FIELD_PRIVATE_KEY string: _privateKey];
    if (_groupNumber != nil)
        [cv put:PEX_DBDH_FIELD_GROUP_NUMBER NSNumberAsInt: _groupNumber];
    if (_dateCreated != nil)
        [cv put:PEX_DBDH_FIELD_DATE_CREATED date: _dateCreated];
    if (_dateExpire != nil)
        [cv put:PEX_DBDH_FIELD_DATE_EXPIRE date: _dateExpire];
    if (_nonce1 != nil)
        [cv put:PEX_DBDH_FIELD_NONCE1 string: _nonce1];
    if (_nonce2 != nil)
        [cv put:PEX_DBDH_FIELD_NONCE2 string: _nonce2];
    if (_aCertHash != nil)
        [cv put:PEX_DBDH_FIELD_ACERT_HASH string: _aCertHash];
    return cv;
}

- (instancetype)initWithCursor: (PEXDbCursor *) c{
    self = [super init];
    if (self) {
        [self createFromCursor:c];
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.id=%@", self.id];
    [description appendFormat:@", self.sip=%@", self.sip];
    [description appendFormat:@", self.publicKey=%@", self.publicKey];
    [description appendFormat:@", self.privateKey=%@", self.privateKey];
    [description appendFormat:@", self.groupNumber=%@", self.groupNumber];
    [description appendFormat:@", self.dateCreated=%@", self.dateCreated];
    [description appendFormat:@", self.dateExpire=%@", self.dateExpire];
    [description appendFormat:@", self.nonce1=%@", self.nonce1];
    [description appendFormat:@", self.nonce2=%@", self.nonce2];
    [description appendFormat:@", self.aCertHash=%@", self.aCertHash];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.sip = [coder decodeObjectForKey:@"self.sip"];
        self.publicKey = [coder decodeObjectForKey:@"self.publicKey"];
        self.privateKey = [coder decodeObjectForKey:@"self.privateKey"];
        self.groupNumber = [coder decodeObjectForKey:@"self.groupNumber"];
        self.dateCreated = [coder decodeObjectForKey:@"self.dateCreated"];
        self.dateExpire = [coder decodeObjectForKey:@"self.dateExpire"];
        self.nonce1 = [coder decodeObjectForKey:@"self.nonce1"];
        self.nonce2 = [coder decodeObjectForKey:@"self.nonce2"];
        self.aCertHash = [coder decodeObjectForKey:@"self.aCertHash"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.sip forKey:@"self.sip"];
    [coder encodeObject:self.publicKey forKey:@"self.publicKey"];
    [coder encodeObject:self.privateKey forKey:@"self.privateKey"];
    [coder encodeObject:self.groupNumber forKey:@"self.groupNumber"];
    [coder encodeObject:self.dateCreated forKey:@"self.dateCreated"];
    [coder encodeObject:self.dateExpire forKey:@"self.dateExpire"];
    [coder encodeObject:self.nonce1 forKey:@"self.nonce1"];
    [coder encodeObject:self.nonce2 forKey:@"self.nonce2"];
    [coder encodeObject:self.aCertHash forKey:@"self.aCertHash"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbDhKey *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.id = self.id;
        copy.sip = self.sip;
        copy.publicKey = self.publicKey;
        copy.privateKey = self.privateKey;
        copy.groupNumber = self.groupNumber;
        copy.dateCreated = self.dateCreated;
        copy.dateExpire = self.dateExpire;
        copy.nonce1 = self.nonce1;
        copy.nonce2 = self.nonce2;
        copy.aCertHash = self.aCertHash;
    }

    return copy;
}


/**
* Looks up the DH key with given nonce2.
*
* @param cr
* @param nonce2
* @return
*/
+(instancetype) getByNonce2: (NSString *) nonce2 cr: (PEXDbContentProvider *) cr {
    if ([PEXStringUtils isEmpty:nonce2]){
        DDLogWarn(@"Nonce2 is nil / empty");
        return nil;
    }

    PEXDbCursor * c = [cr query:[self getURI]
                     projection:[self getFullProjection]
                      selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_NONCE2]
                  selectionArgs:@[nonce2]
                      sortOrder:nil];

    if (c == nil){
        return nil;
    }

    @try {
        if ([c moveToFirst]){
            return [[self alloc] initWithCursor:c];
        }
    } @catch (NSException * e) {
        DDLogError(@"Error while getting DHOffline item, exception=%@", e);
        return nil;
    } @finally {
        [PEXUtils closeSilentlyCursor:c];
    }

    return nil;
}

/**
* Deletes key corresponding to the given user with given nonce from database.
*
* @param cr
* @param nonce2
* @param user
*/
+(int) delete: (NSString *) nonce2 user: (NSString *) user cr: (PEXDbContentProvider *) cr{
    if (nonce2 == nil || user == nil){
        DDLogWarn(@"User/nonce2 is nil");
        return -1;
    }

    @try {
        return [cr delete:[self getURI]
                selection:[NSString stringWithFormat:@"WHERE %@=? AND %@=?", PEX_DBDH_FIELD_NONCE2, PEX_DBDH_FIELD_SIP]
            selectionArgs:@[nonce2, user]];
    } @catch(NSException * e){
        DDLogError(@"Cannot delete key, exception=%@", e);
    }

    return -1;
}

/**
* Returns list of a nonce2s for ready DH keys. If
* sip is not null, for a given user, otherwise for
* everybody.
*
* @param sip OPTIONAL
* @return
*/
+(NSArray *) getReadyDHKeysNonce2: (NSString *) sip cr: (PEXDbContentProvider *) cr {
    NSMutableArray * nonceList = [[NSMutableArray alloc] init];

    @try {
        // Search criteria = nonce2 (and optionally SIP).
        NSString * selection = [NSString stringWithFormat:@"WHERE 1"];
        NSArray * selectionArgs = @[];
        if (![PEXStringUtils isEmpty:sip]){
            selection = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_SIP];
            selectionArgs = @[sip];
        }

        PEXDbCursor * c = [cr query:[self getURI]
                         projection:[self getLightProjection]
                          selection:selection
                      selectionArgs:selectionArgs
                          sortOrder:nil];
        if (c == nil){
            return nonceList;
        }

        while([c moveToNext]){
            PEXDbDhKey * dhKey = [[PEXDbDhKey alloc] initWithCursor:c];
            if (dhKey.nonce2 == nil){
                DDLogError(@"Pathological entry: %@", dhKey);

                if (dhKey.id != nil) {
                    DDLogVerbose(@"Going to remove pathological entry with id=%@", dhKey.id);
                    [self removeDHKeyById:[dhKey.id longLongValue] cr:cr];
                }

                continue;
            }

            [nonceList addObject:dhKey.nonce2];
        }

        [PEXUtils closeSilentlyCursor:c];
        return nonceList;

    } @catch(NSException * e){
        DDLogError(@"Exception during loading DHKey nonce2sip: %@, exception=%@", sip, e);
        return nonceList;
    }
}

/**
* Loads specific DHkey from the database.
* Sip can be null, in that case only nonce2 is used for search.
*
* @param nonce2
* @param sip
* @return
*/
+(instancetype) loadDHKey: (NSString *) nonce2 sip: (NSString *) sip cr: (PEXDbContentProvider *) cr {
    if ([PEXStringUtils isEmpty:nonce2] && [PEXStringUtils isEmpty:sip]){
        DDLogWarn(@"Both nonce2 and sip is empty");
        return nil;
    }

    @try {
        // Search criteria = nonce2 (and optionally SIP).
        NSString * selection = nil;
        NSArray * selectionArgs = nil;
        if (![PEXStringUtils isEmpty:sip]){
            selection = [NSString stringWithFormat:@"WHERE %@=? AND %@=?", PEX_DBDH_FIELD_NONCE2, PEX_DBDH_FIELD_SIP];
            selectionArgs = @[nonce2, sip];
        } else {
            selection = [NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_NONCE2];
            selectionArgs = @[nonce2];
        }

        PEXDbCursor * c = [cr query:[self getURI]
                         projection:[self getFullProjection]
                          selection:selection
                      selectionArgs:selectionArgs
                          sortOrder:nil];

        if (c == nil){
            return nil;
        }

        if ([c getCount] > 0 && [c moveToFirst]){
            PEXDbDhKey * dh = [[PEXDbDhKey alloc] initWithCursor:c];
            [PEXUtils closeSilentlyCursor:c];
            return dh;

        } else {
            [PEXUtils closeSilentlyCursor:c];
        }

        return nil;
    } @catch(NSException * e){
        DDLogError(@"Exception during loading DHKey nonce2: %@, exception=%@", nonce2, e);
        return nil;
    }
}

+(int) removeDHKeysForUser: (NSString *) sip cr: (PEXDbContentProvider *) cr {
    if ([PEXStringUtils isEmpty:sip]){
        DDLogWarn(@"Empty sip");
        return 0;
    }

    @try {
        int d = [cr delete:[self getURI]
                 selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_SIP]
             selectionArgs:@[sip]];

        return d;
    } @catch(NSException * e){
        DDLogError(@"Exception during removing DHKeys for user: %@, exception=%@", sip, e);
        return 0;
    }
}

/**
* Removes a DHKey with given nonce2
*
* @param sip
* @return
*/
+(BOOL) removeDHKey: (NSString *) nonce2 cr: (PEXDbContentProvider *) cr{
    if ([PEXStringUtils isEmpty:nonce2]){
        return NO;
    }

    @try {
        return [cr delete:[self getURI]
                selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_NONCE2]
            selectionArgs:@[nonce2]] > 0;

    } @catch(NSException * e){
        DDLogError(@"Exception during removing DHKey with nonce2: %@, exception=%@", nonce2, e);
        return NO;
    }
}

+(BOOL) removeDHKeyById: (int64_t) id cr: (PEXDbContentProvider *) cr{
    @try {
        return [cr delete:[self getURI]
                selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_ID]
            selectionArgs:@[[@(id) stringValue]]] > 0;

    } @catch(NSException * e){
        DDLogError(@"Exception during removing DHKey with id: %lld, exception=%@", id, e);
        return NO;
    }
}


+(int) removeDHKeys: (NSArray *) nonces cr: (PEXDbContentProvider *) cr {
    int d = 0;
    if ([PEXUtils isEmptyArr:nonces]){
        return 0;
    }

    NSUInteger nCount = [nonces count];
    @try {
        NSString * selection = [NSString stringWithFormat:@"WHERE %@ IN (%@)", PEX_DBDH_FIELD_NONCE2, [PEXUtils generateDbPlaceholders:(int)nCount]];
        d = [cr delete:[self getURI] selection:selection selectionArgs:nonces];
        return d;
    } @catch(NSException * e){
        DDLogError(@"Exception during removing DHKey, exception=%@", e);
        return 0;
    }
}

/**
* Removes DH keys that are either a) older than given date
* OR b) does not have given certificate hash OR both OR just
* equals the sip.
*
* Returns number of removed entries.
*
* @param sip
* @param olderThan
* @param certHash
* @param expirationLimit
* @return
*/
+(int) removeDHKeys: (NSString *) sip olderThan: (NSDate *) olderThan certHash: (NSString *) certHash
    expirationLimit: (NSDate *) expirationLimit cr: (PEXDbContentProvider *) cr {
    int removed = 0;

    if (sip == nil){
        DDLogWarn(@"SIP is nil");
        return removed;
    }

    @try {
        NSMutableArray * args = [[NSMutableArray alloc] init];
        NSMutableString * selection = [NSMutableString stringWithFormat:@"WHERE %@=?", PEX_DBDH_FIELD_SIP];
        [args addObject:sip];

        if (olderThan != nil && certHash != nil){
            [selection appendFormat:@" AND (((%@ < ?) OR (%@ != ?))", PEX_DBDH_FIELD_DATE_CREATED, PEX_DBDH_FIELD_ACERT_HASH];
            [args addObject:[NSString stringWithFormat:@"%f", [olderThan timeIntervalSince1970]]];
            [args addObject:certHash];

        } else if (olderThan != nil){
            [selection appendFormat:@" AND ((%@ < ?)", PEX_DBDH_FIELD_DATE_CREATED];
            [args addObject:[NSString stringWithFormat:@"%f", [olderThan timeIntervalSince1970]]];

        } else if (certHash != nil){
            [selection appendFormat:@" AND ((%@ != ?)", PEX_DBDH_FIELD_ACERT_HASH];
            [args addObject:certHash];

        } else if (expirationLimit != nil){
            [selection appendFormat:@" AND ( 1 "];
        }

        // Expiration
        if (expirationLimit != nil){
            [selection appendFormat:@" OR %@ < ? )", PEX_DBDH_FIELD_DATE_EXPIRE] ;
            [args addObject:[NSString stringWithFormat:@"%f", [expirationLimit timeIntervalSince1970]]];
        } else {
            // Closing the brace for AND condition
            [selection appendFormat:@" ) "];
        }

        removed = [cr delete:[self getURI]
                   selection:selection
               selectionArgs:args];

        return removed;
    } @catch(NSException * e){
        DDLogError(@"Exception during removing DHKey olderThan=%@; and certHash=%@, exception=%@", olderThan, certHash, e);
        return removed;
    }
}

@end