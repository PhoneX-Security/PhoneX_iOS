//
// Created by Dusan Klinec on 18.03.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXXMPPPhxPushModule.h"

@protocol PEXXmppQueryFinished;
@class PEXXMPPPhxPushModule;
@class XMPPIQ;
@class PEXXMPPPhxPushInfo;

/**
* Simple holder for sending XMPP IQs to the server.
* Holds packetId, number of send attempts (expiration), flag whether packet should be re-sent on connectivity recovery.
*/
@interface PEXXMPPSimplePacketSendRecord : NSObject

/**
 * Last valid packet Id.
 * Important for tracking responses.
 */
@property (nonatomic) NSString * packetId;

/**
 * Number of attempts to send the record.
 */
@property (nonatomic) int sentCount;

/**
 * YES if sending should be kicked-off as connectivity restores.
 */
@property (nonatomic) BOOL tryAfterConnectivityOn;

/**
 * If set to YES, record was finished sucessfully.
 */
@property (nonatomic) BOOL doneFlag;

/**
 * Callback delegate.
 */
@property (nonatomic) id<PEXXmppQueryFinished> onFinishedHandler;

/**
 * Last set completion handler.
 */
@property (nonatomic, copy) PEXXmppPushCompletion completionHandler;

/**
 * YES if the request is being sent.
 */
@property (nonatomic) BOOL sending;

/**
 * Request data, filled by user. Arbitrary object to differentiate.
 */
@property (nonatomic) id auxData;

/**
 * User object. Usually data source.
 */
@property (nonatomic) id usrData;

/**
 * Date of a new attempt
 */
@property (nonatomic) NSDate * sendStarted;

/**
 * Weak reference on the current sending query info / packet tracer.
 */
@property (nonatomic, weak) PEXXMPPPhxPushInfo * queryInfo;

/**
 * Sender from the last response, set by -(void)storeLastResult
 */
@property (nonatomic, readonly, weak) PEXXMPPPhxPushModule * sender;

/**
 * IQ response set in the last response handler, set by -(void)storeLastResult
 */
@property (nonatomic, readonly) XMPPIQ * response;

/**
 * Query info / packet tracer from the last response, set by -(void)storeLastResult
 */
@property (nonatomic, readonly) PEXXMPPPhxPushInfo * trackingInfo;

- (instancetype)initSentinel;
- (instancetype)initWithPacketId:(NSString *)packetId;
+ (instancetype)recordWithPacketId:(NSString *)packetId;
- (BOOL) isFinished;

/**
 * Prepares for next resend.
 */
-(void) resetForNextSending;

/**
 * Stores last result for the query.
 */
-(void) storeLastResult: (PEXXMPPPhxPushModule *)sender response:(XMPPIQ *)resp withInfo:(PEXXMPPPhxPushInfo *)info;

/**
 * Call when request failed.
 * Triggers completion handler.
 * Synchronizes on self while setting internal properties. Not synchronized on calling completionHandler.
 */
-(void) onFail;

/**
 * Call when request succeeds.
 * Triggers completion handler.
 * Synchronizes on self while setting internal properties. Not synchronized on calling completionHandler.
 */
-(void) onSuccess;

- (NSString *)description;
@end