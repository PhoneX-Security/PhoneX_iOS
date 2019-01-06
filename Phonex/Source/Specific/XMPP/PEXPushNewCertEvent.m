//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushNewCertEvent.h"


@implementation PEXPushNewCertEvent {

}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.certHashPrefix = [coder decodeObjectForKey:@"self.certHashPrefix"];
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.tstamp = [coder decodeObjectForKey:@"self.tstamp"];
        self.notBefore = [coder decodeInt64ForKey:@"self.notBefore"];
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user tstamp:(NSNumber *)tstamp notBefore:(int64_t)notBefore certHashPrefix:(NSString *)certHashPrefix {
    self = [super init];
    if (self) {
        self.user = user;
        self.tstamp = tstamp;
        self.notBefore = notBefore;
        self.certHashPrefix = certHashPrefix;
    }

    return self;
}

+ (instancetype)eventWithUser:(NSString *)user tstamp:(NSNumber *)tstamp notBefore:(int64_t)notBefore certHashPrefix:(NSString *)certHashPrefix {
    return [[self alloc] initWithUser:user tstamp:tstamp notBefore:notBefore certHashPrefix:certHashPrefix];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.certHashPrefix forKey:@"self.certHashPrefix"];
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeObject:self.tstamp forKey:@"self.tstamp"];
    [coder encodeInt64:self.notBefore forKey:@"self.notBefore"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushNewCertEvent *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.certHashPrefix = self.certHashPrefix;
        copy.user = self.user;
        copy.tstamp = self.tstamp;
        copy.notBefore = self.notBefore;
    }

    return copy;
}


@end