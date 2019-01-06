//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertUpdateProgress.h"
#import "PEXX509.h"


@implementation PEXCertUpdateProgress {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.xnewCertificate = nil;
        self.certChanged = NO;
        self.state = PEX_CERT_UPDATE_STATE_NONE;
        self.when = nil;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when {
    self = [self init];
    if (self) {
        self.user = user;
        self.state = state;
        self.when = when;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when certChanged:(BOOL)certChanged newCertificate:(NSString *)newCertificate {
    self = [self init];
    if (self) {
        self.user = user;
        self.state = state;
        self.when = when;
        self.certChanged = certChanged;
        self.xnewCertificate = newCertificate;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state {
    self = [self init];
    if (self) {
        self.user = user;
        self.state = state;
        self.when = [NSDate date];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.state = (PEXCertUpdateStateEnum) [coder decodeIntForKey:@"self.state"];
        self.when = [coder decodeObjectForKey:@"self.when"];
        self.certChanged = [coder decodeBoolForKey:@"self.certChanged"];
        self.xnewCertificate = [coder decodeObjectForKey:@"self.xnewCertificate"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeInt:self.state forKey:@"self.state"];
    [coder encodeObject:self.when forKey:@"self.when"];
    [coder encodeBool:self.certChanged forKey:@"self.certChanged"];
    [coder encodeObject:self.xnewCertificate forKey:@"self.xnewCertificate"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXCertUpdateProgress *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.user = self.user;
        copy.state = self.state;
        copy.when = self.when;
        copy.certChanged = self.certChanged;
        copy.xnewCertificate = self.xnewCertificate;
    }

    return copy;
}


+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state {
    return [[self alloc] initWithUser:user state:state];
}


+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when certChanged:(BOOL)certChanged newCertificate:(NSString *)newCertificate {
    return [[self alloc] initWithUser:user state:state when:when certChanged:certChanged newCertificate:newCertificate];
}


+ (instancetype)progressWithUser:(NSString *)user state:(PEXCertUpdateStateEnum)state when:(NSDate *)when {
    return [[self alloc] initWithUser:user state:state when:when];
}



@end