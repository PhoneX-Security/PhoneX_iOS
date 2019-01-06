//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "XMPPInternal.h"
#import "PEXXMPPPhxPushModule.h"
#import "NSXMLElement+XMPP.h"
#import "XMPPIDTracker.h"
#import "XMPPIQ.h"
#import "XMPPInternal.h"
#import "DDXML.h"
#import "XMPPStream.h"
#import "NSXMLElement+XMPP.h"
#import "PEXService.h"
#import "PEXXMPPSimplePacketSendRecord.h"
#import "PEXXmppQueryFinished.h"
#import "PEXXmppPhxPushInfo.h"
#import "PEXXmppPhxPushInfo.h"
#import "PEXPushTokenConfig.h"
#import "PEXAppVersionUtils.h"
#import "PEXUtils.h"
#import "PEXMessageDigest.h"
#import "PEXOpenUDID.h"

#define DEFAULT_TIMEOUT 30.0 // seconds

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation PEXXMPPPhxPushModule

- (id)init
{
    return [self initWithDispatchQueue:NULL];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue
{
    if ((self = [super initWithDispatchQueue:queue]))
    {
        respondsToQueries = YES;
    }
    return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    if ([super activate:aXmppStream])
    {
#ifdef _XMPP_CAPABILITIES_H
		[xmppStream autoAddDelegate:self delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
#endif

        packetIdTracker = [[XMPPIDTracker alloc] initWithDispatchQueue:moduleQueue];

        return YES;
    }

    return NO;
}

- (void)deactivate
{
#ifdef _XMPP_CAPABILITIES_H
	[xmppStream removeAutoDelegate:self delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
#endif

    dispatch_block_t block = ^{ @autoreleasepool {

        [packetIdTracker removeAllIDs];
        packetIdTracker = nil;

    }};

    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);

    [super deactivate];
}

- (BOOL)respondsToQueries
{
    if (dispatch_get_specific(moduleQueueTag))
    {
        return respondsToQueries;
    }
    else
    {
        __block BOOL result;

        dispatch_sync(moduleQueue, ^{
            result = respondsToQueries;
        });
        return result;
    }
}

- (void)setRespondsToQueries:(BOOL)flag
{
    dispatch_block_t block = ^{

        if (respondsToQueries != flag)
        {
            respondsToQueries = flag;

#ifdef _XMPP_CAPABILITIES_H
			@autoreleasepool {
				// Capabilities may have changed, need to notify others.
				[xmppStream resendMyPresence];
			}
		#endif
        }
    };

    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

// ---------------------------------------------
#pragma mark - XMPP Query helpers
// ---------------------------------------------

- (PEXXMPPPhxPushInfo *)generateQueryIDWithTimeout:(NSTimeInterval)timeout
                               queryType: (PEXXmppQueryType) queryType
                       completionHandler: (PEXXmppPushCompletion) completionHandler

{
    // This method may be invoked on any thread/queue.
    // Generate unique ID for Ping packet
    // It's important the ID be unique as the ID is the only thing that distinguishes a pong packet
    NSString *pingID = [xmppStream generateUUID];

    PEXXMPPPhxPushInfo * queryInfo = nil;
    if (queryType == PEX_XMPP_QUERY_PUSH){
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handlePushQuery:withInfo:)
                                                       timeout:timeout];

    } else if (queryType == PEX_XMPP_QUERY_PRESENCE) {
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handlePresenceQuery:withInfo:)
                                                       timeout:timeout];

    } else if (queryType == PEX_XMPP_QUERY_ACTIVE){
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handleActiveQuery:withInfo:)
                                                       timeout:timeout];

    } else if (queryType == PEX_XMPP_SET_TOKEN){
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handleSetToken:withInfo:)
                                                       timeout:timeout];

    } else if (queryType == PEX_XMPP_PUSH_ACK){
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handlePushAck:withInfo:)
                                                       timeout:timeout];

    } else if (queryType == PEX_XMPP_PUSH_REQ){
        queryInfo = [[PEXXMPPPhxPushInfo alloc] initWithTarget:self
                                                      selector:@selector(handlePushReq:withInfo:)
                                                       timeout:timeout];
    } else {
        DDLogError(@"Unknown query type");
        [NSException raise:PEXRuntimeException format:@"Unknown XMPP IQ query type: %d", (int)queryType];
        return nil;
    }

    queryInfo.completionHandler = completionHandler;
    queryInfo.packetId = pingID;
    queryInfo.qType = queryType;
    return queryInfo;
}

-(void) addToPacketTracer: (PEXXMPPPhxPushInfo *) queryInfo{
    // Add to the tracker in the module queue.
    dispatch_async(moduleQueue, ^{ @autoreleasepool {
        [packetIdTracker addID:queryInfo.packetId trackingInfo:queryInfo];
    }});
}

-(void) sendIq:(XMPPIQ *) iq {
    dispatch_async(moduleQueue, ^{ @autoreleasepool {
        [xmppStream sendElement:iq];
    }});
}

-(void) sendQuery:(PEXXMPPPhxPushInfo *) queryInfo{
    dispatch_async(moduleQueue, ^{ @autoreleasepool {
        [packetIdTracker addID:queryInfo.packetId trackingInfo:queryInfo];
        [xmppStream sendElement:queryInfo.iq];
    }});
}

// ---------------------------------------------
#pragma mark - XMPP Query API
// ---------------------------------------------

- (PEXXMPPPhxPushInfo *)preparePresenceQuery: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_QUERY_PRESENCE
                                                    completionHandler:completionHandler];
    // Send packet
    //
    // <iq type="get" id="pingID">
    //   <presenceQuery xmlns="urn:xmpp:phx"/>
    // </iq>

    NSXMLElement *root = [NSXMLElement elementWithName:@"presenceQuery" xmlns:@"urn:xmpp:phx"];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

- (PEXXMPPPhxPushInfo *)preparePushQuery: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_QUERY_PUSH
                                                    completionHandler:completionHandler];

    // Send packet
    //
    // <iq type="get" id="pingID">
    //   <pushQuery xmlns="urn:xmpp:phx"/>
    // </iq>

    NSXMLElement *root = [NSXMLElement elementWithName:@"pushQuery" xmlns:@"urn:xmpp:phx"];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"get" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

- (PEXXMPPPhxPushInfo *)prepareCurrentActiveQuery: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_QUERY_ACTIVE
                                                    completionHandler:completionHandler];

    // Send packet
    //
    // <iq type="set" id="pingID">
    //   <active xmlns="urn:xmpp:phxAct"/>
    // </iq>

    PEXService * svc = [PEXService instance];
    BOOL inBg = [svc isInBackground];

    NSXMLElement *root = [NSXMLElement elementWithName: inBg ? @"inactive" : @"active" xmlns:@"urn:xmpp:phxClient"];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

- (PEXXMPPPhxPushInfo *)preparePushTokenQuery:(PEXPushTokenConfig *)token completionHandler: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_SET_TOKEN
                                                    completionHandler:completionHandler];

    // Send packet
    //
    // <iq type="set" id="packetId">
    //   <config xmlns="urn:xmpp:ppush">
    //     <version>1</version>
    //     <json>{"platform":"ios","token":"0f34819381000405","version":"1","app_version":"1.3.1","os_version":"8.4", "langs":["cs", "en"], "debug":1}</json>
    //   </config>
    // </iq>

    NSString * jsonString = [PEXXMPPPhxPushModule generateTokenJson:token];
    NSXMLElement *root = [NSXMLElement elementWithName: @"config" xmlns:@"urn:xmpp:ppush"];
    NSXMLElement *version = [NSXMLElement elementWithName:@"version" stringValue:@"1"];
    NSXMLElement *json = [NSXMLElement elementWithName:@"json" stringValue:jsonString];

    [root addChild:version];
    [root addChild:json];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

- (PEXXMPPPhxPushInfo *)preparePushRequestQuery:(NSString *)jsonString completionHandler: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_PUSH_REQ
                                                    completionHandler:completionHandler];

    // Send packet
    //
    // <iq type="set" id="pingID">
    //   <req xmlns="urn:xmpp:ppush">
    //     <version>1</version>
    //     <json></json>
    //   </req>
    // </iq>

    NSXMLElement *root = [NSXMLElement elementWithName: @"req" xmlns:@"urn:xmpp:ppush"];
    NSXMLElement *version = [NSXMLElement elementWithName:@"version" stringValue:@"1"];
    NSXMLElement *json = [NSXMLElement elementWithName:@"json" stringValue:jsonString];

    [root addChild:version];
    [root addChild:json];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

- (PEXXMPPPhxPushInfo *)preparePushAckQuery:(NSString *)jsonString completionHandler: (PEXXmppPushCompletion) completionHandler {
    // This is a public method.
    // It may be invoked on any thread/queue.
    PEXXMPPPhxPushInfo * queryInfo = [self generateQueryIDWithTimeout:DEFAULT_TIMEOUT
                                                            queryType:PEX_XMPP_PUSH_ACK
                                                    completionHandler:completionHandler];

    // Send packet
    //
    // <iq type="set" id="pushAck">
    //   <ack xmlns="urn:xmpp:ppush">
    //     <version>1</version>
    //     <json></json>
    //   </ack>
    // </iq>

    NSXMLElement *root = [NSXMLElement elementWithName: @"ack" xmlns:@"urn:xmpp:ppush"];
    NSXMLElement *version = [NSXMLElement elementWithName:@"version" stringValue:@"1"];
    NSXMLElement *json = [NSXMLElement elementWithName:@"json" stringValue:jsonString];

    [root addChild:version];
    [root addChild:json];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:nil elementID:queryInfo.packetId child:root];
    queryInfo.iq = iq;

    return queryInfo;
}

+ (NSString *)generateTokenJson:(PEXPushTokenConfig *) token {

    NSString * const appVersionString = [PEXAppVersionUtils fullVersionString];
    NSString * const systemVersionString = [[UIDevice currentDevice] systemVersion];
    NSArray * langs = [NSLocale preferredLanguages];
    if (langs == nil){
        langs = [[NSArray alloc] init];
    }

    // Get language set in the application, merge with the system language list.
    NSString * curAppLang = [PEXResStrings getCurrentAppLanguage];
    if (![PEXUtils isEmpty:curAppLang] && ![PEX_LANGUAGE_SYSTEM isEqualToString:curAppLang]){
        NSMutableArray * newLang = [NSMutableArray arrayWithCapacity:[langs count] + 1];
        [newLang addObject:curAppLang];

        for(NSString * sysLang in langs){
            if ([curAppLang isEqualToString:sysLang]){
                continue;
            }

            [newLang addObject:sysLang];
        }

        langs = [NSArray arrayWithArray:newLang];
    }

    NSDictionary* info = @{
            @"version"      : @(1),
            @"platform"     : @"ios",
            @"tstamp"       : @((long) ([token.whenCreated timeIntervalSince1970] * 1000.0)),
            @"token"        : [PEXMessageDigest bytes2hex:token.token],
            @"fudid"        : [PEXOpenUDID value],
            @"os_version"   : systemVersionString,
            @"debug"        : @([PEXUtils isDebug]),
            @"langs"        : langs,
            @"app_version"  : appVersionString};

    NSError * err = nil;
    NSData * jsonData = nil;
    NSString * jsonReturn = nil;

    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:info options:0 error:&err];
        jsonReturn = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    } @catch(NSException *e){
        DDLogError(@"Exception in JSON entity encoding: %@", info);
        return nil;
    }

    if (err != nil){
        DDLogError(@"Error during building JSON entity from: %@", info);
        return nil;
    }

    if (jsonData == nil || jsonReturn == nil){
        DDLogError(@"JSON entity empty from: %@", info);
        return nil;
    }

    return jsonReturn;
}

// ---------------------------------------------
#pragma mark - XMPP Query response handlers
// ---------------------------------------------

- (void)handlePushQuery:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppPushQuery:self response:respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

- (void)handlePresenceQuery:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppPresenceQuery:self response:respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

- (void)handleActiveQuery:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppActiveQuery:self response: respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

- (void)handleSetToken:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppSetToken:self response:respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

- (void)handlePushAck:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppPushAck:self response:respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

- (void)handlePushReq:(XMPPIQ *)respIQ withInfo:(PEXXMPPPhxPushInfo *)packetInfo
{
    [multicastDelegate xmppPushReq:self response:respIQ withInfo:packetInfo];
    if (packetInfo && packetInfo.completionHandler){
        packetInfo.completionHandler(packetInfo, respIQ);
    }
}

// ---------------------------------------------
#pragma mark - XMPP stream
// ---------------------------------------------

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    // This method is invoked on the moduleQueue.

    NSString *type = [iq type];

    if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"])
    {
        // Example:
        //
        // <iq from="deusty.com" to="robbiehanson@deusty.com/work" id="abc123" type="result"/>

        // If this is a response to a ping that we've sent,
        // then the packetIdTracker will invoke our handlePong:withInfo: method and return YES.

        return [packetIdTracker invokeForID:[iq elementID] withObject:iq];
    }
    else if (respondsToQueries && [type isEqualToString:@"get"])
    {
        // Example:
        //
        // <iq from="deusty.com" to="robbiehanson@deusty.com/work" id="zhq325" type="get">
        //   <push xmlns="urn:xmpp:phx" version="1">
        //     <json><![CDATA[{msg: "test"}]]></json>
        //   </push>
        // </iq>

        NSXMLElement *push = [iq elementForName:@"push" xmlns:@"urn:xmpp:phx"];
        if (push == nil) {
            return NO;
        }

        // Parse packet, extract version & json attributes.
        NSNumber * version  = [push attributeNumberInt32ValueForName:@"version"];
        NSXMLElement * json = [push elementForName:@"json"];
        if (version == nil || [version integerValue] != 1 || json == nil){
            XMPPIQ * resp = [XMPPIQ iqWithType:@"error" to:[iq from] elementID:[iq elementID]];
            [sender sendElement:resp];
            return YES;
        }

        // Give push to the push parser for processing.
        NSString * jsonText = [json stringValue];
        [multicastDelegate xmppPushReceived:self msg:iq json:jsonText];

        // Send response so we dont receive same push message all the time (ACK).
        XMPPIQ * resp = [XMPPIQ iqWithType:@"result" to:[iq from] elementID:[iq elementID]];
        [sender sendElement:resp];
        return YES;
    }

    return NO;
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    [packetIdTracker removeAllIDs];
}

#ifdef _XMPP_CAPABILITIES_H
/**
 * If an XMPPCapabilites instance is used we want to advertise our support for ping.
**/
- (void)xmppCapabilities:(XMPPCapabilities *)sender collectingMyCapabilities:(NSXMLElement *)query
{
	// This method is invoked on the moduleQueue.

	if (respondsToQueries)
	{
		// <query xmlns="http://jabber.org/protocol/disco#info">
		//   ...
		//   <feature var="urn:xmpp:phx"/>
		//   ...
		// </query>

		NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
		[feature addAttributeWithName:@"var" stringValue:@"urn:xmpp:phx"];
		[query addChild:feature];

		NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
		[feature addAttributeWithName:@"var" stringValue:@"urn:xmpp:phxClient"];
		[query addChild:feature];

		NSXMLElement *feature = [NSXMLElement elementWithName:@"feature"];
		[feature addAttributeWithName:@"var" stringValue:@"urn:xmpp:ppush"];
		[query addChild:feature];
	}
}
#endif

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

