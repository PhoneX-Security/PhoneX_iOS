//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjRegStatus.h"


@implementation PEXPjRegStatus {

}
- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.created=%@", self.created];
    [description appendFormat:@", self.registered=%d", self.registered];
    [description appendFormat:@", self.registeringInProgress=%d", self.registeringInProgress];
    [description appendFormat:@", self.expire=%i", self.expire];
    [description appendFormat:@", self.lastStatusCode=%i", self.lastStatusCode];
    [description appendFormat:@", self.lastStatusText=%@", self.lastStatusText];
    [description appendFormat:@", self.ipReregistrationInProgress=%d", self.ipReregistrationInProgress];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.created = [coder decodeObjectForKey:@"self.created"];
        self.registered = [coder decodeBoolForKey:@"self.registered"];
        self.registeringInProgress = [coder decodeBoolForKey:@"self.registeringInProgress"];
        self.expire = [coder decodeIntForKey:@"self.expire"];
        self.lastStatusCode = [coder decodeIntForKey:@"self.lastStatusCode"];
        self.lastStatusText = [coder decodeObjectForKey:@"self.lastStatusText"];
        self.ipReregistrationInProgress = [coder decodeBoolForKey:@"self.ipReregistrationInProgress"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.created forKey:@"self.created"];
    [coder encodeBool:self.registered forKey:@"self.registered"];
    [coder encodeBool:self.registeringInProgress forKey:@"self.registeringInProgress"];
    [coder encodeInt:self.expire forKey:@"self.expire"];
    [coder encodeInt:self.lastStatusCode forKey:@"self.lastStatusCode"];
    [coder encodeObject:self.lastStatusText forKey:@"self.lastStatusText"];
    [coder encodeBool:self.ipReregistrationInProgress forKey:@"self.ipReregistrationInProgress"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPjRegStatus *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.created = self.created;
        copy.registered = self.registered;
        copy.registeringInProgress = self.registeringInProgress;
        copy.expire = self.expire;
        copy.lastStatusCode = self.lastStatusCode;
        copy.lastStatusText = self.lastStatusText;
        copy.ipReregistrationInProgress = self.ipReregistrationInProgress;
    }

    return copy;
}


@end