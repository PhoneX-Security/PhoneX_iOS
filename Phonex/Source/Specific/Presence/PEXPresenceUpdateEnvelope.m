//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPresenceUpdateEnvelope.h"
#import "PEXPresenceState.h"


@implementation PEXPresenceUpdateEnvelope {

}

- (instancetype)initWithIsAvailable:(NSNumber *)isAvailable statusMessage:(NSString *)statusMessage {
    self = [super init];
    if (self) {
        self.isAvailable = isAvailable;
        self.statusMessage = statusMessage;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.isAvailable=%@", self.isAvailable];
    [description appendFormat:@", self.statusMessage=%@", self.statusMessage];
    [description appendFormat:@", self.state=%@", self.state];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.isAvailable = [coder decodeObjectForKey:@"self.isAvailable"];
        self.statusMessage = [coder decodeObjectForKey:@"self.statusMessage"];
        self.state = [coder decodeObjectForKey:@"self.state"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.isAvailable forKey:@"self.isAvailable"];
    [coder encodeObject:self.statusMessage forKey:@"self.statusMessage"];
    [coder encodeObject:self.state forKey:@"self.state"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPresenceUpdateEnvelope *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.isAvailable = self.isAvailable;
        copy.statusMessage = self.statusMessage;
        copy.state = self.state;
    }

    return copy;
}


+ (instancetype)envelopeWithIsAvailable:(NSNumber *)isAvailable statusMessage:(NSString *)statusMessage {
    return [[self alloc] initWithIsAvailable:isAvailable statusMessage:statusMessage];
}

@end