//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPjCallbacks.h"
#import "PEXZrtpProtocol.h"

@class PEXUserPrivate;
@class PEXPjConfig;
@class PEXToCall;
@class PEXConcurrentHashMap;
@protocol PEXPjCallCallbacks;
@class PEXConcurrentRingQueue;
@class PEXPjRegStatus;
@class CTCall;
@class PEXPjMsgSendAux;

FOUNDATION_EXPORT NSString *PEX_ACTION_SIP_REGISTRATION;
FOUNDATION_EXPORT NSString *PEX_EXTRA_SIP_REGISTRATION;

FOUNDATION_EXPORT NSString * const PEXPjManagerErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXPjStartFailed;
FOUNDATION_EXPORT NSInteger const PEXPjSubCreateFailed;
FOUNDATION_EXPORT NSInteger const PEXPjSubInitFailed;
FOUNDATION_EXPORT NSInteger const PEXPjSubStartFailed;
FOUNDATION_EXPORT NSInteger const PEXPjSubAccAddFailed;

#define PEX_HEADER_BYE_TERMINATION "X-ByeCause"
#define PEX_HEADER_MESSAGE_TYPE "X-MsgType"
enum PEXAuxSipCodes {
    PJSIP_SC_GSM_BUSY = 499
};

// Block using for map enumeration.
typedef void (^pj_completion_block)(pj_status_t status);

@interface PEXPjManager : PEXPjCallbacks<PEXZrtpProtocol>{
    NSMutableDictionary * _pjThreads;
}

@property (nonatomic, readonly) PEXPjRegStatus * regStatus;
@property(nonatomic) PEXPjConfig * configuration;
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) BOOL created;
@property(nonatomic) NSError * lastError;

@property(nonatomic, readonly) PEXConcurrentHashMap * callRegister;
@property(nonatomic, readonly) PEXConcurrentHashMap * callDelegates;

+ (PEXPjManager *)instance;
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;

+(void) pjLogWrapper:(int)level data:(const char *)data len: (int) len;
+(void) logPjError: (NSString *) sender title: (NSString *) title status: (pj_status_t) status;

-(void) updatePrivData: (PEXUserPrivate *) privData;
-(void) registerCallDelegate: (NSNumber *) callId delegate: (id<PEXPjCallCallbacks>) delegate;
-(void) unregisterCallDelegate: (NSNumber *) callId delegate: (id<PEXPjCallCallbacks>) delegate;

-(void) doRegister;
-(void) doUnregister;

/**
* Call to start sip stack.
* Blocking call.
*/
-(int) startStack: (NSError **) pError;

/**
* Call to destroy currently running stack.
* Blocking call.
*/
-(void) cleanDestroy;

/**
* Returns YES if the SIP stack is turned off = no process is running.
*/
-(BOOL) isStackTurnedOff;

/**
 * Main entry point for sending messages through SIP stack.
 */
- (PEXToCall *)sendMessage:(NSString *)callee
                   message:(NSString *)message
                 accountId:(NSNumber *)accountId
                      mime:(NSString *)mime
                 msgTypeId:(PEXPjMsgSendAux *)msgTypeId
                    status:(int *)pStatus
                     error:(NSError **)pError;

/**
* Creates a new call to a given SIP uri.
*/
- (pj_status_t) makeCallTo:(NSString *)destUri;

/**
* Creates a new call to a given SIP uri, returns callId in a second parameter, if is non-NULL.
* Caller should register to this call number in order to receive call state updates if this method returns PJ_SUCCESS.
*/
- (pj_status_t) makeCallTo:(NSString *)destUri callId: (pjsua_call_id *) callId;

/**
* Answers given call number with code 200. Blocking call.
*/
-(pj_status_t) answerCall: (pjsua_call_id) callId;

/**
* Answers given call number with given code. Blocking call.
*/
-(pj_status_t) answerCall: (pjsua_call_id) callId code: (NSUInteger) code;

/**
* General method for answering a call with a given call number.
* If called asynchronously, return value is still PJ_SUCCESS and completion block
* is called upon completion (if non-nil) with return state as a parameter.
* If called synchronously, return value is state of answer call from lower stack.
*/
-(pj_status_t) answerCall: (pjsua_call_id) callId code: (NSUInteger) code async: (BOOL) async completionBlock: (pj_completion_block) completionBlock;

/**
* End all calls in progress.
*/
- (void)endCall;

/**
* Ends call with given call number.
* Always returns PJ_SUCCESS, async call.
*/
-(pj_status_t) endCallWithId: (pjsua_call_id) callId;

/**
* Ends call with given call number. If async call is needed, always returns PJ_SUCCESS.
*/
-(pj_status_t) endCallWithId: (pjsua_call_id) callId async: (BOOL) async;

/**
* Tries to terminate call in progress. Last resort for legal call termination.
*/
-(pj_status_t) terminateCallWithId: (pjsua_call_id) callId async: (BOOL) async completionBlock: (pj_completion_block) completionBlock;

/**
* Call when user verified SAS with remote party for given call id.
*/
-(void) sasVerified: (pjsua_call_id) call_id async: (BOOL) async;

/**
* Call when SAS verification failed with remote party for given call id.
*/
-(void) sasRevoked: (pjsua_call_id) call_id async: (BOOL) async;

/**
* iOS keep-alive handler.
*/
- (void)keepAlive;
- (void)keepAlive: (BOOL) async;
- (void)keepAlive: (BOOL) async completionBlock: (pj_completion_block) completionBlock;

/**
* Call on connectivity recovered event.
*/
-(void) ipChange;

/**
* Calls for re-registration for current account.
*/
-(void) reregister;
-(void) reregister: (BOOL) async;
-(void) reregister: (BOOL) async allowDuringCall: (BOOL) allowCall;
-(void) reregister: (BOOL) async allowDuringCall: (BOOL) allowCall manual: (BOOL) manual;
-(void) resetRegistrationBackoff:(BOOL) async;

-(NSString *) call_secure_media_info: (pjsua_call_id) call_id;

/**
* Switch audio routing to loud speaker or to default.
*/
-(pj_status_t) switchAudioRoutingToLoud: (BOOL) toLoudSpeaker async: (BOOL) async onFinished:(pj_completion_block) onFinished;
-(pj_status_t) muteMicrophone: (BOOL) mute async: (BOOL) async onFinished:(pj_completion_block) onFinished;
-(pj_status_t) switchBluetooth: (BOOL) bluetoothEnabled async: (BOOL) async onFinished:(pj_completion_block) onFinished;

- (BOOL) isHandsfreeDefault;
- (BOOL) micMuted;
- (BOOL) loudSpeakerActive;
- (BOOL) handsfreeActive;

/**
* Set RX TX level on conference bridge according to internal settings.
*/
-(pj_status_t) adjustRxTxAsync: (BOOL) async;

/**
* Play sound during call from a given file.
*/
-(pj_status_t)playSoundDuringCall: (NSString *) sound_file_str;
-(pj_status_t)playSoundDuringCall: (NSString *) sound_file_str async: (BOOL) async;

- (void) pjExecName: (NSString *) name async:(BOOL) async block: (dispatch_block_t) block;

-(NSString *) regWatcherReport;
-(NSString *) regWatcherReportForUI;
-(NSString *) watchdogReport;

/**
 * Warning! Restarts PJSIP, use with care.
 */
-(void) watchdogTrigger;

/**
 * Triggers internal DNS update. Call after connectivity change.
 * This is essential so *async* DNS resolver works. Without valid DNS standard DNS resolver is used.
 */
-(BOOL) updateDNS;

/**
 * Sets DNS resolver retry count and delay.
 */
- (BOOL)setResolverDelay: (unsigned) delay retryCount: (unsigned) retryCount;

/**
 * Set DNS resolver retry count and delay based on whether connectivity is working or not.
 * If connectivity is not working, DNS retrycount is set to 1 to block for maximally 2 seconds.
 */
- (BOOL)setResolverDelay: (BOOL) isConnectivityOn;

/**
 * Called when application settigns were updated by the server.
 */
- (void) onSettingsUpdate: (NSDictionary *) settings privData: (PEXUserPrivate *) privData;

/**
 * Cellular calls change.
 */
- (void) onCellularCall: (CTCall *) call numActiveCalls: (int) numOfActive;
@end