//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
* Capabilities.
*/
FOUNDATION_EXPORT NSString * CAP_SIP DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_XMPP DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_XMPP_PRESENCE DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_XMPP_MESSAGES DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL DEPRECATED_ATTRIBUTE;
// Message protocol v1 - S/MIME
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_MESSAGES_1 DEPRECATED_ATTRIBUTE;
// Message protocol v2 - based on protocol buffers
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_MESSAGES_2 DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_MESSAGES_2_1 DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_MESSAGES_2_2;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_FILETRANSFER DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_FILETRANSFER_1 DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PROTOCOL_FILETRANSFER_2 DEPRECATED_ATTRIBUTE;
FOUNDATION_EXPORT NSString * CAP_PUSH;

@interface PEXPhonexSettings : NSObject

/**
* Returns array of strings - all capabilities supported in this version.
* Is broadcasted via push notifications for other users so they know
* which features we support.
*/
+(NSSet *) getCapabilities;

/**
* Returns true if multiple calls are allowed to be made.
*/
+(BOOL) supportMultipleCalls;

/**
* Returns true if it is allowed to connect incoming calls between each other.
*
* Warning! Using this mode of operation can have security consequences.
* One hub can control communication of others, forge it or selective drop.
* This role should have only a trusted server and new crypto protocol for
* correctness have to be employed. Secure option is to establish 1:1 communication
* link between each participants in a conference. Better solution is to use
* conference keying protocol and use server as a simple replay server. Server
* would not see data (no crypto keys on server), randomized selective dropping checks,
* rekeying.
*
* Benefit is users can group themselves into clusters (multiple hubs).
*/
+ (BOOL)multipleCallsMixingAllowed;

/**
* If YES, certificate of a particular user is checked when user becomes online after a while no
* matter if certificate freshness is OK.
*/
+ (BOOL)checkCertificateOnBecomeOnlineEvent;

/**
* If YES, cellular calls are taken into account for BUSY state and for incoming call.
* On iOS some cellular updates are lost and sometimes also active cellular call records are outdated
* what leads to situations when contact is busy, cannot be called but in fact he is not calling at the moment and
* should be reachable. For better usability better disable cellular calls integration for now.
*/
+ (BOOL) takeCellularCallsToBusyState;
@end