//
// Created by Dusan Klinec on 03.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPjMsgSendAux.h"


@implementation PEXPjMsgSendAux {

}
- (instancetype)initWithMsgType:(NSNumber *)msgType msgSubType:(NSNumber *)msgSubType {
    self = [super init];
    if (self) {
        self.msgType = msgType;
        self.msgSubType = msgSubType;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.msgSubType = [coder decodeObjectForKey:@"self.msgSubType"];
        self.msgType = [coder decodeObjectForKey:@"self.msgType"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.msgSubType forKey:@"self.msgSubType"];
    [coder encodeObject:self.msgType forKey:@"self.msgType"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPjMsgSendAux *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.msgSubType = self.msgSubType;
        copy.msgType = self.msgType;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToAux:other];
}

- (BOOL)isEqualToAux:(PEXPjMsgSendAux *)aux {
    if (self == aux)
        return YES;
    if (aux == nil)
        return NO;
    if (self.msgSubType != aux.msgSubType && ![self.msgSubType isEqualToNumber:aux.msgSubType])
        return NO;
    if (self.msgType != aux.msgType && ![self.msgType isEqualToNumber:aux.msgType])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.msgSubType hash];
    hash = hash * 31u + [self.msgType hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.msgSubType=%@", self.msgSubType];
    [description appendFormat:@", self.msgType=%@", self.msgType];
    [description appendString:@">"];
    return description;
}


+ (instancetype)auxWithMsgType:(NSNumber *)msgType msgSubType:(NSNumber *)msgSubType {
    return [[self alloc] initWithMsgType:msgType msgSubType:msgSubType];
}

@end