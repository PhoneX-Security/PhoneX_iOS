//
// Created by Dusan Klinec on 29.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushDhUseEvent.h"


@implementation PEXPushDhUseEvent {

}
- (instancetype)initWithUser:(NSString *)user tstamp:(NSNumber *)tstamp {
    self = [super init];
    if (self) {
        self.user = user;
        self.tstamp = tstamp;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.tstamp = [coder decodeObjectForKey:@"self.tstamp"];
        self.user = [coder decodeObjectForKey:@"self.user"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.tstamp forKey:@"self.tstamp"];
    [coder encodeObject:self.user forKey:@"self.user"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushDhUseEvent *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.tstamp = self.tstamp;
        copy.user = self.user;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.tstamp=%@", self.tstamp];
    [description appendFormat:@", self.user=%@", self.user];
    [description appendString:@">"];
    return description;
}


+ (instancetype)eventWithUser:(NSString *)user tstamp:(NSNumber *)tstamp {
    return [[self alloc] initWithUser:user tstamp:tstamp];
}

@end