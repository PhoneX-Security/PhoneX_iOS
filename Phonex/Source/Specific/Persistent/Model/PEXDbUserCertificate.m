//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbUserCertificate.h"
#import "PEXCryptoUtils.h"
#import "PEXDbUri.h"
#import "PEXUtils.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDbContentProvider.h"

// Naming macro for callers.
#define F(X) PEX_UCRT_##X

NSString * const PEX_UCRT_TABLE = @"certificates";
NSString * const PEX_UCRT_FIELD_ID = @"id";
NSString * const PEX_UCRT_FIELD_OWNER = @"owner";
NSString * const PEX_UCRT_FIELD_CERTIFICATE_STATUS = @"certificateStatus";
NSString * const PEX_UCRT_FIELD_CERTIFICATE = @"certificate";
NSString * const PEX_UCRT_FIELD_CERTIFICATE_HASH = @"certificateHash";
NSString * const PEX_UCRT_FIELD_DATE_LAST_QUERY = @"dateLastQuery";
NSString * const PEX_UCRT_FIELD_DATE_CREATED = @"dateCreated";
NSString * const PEX_UCRT_DATE_FORMAT = @"yyyy-MM-dd HH:mm:ss";
const int64_t PEX_UCRT_INVALID_ID = -1l;

NSInteger const CERTIFICATE_STATUS_OK = 1;
NSInteger const CERTIFICATE_STATUS_INVALID = 2;
NSInteger const CERTIFICATE_STATUS_REVOKED = 3;
NSInteger const CERTIFICATE_STATUS_FORBIDDEN = 4;
NSInteger const CERTIFICATE_STATUS_MISSING = 5;
NSInteger const CERTIFICATE_STATUS_NOUSER = 6;

@implementation PEXDbUserCertificate {

}

+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString * createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@  (         "
                        "        %@ INTEGER PRIMARY KEY AUTOINCREMENT,     "
                        "        %@ TEXT,                                  "
                        "        %@ INTEGER DEFAULT %ld,                   "
                        "        %@ BLOB,                                  "
                        "        %@ TEXT,                                  "
                        "        %@ NUMERIC DEFAULT 0,                     "
                        "        %@ NUMERIC DEFAULT 0,                     "
                        "        UNIQUE(%@)                                "
                        "        );",
                PEX_UCRT_TABLE, PEX_UCRT_FIELD_ID, PEX_UCRT_FIELD_OWNER, PEX_UCRT_FIELD_CERTIFICATE_STATUS, (long) CERTIFICATE_STATUS_MISSING,
                PEX_UCRT_FIELD_CERTIFICATE, PEX_UCRT_FIELD_CERTIFICATE_HASH, PEX_UCRT_FIELD_DATE_LAST_QUERY,
                PEX_UCRT_FIELD_DATE_CREATED,
                PEX_UCRT_FIELD_OWNER];
    });
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[PEX_UCRT_FIELD_ID,
                PEX_UCRT_FIELD_OWNER, PEX_UCRT_FIELD_CERTIFICATE,
                PEX_UCRT_FIELD_CERTIFICATE_HASH, PEX_UCRT_FIELD_DATE_CREATED,
                PEX_UCRT_FIELD_CERTIFICATE_STATUS, PEX_UCRT_FIELD_DATE_LAST_QUERY];
    });
    return fullProjection;
}

+(NSArray *) getNormalProjection {
    static dispatch_once_t once;
    static NSArray * normalProjection;
    dispatch_once(&once, ^{
        normalProjection = @[PEX_UCRT_FIELD_ID,
                PEX_UCRT_FIELD_OWNER, PEX_UCRT_FIELD_CERTIFICATE_HASH,
                PEX_UCRT_FIELD_DATE_CREATED, PEX_UCRT_FIELD_CERTIFICATE_STATUS,
                PEX_UCRT_FIELD_DATE_LAST_QUERY];
    });
    return normalProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:PEX_UCRT_TABLE];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:PEX_UCRT_TABLE isBase:YES];
    });
    return uriBase;
}

- (instancetype)init {
    self = [super init];
    if (self){
        _id = nil;
    }
    return self;
}

- (instancetype)initWithCursor:(PEXDbCursor *)cursor {
    if (self = [super init]) {
        [self createFromCursor:cursor];
    }

    return self;
}

+ (instancetype)certificateWithCursor:(PEXDbCursor *)cursor {
    PEXDbUserCertificate * cert = [[PEXDbUserCertificate alloc] initWithCursor:cursor];
    return cert;
}


/**
* OldSchool method of initialization from cursor
* @param c
*/
-(void) createFromCursor: (PEXDbCursor *) c{
    int colCount = [c getColumnCount];
    for(int i=0; i<colCount; i++){
        NSString * colname = [c getColumnName:i];
        if ([PEX_UCRT_FIELD_ID isEqualToString: colname]){
            _id = [c getInt64:i];
        } else if ([PEX_UCRT_FIELD_OWNER isEqualToString: colname]){
            _owner = [c getString:i];
        } else if ([PEX_UCRT_FIELD_CERTIFICATE_STATUS isEqualToString: colname]){
            _certificateStatus = [c getInt:i];
        } else if ([PEX_UCRT_FIELD_CERTIFICATE isEqualToString: colname]){
            _certificate = [c getBlob:i];
        } else if ([PEX_UCRT_FIELD_CERTIFICATE_HASH isEqualToString: colname]){
            _certificateHash = [c getString:i];
        } else if ([PEX_UCRT_FIELD_DATE_CREATED isEqualToString: colname]){
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([PEX_UCRT_FIELD_DATE_LAST_QUERY isEqualToString: colname]){
            _dateLastQuery = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

- (PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
    if (_id!=nil && [_id longLongValue]!=PEX_UCRT_INVALID_ID){
        [args put:PEX_UCRT_FIELD_ID NSNumberAsLongLong:_id];
    }

    [args put:PEX_UCRT_FIELD_OWNER string:_owner];
    [args put:PEX_UCRT_FIELD_CERTIFICATE_STATUS NSNumberAsInt:_certificateStatus];
    if (_certificate!=nil){
        [args put:PEX_UCRT_FIELD_CERTIFICATE data:_certificate];
    }

    if (_certificateHash!=nil){
        [args put:PEX_UCRT_FIELD_CERTIFICATE_HASH string: _certificateHash];
    }

    if (_dateCreated!=nil){
        [args put:PEX_UCRT_FIELD_DATE_CREATED double: [_dateCreated timeIntervalSince1970]];
    }

    if (_dateLastQuery!=nil){
        [args put:PEX_UCRT_FIELD_DATE_LAST_QUERY double: [_dateLastQuery timeIntervalSince1970]];
    }

    return args;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.id forKey:@"id"];
    [coder encodeObject:self.owner forKey:@"owner"];
    [coder encodeObject:self.certificate forKey:@"certificate"];
    [coder encodeObject:self.certificateHash forKey:@"certificateHash"];
    [coder encodeObject:self.dateCreated forKey:@"dateCreated"];
    [coder encodeObject:self.certificateStatus forKey:@"certificateStatus"];
    [coder encodeObject:self.dateLastQuery forKey:@"dateLastQuery"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.id = [decoder decodeObjectForKey:@"id"];
    self.owner = [decoder decodeObjectForKey:@"owner"];
    self.certificate = [decoder decodeObjectForKey:@"certificate"];
    self.certificateHash = [decoder decodeObjectForKey:@"certificateHash"];
    self.dateCreated = [decoder decodeObjectForKey:@"dateCreated"];
    self.certificateStatus = [decoder decodeObjectForKey:@"certificateStatus"];
    self.dateLastQuery = [decoder decodeObjectForKey:@"dateLastQuery"];
    return self;
}

- (PEXX509 *)getCertificateObj {
    if (_certificate==nil || _certificate.length==0){
        return nil;
    }


    X509 * crt = [PEXCryptoUtils importCertificateFromDER:_certificate];
    if (crt==nil){
        return nil;
    }

    return [[PEXX509 alloc] initWith:crt];
}

/**
* Tries to parse stored byte representation of the certificate and returns whether
* it is valid X509 certificate or not.
*
* @return
*/
- (BOOL) isValidCertObj {
    if (_certificate==nil || _certificate.length==0){
        return NO;
    }

    @try {
        [self getCertificateObj];
        return true;
    } @catch (NSException * e) {
        return false;
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.id=%@", self.id];
    [description appendFormat:@", self.owner=%@", self.owner];
    [description appendFormat:@", self.certificate=%@", self.certificate];
    [description appendFormat:@", self.certificateHash=%@", self.certificateHash];
    [description appendFormat:@", self.dateCreated=%@", self.dateCreated];
    [description appendFormat:@", self.certificateStatus=%@", self.certificateStatus];
    [description appendFormat:@", self.dateLastQuery=%@", self.dateLastQuery];
    [description appendString:@">"];
    return description;
}

//public void setCertificateStatus(CertificateStatus status) {
//    switch(status){
//        case FORBIDDEN:
//            this.certificateStatus = CERTIFICATE_STATUS_FORBIDDEN;
//            break;
//        case MISSING:
//            this.certificateStatus = CERTIFICATE_STATUS_MISSING;
//            break;
//        case NOUSER:
//            this.certificateStatus = CERTIFICATE_STATUS_NOUSER;
//            break;
//        case OK:
//            this.certificateStatus = CERTIFICATE_STATUS_OK;
//            break;
//        case REVOKED:
//            this.certificateStatus = CERTIFICATE_STATUS_REVOKED;
//            break;
//        case INVALID:
//        default:
//            this.certificateStatus = CERTIFICATE_STATUS_INVALID;
//            break;
//    }
//}
//
//public static String getCertificateErrorString(int status, Context ctxt){
//    switch(status){
//        case CERTIFICATE_STATUS_OK:
//            return ctxt.getString(R.string.cert_status_ok);
//        case CERTIFICATE_STATUS_INVALID:
//            return ctxt.getString(R.string.cert_status_invalid);
//        case CERTIFICATE_STATUS_REVOKED:
//            return ctxt.getString(R.string.cert_status_revoked);
//        case CERTIFICATE_STATUS_FORBIDDEN:
//            return ctxt.getString(R.string.cert_status_forbidden);
//        case CERTIFICATE_STATUS_MISSING:
//            return ctxt.getString(R.string.cert_status_missing);
//        case CERTIFICATE_STATUS_NOUSER:
//            return ctxt.getString(R.string.cert_status_nouser);
//    }
//
//    return ctxt.getString(R.string.cert_status_missing);
//}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbUserCertificate *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.id = self.id;
        copy.owner = self.owner;
        copy.certificate = self.certificate;
        copy.certificateHash = self.certificateHash;
        copy.dateCreated = self.dateCreated;
        copy.certificateStatus = self.certificateStatus;
        copy.dateLastQuery = self.dateLastQuery;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToCertificate:other];
}

- (BOOL)isEqualToCertificate:(PEXDbUserCertificate *)certificate {
    if (self == certificate)
        return YES;
    if (certificate == nil)
        return NO;
    if (self.id != certificate.id && ![self.id isEqualToNumber:certificate.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

+(PEXDbUserCertificate *) newCertificateForUser: (NSString *) user cr: (PEXDbContentProvider *) cr projection: (NSArray *) projection {
    @try {
        NSString * selection = [NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER];

        PEXDbCursor * c = [cr query:[self getURI]
                         projection:projection == nil ? [self getFullProjection]  : projection
                          selection:selection
                      selectionArgs:@[user]
                          sortOrder:nil];
        if (c == nil){
            return nil;
        }

        PEXDbUserCertificate * cert = nil;
        if ([c moveToFirst]){
            cert = [PEXDbUserCertificate certificateWithCursor:c];
        }

        [PEXUtils closeSilentlyCursor:c];
        return cert;

    } @catch(NSException * e){
        DDLogError(@"Exception during loading stored certificate for: %@, exception=%@", user, e);
        return nil;
    }
}

+(NSDictionary *) loadCertificatesForUsers: (NSArray *) user cr: (PEXDbContentProvider *) cr projection: (NSArray *) projection{
    @try {
        // TODO: do chunking if list is too long.
        if (user == nil || user.count == 0){
            return @{};
        }

        NSMutableDictionary * ret = [[NSMutableDictionary alloc] initWithCapacity:user.count];
        NSString * selection = [NSString stringWithFormat:@"WHERE %@ IN (%@)",
                        PEX_UCRT_FIELD_OWNER,
                        [PEXUtils generateDbPlaceholders:user.count]];

        PEXDbCursor * c = [cr query:[self getURI]
                         projection:projection == nil ? [self getFullProjection] : projection
                          selection:selection
                      selectionArgs:user
                          sortOrder:nil];
        if (c == nil){
            return ret;
        }

        for(; [c moveToNext]; ){
            PEXDbUserCertificate * cert = [PEXDbUserCertificate certificateWithCursor:c];
            if (cert == nil){
                continue;
            }

            ret[cert.owner] = cert;
        }

        [PEXUtils closeSilentlyCursor:c];
        return ret;

    } @catch(NSException * e){
        DDLogError(@"Exception during loading stored certificates for: %@, exception=%@", user, e);
        return nil;
    }
}

+ (void)updateCertificateStatus:(NSNumber *)status owner:(NSString *)owner cr:(PEXDbContentProvider *)cr {
    PEXDbContentValues * dataToInsert = [[PEXDbContentValues alloc] init];
    [dataToInsert put:PEX_UCRT_FIELD_DATE_LAST_QUERY date: [NSDate date]];
    [dataToInsert put:PEX_UCRT_FIELD_CERTIFICATE_STATUS integer: [status integerValue]];
    NSString * where = [NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER];
    [     cr update:[PEXDbUserCertificate getURI]
      ContentValues:dataToInsert
          selection:where
      selectionArgs:@[owner]];
}

+ (int) deleteCertificateForUser:(NSString *)owner cr:(PEXDbContentProvider *)cr {
    return [cr  delete:[PEXDbUserCertificate getURI]
             selection:[NSString stringWithFormat:@"WHERE %@=?", PEX_UCRT_FIELD_OWNER]
         selectionArgs:@[owner]];
}

+ (int)deleteCertificateForUser:(NSString *)owner cr:(PEXDbContentProvider *)cr error:(NSError **)pError {
    int deleteResult = 0;
    @try {
        deleteResult = [PEXDbUserCertificate deleteCertificateForUser:owner cr:cr];
    } @catch(NSException * e){
        DDLogError(@"Exception during removing invalid certificate for: %@, exception=%@", owner, e);
        if (pError != nil){
            *pError = [[NSError alloc] init];
        }
    }

    return deleteResult;
}

+ (int)insertUnique:(NSString *)owner cr:(PEXDbContentProvider *)cr cv:(const PEXDbContentValues *const)contentValues {
    @try {
        [self deleteCertificateForUser:owner cr:cr];
        [cr insert:[self getURI] contentValues:contentValues];
    } @catch(NSException * e){
        DDLogError(@"Exception during inserting a new certificate. Exception: %@", e);
    }
    return 0;
}

@end