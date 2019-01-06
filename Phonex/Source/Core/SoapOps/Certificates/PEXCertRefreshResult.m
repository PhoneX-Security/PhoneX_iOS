//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertRefreshResult.h"
#import "PEXCertRefreshParams.h"
#import "PEXCertificate.h"
#import "PEXDbUserCertificate.h"

@implementation PEXCertRefreshResult
- (instancetype)init {
    self = [super init];
    if (self) {
        self.canceled = NO;
        self.statusCode = 0;
    }

    return self;
}

- (instancetype)initWithParams:(PEXCertRefreshParams *)params {
    self = [super init];
    if (self) {
        self.params = params;
    }

    return self;
}

+ (instancetype)resultWithParams:(PEXCertRefreshParams *)params {
    return [[self alloc] initWithParams:params];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.params = [coder decodeObjectForKey:@"self.params"];
        self.canceled = [coder decodeBoolForKey:@"self.canceled"];
        self.statusCode = [coder decodeIntForKey:@"self.statusCode"];
        self.remoteCert = [coder decodeObjectForKey:@"self.remoteCert"];
        self.recheckNeeded = [coder decodeObjectForKey:@"self.recheckNeeded"];
        self.certHash = [coder decodeObjectForKey:@"self.certHash"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.params forKey:@"self.params"];
    [coder encodeBool:self.canceled forKey:@"self.canceled"];
    [coder encodeInt:self.statusCode forKey:@"self.statusCode"];
    [coder encodeObject:self.remoteCert forKey:@"self.remoteCert"];
    [coder encodeObject:self.recheckNeeded forKey:@"self.recheckNeeded"];
    [coder encodeObject:self.certHash forKey:@"self.certHash"];
}

@end