//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushAckPart.h"
#import "PEXUtils.h"


@implementation PEXPushAckPart {

}

- (NSMutableDictionary *)getSerializationBase {
    NSMutableDictionary * ret = [NSMutableDictionary dictionaryWithDictionary:
            @{
                    PEX_PUSH_FIELD_ACK_ACTION : self.action,
                    PEX_PUSH_FIELD_ACK_TIMESTAMP : self.timestamp
            }];

    if (![PEXUtils isEmpty:self.key]) {
        ret[PEX_PUSH_FIELD_ACK_KEY] = self.key;
    }

    return ret;
}

// ---------------------------------------------
#pragma mark - Generated
// ---------------------------------------------

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.action = [coder decodeObjectForKey:@"self.action"];
        self.timestamp = [coder decodeObjectForKey:@"self.timestamp"];
        self.key = [coder decodeObjectForKey:@"self.key"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.action forKey:@"self.action"];
    [coder encodeObject:self.timestamp forKey:@"self.timestamp"];
    [coder encodeObject:self.key forKey:@"self.key"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushAckPart *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.action = self.action;
        copy.timestamp = self.timestamp;
        copy.key = self.key;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.action=%@", self.action];
    [description appendFormat:@", self.timestamp=%@", self.timestamp];
    [description appendFormat:@", self.key=%@", self.key];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToPart:other];
}

- (BOOL)isEqualToPart:(PEXPushAckPart *)part {
    if (self == part)
        return YES;
    if (part == nil)
        return NO;
    if (self.action != part.action && ![self.action isEqualToString:part.action])
        return NO;
    if (self.timestamp != part.timestamp && ![self.timestamp isEqualToNumber:part.timestamp])
        return NO;
    if (self.key != part.key && ![self.key isEqualToString:part.key])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.action hash];
    hash = hash * 31u + [self.timestamp hash];
    hash = hash * 31u + [self.key hash];
    return hash;
}


@end