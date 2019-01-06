//
// Created by Dusan Klinec on 02.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAccountingPermissionId.h"
#import "PEXDbAccountingPermission.h"


@implementation PEXAccountingPermissionId {

}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.licId = [coder decodeObjectForKey:@"self.licId"];
        self.permId = [coder decodeObjectForKey:@"self.permId"];
    }

    return self;
}

- (instancetype)initWithLicId:(NSNumber *)licId permId:(NSNumber *)permId {
    self = [super init];
    if (self) {
        self.licId = licId;
        self.permId = permId;
    }

    return self;
}

- (instancetype)initWithPermission:(PEXDbAccountingPermission *)per {
    self = [super init];
    if (self) {
        self.licId = per.licId;
        self.permId = per.permId;
    }

    return self;
}

+ (instancetype)idWithLicId:(NSNumber *)licId permId:(NSNumber *)permId {
    return [[self alloc] initWithLicId:licId permId:permId];
}

+ (instancetype)idWithPermission:(PEXDbAccountingPermission *)per {
    return [[self alloc] initWithPermission:per];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.licId forKey:@"self.licId"];
    [coder encodeObject:self.permId forKey:@"self.permId"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXAccountingPermissionId *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.licId = self.licId;
        copy.permId = self.permId;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToId:other];
}

- (BOOL)isEqualToId:(PEXAccountingPermissionId *)permissionId {
    if (self == permissionId)
        return YES;
    if (permissionId == nil)
        return NO;
    if (self.licId != permissionId.licId && ![self.licId isEqualToNumber:permissionId.licId])
        return NO;
    if (self.permId != permissionId.permId && ![self.permId isEqualToNumber:permissionId.permId])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.licId hash];
    hash = hash * 31u + [self.permId hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.licId=%@", self.licId];
    [description appendFormat:@", self.permId=%@", self.permId];
    [description appendString:@">"];
    return description;
}


@end