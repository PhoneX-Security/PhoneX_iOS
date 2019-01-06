//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushTokenConfig.h"


@implementation PEXPushTokenConfig {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.whenCreated = [NSDate date];
    }

    return self;
}


- (instancetype)initWithToken:(NSData *)token {
    self = [self init];
    if (self) {
        self.token = token;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.token = [coder decodeObjectForKey:@"self.token"];
        self.whenCreated = [coder decodeObjectForKey:@"self.whenCreated"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.token forKey:@"self.token"];
    [coder encodeObject:self.whenCreated forKey:@"self.whenCreated"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushTokenConfig *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.token = self.token;
        copy.whenCreated = self.whenCreated;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToConfig:other];
}

- (BOOL)isEqualToConfig:(PEXPushTokenConfig *)config {
    if (self == config)
        return YES;
    if (config == nil)
        return NO;
    if (self.token != config.token && ![self.token isEqualToData:config.token])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.token hash];
}


+ (instancetype)configWithToken:(NSData *)token {
    return [[self alloc] initWithToken:token];
}

@end