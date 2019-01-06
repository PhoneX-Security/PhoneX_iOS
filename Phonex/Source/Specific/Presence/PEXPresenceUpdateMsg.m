//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPresenceUpdateMsg.h"


@implementation PEXPresenceUpdateMsg {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.doUpdatePresence = YES;
    }

    return self;
}


- (instancetype)initWithUser:(NSString *)user {
    self = [self init];
    if (self) {
        self.user = user;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.user=%@", self.user];
    [description appendFormat:@", self.isAvailable=%@", self.isAvailable];
    [description appendFormat:@", self.statusId=%@", self.statusId];
    [description appendFormat:@", self.sipRegistered=%@", self.sipRegistered];
    [description appendFormat:@", self.isCallingRightNow=%@", self.isCallingRightNow];
    [description appendFormat:@", self.isCellularCallingRightNow=%@", self.isCellularCallingRightNow];
    [description appendFormat:@", self.statusMessage=%@", self.statusMessage];
    [description appendFormat:@", self.doUpdatePresence=%d", self.doUpdatePresence];
    [description appendFormat:@", self.updateKey=%@", self.updateKey];
    [description appendFormat:@", self.isInBackground=%@", self.isInBackground];
    [description appendString:@">"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPresenceUpdateMsg *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.user = self.user;
        copy.isAvailable = self.isAvailable;
        copy.statusId = self.statusId;
        copy.sipRegistered = self.sipRegistered;
        copy.isCallingRightNow = self.isCallingRightNow;
        copy.isCellularCallingRightNow = self.isCellularCallingRightNow;
        copy.statusMessage = self.statusMessage;
        copy.doUpdatePresence = self.doUpdatePresence;
        copy.updateKey = self.updateKey;
        copy.isInBackground = self.isInBackground;
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.isAvailable = [coder decodeObjectForKey:@"self.isAvailable"];
        self.statusId = [coder decodeObjectForKey:@"self.statusId"];
        self.sipRegistered = [coder decodeObjectForKey:@"self.sipRegistered"];
        self.isCallingRightNow = [coder decodeObjectForKey:@"self.isCallingRightNow"];
        self.isCellularCallingRightNow = [coder decodeObjectForKey:@"self.isCellularCallingRightNow"];
        self.statusMessage = [coder decodeObjectForKey:@"self.statusMessage"];
        self.doUpdatePresence = [coder decodeBoolForKey:@"self.doUpdatePresence"];
        self.updateKey = [coder decodeObjectForKey:@"self.updateKey"];
        self.isInBackground = [coder decodeObjectForKey:@"self.isInBackground"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeObject:self.isAvailable forKey:@"self.isAvailable"];
    [coder encodeObject:self.statusId forKey:@"self.statusId"];
    [coder encodeObject:self.sipRegistered forKey:@"self.sipRegistered"];
    [coder encodeObject:self.isCallingRightNow forKey:@"self.isCallingRightNow"];
    [coder encodeObject:self.isCellularCallingRightNow forKey:@"self.isCellularCallingRightNow"];
    [coder encodeObject:self.statusMessage forKey:@"self.statusMessage"];
    [coder encodeBool:self.doUpdatePresence forKey:@"self.doUpdatePresence"];
    [coder encodeObject:self.updateKey forKey:@"self.updateKey"];
    [coder encodeObject:self.isInBackground forKey:@"self.isInBackground"];
}


+ (instancetype)msgWithUser:(NSString *)user {
    return [[self alloc] initWithUser:user];
}

@end