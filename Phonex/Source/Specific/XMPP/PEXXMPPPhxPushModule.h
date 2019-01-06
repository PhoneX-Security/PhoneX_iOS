//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPModule.h"

@class XMPPIDTracker;
@class XMPPIQ;
@class PEXXMPPPhxPushInfo;
@class PEXPushTokenConfig;

/**
 * Completion handler type for XMPP record send.
 */
typedef void (^PEXXmppPushCompletion)(PEXXMPPPhxPushInfo * info, XMPPIQ * response);

/**
* PhoneX XMPP push module, handles urn:xmpp:phx namespace, in particular,
* Server message "push", containing JSON encoded push messages to client, acknowledged by IQ result packet.
* Client request pushQuery, asking server to send most recent stored "push" messages.
* Client request presenceQuery, asking server to send all presence information about contacts stored in our roster.
*/
@interface PEXXMPPPhxPushModule : XMPPModule
{
    BOOL respondsToQueries;
    XMPPIDTracker *packetIdTracker;
}

/**
* SEND: <iq id="<returned_string>" type="get" .../>
* RECV: <iq id="<returned_string>" type="result" .../>
*
* This may be helpful if you are sending multiple simultaneous pings to the same target.
**/

/**
 * Sends prepared query to the server.
 * Assigns info object to packet tracer and sends the IQ data in the info structure.
 */
-(void) sendQuery:(PEXXMPPPhxPushInfo *) queryInfo;

/**
* Sends Push query to the server asking for all recent push notifications.
* <iq type="get" id="pingID">
*   <pushQuery xmlns="urn:xmpp:phx"/>
* </iq>
*/
- (PEXXMPPPhxPushInfo *)preparePushQuery: (PEXXmppPushCompletion) completionHandler;

/**
* Sends Presence query to the server asking for all presence updates related to the user's roster.
* <iq type="get" id="pingID">
*   <presenceQuery xmlns="urn:xmpp:phx"/>
* </iq>
*
*/
- (PEXXMPPPhxPushInfo *)preparePresenceQuery: (PEXXmppPushCompletion) completionHandler;

/**
* Sends current client state to the server. Can be either active or inactive.
* <iq type="set" id="pingID">
*   <active xmlns="urn:xmpp:phxClient"/>
* </iq>
*/
- (PEXXMPPPhxPushInfo *)prepareCurrentActiveQuery: (PEXXmppPushCompletion) completionHandler;

/**
* Sends given token configuration to the server.
*/
- (PEXXMPPPhxPushInfo *)preparePushTokenQuery:(PEXPushTokenConfig *)token completionHandler: (PEXXmppPushCompletion) completionHandler;

/**
 * Sends json-encoded push request to the server.
 */
- (PEXXMPPPhxPushInfo *)preparePushRequestQuery:(NSString *)jsonString completionHandler: (PEXXmppPushCompletion) completionHandler;

/**
 * Sends json-encoded push ack to the server.
 */
- (PEXXMPPPhxPushInfo *)preparePushAckQuery:(NSString *)jsonString completionHandler: (PEXXmppPushCompletion) completionHandler;

/**
* Helper utility method to generate JSON token configuration for push message from token configuration.
*/
+ (NSString *)generateTokenJson:(PEXPushTokenConfig *) token;
@end

/**
* Delegate responsible for processing push message received from server and query client messages sending state changes.
*/
@protocol XMPPPhxPushDelegate
@optional
- (void)xmppPushReceived: (PEXXMPPPhxPushModule *) sender msg: (XMPPIQ *) msg json: (NSString *) json;
- (void)xmppPresenceQuery:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo;
- (void)xmppPushQuery:(PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo;
- (void)xmppActiveQuery: (PEXXMPPPhxPushModule *) sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo;
- (void)xmppSetToken: (PEXXMPPPhxPushModule *) sender response: (XMPPIQ *) resp withInfo:(PEXXMPPPhxPushInfo *)pingInfo;
- (void)xmppPushReq: (PEXXMPPPhxPushModule *) sender response: (XMPPIQ *) resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo;
- (void)xmppPushAck: (PEXXMPPPhxPushModule *) sender response: (XMPPIQ *) resp withInfo:(PEXXMPPPhxPushInfo *)packetInfo;
// Note: If the xmpp stream is disconnected, no delegate methods will be called, and outstanding pings are forgotten.
@end
