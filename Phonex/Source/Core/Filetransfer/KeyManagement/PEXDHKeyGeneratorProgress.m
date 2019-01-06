//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHKeyGeneratorProgress.h"


@implementation PEXDHKeyGeneratorProgress {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.error = NO;
        self.state = PEX_KEYGEN_STATE_NONE;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.state = (PEXKeyGenStateEnum) [coder decodeIntForKey:@"self.state"];
        self.when = [coder decodeObjectForKey:@"self.when"];
        self.error = [coder decodeBoolForKey:@"self.error"];
        self.errorCode = [coder decodeObjectForKey:@"self.errorCode"];
        self.errorCodeAux = [coder decodeObjectForKey:@"self.errorCodeAux"];
        self.errorReason = [coder decodeObjectForKey:@"self.errorReason"];
        self.maxKeysToGen = [coder decodeObjectForKey:@"self.maxKeysToGen"];
        self.alreadyGeneratedKeys = [coder decodeObjectForKey:@"self.alreadyGeneratedKeys"];
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state {
    self = [self init];
    if (self) {
        self.user = user;
        self.state = state;
        self.when = [NSDate date];
        self.error = NO;
    }

    return self;
}

- (instancetype)initWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state when:(NSDate *)when {
    self = [self init];
    if (self) {
        self.user = user;
        self.state = state;
        self.when = when;
    }

    return self;
}

+ (instancetype)progressWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state when:(NSDate *)when {
    return [[self alloc] initWithUser:user state:state when:when];
}


+ (instancetype)progressWithUser:(NSString *)user state:(PEXKeyGenStateEnum)state {
    return [[self alloc] initWithUser:user state:state];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeInt:self.state forKey:@"self.state"];
    [coder encodeObject:self.when forKey:@"self.when"];
    [coder encodeBool:self.error forKey:@"self.error"];
    [coder encodeObject:self.errorCode forKey:@"self.errorCode"];
    [coder encodeObject:self.errorCodeAux forKey:@"self.errorCodeAux"];
    [coder encodeObject:self.errorReason forKey:@"self.errorReason"];
    [coder encodeObject:self.maxKeysToGen forKey:@"self.maxKeysToGen"];
    [coder encodeObject:self.alreadyGeneratedKeys forKey:@"self.alreadyGeneratedKeys"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDHKeyGeneratorProgress *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.user = self.user;
        copy.state = self.state;
        copy.when = self.when;
        copy.error = self.error;
        copy.errorCode = self.errorCode;
        copy.errorCodeAux = self.errorCodeAux;
        copy.errorReason = self.errorReason;
        copy.maxKeysToGen = self.maxKeysToGen;
        copy.alreadyGeneratedKeys = self.alreadyGeneratedKeys;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToProgress:other];
}

- (BOOL)isEqualToProgress:(PEXDHKeyGeneratorProgress *)progress {
    if (self == progress)
        return YES;
    if (progress == nil)
        return NO;
    if (self.user != progress.user && ![self.user isEqualToString:progress.user])
        return NO;
    if (self.state != progress.state)
        return NO;
    if (self.when != progress.when && ![self.when isEqualToDate:progress.when])
        return NO;
    if (self.error != progress.error)
        return NO;
    if (self.errorCode != progress.errorCode && ![self.errorCode isEqualToNumber:progress.errorCode])
        return NO;
    if (self.errorCodeAux != progress.errorCodeAux && ![self.errorCodeAux isEqualToNumber:progress.errorCodeAux])
        return NO;
    if (self.errorReason != progress.errorReason && ![self.errorReason isEqualToString:progress.errorReason])
        return NO;
    if (self.maxKeysToGen != progress.maxKeysToGen && ![self.maxKeysToGen isEqualToNumber:progress.maxKeysToGen])
        return NO;
    if (self.alreadyGeneratedKeys != progress.alreadyGeneratedKeys && ![self.alreadyGeneratedKeys isEqualToNumber:progress.alreadyGeneratedKeys])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.user hash];
    hash = hash * 31u + (NSUInteger) self.state;
    hash = hash * 31u + [self.when hash];
    hash = hash * 31u + self.error;
    hash = hash * 31u + [self.errorCode hash];
    hash = hash * 31u + [self.errorCodeAux hash];
    hash = hash * 31u + [self.errorReason hash];
    hash = hash * 31u + [self.maxKeysToGen hash];
    hash = hash * 31u + [self.alreadyGeneratedKeys hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.user=%@", self.user];
    [description appendFormat:@", self.state=%d", self.state];
    [description appendFormat:@", self.when=%@", self.when];
    [description appendFormat:@", self.error=%d", self.error];
    [description appendFormat:@", self.errorCode=%@", self.errorCode];
    [description appendFormat:@", self.errorCodeAux=%@", self.errorCodeAux];
    [description appendFormat:@", self.errorReason=%@", self.errorReason];
    [description appendFormat:@", self.maxKeysToGen=%@", self.maxKeysToGen];
    [description appendFormat:@", self.alreadyGeneratedKeys=%@", self.alreadyGeneratedKeys];
    [description appendString:@">"];
    return description;
}

@end