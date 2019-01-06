//
// Created by Dusan Klinec on 06.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoenixPortServiceSvc.h"
#import "PEXSystemUtils.h"
#import "PEXUserPrivate.h"

@interface PEXSOAPManager : NSObject
+(PhoenixPortSoap11Binding *) getDefaultSOAPBinding;
+(PhoenixPortSoap11Binding *) getDefaultSOAPBinding: (BOOL) withClientCertificate;
+(PhoenixPortSoap11Binding *) getDefaultSOAPBindingWithIdentity: (PEXUserPrivate *) identity andUsername: (NSString *) username;

/**
* Clear cookies sent by server.
* Has to be done when user credentials changes so server
* sends new auth requests in TLS connections.
*/
+ (void)clearCookiesForURL: (NSURL *) url;
+ (void)clearCookies;
+ (void)clearPhonexCookies;

/**
* Erases all stored TLS credentials.
*/
+ (void) eraseCredentials;

+(BOOL) isValidOperation: (PhoenixPortSoap11BindingOperation *) op ofType: (Class) aClass;
+(SOAPFault *) getSOAPFault: (PhoenixPortSoap11BindingResponse *) response;
+(id) getResponsePart: (PhoenixPortSoap11BindingResponse *) response class: (Class) aClass numResponses: (int*) numResponses;

+(void) executeAsync: (NSOperation *) operation queueName: (NSString *)queueName
             timeout:(NSTimeInterval) timeout finishBlock: (BOOL (^)()) finishBlock;

+(void) executeAsync: (NSOperation *) operation queueName: (NSString *)queueName
             timeout:(NSTimeInterval) timeout finishSelector:(SEL)sel withObject:(id) obj;

+(void) executeAsync: (NSOperation *) operation queueName: (NSString *)queueName
             timeout:(NSTimeInterval) timeout semaphore: (dispatch_semaphore_t) sem semWaitTime: (dispatch_time_t) semTime;

/**
 * Waiting loop for an semaphore with cancellation support.
 * Waiting can be cancelled, then 1 is returned and no wait for semaphore is done.
 *   If operation is non-nil, cancel event is sent to the operation.
 * Waiting can timeout. If timeout value is non-negative, waiting timeouts after specified amount of time. If 0, then
 *   no timeout is used.
 *
 * @return value 0=semaphore acquired, 1=cancelled, 2=timeouted
 */
+(int) waitWithCancellation: (NSOperation *) operation doneSemaphore: (dispatch_semaphore_t) sem
                     semWaitTime: (dispatch_time_t) semTime timeout:(NSTimeInterval) timeout cancelBlock:(BOOL (^)())cancelBlock;
+(int) waitWithCancellation: (NSOperation *) operation doneSemaphore:(dispatch_semaphore_t)sem
                semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout doRunLoop: (BOOL) doRunLoop
                cancelBlock:(BOOL (^)())cancelBlock;
+ (int)waitThreadWithCancellation:(NSThread *)operation doneSemaphore:(dispatch_semaphore_t)sem
                      semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout
                      cancelBlock:(BOOL (^)())cancelBlock;
+ (int)waitThreadWithCancellation:(NSThread *)operation doneSemaphore:(dispatch_semaphore_t)sem
                      semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout doRunLoop: (BOOL) doRunLoop
                      cancelBlock:(BOOL (^)())cancelBlock;

@end