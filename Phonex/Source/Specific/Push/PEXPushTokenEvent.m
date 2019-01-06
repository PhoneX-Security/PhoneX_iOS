//
// Created by Dusan Klinec on 09.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushTokenEvent.h"
#import "PEXPushTokenConfig.h"


@implementation PEXPushTokenEvent {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploadFinished = NO;
    }

    return self;
}


- (instancetype)initWithToken:(PEXPushTokenConfig *)token {
    self = [super init];
    if (self) {
        self.token = token;
        self.when = [NSDate date];
        self.uploadFinished = NO;
    }

    return self;
}

+ (instancetype)eventWithToken:(PEXPushTokenConfig *)token {
    return [[self alloc] initWithToken:token];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.token = [coder decodeObjectForKey:@"self.token"];
        self.when = [coder decodeObjectForKey:@"self.when"];
        self.uploadFinished = [coder decodeBoolForKey:@"self.uploadFinished"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.token forKey:@"self.token"];
    [coder encodeObject:self.when forKey:@"self.when"];
    [coder encodeBool:self.uploadFinished forKey:@"self.uploadFinished"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushTokenEvent *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.token = self.token;
        copy.when = self.when;
        copy.uploadFinished = self.uploadFinished;
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

- (BOOL)isEqualToEvent:(PEXPushTokenEvent *)event {
    if (self == event)
        return YES;
    if (event == nil)
        return NO;
    if (self.token != event.token && ![self.token isEqualToConfig:event.token])
        return NO;
    if (self.when != event.when && ![self.when isEqualToDate:event.when])
        return NO;
    if (self.uploadFinished != event.uploadFinished)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.token hash];
    hash = hash * 31u + [self.when hash];
    hash = hash * 31u + self.uploadFinished;
    return hash;
}


@end