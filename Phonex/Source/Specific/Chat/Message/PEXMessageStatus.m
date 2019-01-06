//
// Created by Matej Oravec on 31/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMessageStatus.h"


@implementation PEXMessageStatus {

}
- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToStatus:other];
}

- (BOOL)isEqualToStatus:(PEXMessageStatus *)status {
    if (self == status)
        return YES;
    if (status == nil)
        return NO;
    if (self.nameDescription != status.nameDescription && ![self.nameDescription isEqualToString:status.nameDescription])
        return NO;
    if (self.type != status.type)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.nameDescription hash];
    hash = hash * 31u + (NSUInteger) self.type;
    return hash;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.nameDescription = [coder decodeObjectForKey:@"self.nameDescription"];
        self.type = (PEXMessageStatusTypeEnum) [coder decodeIntForKey:@"self.type"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.nameDescription forKey:@"self.nameDescription"];
    [coder encodeInt:self.type forKey:@"self.type"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXMessageStatus *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.nameDescription = self.nameDescription;
        copy.type = self.type;
    }

    return copy;
}


@end