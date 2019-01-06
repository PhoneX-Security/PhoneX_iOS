//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPresenceState.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXUtils.h"


@implementation PEXPresenceState {

}

- (instancetype)initWithUser:(NSString *)user {
    self = [super init];
    if (self) {
        self.user = user;
    }

    return self;
}

+ (instancetype)stateWithUser:(NSString *)user {
    return [[self alloc] initWithUser:user];
}


- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToState:other];
}

- (BOOL)isEqualToState:(PEXPresenceState *)state {
    if (self == state)
        return YES;
    if (state == nil)
        return NO;
    if (self.isAvailable != state.isAvailable && ![PEXUtils areNSNumbersEqual:_isAvailable b:state.isAvailable])
        return NO;
    if (self.user != state.user && [PEXUtils areNSStringsEqual:_user b:state.user])
        return NO;
    if (self.statusId != state.statusId && ![PEXUtils areNSNumbersEqual:_statusId b:state.statusId])
        return NO;
    if (self.sipRegistered != state.sipRegistered && ![PEXUtils areNSNumbersEqual:_sipRegistered b:state.sipRegistered])
        return NO;
    if (self.isCallingRightNow != state.isCallingRightNow && ![PEXUtils areNSNumbersEqual:_isCallingRightNow b:state.isCallingRightNow])
        return NO;
    if (self.isCellularCallingRightNow != state.isCellularCallingRightNow && ![PEXUtils areNSNumbersEqual:_isCellularCallingRightNow b:state.isCellularCallingRightNow])
        return NO;
    if (self.isInBackground != state.isInBackground && ![PEXUtils areNSNumbersEqual:_isInBackground b:state.isInBackground])
        return NO;
    if (self.statusMessage != state.statusMessage && ![PEXUtils areNSStringsEqual:_statusMessage b:state.statusMessage])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.isAvailable hash];
    hash = hash * 31u + [self.user hash];
    hash = hash * 31u + [self.statusId hash];
    hash = hash * 31u + [self.sipRegistered hash];
    hash = hash * 31u + [self.isCallingRightNow hash];
    hash = hash * 31u + [self.isCellularCallingRightNow hash];
    hash = hash * 31u + [self.isInBackground hash];
    hash = hash * 31u + [self.statusMessage hash];
    hash = hash * 31u + [self.lastUpdate hash];
    return hash;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.isAvailable = [coder decodeObjectForKey:@"self.isAvailable"];
        self.user = [coder decodeObjectForKey:@"self.user"];
        self.statusId = [coder decodeObjectForKey:@"self.statusId"];
        self.sipRegistered = [coder decodeObjectForKey:@"self.sipRegistered"];
        self.isCallingRightNow = [coder decodeObjectForKey:@"self.isCallingRightNow"];
        self.isCellularCallingRightNow = [coder decodeObjectForKey:@"self.isCellularCallingRightNow"];
        self.isInBackground = [coder decodeObjectForKey:@"self.isInBackground"];
        self.statusMessage = [coder decodeObjectForKey:@"self.statusMessage"];
        self.lastUpdate = [coder decodeObjectForKey:@"self.lastUpdate"];
        self.lastUpdateTime = [coder decodeObjectForKey:@"self.lastUpdateTime"];
        self.lastUpdateSendTime = [coder decodeObjectForKey:@"self.lastUpdateSendTime"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.isAvailable forKey:@"self.isAvailable"];
    [coder encodeObject:self.user forKey:@"self.user"];
    [coder encodeObject:self.statusId forKey:@"self.statusId"];
    [coder encodeObject:self.sipRegistered forKey:@"self.sipRegistered"];
    [coder encodeObject:self.isCallingRightNow forKey:@"self.isCallingRightNow"];
    [coder encodeObject:self.isCellularCallingRightNow forKey:@"self.isCellularCallingRightNow"];
    [coder encodeObject:self.isInBackground forKey:@"self.isInBackground"];
    [coder encodeObject:self.statusMessage forKey:@"self.statusMessage"];
    [coder encodeObject:self.lastUpdate forKey:@"self.lastUpdate"];
    [coder encodeObject:self.lastUpdateTime forKey:@"self.lastUpdateTime"];
    [coder encodeObject:self.lastUpdateSendTime forKey:@"self.lastUpdateSendTime"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPresenceState *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.isAvailable = self.isAvailable;
        copy.user = self.user;
        copy.statusId = self.statusId;
        copy.sipRegistered = self.sipRegistered;
        copy.isCallingRightNow = self.isCallingRightNow;
        copy.isCellularCallingRightNow = self.isCellularCallingRightNow;
        copy.isInBackground = self.isInBackground;
        copy.statusMessage = self.statusMessage;
        copy.lastUpdate = self.lastUpdate;
        copy.lastUpdateTime = self.lastUpdateTime;
        copy.lastUpdateSendTime = self.lastUpdateSendTime;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.isAvailable=%@", self.isAvailable];
    [description appendFormat:@", self.user=%@", self.user];
    [description appendFormat:@", self.statusId=%@", self.statusId];
    [description appendFormat:@", self.sipRegistered=%@", self.sipRegistered];
    [description appendFormat:@", self.isCallingRightNow=%@", self.isCallingRightNow];
    [description appendFormat:@", self.isCellularCallingRightNow=%@", self.isCellularCallingRightNow];
    [description appendFormat:@", self.isInBackground=%@", self.isInBackground];
    [description appendFormat:@", self.statusMessage=%@", self.statusMessage];
    [description appendFormat:@", self.lastUpdate=%@", self.lastUpdate];
    [description appendFormat:@", self.lastUpdateTime=%@", self.lastUpdateTime];
    [description appendFormat:@", self.lastUpdateSendTime=%@", self.lastUpdateSendTime];
    [description appendString:@">"];
    return description;
}


@end