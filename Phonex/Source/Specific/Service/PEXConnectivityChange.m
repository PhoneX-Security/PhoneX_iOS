//
// Created by Dusan Klinec on 22.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXConnectivityChange.h"


@implementation PEXConnectivityChange {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.xmpp = PEX_CONN_NO_CHANGE;
        self.sip = PEX_CONN_NO_CHANGE;
        self.connection = PEX_CONN_NO_CHANGE;

        self.sipWorks = PEX_CONN_DONT_KNOW;
        self.xmppWorks = PEX_CONN_DONT_KNOW;
        self.connectionWorks = PEX_CONN_DONT_KNOW;

        self.sipWorksPrev = PEX_CONN_DONT_KNOW;
        self.xmppWorksPrev = PEX_CONN_DONT_KNOW;
        self.connectionWorksPrev = PEX_CONN_DONT_KNOW;

        self.recheckIPChange = NO;
        self.networkStatus = NotReachable;
        self.networkStatusPrev = NotReachable;
    }

    return self;
}

- (instancetype)initWithConnection:(PEXConnChangeVal)connection sip:(PEXConnChangeVal)sip xmpp:(PEXConnChangeVal)xmpp {
    self = [self init];
    if (self) {
        self.connection = connection;
        self.sip = sip;
        self.xmpp = xmpp;
    }

    return self;
}


+ (instancetype)changeWithConnection:(PEXConnChangeVal)connection sip:(PEXConnChangeVal)sip xmpp:(PEXConnChangeVal)xmpp {
    return [[self alloc] initWithConnection:connection sip:sip xmpp:xmpp];
}

- (BOOL)isWholeSystemConnected {
    return self.connectionWorks == PEX_CONN_IS_UP && self.sipWorks == PEX_CONN_IS_UP && self.xmppWorks == PEX_CONN_IS_UP;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXConnectivityChange *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.connection = self.connection;
        copy.sip = self.sip;
        copy.xmpp = self.xmpp;
        copy.connectionWorks = self.connectionWorks;
        copy.sipWorks = self.sipWorks;
        copy.xmppWorks = self.xmppWorks;
        copy.connectionWorksPrev = self.connectionWorksPrev;
        copy.sipWorksPrev = self.sipWorksPrev;
        copy.xmppWorksPrev = self.xmppWorksPrev;
        copy.networkStatus = self.networkStatus;
        copy.networkStatusPrev = self.networkStatusPrev;
        copy.recheckIPChange = self.recheckIPChange;
        copy.radioTechnology = self.radioTechnology;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.connection=%d", self.connection];
    [description appendFormat:@", self.sip=%d", self.sip];
    [description appendFormat:@", self.xmpp=%d", self.xmpp];
    [description appendFormat:@", self.connectionWorks=%d", self.connectionWorks];
    [description appendFormat:@", self.sipWorks=%d", self.sipWorks];
    [description appendFormat:@", self.xmppWorks=%d", self.xmppWorks];
    [description appendFormat:@", self.connectionWorksPrev=%d", self.connectionWorksPrev];
    [description appendFormat:@", self.sipWorksPrev=%d", self.sipWorksPrev];
    [description appendFormat:@", self.xmppWorksPrev=%d", self.xmppWorksPrev];
    [description appendFormat:@", self.networkStatus=%ld", (long)self.networkStatus];
    [description appendFormat:@", self.networkStatusPrev=%ld", (long)self.networkStatusPrev];
    [description appendFormat:@", self.recheckIPChange=%d", self.recheckIPChange];
    [description appendFormat:@", self.radioTechnology=%@", self.radioTechnology];
    [description appendString:@">"];
    return description;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToChange:other];
}

- (BOOL)isEqualToChange:(PEXConnectivityChange *)change {
    if (self == change)
        return YES;
    if (change == nil)
        return NO;
    if (self.connection != change.connection)
        return NO;
    if (self.sip != change.sip)
        return NO;
    if (self.xmpp != change.xmpp)
        return NO;
    if (self.connectionWorks != change.connectionWorks)
        return NO;
    if (self.sipWorks != change.sipWorks)
        return NO;
    if (self.xmppWorks != change.xmppWorks)
        return NO;
    if (self.connectionWorksPrev != change.connectionWorksPrev)
        return NO;
    if (self.sipWorksPrev != change.sipWorksPrev)
        return NO;
    if (self.xmppWorksPrev != change.xmppWorksPrev)
        return NO;
    if (self.networkStatus != change.networkStatus)
        return NO;
    if (self.networkStatusPrev != change.networkStatusPrev)
        return NO;
    if (self.recheckIPChange != change.recheckIPChange)
        return NO;
    if (self.radioTechnology != change.radioTechnology && ![self.radioTechnology isEqualToString:change.radioTechnology])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.connection;
    hash = hash * 31u + (NSUInteger) self.sip;
    hash = hash * 31u + (NSUInteger) self.xmpp;
    hash = hash * 31u + (NSUInteger) self.connectionWorks;
    hash = hash * 31u + (NSUInteger) self.sipWorks;
    hash = hash * 31u + (NSUInteger) self.xmppWorks;
    hash = hash * 31u + (NSUInteger) self.connectionWorksPrev;
    hash = hash * 31u + (NSUInteger) self.sipWorksPrev;
    hash = hash * 31u + (NSUInteger) self.xmppWorksPrev;
    hash = hash * 31u + (NSUInteger) self.networkStatus;
    hash = hash * 31u + (NSUInteger) self.networkStatusPrev;
    hash = hash * 31u + self.recheckIPChange;
    hash = hash * 31u + [self.radioTechnology hash];
    return hash;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.connection = (PEXConnChangeVal) [coder decodeIntForKey:@"self.connection"];
        self.sip = (PEXConnChangeVal) [coder decodeIntForKey:@"self.sip"];
        self.xmpp = (PEXConnChangeVal) [coder decodeIntForKey:@"self.xmpp"];
        self.connectionWorks = (PEXConnWorksVal) [coder decodeIntForKey:@"self.connectionWorks"];
        self.sipWorks = (PEXConnWorksVal) [coder decodeIntForKey:@"self.sipWorks"];
        self.xmppWorks = (PEXConnWorksVal) [coder decodeIntForKey:@"self.xmppWorks"];
        self.connectionWorksPrev = (PEXConnWorksVal) [coder decodeIntForKey:@"self.connectionWorksPrev"];
        self.sipWorksPrev = (PEXConnWorksVal) [coder decodeIntForKey:@"self.sipWorksPrev"];
        self.xmppWorksPrev = (PEXConnWorksVal) [coder decodeIntForKey:@"self.xmppWorksPrev"];
        self.networkStatus = (NetworkStatus) [coder decodeIntForKey:@"self.networkStatus"];
        self.networkStatusPrev = (NetworkStatus) [coder decodeIntForKey:@"self.networkStatusPrev"];
        self.recheckIPChange = [coder decodeBoolForKey:@"self.recheckIPChange"];
        self.radioTechnology = [coder decodeObjectForKey:@"self.radioTechnology"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.connection forKey:@"self.connection"];
    [coder encodeInt:self.sip forKey:@"self.sip"];
    [coder encodeInt:self.xmpp forKey:@"self.xmpp"];
    [coder encodeInt:self.connectionWorks forKey:@"self.connectionWorks"];
    [coder encodeInt:self.sipWorks forKey:@"self.sipWorks"];
    [coder encodeInt:self.xmppWorks forKey:@"self.xmppWorks"];
    [coder encodeInt:self.connectionWorksPrev forKey:@"self.connectionWorksPrev"];
    [coder encodeInt:self.sipWorksPrev forKey:@"self.sipWorksPrev"];
    [coder encodeInt:self.xmppWorksPrev forKey:@"self.xmppWorksPrev"];
    [coder encodeInt:self.networkStatus forKey:@"self.networkStatus"];
    [coder encodeInt:self.networkStatusPrev forKey:@"self.networkStatusPrev"];
    [coder encodeBool:self.recheckIPChange forKey:@"self.recheckIPChange"];
    [coder encodeObject:self.radioTechnology forKey:@"self.radioTechnology"];
}


@end