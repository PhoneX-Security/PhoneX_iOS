//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "XMPPIDTracker.h"
#include "PEXXmppPhxPushInfo.h"

@implementation PEXXMPPPhxPushInfo

@synthesize timeSent;

- (id)initWithTarget:(id)aTarget selector:(SEL)aSelector timeout:(NSTimeInterval)aTimeout
{
    if ((self = [super initWithTarget:aTarget selector:aSelector timeout:aTimeout]))
    {
        timeSent = [[NSDate alloc] init];
    }
    return self;
}

- (NSTimeInterval)rtt
{
    return [timeSent timeIntervalSinceNow] * -1.0;
}

- (NSString *)qTypeToString {
    switch(self.qType){
        case PEX_XMPP_QUERY_PUSH:
            return @"push";
        case PEX_XMPP_QUERY_PRESENCE:
            return @"queryPresence";
        case PEX_XMPP_QUERY_ACTIVE:
            return @"active";
        case PEX_XMPP_SET_TOKEN:
            return @"setToken";
        case PEX_XMPP_PUSH_ACK:
            return @"pushAck";
        case PEX_XMPP_PUSH_REQ:
            return @"pushReq";
        default: return @"UNKNOWN";
    }
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.iq=%@", self.iq];
    [description appendFormat:@", self.packetId=%@", self.packetId];
    [description appendFormat:@", self.qType=%@", [self qTypeToString]];
    [description appendString:@">"];
    return description;
}


@end