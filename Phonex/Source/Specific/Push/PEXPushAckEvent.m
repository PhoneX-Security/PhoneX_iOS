//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushAckEvent.h"
#import "PEXPushAckMsg.h"


@implementation PEXPushAckEvent {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.sending = NO;
    }

    return self;
}

// ---------------------------------------------
#pragma mark - Generated
// ---------------------------------------------

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.ackMsg = [coder decodeObjectForKey:@"self.ackMsg"];
        self.timestamp = [coder decodeObjectForKey:@"self.timestamp"];
        self.packetId = [coder decodeObjectForKey:@"self.packetId"];
        self.sending = [coder decodeBoolForKey:@"self.sending"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.ackMsg forKey:@"self.ackMsg"];
    [coder encodeObject:self.timestamp forKey:@"self.timestamp"];
    [coder encodeObject:self.packetId forKey:@"self.packetId"];
    [coder encodeBool:self.sending forKey:@"self.sending"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushAckEvent *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.ackMsg = self.ackMsg;
        copy.timestamp = self.timestamp;
        copy.packetId = self.packetId;
        copy.sending = self.sending;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToEvent:other];
}

- (BOOL)isEqualToEvent:(PEXPushAckEvent *)event {
    if (self == event)
        return YES;
    if (event == nil)
        return NO;
    if (self.ackMsg != event.ackMsg && ![self.ackMsg isEqual:event.ackMsg])
        return NO;
    if (self.timestamp != event.timestamp && ![self.timestamp isEqualToDate:event.timestamp])
        return NO;
    if (self.packetId != event.packetId && ![self.packetId isEqualToString:event.packetId])
        return NO;
    if (self.sending != event.sending)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.ackMsg hash];
    hash = hash * 31u + [self.timestamp hash];
    hash = hash * 31u + [self.packetId hash];
    hash = hash * 31u + self.sending;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.ackMsg=%@", self.ackMsg];
    [description appendFormat:@", self.timestamp=%@", self.timestamp];
    [description appendFormat:@", self.packetId=%@", self.packetId];
    [description appendFormat:@", self.sending=%d", self.sending];
    [description appendString:@">"];
    return description;
}


@end