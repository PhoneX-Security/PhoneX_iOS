//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPAutoPing.h"
#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPStream.h"
#import "PEXXMPPPhxPushModule.h"

@class XMPPReconnect;
@class XMPPStream;
@class XMPPAutoPing;
@class XMPPPing;
@class XMPPRoster;
@class XMPPStreamManagement;
@class PEXUserPrivate;
@class XMPPPresence;
@class XMPPRosterMemoryStorage;
@protocol XMPPRosterStorage;
@protocol PEXXmppQueryFinished;
@class PEXPushTokenConfig;

FOUNDATION_EXPORT NSString *PEX_ACTION_XMPP_CONNECTION;
FOUNDATION_EXPORT NSString *PEX_EXTRA_XMPP_CONNECTION;

FOUNDATION_EXPORT NSString * const PEXXMPPManagerErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXXMPPConnectError;
FOUNDATION_EXPORT NSInteger const PEXXMPPDisconnectError;

FOUNDATION_EXPORT NSInteger const PEXNoPrivDataCode;
FOUNDATION_EXPORT NSInteger const PEXAlreadyConnectedCode;
FOUNDATION_EXPORT NSInteger const PEXNotConnectedCode;

/**
* Object handling one particular XMPP connection with a defined user.
*/
@interface PEXXmppManager : NSObject <XMPPStreamDelegate, XMPPReconnectDelegate, XMPPRosterDelegate, XMPPAutoPingDelegate, XMPPPingDelegate, XMPPPhxPushDelegate>
@property(nonatomic, readonly) dispatch_queue_t dispatchQueue;
@property(nonatomic, readonly) BOOL isConnected;

@property(nonatomic, weak) PEXUserPrivate * privData;

/**
* Main XMPP object - xmpp stream, used for receiving and sending packets. Lowest level used.
*/
@property(nonatomic) XMPPStream * xmppStream;

/**
* Presence state sent last time.
*/
@property(nonatomic) XMPPPresence *lastPresence;

/**
 * Resource being used with XMPP client.
 */
@property(nonatomic, readonly) NSString * resourceId;

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;
+ (instancetype)managerWithPrivData:(PEXUserPrivate *)privData;

-(void) doRegister;
-(void) doUnregister;

/**
* iOS keep-alive handler for background run.
*/
-(void) keepAlive;

/**
* Returns YES if XMPP stream is nil or in disconnected state.
*/
-(BOOL) isStreamDisconnected;

/**
 * Triggers reconnection manually in the background.
 */
-(void) triggerReconnect;

/**
* Should be called on login completed event.
* Internally, creates a new XMPP connection. PrivData has to be set
* at the moment of calling this function.
*/
-(pex_status) onLoginCompleted;

-(pex_status) connect;
-(pex_status) connect: (NSError **) pError;

-(pex_status) quit;
-(pex_status) quit: (NSError **) pError;

-(void) sendMessageTo: (NSString *) to body: (NSString *) messageStr;

-(void) updatePrivData: (PEXUserPrivate *) privData;
-(void) trySendPushToken: (PEXPushTokenConfig *) token onFinished: (id<PEXXmppQueryFinished>) onFinished;
-(void) trySendPushReq: (NSString *) jsonEncoded onFinished: (id<PEXXmppQueryFinished>) onFinished;
-(void) trySendPushAck: (NSString *) jsonEncoded onFinished: (id<PEXXmppQueryFinished>) onFinished;

-(NSString *) xmppReport;
-(NSString *) xmppReportForUI;

@end