//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHKeyGeneratorParams.h"


@implementation PEXDHKeyGeneratorParams {

}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.mySip = [coder decodeObjectForKey:@"self.mySip"];
        [coder decodeObjectForKey:@"self.myCert"];
        self.userList = [coder decodeObjectForKey:@"self.userList"];
        self.deleteNonce2List = [coder decodeObjectForKey:@"self.deleteNonce2List"];
        self.numKeys = [coder decodeIntForKey:@"self.numKeys"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.mySip forKey:@"self.mySip"];
    [coder encodeObject:self.userList forKey:@"self.userList"];
    [coder encodeObject:self.deleteNonce2List forKey:@"self.deleteNonce2List"];
    [coder encodeInt:self.numKeys forKey:@"self.numKeys"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDHKeyGeneratorParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.mySip = self.mySip;
        copy.privKey = self.privKey;
        copy.userList = self.userList;
        copy.deleteNonce2List = self.deleteNonce2List;
        copy.numKeys = self.numKeys;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToParams:other];
}

- (BOOL)isEqualToParams:(PEXDHKeyGeneratorParams *)params {
    if (self == params)
        return YES;
    if (params == nil)
        return NO;
    if (self.mySip != params.mySip && ![self.mySip isEqualToString:params.mySip])
        return NO;
    if (self.privKey != params.privKey && ![self.privKey isEqual:params.privKey])
        return NO;
    if (self.userList != params.userList && ![self.userList isEqualToArray:params.userList])
        return NO;
    if (self.deleteNonce2List != params.deleteNonce2List && ![self.deleteNonce2List isEqualToArray:params.deleteNonce2List])
        return NO;
    if (self.numKeys != params.numKeys)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.mySip hash];
    hash = hash * 31u + [self.privKey hash];
    hash = hash * 31u + [self.userList hash];
    hash = hash * 31u + [self.deleteNonce2List hash];
    hash = hash * 31u + self.numKeys;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.mySip=%@", self.mySip];
    [description appendFormat:@", self.privKey=%@", self.privKey];
    [description appendFormat:@", self.userList=%@", self.userList];
    [description appendFormat:@", self.deleteNonce2List=%@", self.deleteNonce2List];
    [description appendFormat:@", self.numKeys=%i", self.numKeys];
    [description appendString:@">"];
    return description;
}

@end

@implementation PEXDHKeyGenForUser {}
- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToUser:other];
}

- (BOOL)isEqualToUser:(PEXDHKeyGenForUser *)user {
    if (self == user)
        return YES;
    if (user == nil)
        return NO;
    if (self.userSip != user.userSip && ![self.userSip isEqualToString:user.userSip])
        return NO;
    if (self.userCert != user.userCert && ![self.userCert isEqual:user.userCert])
        return NO;
    if (self.numKeys != user.numKeys)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.userSip hash];
    hash = hash * 31u + [self.userCert hash];
    hash = hash * 31u + self.numKeys;
    return hash;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDHKeyGenForUser *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.userSip = self.userSip;
        copy.userCert = self.userCert;
        copy.numKeys = self.numKeys;
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.userSip = [coder decodeObjectForKey:@"self.userSip"];
        self.userCert = [coder decodeObjectForKey:@"self.userCert"];
        self.numKeys = [coder decodeIntForKey:@"self.numKeys"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.userSip forKey:@"self.userSip"];
    [coder encodeObject:self.userCert forKey:@"self.userCert"];
    [coder encodeInt:self.numKeys forKey:@"self.numKeys"];
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.userSip=%@", self.userSip];
    [description appendFormat:@", self.userCert=%@", self.userCert];
    [description appendFormat:@", self.numKeys=%i", self.numKeys];
    [description appendString:@">"];
    return description;
}

@end