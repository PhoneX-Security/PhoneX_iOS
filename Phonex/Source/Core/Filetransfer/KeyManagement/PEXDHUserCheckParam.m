//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHUserCheckParam.h"


@implementation PEXDHUserCheckParam {

}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.forceRecheck = [coder decodeBoolForKey:@"self.forceRecheck"];
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user {
    self = [super init];
    if (self) {
        self.user = user;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck {
    self = [super init];
    if (self) {
        self.user = user;
        self.forceRecheck = forceRecheck;
    }

    return self;
}

+ (instancetype)paramWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck {
    return [[self alloc] initWithUser:user forceRecheck:forceRecheck];
}


+ (instancetype)paramWithUser:(NSString *)user {
    return [[self alloc] initWithUser:user];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeBool:self.forceRecheck forKey:@"self.forceRecheck"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDHUserCheckParam *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.user = self.user;
        copy.forceRecheck = self.forceRecheck;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToParam:other];
}

- (BOOL)isEqualToParam:(PEXDHUserCheckParam *)param {
    if (self == param)
        return YES;
    if (param == nil)
        return NO;
    if (self.user != param.user && ![self.user isEqualToString:param.user])
        return NO;
    if (self.forceRecheck != param.forceRecheck)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.user hash];
    hash = hash * 31u + self.forceRecheck;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.user=%@", self.user];
    [description appendFormat:@", self.forceRecheck=%d", self.forceRecheck];
    [description appendString:@">"];
    return description;
}


@end