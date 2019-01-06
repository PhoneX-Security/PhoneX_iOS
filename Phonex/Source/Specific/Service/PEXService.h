//
// Created by Dusan Klinec on 01.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXReachability.h"

@class PEXXmppCenter;
@class PEXPjManager;
@class PEXMessageManager;
@class PEXUserPrivate;
@class PEXCertificateUpdateManager;
@class PEXFirewall;
@class PEXPresenceCenter;
@class PEXReachability;
@class PEXConnectivityChange;
@class PEXSingleLoginWatcher;
@class CTCallCenter;
@class CTTelephonyNetworkInfo;
@class PEXDhKeyGenManager;
@class PEXVersionChecker;
@class PEXFtTransferManager;
@class PEXXMPPPhxPushModule;
@class PEXPushManager;
@class PEXDbWatchdog;
@class PEXApplicationStateChange;
@class PEXPaymentManager;
@class PEXFileSecurityManager;

/**
* State enum for init state property of the service.
*/
typedef NS_ENUM(NSUInteger, PEXServiceInitState) {
    PEX_SERVICE_INITIALIZED=1,
    PEX_SERVICE_STARTING,
    PEX_SERVICE_STARTED,
    PEX_SERVICE_FINISHING,
    PEX_SERVICE_FINISHED,
};

FOUNDATION_EXPORT NSString *PEX_ACTION_USER_LOGIN;
FOUNDATION_EXPORT NSString *PEX_ACTION_USER_LOGOUT;
FOUNDATION_EXPORT NSString *PEX_ACTION_CONNECTIVITY_CHANGE;
FOUNDATION_EXPORT NSString *PEX_EXTRA_CONNECTIVITY_CHANGE;
FOUNDATION_EXPORT NSString *PEX_ACTION_APPSTATE_CHANGE;
FOUNDATION_EXPORT NSString *PEX_EXTRA_APPSTATE_CHANGE;
FOUNDATION_EXPORT NSString *PEX_EXTRA_APPSTATE_APP;
FOUNDATION_EXPORT NSString *PEX_ACTION_LOW_MEMORY;
FOUNDATION_EXPORT NSString *PEX_EXTRA_LOW_MEMORY;

/**
* Main controller of the main logic components. Contains executor queues.
*/
@interface PEXService : NSObject
@property(nonatomic, readonly) dispatch_queue_t dispatchQueue;
@property(nonatomic, readonly) NSOperationQueue * serialOpQueue;
@property(nonatomic) PEXXmppCenter * xmppCenter;
@property(nonatomic) PEXPjManager * pjManager;
@property(nonatomic) PEXMessageManager * msgManager;
@property(nonatomic) PEXDhKeyGenManager * dhKeyGenManager;
@property(nonatomic) PEXFtTransferManager * ftManager;
@property(nonatomic) PEXCertificateUpdateManager * certUpdateManager;
@property(nonatomic) PEXFirewall * firewall;
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) PEXPresenceCenter * presenceCenter;
@property(nonatomic) PEXReachability * reachability;
@property(nonatomic) PEXSingleLoginWatcher * singleLoginWatcher;
@property(nonatomic) PEXPushManager * pushManager;
@property(nonatomic) PEXVersionChecker * versionChecker;
@property(nonatomic) PEXDbWatchdog * dbWatchdog;
@property(nonatomic) PEXPaymentManager * paymentManager;
@property(nonatomic) PEXLicenceManager * licenceManager;
@property(nonatomic) PEXFileSecurityManager * fileSecManager;
@property(nonatomic) CTCallCenter * callCenter;
@property(nonatomic) CTTelephonyNetworkInfo * telephonyInfo;
@property(nonatomic, readonly) PEXServiceInitState initState;
@property(nonatomic, readonly) BOOL userLoggedIn;
@property(nonatomic, readonly) BOOL wasSipRegisteredLastTime;
@property(nonatomic, readonly) BOOL wasXMPPRegisteredLastTime;
@property(nonatomic, copy) dispatch_block_t onSvcFinishedBlock;
@property(nonatomic) PEXApplicationStateChange * lastAppStateChange;

/**
* Last username that was used for login. Need to remember due to bug IPH-10, related
* to iOS bug, affecting TLS cache which cannot be reset/flushed thus old certificate is used for new user.
*/
@property (nonatomic) NSString * lastLoginUserName;

+ (PEXService *)instance;

/**
* Main function for submitting a job to the dispatch queue.
*/
-(void) executeBareAsync: (BOOL) async block: (dispatch_block_t) block;
- (void) execute: (dispatch_block_t) block;
- (void) executeAsync: (BOOL) async block: (dispatch_block_t)block;
- (void) executeWithName: (NSString *) name block: (dispatch_block_t) block;
- (void) executeWithName: (NSString *) name async: (BOOL) async block:(dispatch_block_t)block;
- (void) executeOnGlobalQueueWithName: (NSString *)name async: (BOOL) async block:(dispatch_block_t)block;
- (void) executeWithName: (NSString *)name async: (BOOL) async onQueue:(dispatch_queue_t) queue block:(dispatch_block_t)block;
+ (void) execute: (dispatch_block_t) block;
+ (void) executeWithName: (NSString *) name block: (dispatch_block_t) block;
+ (void) executeWithName:(NSString *)name async: (BOOL) async block:(dispatch_block_t)block;
- (void) executeDelayedWithName: (NSString *)name timeout:(NSTimeInterval) timeout block:(dispatch_block_t)block;
+ (void) executeDelayedWithName: (NSString *)name timeout:(NSTimeInterval) timeout block:(dispatch_block_t)block;
+ (void) executeOnGlobalQueueWithName: (NSString *)name async: (BOOL) async block:(dispatch_block_t)block;
+ (void) executeOnMain: (BOOL) async block: (dispatch_block_t)block;
+ (void) executeOnMainDelayed: (NSTimeInterval) delay block: (dispatch_block_t)block;
+ (void) executeWithName: (NSString *)name async: (BOOL) async onQueue:(dispatch_queue_t) queue block:(dispatch_block_t)block;

/**
* Updates private data in all registered components.
*/
- (void) updatePrivData: (PEXUserPrivate *) privData;

/**
* Should be called on login finished. Handles starting of core libraries.
*/
- (void) onLoginCompleted;

/**
* Supposed to be called on logout event so stacks are shut down.
*/
- (void) onLogout: (const bool) resetKeychain;

/**
 * Called when application settings were updated by the server.
 */
- (void) onSettingsUpdate: (NSDictionary *) settings privData: (PEXUserPrivate *) privData;

/**
* Returns last connection change notification.
* Can be used to determine if current connection is valid.
*/
-(PEXConnectivityChange *) getLastConnectionChange;

/**
* Returns true if this URI is one of ours = currently logged user is logged under this uri somewhere.
*/
- (BOOL)isUriOneOfOurs:(NSString *)uri;
- (NSString *) sanitizeUserContact: (NSString *) address;
+ (BOOL) isNetworkStatusWorking: (NetworkStatus) status;
- (BOOL) isIPProbablyChanged: (NetworkStatus) status;
- (NetworkStatus) getCurentNetworkStatus;

/**
* Main method to determine if the connectivity is working. I.e., whether the device is currently connected
* to the Internet via valid connection, e.g., by WiFi or mobile. It still does not mean it can be used
* for sending / receiving packets. There can be 100% packet loss, application firewall, etc...
*/
- (BOOL) isConnectivityWorking;

/**
* Same as isConnectivityWorking but also takes current service registration into consideration.
* If service looses registration it means there is no connectivity to our application server which
* may indicate problem with connectivity to PhoneX service.
*/
- (BOOL) isConnectivityAndServiceWorking;
- (NSString *) getCurrentRadioTechnology;

/**
* Returns YES if application currently running in the background mode.
* Components should take care about this state and keep wake-up limits in mind so application is not terminated by OS.
*/
- (BOOL) isInBackground;

/**
 * Returns number of currently active cellular calls.
 * Call does not block, can be called on ony thread, uses internal counter updated asynchronously.
 */
-(NSUInteger) getNumberOfActiveCellularCalls;

/**
 * Recomputes number of active cellular calls. Updates PEXService activeCalls counter.
 *
 * Completion block can be set. If async is YES, return value is always zero.
 * If completion async is set, completion handler is called on the parallel queue, otherwise it is
 * called on the same thread as the post processing function thus is async=NO the current thread, if async=YES in
 * the parallel thread.
 *
 * Cellular center operations are performed on the main thread.
 * It needs to be executed on the main thread, mainly init/alloc, in order to avoid stale data in the
 * currentCalls property. Moreover there is a bug reported where after setting observer to callCenter,
 * its property currentCalls will become stale. Thus code path on cellular callback is: main_thread(create new call center,
 * get current calls, register observer).
 *
 * If async == NO:
 *  - call center operations are performed on the main thread, synchronously (can block a lot)
 *  - post processing is called in the calling thread
 *  - completionBlock is called in the calling thread.
 *
 * If async == YES:
 *  - call center operations are performed on the main thread, asynchronously.
 *  - once finished, post processing block is submitted to the parallel queue.
 *  - completionBlock is invoked on the parallel queue, from the postProcessing block.
 *  returns always 0.
 */
- (NSUInteger) recomputeNumberOfCellularCallsAsync: (BOOL) async
                                   completionBlock: (void (^)(NSArray *, NSUInteger)) completionBlock;

/**
 * Calls @see recomputeNumberOfCellularCallsAsync.
 * Plus new asynchronous task for handlers invocation is executed.
 */
- (NSUInteger) recheckCellularCallsAsync: (BOOL) async completionBlock: (void (^)(NSArray *, NSUInteger)) completionBlock;

/**
* Sets all contacts to offline state.
* Called by XMPP modules in transition to background. After transition to active state, new presence is requestted,
* but only online presence is delivered.
*/
-(void) setAllToOffline;

- (BOOL)isUriSystemContact:(NSString *)uri;

- (void)onApplicationWillResignActive:(UIApplication *)application;

- (void)onApplicationDidEnterBackground:(UIApplication *)application;

- (void)onApplicationWillEnterForeground:(UIApplication *)application;

- (void)onApplicationDidBecomeActive:(UIApplication *)application;

- (void)onApplicationWillTerminate:(UIApplication *)application;

- (void)onLowMemoryWarning:(UIApplication *)application;

/**
 * Returns basic service report for logging / UI as a string.
 */
- (NSString *) getServiceReport;

/**
 * Installs ours uncaught exception handler on the top of the uncaught exception handler chain.
 */
- (void) installExceptionHandler;

+ (void) uncaughtException: (NSException *) e fromUncaughtHandler: (BOOL) fromHandler;
@end