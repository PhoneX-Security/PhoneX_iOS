//
// Created by Dusan Klinec on 10.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//


#ifndef __PEXXmppPhxPushInfo_H_
#define __PEXXmppPhxPushInfo_H_

#import "XMPPIDTracker.h"
#import "PEXXMPPPhxPushModule.h"

typedef enum : NSInteger{
    PEX_XMPP_QUERY_PUSH = 0,
    PEX_XMPP_QUERY_PRESENCE,
    PEX_XMPP_QUERY_ACTIVE,
    PEX_XMPP_SET_TOKEN,
    PEX_XMPP_PUSH_ACK,
    PEX_XMPP_PUSH_REQ,
} PEXXmppQueryType;

/**
 * Extension of XMPPBasicTrackingInfo, helps in tracking sending status of the XMPP IQ.
 */
@interface PEXXMPPPhxPushInfo : XMPPBasicTrackingInfo
{
    NSDate *timeSent;
}

@property (nonatomic) PEXXmppQueryType qType;
@property (nonatomic, readonly) NSDate *timeSent;

/**
 * Mesage body
 */
@property (nonatomic) XMPPIQ * iq;

/**
 * Packet ID
 */
@property (nonatomic) NSString * packetId;

/**
 * Completion handler for this particular request.
 */
@property (nonatomic, copy) PEXXmppPushCompletion completionHandler;

- (NSTimeInterval)rtt;
- (NSString *) qTypeToString;

- (NSString *)description;
@end

#endif //__PEXXmppPhxPushInfo_H_
