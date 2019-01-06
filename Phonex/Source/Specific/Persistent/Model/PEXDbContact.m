//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbContact.h"
#import "PEXDbUri.h"
#import "PEXUtils.h"
#import "PEXDbContentProvider.h"
#import "PEXUri.h"
#import "PEXStringUtils.h"
#import "PEXRegex.h"
#import "PEXPbPush.pb.h"

NSString * const DBCL(TABLE) = @"clist";
NSString * const DBCL(STATUS_TABLE) = @"clist_status";

NSString * const DBCL(FIELD_ID) = @"_id";
NSString * const DBCL(FIELD_ACCOUNT) = @"account";
NSString * const DBCL(FIELD_SIP) = @"sip";
NSString * const DBCL(FIELD_DISPLAY_NAME) = @"name";
NSString * const DBCL(FIELD_CERTIFICATE) = @"certificate";
NSString * const DBCL(FIELD_CERTIFICATE_HASH) = @"certificateHash";
NSString * const DBCL(FIELD_IN_WHITELIST) = @"inWhitelist";
NSString * const DBCL(FIELD_DATE_CREATED) = @"dateCreated";
NSString * const DBCL(FIELD_DATE_LAST_CHANGE) = @"dateLastChange";
NSString * const DBCL(FIELD_PRESENCE_ONLINE) = @"presenceOnline";
NSString * const DBCL(FIELD_PRESENCE_STATUS) = @"presenceStatus";
NSString * const DBCL(FIELD_PRESENCE_LAST_UPDATE) = @"presenceLastUpdate";
NSString * const DBCL(FIELD_PRESENCE_STATUS_TYPE) = @"presenceStatusType";
NSString * const DBCL(FIELD_PRESENCE_STATUS_TEXT) = @"presenceStatusText";
NSString * const DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX) = @"presenceCertHashPrefix";
NSString * const DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE) = @"presenceCertNotBefore";
NSString * const DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE) = @"presenceLastCertUpdate";
NSString * const DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE) = @"presenceNumCertUpdate";
NSString * const DBCL(FIELD_PRESENCE_DOS_CERT_UPDATE) = @"presenceDosCertUpdate";
NSString * const DBCL(FIELD_UNREAD_MESSAGES) = @"unreadMessages";
NSString * const DBCL(FIELD_HIDE_CONTACT) = @"hideContact";
NSString * const DBCL(FIELD_LAST_ACTIVE) = @"lastActive";
NSString * const DBCL(FIELD_LAST_TYPING) = @"lastTyping";
NSString * const DBCL(FIELD_CAPABILITIES) = @"capabilities";

NSString * const DBCL(DATE_FORMAT) = @"yyyy-MM-dd HH:mm:ss";
const int64_t DBCL(INVALID_ID) = -1;

@implementation PEXDbContact {

}

+ (NSString *) usernameWithoutDomain: (NSString * const) username
{
    NSRange range = [username rangeOfString:@"@"];
    return (range.location != NSNotFound) ?
            [username substringToIndex:range.location] :
            username;
}

+(NSString *) getCreateTable {
    static dispatch_once_t once;
    static NSString * createTable;
    dispatch_once(&once, ^{
        createTable = [[NSString alloc] initWithFormat:
                @"CREATE TABLE IF NOT EXISTS %@ ("
                        "%@ INTEGER PRIMARY KEY AUTOINCREMENT, " // FIELD_ID
                        "%@       INTEGER, "            // FIELD_ACCOUNT
                        "%@       TEXT, "               // FIELD_SIP
                        "%@       TEXT, "               // FIELD_DISPLAY_NAME
                        "%@       INTEGER, "            // FIELD_IN_WHITELIST
                        "%@       BLOB, "               // FIELD_CERTIFICATE
                        "%@       TEXT, "               // FIELD_CERTIFICATE_HASH
                        "%@       NUMERIC, "            // FIELD_DATE_CREATED
                        "%@       NUMERIC, "            // FIELD_DATE_LAST_CHANGE
                        "%@       INTEGER, "            // FIELD_PRESENCE_ONLINE
                        "%@       TEXT, "               // FIELD_PRESENCE_STATUS
                        "%@       NUMERIC, "            // FIELD_PRESENCE_LAST_UPDATE
                        "%@       INTEGER DEFAULT 0 , " // FIELD_PRESENCE_STATUS_TYPE
                        "%@       TEXT, "               // FIELD_PRESENCE_STATUS_TEXT
                        "%@       TEXT, "               // FIELD_PRESENCE_CERT_HASH_PREFIX
                        "%@       NUMERIC DEFAULT 0, "  // FIELD_PRESENCE_CERT_NOT_BEFORE
                        "%@       NUMERIC DEFAULT 0, "  // FIELD_PRESENCE_LAST_CERT_UPDATE
                        "%@       INTEGER DEFAULT 0, "  // FIELD_PRESENCE_NUM_CERT_UPDATE
                        "%@       TEXT, "               // FIELD_PRESENCE_DOS_CERT_UPDATE
                        "%@       INTEGER DEFAULT 0, "  // FIELD_HIDE_CONTACT
                        "%@       NUMERIC DEFAULT 0, "  // FIELD_LAST_ACTIVE
                        "%@       NUMERIC DEFAULT 0, "  // FIELD_LAST_TYPING
                        "%@       TEXT "                // FIELD_CAPABILITIES
                        ");",   DBCL(TABLE),
                        DBCL(FIELD_ID),
                        DBCL(FIELD_ACCOUNT),
                        DBCL(FIELD_SIP),
                        DBCL(FIELD_DISPLAY_NAME),
                        DBCL(FIELD_IN_WHITELIST),
                        DBCL(FIELD_CERTIFICATE),
                        DBCL(FIELD_CERTIFICATE_HASH),
                        DBCL(FIELD_DATE_CREATED),
                        DBCL(FIELD_DATE_LAST_CHANGE),
                        DBCL(FIELD_PRESENCE_ONLINE),
                        DBCL(FIELD_PRESENCE_STATUS),
                        DBCL(FIELD_PRESENCE_LAST_UPDATE),
                        DBCL(FIELD_PRESENCE_STATUS_TYPE),
                        DBCL(FIELD_PRESENCE_STATUS_TEXT),
                        DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX),
                        DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE),
                        DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE),
                        DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE),
                        DBCL(FIELD_PRESENCE_DOS_CERT_UPDATE),
                        DBCL(FIELD_HIDE_CONTACT),
                        DBCL(FIELD_LAST_ACTIVE),
                        DBCL(FIELD_LAST_TYPING),
                        DBCL(FIELD_CAPABILITIES)];
    });
    return createTable;
}

+(NSArray *) getFullProjection {
    static dispatch_once_t once;
    static NSArray * fullProjection;
    dispatch_once(&once, ^{
        fullProjection = @[
                DBCL(FIELD_ID),
                DBCL(FIELD_ACCOUNT),
                DBCL(FIELD_SIP),
                DBCL(FIELD_DISPLAY_NAME),
                DBCL(FIELD_CERTIFICATE),
                DBCL(FIELD_CERTIFICATE_HASH),
                DBCL(FIELD_IN_WHITELIST),
                DBCL(FIELD_DATE_CREATED),
                DBCL(FIELD_DATE_LAST_CHANGE),
                DBCL(FIELD_PRESENCE_ONLINE),
                DBCL(FIELD_PRESENCE_STATUS),
                DBCL(FIELD_PRESENCE_LAST_UPDATE),
                DBCL(FIELD_PRESENCE_STATUS_TYPE),
                DBCL(FIELD_PRESENCE_STATUS_TEXT),
                DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX),
                DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE),
                DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE),
                DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE),
                DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE),
                DBCL(FIELD_HIDE_CONTACT),
                DBCL(FIELD_LAST_ACTIVE),
                DBCL(FIELD_LAST_TYPING),
                DBCL(FIELD_CAPABILITIES)];
    });
    return fullProjection;
}

+(NSArray *) getNormalProjection {
    static dispatch_once_t once;
    static NSArray * normalProjection;
    dispatch_once(&once, ^{
        normalProjection = @[
                DBCL(FIELD_ID),
                DBCL(FIELD_ACCOUNT),
                DBCL(FIELD_SIP),
                DBCL(FIELD_DISPLAY_NAME),
                DBCL(FIELD_CERTIFICATE_HASH),
                DBCL(FIELD_IN_WHITELIST),
                DBCL(FIELD_DATE_CREATED),
                DBCL(FIELD_DATE_LAST_CHANGE),
                DBCL(FIELD_PRESENCE_ONLINE),
                DBCL(FIELD_PRESENCE_STATUS),
                DBCL(FIELD_PRESENCE_LAST_UPDATE),
                DBCL(FIELD_PRESENCE_STATUS_TYPE),
                DBCL(FIELD_PRESENCE_STATUS_TEXT),
                DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX),
                DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE),
                DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE),
                DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE),
                DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE),
                DBCL(FIELD_HIDE_CONTACT),
                DBCL(FIELD_LAST_ACTIVE),
                DBCL(FIELD_LAST_TYPING)];
    });
    return normalProjection;
}

+(NSArray *) getLightProjection {
    static dispatch_once_t once;
    static NSArray * lightProjection;
    dispatch_once(&once, ^{
        lightProjection = @[
                DBCL(FIELD_ID),
                DBCL(FIELD_ACCOUNT),
                DBCL(FIELD_SIP),
                DBCL(FIELD_DISPLAY_NAME),
                DBCL(FIELD_PRESENCE_ONLINE),
                DBCL(FIELD_PRESENCE_STATUS),
                DBCL(FIELD_PRESENCE_STATUS_TEXT),
                DBCL(FIELD_PRESENCE_STATUS_TYPE),
                DBCL(FIELD_HIDE_CONTACT),
                DBCL(FIELD_LAST_ACTIVE),
                DBCL(FIELD_LAST_TYPING),];
    });
    return lightProjection;
}

+(const PEXDbUri * const) getURI {
    static dispatch_once_t once;
    static PEXDbUri * uri;
    dispatch_once(&once, ^{
        uri = [[PEXDbUri alloc] initWithTableName:DBCL(TABLE)];
    });
    return uri;
}

+(const PEXDbUri * const) getURIBase {
    static dispatch_once_t once;
    static PEXDbUri * uriBase;
    dispatch_once(&once, ^{
        uriBase = [[PEXDbUri alloc] initWithTableName:DBCL(TABLE) isBase:YES];
    });
    return uriBase;
}

+(NSString * const) getWhereForId
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?",
                  DBCL(FIELD_ID)];
    });
    return result;
}

+(NSArray*) getWhereForIdArgs: (const NSNumber * const) IdValue
{
    return @[[IdValue description]];
}

+(NSString * const) getWhereForSip
{
    static dispatch_once_t once;
    static NSString * result;
    dispatch_once(&once, ^{
        result = [NSString stringWithFormat:@"WHERE %@=?",
                  DBCL(FIELD_SIP)];
    });
    return result;
}

+(NSArray*) getWhereForSipArgs: (NSString * const) sip
{
    return @[sip];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.account = [coder decodeObjectForKey:@"self.account"];
        self.id = [coder decodeObjectForKey:@"self.id"];
        self.sip = [coder decodeObjectForKey:@"self.sip"];
        self.displayName = [coder decodeObjectForKey:@"self.displayName"];
        self.certificate = [coder decodeObjectForKey:@"self.certificate"];
        self.certificateHash = [coder decodeObjectForKey:@"self.certificateHash"];
        self.inWhitelist = [coder decodeBoolForKey:@"self.inWhitelist"];
        self.dateCreated = [coder decodeObjectForKey:@"self.dateCreated"];
        self.dateLastModified = [coder decodeObjectForKey:@"self.dateLastModified"];
        self.presenceOnline = [coder decodeBoolForKey:@"self.presenceOnline"];
        self.presenceStatus = [coder decodeObjectForKey:@"self.presenceStatus"];
        self.presenceLastUpdate = [coder decodeObjectForKey:@"self.presenceLastUpdate"];
        self.presenceStatusType = [coder decodeObjectForKey:@"self.presenceStatusType"];
        self.presenceStatusText = [coder decodeObjectForKey:@"self.presenceStatusText"];
        self.presenceCertHashPrefix = [coder decodeObjectForKey:@"self.presenceCertHashPrefix"];
        self.presenceCertNotBefore = [coder decodeObjectForKey:@"self.presenceCertNotBefore"];
        self.presenceLastCertUpdate = [coder decodeObjectForKey:@"self.presenceLastCertUpdate"];
        self.presenceNumCertUpdate = [coder decodeObjectForKey:@"self.presenceNumCertUpdate"];
        self.presenceDosCertUpdate = [coder decodeObjectForKey:@"self.presenceDosCertUpdate"];
        self.unreadMessages = [coder decodeObjectForKey:@"self.unreadMessages"];
        self.hideContact = [coder decodeObjectForKey:@"self.hideContact"];
        self.capabilities = [coder decodeObjectForKey:@"self.capabilities"];
        self.lastActive = [coder decodeObjectForKey:@"self.lastActive"];
        self.lastTyping = [coder decodeObjectForKey:@"self.lastTyping"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.account forKey:@"self.account"];
    [coder encodeObject:self.id forKey:@"self.id"];
    [coder encodeObject:self.sip forKey:@"self.sip"];
    [coder encodeObject:self.displayName forKey:@"self.displayName"];
    [coder encodeObject:self.certificate forKey:@"self.certificate"];
    [coder encodeObject:self.certificateHash forKey:@"self.certificateHash"];
    [coder encodeBool:self.inWhitelist forKey:@"self.inWhitelist"];
    [coder encodeObject:self.dateCreated forKey:@"self.dateCreated"];
    [coder encodeObject:self.dateLastModified forKey:@"self.dateLastModified"];
    [coder encodeBool:self.presenceOnline forKey:@"self.presenceOnline"];
    [coder encodeObject:self.presenceStatus forKey:@"self.presenceStatus"];
    [coder encodeObject:self.presenceLastUpdate forKey:@"self.presenceLastUpdate"];
    [coder encodeObject:self.presenceStatusType forKey:@"self.presenceStatusType"];
    [coder encodeObject:self.presenceStatusText forKey:@"self.presenceStatusText"];
    [coder encodeObject:self.presenceCertHashPrefix forKey:@"self.presenceCertHashPrefix"];
    [coder encodeObject:self.presenceCertNotBefore forKey:@"self.presenceCertNotBefore"];
    [coder encodeObject:self.presenceLastCertUpdate forKey:@"self.presenceLastCertUpdate"];
    [coder encodeObject:self.presenceNumCertUpdate forKey:@"self.presenceNumCertUpdate"];
    [coder encodeObject:self.presenceDosCertUpdate forKey:@"self.presenceDosCertUpdate"];
    [coder encodeObject:self.unreadMessages forKey:@"self.unreadMessages"];
    [coder encodeObject:self.hideContact forKey:@"self.hideContact"];
    [coder encodeObject:self.capabilities forKey:@"self.capabilities"];
    [coder encodeObject:self.lastActive forKey:@"self.lastActive"];
    [coder encodeObject:self.lastTyping forKey:@"self.lastTyping"];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.account=%@", self.account];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendFormat:@", self.sip=%@", self.sip];
    [description appendFormat:@", self.displayName=%@", self.displayName];
    [description appendFormat:@", self.certificate=%@", self.certificate];
    [description appendFormat:@", self.certificateHash=%@", self.certificateHash];
    [description appendFormat:@", self.inWhitelist=%d", self.inWhitelist];
    [description appendFormat:@", self.dateCreated=%@", self.dateCreated];
    [description appendFormat:@", self.dateLastModified=%@", self.dateLastModified];
    [description appendFormat:@", self.presenceOnline=%d", self.presenceOnline];
    [description appendFormat:@", self.presenceStatus=%@", self.presenceStatus];
    [description appendFormat:@", self.presenceLastUpdate=%@", self.presenceLastUpdate];
    [description appendFormat:@", self.presenceStatusType=%@", self.presenceStatusType];
    [description appendFormat:@", self.presenceStatusText=%@", self.presenceStatusText];
    [description appendFormat:@", self.presenceCertHashPrefix=%@", self.presenceCertHashPrefix];
    [description appendFormat:@", self.presenceCertNotBefore=%@", self.presenceCertNotBefore];
    [description appendFormat:@", self.presenceLastCertUpdate=%@", self.presenceLastCertUpdate];
    [description appendFormat:@", self.presenceNumCertUpdate=%@", self.presenceNumCertUpdate];
    [description appendFormat:@", self.presenceDosCertUpdate=%@", self.presenceDosCertUpdate];
    [description appendFormat:@", self.unreadMessages=%@", self.unreadMessages];
    [description appendFormat:@", self.hideContact=%@", self.hideContact];
    [description appendFormat:@", self.capabilities=%@", self.capabilities];
    [description appendFormat:@", self.lastActive=%@", self.lastActive];
    [description appendFormat:@", self.lastTyping=%@", self.lastTyping];
    [description appendString:@">"];
    return description;
}


- (instancetype)init {
    self = [super init];
    if (self){
        _id = nil;
        _hideContact = @(NO);
        _inWhitelist = YES;
        _presenceOnline = NO;
        _presenceStatusType = @(PEXPbPresencePushPEXPbStatusOffline);
    }
    return self;
}

- (instancetype)initWithCursor:(PEXDbCursor *)cursor {
    if (self = [self init]) {
        [self createFromCursor:cursor];
    }

    return self;
}

+ (instancetype)contactFromCursor:(PEXDbCursor *)cursor {
    PEXDbContact * cert = [[PEXDbContact alloc] initWithCursor:cursor];
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

        if ([DBCL(FIELD_ID) isEqualToString: colname]){
            _id = [c getInt64:i];
        } else if ([DBCL(FIELD_ACCOUNT) isEqualToString: colname]){
            _account = [c getInt64:i];
        } else if ([DBCL(FIELD_SIP) isEqualToString: colname]){
            _sip = [c getString:i];
        } else if ([DBCL(FIELD_DISPLAY_NAME) isEqualToString: colname]){
            _displayName = [c getString:i];
        } else if ([DBCL(FIELD_CERTIFICATE) isEqualToString: colname]){
            _certificate = [c getBlob:i];
        } else if ([DBCL(FIELD_CERTIFICATE_HASH) isEqualToString: colname]){
            _certificateHash = [c getString:i];
        } else if ([DBCL(FIELD_IN_WHITELIST) isEqualToString: colname]){
            _inWhitelist = [[c getInt:i] integerValue] != 0;
        } else if ([DBCL(FIELD_PRESENCE_ONLINE) isEqualToString: colname]){
            _presenceOnline = [[c getInt:i] integerValue] != 0;
        } else if ([DBCL(FIELD_PRESENCE_STATUS) isEqualToString: colname]){
            _presenceStatus = [c getString:i];
        } else if ([DBCL(FIELD_DATE_CREATED) isEqualToString: colname]){
            _dateCreated = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_DATE_LAST_CHANGE) isEqualToString: colname]){
            _dateLastModified = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_PRESENCE_LAST_UPDATE) isEqualToString: colname]){
            _presenceLastUpdate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_UNREAD_MESSAGES) isEqualToString: colname]){
            _unreadMessages = [c getInt:i];
        } else if ([DBCL(FIELD_PRESENCE_STATUS_TYPE) isEqualToString: colname]){
            _presenceStatusType = [c getInt:i];
        } else if ([DBCL(FIELD_PRESENCE_STATUS_TEXT) isEqualToString: colname]){
            _presenceStatusText = [c getString:i];
        } else if ([DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX) isEqualToString: colname]){
            _presenceCertHashPrefix = [c getString:i];
        } else if ([DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE) isEqualToString: colname]){
            _presenceCertNotBefore = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE) isEqualToString: colname]){
            _presenceLastCertUpdate = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE) isEqualToString: colname]){
            _presenceNumCertUpdate = [c getInt:i];
        } else if ([DBCL(FIELD_PRESENCE_DOS_CERT_UPDATE) isEqualToString: colname]){
            _presenceDosCertUpdate = [c getString:i];
        } else if ([DBCL(FIELD_HIDE_CONTACT) isEqualToString: colname]){
            _hideContact = @([[c getInt:i] integerValue] != 0);
        } else if ([DBCL(FIELD_LAST_ACTIVE) isEqualToString: colname]){
            _lastActive = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_LAST_TYPING) isEqualToString: colname]){
            _lastTyping = [PEXDbModelBase getDateFromCursor:c idx:i];
        } else if ([DBCL(FIELD_CAPABILITIES) isEqualToString: colname]) {
            _capabilities = [c getString:i];
        } else {
            DDLogError(@"Unknown column name: %@", colname);
        }
    }
}

- (PEXDbContentValues *) getDbContentValues {
    PEXDbContentValues * args = [[PEXDbContentValues alloc] init];
    if (_id!=nil && [_id longLongValue]!=DBCL(INVALID_ID)){
        [args put:DBCL(FIELD_ID) NSNumberAsLongLong:_id];
    }

    if (_account != nil)
        [args put: DBCL(FIELD_ACCOUNT) NSNumberAsLongLong: _account];
    if (_sip != nil)
        [args put: DBCL(FIELD_SIP) string: _sip];
    if (_displayName != nil)
        [args put: DBCL(FIELD_DISPLAY_NAME) string: _displayName];
    if (_certificate!=nil)
        [args put: DBCL(FIELD_CERTIFICATE) data: _certificate];
    if (_certificateHash!=nil)
        [args put: DBCL(FIELD_CERTIFICATE_HASH) string: _certificateHash];

    [args put:DBCL(FIELD_IN_WHITELIST) NSNumberAsInt: @(_inWhitelist ? 1 : 0)];
    if (_dateCreated != nil)
        [args put: DBCL(FIELD_DATE_CREATED) date: _dateCreated];
    if (_dateLastModified != nil)
        [args put: DBCL(FIELD_DATE_LAST_CHANGE) date: _dateLastModified];
    [args put: DBCL(FIELD_PRESENCE_ONLINE) NSNumberAsInt: @(_presenceOnline ? 1 : 0)];
    if (_presenceStatus!=nil)
        [args put: DBCL(FIELD_PRESENCE_STATUS) string: _presenceStatus];
    if (_presenceLastUpdate!=nil)
        [args put: DBCL(FIELD_PRESENCE_LAST_UPDATE) date: _presenceLastUpdate];
    if (_presenceStatusType!=nil)
        [args put: DBCL(FIELD_PRESENCE_STATUS_TYPE) NSNumberAsInt: _presenceStatusType];
    if (_presenceStatusText!=nil)
        [args put: DBCL(FIELD_PRESENCE_STATUS_TEXT) string: _presenceStatusText];
    if (_presenceCertHashPrefix!=nil)
        [args put: DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX) string: _presenceCertHashPrefix];
    if (_presenceCertNotBefore!=nil)
        [args put: DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE) date: _presenceCertNotBefore];
    if (_presenceLastCertUpdate!=nil)
        [args put: DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE) date: _presenceLastCertUpdate];
    if (_presenceNumCertUpdate!=nil)
        [args put: DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE) NSNumberAsInt: _presenceNumCertUpdate];
    if (_presenceDosCertUpdate!=nil)
        [args put: DBCL(FIELD_PRESENCE_DOS_CERT_UPDATE) string: _presenceDosCertUpdate];
    if (_hideContact!=nil)
        [args put: DBCL(FIELD_HIDE_CONTACT) NSNumberAsBoolean:_hideContact];
    if (_lastActive!=nil)
        [args put: DBCL(FIELD_LAST_ACTIVE) date:_lastActive];
    if (_lastTyping!=nil)
        [args put: DBCL(FIELD_LAST_TYPING) date:_lastTyping];
    if (_capabilities!=nil)
        [args put: DBCL(FIELD_CAPABILITIES) string: _capabilities];

    return args;
}

+(int) cleanContactList: (PEXDbContentProvider *) cr forUser: (NSNumber *) user {
    @try {
        NSString * selection = [NSString stringWithFormat:@" WHERE %@=?", PEX_DBCL_FIELD_ACCOUNT];
        [cr delete:[self getURI] selection:selection selectionArgs:@[[user stringValue]]];
        return 1;
    } @catch(NSException * e){
        DDLogError(@"Exception during removing all contacts for: %@, exception=%@", user, e);
        return 0;
    }
}

+(NSArray *) getListForAccount: (PEXDbContentProvider *) cr accountId: (int64_t) accId {
    PEXDbCursor * c = [cr query:[self getURI] projection:[self getLightProjection]
                      selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBCL_FIELD_ACCOUNT]
                  selectionArgs:@[[@(accId) stringValue]]
                      sortOrder:nil];
    if (c == nil){
        return [NSArray array];
    }

    NSMutableArray * acc = [[NSMutableArray alloc] init];
    @try {
        while([c moveToNext]){
            PEXDbContact * clist = [PEXDbContact contactFromCursor:c];
            [acc addObject:clist];
        }
    } @catch (NSException * e) {
        DDLogError(@"Error while getting SipClist from DB, exception=%@", e);
    } @finally {
        [c close];
    }

    return [NSArray arrayWithArray:acc];
}

+(int) removeContactsForAccount: (PEXDbContentProvider *) cr accountId: (int64_t) accId names: (NSArray *) names{
    if (names == nil || [names count] == 0){
        return 0;
    }

    @try {
        const NSUInteger cnt = [names count];
        NSString * selection = [NSString stringWithFormat:@" WHERE %@=? AND %@ IN (%@)",
                        PEX_DBCL_FIELD_ACCOUNT,
                        PEX_DBCL_FIELD_SIP,
                        [PEXUtils generateDbPlaceholders:cnt]];
        NSMutableArray * args = [[NSMutableArray alloc] init];
        [args addObject:@(accId)];
        [args addObjectsFromArray:names];
        return [cr delete:[self getURI] selection:selection selectionArgs:args];

    } @catch(NSException * e){
        DDLogError(@"Exception during removing contacts for: %lld, exception=%@", accId, e);
        return 0;
    }
}


/**
* Helper method to retrieve a PEXDbContact object from its account database
*
* @param cr Content provider
* @param sip Sip in text format: e.g: test610@phone-x.net
* @param projection The list of fields you want to retrieve. Must be in FIELD_* of this class.<br/>
* Reducing your requested fields to minimum will improve speed of the request.
* @return A wrapper SipClist object on the request you done. If not found an invalid account with an {@link #id} equals to {@link #INVALID_ID}
*/
+(PEXDbContact *) newProfileFromDbSip: (PEXDbContentProvider *) cr sip: (NSString *) sip projection: (NSArray *) projection {
    PEXDbCursor * c = [cr query:[self getURI] projection:projection
                      selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBCL_FIELD_SIP]
                  selectionArgs:@[sip]
                      sortOrder:nil];
    if (c == nil){
        return nil;
    }

    PEXDbContact * clist = nil;
    @try {
        if ([c moveToFirst]){
            clist = [PEXDbContact contactFromCursor:c];
        }
    } @catch (NSException * e) {
        DDLogError(@"Error while getting SipClist from DB, exception=%@", e);
    } @finally {
        [c close];
    }

    return clist;
}

/**
* Helper method to retrieve a list of PEXDbContact objects from its account database
*
* @param cr Content provider
* @param sip array of sip identifiers.
* @param projection The list of fields you want to retrieve. Must be in FIELD_* of this class.<br/>
* Reducing your requested fields to minimum will improve speed of the request.
* @return A wrapper SipClist object on the request you done. If not found an invalid account with an {@link #id} equals to {@link #INVALID_ID}
*/
+(NSArray *) newProfilesFromDbSip: (PEXDbContentProvider *) cr sip: (NSArray *) sip projection: (NSArray *) projection {
    int count = sip == nil ? 0 : [sip count];

    NSMutableArray * ret = [[NSMutableArray alloc] initWithCapacity: count];
    if (count == 0){
        return ret;
    }

    PEXDbCursor * c = [cr query:[self getURI]
                     projection:projection
                      selection:[NSString stringWithFormat:@" WHERE %@ IN (%@)", PEX_DBCL_FIELD_SIP, [PEXUtils generateDbPlaceholders:count]]
                  selectionArgs:sip
                      sortOrder:nil];

    if (c == nil){
        return ret;
    }

    @try {
        while([c moveToNext]){
            [ret addObject: [PEXDbContact contactFromCursor:c]];
        }
    } @catch(NSException * ex){
        DDLogError(@"Error while getting SipClist from DB, exception=%@", ex);

    } @finally {
        // Close cursor.
        @try {
            [c close];
        } @catch(NSException * e) { }
    }

    return ret;
}

+ (int)updateContact:(PEXDbContentProvider *)cr contactId:(NSNumber *)id1 contentValues:(PEXDbContentValues *)cv {
    if (id1 == nil){
        return 0;
    }

    return [cr update:[self getURI] ContentValues:cv
            selection:[NSString stringWithFormat:@" WHERE %@=?", PEX_DBCL_FIELD_ID]
        selectionArgs:@[[NSString stringWithFormat:@"%lld", [id1 longLongValue]]]] ? 1 : 0;
}

/**
* Returns true if a given contact has a given capability.
*/
-(BOOL) hasCapability: (NSString *) capability{
    return [PEXDbContact hasCapability:capability capabilities:self.capabilities];
}

/**
* Adds capability to the string, checks for duplicates in O(mn).
* @param capability
*/
+(NSString *) addCapability: (NSString *) capability capabilities: (NSString *) capabilities{
    NSString * toSearch = [NSString stringWithFormat:@";%@;", capability];
    if ([PEXUtils isEmpty:capabilities]){
        return toSearch;
    }

    // Check for duplicates
    if ([capabilities rangeOfString: toSearch].location != NSNotFound){
        return capabilities;
    }

    // Add to non-empty capabilities set.
    return [NSString stringWithFormat:@"%@%@;", capabilities, capability];
}

/**
* Determines whether given capability is among stored ones.
*
* @param capability
* @param capabilities
* @return
*/
+(BOOL) hasCapability: (NSString *) capability capabilities: (NSString *) capabilities{
    if ([PEXUtils isEmpty:capabilities]){
        return NO;
    }

    NSString * toSearch = [NSString stringWithFormat:@";%@;", capability];
    return [capabilities rangeOfString: toSearch].location != NSNotFound;
}

/**
* Parse given capability to the set. Deserialization routine.
* @param capabilities
* @return
*/
+(NSSet *) getCapabilitiesAsSet: (NSString *) capabilities{
    NSMutableSet * ret = [[NSMutableSet alloc] init];
    if ([PEXUtils isEmpty:capabilities]){
        return ret;
    }

    NSArray * caps = [capabilities componentsSeparatedByString:@";"];
    for(NSString * cap in caps){
        if ([PEXUtils isEmpty:cap]) {
            continue;
        }

        [ret addObject:cap];
    }

    return ret;
}

/**
* Assemble capabilities hash set to the string that can be stored to the database.
* Serialization routine.
*
* @param caps
* @return
*/
+(NSString *) assembleCapabilities: (NSSet *) caps{
    if (caps == nil || [caps count] == 0){
        return @"";
    }

    NSMutableString * sb = [[NSMutableString alloc] initWithString:@";"];
    for(NSString * cap in caps){
        [sb appendFormat:@"%@;", cap];
    }

    return sb;
}

+ (NSString *)stripHidePrefix:(NSString *)displayName wasPresent: (BOOL *) wasPresent {
    if (wasPresent != NULL){
        *wasPresent = NO;
    }

    if ([PEXStringUtils isEmpty:displayName]){
        return displayName;
    }

    NSString * toReturn = displayName;
    if ([PEXStringUtils startsWith:toReturn prefix:@PEX_CONTACT_HIDDEN_PREFIX]){
        toReturn = [toReturn substringFromIndex:[@PEX_CONTACT_HIDDEN_PREFIX length]];

        if (wasPresent != NULL){
            *wasPresent |= YES;
        }
    }

    return toReturn;
}

+ (NSString *)prependHidePrefix:(NSString *) displayName wasPresent: (BOOL *) wasPresent {
    if ([PEXStringUtils isEmpty:displayName]){
        return  displayName;
    }

    if ([PEXStringUtils startsWith:displayName prefix:@PEX_CONTACT_HIDDEN_PREFIX]){
        if (wasPresent != NULL){
            *wasPresent |= YES;
        }

        return displayName;
    }

    if (wasPresent != NULL){
        *wasPresent = NO;
    }
    return [NSString stringWithFormat:@"%@%@", @PEX_CONTACT_HIDDEN_PREFIX, displayName];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDbContact *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.account = self.account;
        copy.id = self.id;
        copy.sip = self.sip;
        copy.displayName = self.displayName;
        copy.certificate = self.certificate;
        copy.certificateHash = self.certificateHash;
        copy.inWhitelist = self.inWhitelist;
        copy.dateCreated = self.dateCreated;
        copy.dateLastModified = self.dateLastModified;
        copy.presenceOnline = self.presenceOnline;
        copy.presenceStatus = self.presenceStatus;
        copy.presenceLastUpdate = self.presenceLastUpdate;
        copy.presenceStatusType = self.presenceStatusType;
        copy.presenceStatusText = self.presenceStatusText;
        copy.presenceCertHashPrefix = self.presenceCertHashPrefix;
        copy.presenceCertNotBefore = self.presenceCertNotBefore;
        copy.presenceLastCertUpdate = self.presenceLastCertUpdate;
        copy.presenceNumCertUpdate = self.presenceNumCertUpdate;
        copy.presenceDosCertUpdate = self.presenceDosCertUpdate;
        copy.unreadMessages = self.unreadMessages;
        copy.hideContact = self.hideContact;
        copy.capabilities = self.capabilities;
        copy.lastActive = self.lastActive;
        copy.lastTyping = self.lastTyping;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToContact:other];
}

- (BOOL)isEqualToContact:(const PEXDbContact * const)contact {
    if (self == contact)
        return YES;
    if (contact == nil)
        return NO;
    if (self.id != contact.id && ![self.id isEqualToNumber:contact.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.id hash];
}

@end