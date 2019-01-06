//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushPairingRequestEvent.h"


@implementation PEXPushPairingRequestEvent {

}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.tstamp = [coder decodeObjectForKey:@"self.tstamp"];
        self.user = [coder decodeObjectForKey:@"self.user"];
    }

    return self;
}

- (instancetype)initWithTstamp:(NSNumber *)tstamp user:(NSString *)user {
    self = [super init];
    if (self) {
        self.tstamp = tstamp;
        self.user = user;
    }

    return self;
}

+ (instancetype)eventWithTstamp:(NSNumber *)tstamp user:(NSString *)user {
    return [[self alloc] initWithTstamp:tstamp user:user];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.tstamp forKey:@"self.tstamp"];
    [coder encodeObject:self.user forKey:@"self.user"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushPairingRequestEvent *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.tstamp = self.tstamp;
        copy.user = self.user;
    }

    return copy;
}


@end