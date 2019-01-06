//
// Created by Dusan Klinec on 17.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXUserPrivate.h"
#import "PEXPKCS12Passwd.h"


@implementation PEXUserPrivate {

}

- (SecIdentityRef *)identityPtr {
    return &_identity;
}

- (instancetype)copyPasswordsTo:(PEXUserPrivate *)privData {
    privData.pkcsPass = self.pkcsPass;
    privData.xmppPass = self.xmppPass;
    privData.pass = self.pass;
    privData.pemPass = self.pemPass;
    privData.username = self.username;
    return privData;
}

- (instancetype)copyIdentityTo:(PEXUserPrivate *)privData {
    privData.privKey = self.privKey;
    privData.cacerts = self.cacerts;
    privData.cert = self.cert;
    privData.identity = self.identity;
    privData.accountId = self.accountId;
    return privData;
}

- (instancetype)copyTo:(PEXUserPrivate *)privData {
    [self copyIdentityTo:privData];
    [self copyPasswordsTo:privData];
    return privData;
}

- (instancetype)initCopy {
    return [self copy];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXUserPrivate *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.username = self.username;
        copy.pass = self.pass;
        copy.pemPass = self.pemPass;
        copy.pkcsPass = self.pkcsPass;
        copy.xmppPass = self.xmppPass;
        copy.sipPass = self.sipPass;
        copy.accountId = self.accountId;
        copy.identity = self.identity;
        copy.cert = self.cert;
        copy.privKey = self.privKey;
        copy.cacerts = self.cacerts;
        copy.pemCAPath = self.pemCAPath;
        copy.pemCrtPath = self.pemCrtPath;
        copy.pemKeyPath = self.pemKeyPath;
        copy.invalidPasswordEntries = self.invalidPasswordEntries;
    }

    return copy;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.username=nil;
        self.pass=nil;
        self.pemPass=nil;
        self.pkcsPass=nil;
        self.xmppPass=nil;
        self.identity=nil;
        self.cert=nil;
        self.privKey=nil;
        self.cacerts=nil;
        self.accountId=nil;
        self.invalidPasswordEntries = 0;
    }

    return self;
}

- (instancetype)initWithUsername:(NSString *)username pass:(NSString *)pass {
    self = [self init];
    if (self) {
        self.username = username;
        self.pass = pass;
    }

    return self;
}

+ (instancetype)aPrivateWithUsername:(NSString *)username pass:(NSString *)pass {
    return [[self alloc] initWithUsername:username pass:pass];
}

- (NSInteger)incAndGetInvalidPasswordEntryCounter {
    NSUInteger invalidRetries = (NSUInteger)[[PEXUserAppPreferences instance]
            getIntPrefForKey:PEX_PREF_INVALID_PASSWORD_ENTRIES
                defaultValue:0];

    self.invalidPasswordEntries = MAX(invalidRetries, self.invalidPasswordEntries);
    self.invalidPasswordEntries += 1;

    // Update preferences.
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_INVALID_PASSWORD_ENTRIES value:self.invalidPasswordEntries];

    return self.invalidPasswordEntries;
}

- (void)resetInvalidPasswordEntryCounter {
    self.invalidPasswordEntries = 0;
    [[PEXUserAppPreferences instance] setIntPrefForKey:PEX_PREF_INVALID_PASSWORD_ENTRIES value:self.invalidPasswordEntries];
}

@end