//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertRefreshParams.h"
#import "PEXCertificate.h"
#import "PEXDbUserCertificate.h"
#import "hr.h"
#import "PEXSOAPTask.h"


@implementation PEXCertRefreshParams {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.allowDhKeyRefreshOnCertChange = YES;
        self.forceRecheck = NO;
        self.loadNewCertificateAfterInsert = YES;
        self.loadCertificateToResult = YES;
        self.useCertHash = YES;
        self.becameOnlineCheck = NO;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck {
    self = [self init];
    if (self) {
        self.user = user;
        self.forceRecheck = forceRecheck;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck existingCertHash2recheck:(NSString *)existingCertHash2recheck {
    self = [self init];
    if (self) {
        self.user = user;
        self.forceRecheck = forceRecheck;
        self.existingCertHash2recheck = existingCertHash2recheck;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.allowDhKeyRefreshOnCertChange = [coder decodeBoolForKey:@"self.allowDhKeyRefreshOnCertChange"];
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.forceRecheck = [coder decodeBoolForKey:@"self.forceRecheck"];
        self.useCertHash = [coder decodeBoolForKey:@"self.useCertHash"];
        self.existingCertHash2recheck = [coder decodeObjectForKey:@"self.existingCertHash2recheck"];
        self.loadCertificateToResult = [coder decodeBoolForKey:@"self.loadCertificateToResult"];
        self.loadNewCertificateAfterInsert = [coder decodeBoolForKey:@"self.loadNewCertificateAfterInsert"];
        self.pushNotification = [coder decodeBoolForKey:@"self.pushNotification"];
        self.becameOnlineCheck = [coder decodeBoolForKey:@"self.becameOnlineCheck"];
        self.notBefore = [coder decodeObjectForKey:@"self.notBefore"];
        self.callbackId = [coder decodeObjectForKey:@"self.callbackId"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.allowDhKeyRefreshOnCertChange forKey:@"self.allowDhKeyRefreshOnCertChange"];
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeBool:self.forceRecheck forKey:@"self.forceRecheck"];
    [coder encodeBool:self.useCertHash forKey:@"self.useCertHash"];
    [coder encodeObject:self.existingCertHash2recheck forKey:@"self.existingCertHash2recheck"];
    [coder encodeBool:self.loadCertificateToResult forKey:@"self.loadCertificateToResult"];
    [coder encodeBool:self.loadNewCertificateAfterInsert forKey:@"self.loadNewCertificateAfterInsert"];
    [coder encodeBool:self.pushNotification forKey:@"self.pushNotification"];
    [coder encodeBool:self.becameOnlineCheck forKey:@"self.becameOnlineCheck"];
    [coder encodeObject:self.notBefore forKey:@"self.notBefore"];
    [coder encodeObject:self.callbackId forKey:@"self.callbackId"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXCertRefreshParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.allowDhKeyRefreshOnCertChange = self.allowDhKeyRefreshOnCertChange;
        copy.user = self.user;
        copy.forceRecheck = self.forceRecheck;
        copy.useCertHash = self.useCertHash;
        copy.existingCertHash2recheck = self.existingCertHash2recheck;
        copy.loadCertificateToResult = self.loadCertificateToResult;
        copy.loadNewCertificateAfterInsert = self.loadNewCertificateAfterInsert;
        copy.pushNotification = self.pushNotification;
        copy.becameOnlineCheck = self.becameOnlineCheck;
        copy.notBefore = self.notBefore;
        copy.callbackId = self.callbackId;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.allowDhKeyRefreshOnCertChange=%d", self.allowDhKeyRefreshOnCertChange];
    [description appendFormat:@", self.user=%@", self.user];
    [description appendFormat:@", self.forceRecheck=%d", self.forceRecheck];
    [description appendFormat:@", self.useCertHash=%d", self.useCertHash];
    [description appendFormat:@", self.existingCertHash2recheck=%@", self.existingCertHash2recheck];
    [description appendFormat:@", self.loadCertificateToResult=%d", self.loadCertificateToResult];
    [description appendFormat:@", self.loadNewCertificateAfterInsert=%d", self.loadNewCertificateAfterInsert];
    [description appendFormat:@", self.pushNotification=%d", self.pushNotification];
    [description appendFormat:@", self.becameOnlineCheck=%d", self.becameOnlineCheck];
    [description appendFormat:@", self.notBefore=%@", self.notBefore];
    [description appendFormat:@", self.callbackId=%@", self.callbackId];
    [description appendString:@">"];
    return description;
}

+ (instancetype)paramsWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck existingCertHash2recheck:(NSString *)existingCertHash2recheck {
    return [[self alloc] initWithUser:user forceRecheck:forceRecheck existingCertHash2recheck:existingCertHash2recheck];
}


+ (instancetype)paramsWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck {
    return [[self alloc] initWithUser:user forceRecheck:forceRecheck];
}

@end
