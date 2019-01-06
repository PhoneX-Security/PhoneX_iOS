//
// Created by Dusan Klinec on 06.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSOAPManager.h"
#import "PhoenixPortServiceSvc.h"
#import "PEXSOAPSSLManager.h"
#import "USAdditions.h"
#import "PEXSystemUtils.h"
#import <objc/message.h>

@implementation PEXSOAPManager {

}

+(PhoenixPortSoap11Binding *) getDefaultSOAPBinding {
    return [self getDefaultSOAPBinding:NO];
}

+ (PhoenixPortSoap11Binding *)getDefaultSOAPBinding:(BOOL)withClientCertificate {
    // Construct service binding.
    PhoenixPortSoap11Binding *binding = [PhoenixPortServiceSvc PhoenixPortSoap11Binding:withClientCertificate];
    binding.logXMLInOut = NO;  // Set to YES for debugging output.

    // Construct SSL Manager
    PEXSOAPSSLManager *manager = [PEXSOAPSSLManager new];
    binding.sslManager = manager;

    return binding;
}

+ (PhoenixPortSoap11Binding *)getDefaultSOAPBindingWithIdentity:(PEXUserPrivate *)identity andUsername: (NSString *) username {
    // Construct service binding.
    PhoenixPortSoap11Binding *binding = [PhoenixPortServiceSvc PhoenixPortSoap11Binding: [PEXSOAPSSLManager isIdendityUsableForSOAP:identity]];
    binding.logXMLInOut = NO;  // Set to YES for debugging output.

    // Construct SSL Manager
    PEXSOAPSSLManager *manager = [[PEXSOAPSSLManager alloc] initWithPrivData:identity andUsername:username];
    binding.sslManager = manager;

    return binding;
}

+ (void)clearCookiesForURL: (NSURL *) url {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookiesForURL:url];
    for (NSHTTPCookie *cookie in cookies) {
        DDLogInfo(@"Deleting cookie for domain: %@", [cookie domain]);
        [cookieStorage deleteCookie:cookie];
    }
}

+ (void)clearCookies {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [[cookieStorage cookies] copy];
    for (NSHTTPCookie *cookie in cookies) {
        DDLogInfo(@"Deleting cookie for domain: %@, name=%@, path=%@", cookie.domain, cookie.name, cookie.path);
        [cookieStorage deleteCookie:cookie];
    }
}

+ (void)clearPhonexCookies {
    // TODO: restrict to particular cookies.
    [self clearCookies];
}

+ (void) eraseCredentials {
    NSURLCredentialStorage *credentialsStorage = [NSURLCredentialStorage sharedCredentialStorage];
    NSDictionary *allCredentials = [credentialsStorage allCredentials];

    //iterate through all credentials to find the twitter host
    for (NSURLProtectionSpace *protectionSpace in allCredentials) {
        NSString * host = [protectionSpace host];
        DDLogVerbose(@"Credentials for host=%@", host);

        if ([host rangeOfString:@"phone-x"].location != NSNotFound) {
            NSDictionary *credentials = [credentialsStorage credentialsForProtectionSpace:protectionSpace];
            for (NSString *credentialKey in credentials){
                DDLogInfo(@"Deleting credential for host=%@, key=%@", host, credentialKey);
                [credentialsStorage removeCredential:credentials[credentialKey] forProtectionSpace:protectionSpace];
            }
        }
    }
}

+ (BOOL)isValidOperation:(PhoenixPortSoap11BindingOperation *)op ofType:(Class)aClass {
    return op != nil && ([op isKindOfClass:aClass]);
}

+ (SOAPFault *)getSOAPFault:(PhoenixPortSoap11BindingResponse *)response {
    if (response == nil || response.bodyParts == nil){
        return nil;
    }

    NSArray * responseBodyParts = response.bodyParts;
    for(id bodyPart in responseBodyParts) {
        if (bodyPart != nil && [bodyPart isKindOfClass:[SOAPFault class]]){
            return (SOAPFault*)bodyPart;
        }
    }

    return nil;
}

+(id) getResponsePart: (PhoenixPortSoap11BindingResponse *) response class: (Class) aClass numResponses: (int*) numResponses {
    if (response==nil || response.bodyParts==nil){
        return nil;
    }

    int totalMatches = 0;

    id toReturn = nil;
    NSArray * responseBodyParts = response.bodyParts;

    for(id bodyPart in responseBodyParts) {
        if(![bodyPart isKindOfClass:aClass]) {
            continue;
        }

        totalMatches+=1;

        // Take only first one.
        if (toReturn==nil){
            toReturn = bodyPart;
        }
    }

    // If numResponses is non-null, fill in number of matching responses.
    if (numResponses!=NULL){
        *numResponses = totalMatches;
    }

    return toReturn;
}

+ (void)executeAsync:(NSOperation *)operation queueName:(NSString *)queueName
             timeout:(NSTimeInterval)timeout finishBlock:(BOOL (^)())finishBlock
{
    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], 0);

    // Async call.
    dispatch_async(queue, ^{
        // Start operation in this thread. Connection is kicked-off.
        // Prepares data & starts async NSURLConnection.
        [operation start];

        // Runloop has to be run here otherwise callbacks are not delivered to a delegate.
        // Required because of the NSURLConnection running asynchronously.
        NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
        while (finishBlock() && [loopUntil timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        DDLogVerbose(@"Queue[%@] Exiting background thread.", queueName);
    });
}

+ (void)executeAsync:(NSOperation *)operation queueName:(NSString *)queueName
             timeout:(NSTimeInterval)timeout finishSelector:(SEL)sel withObject:(id)obj
{
    if (![obj respondsToSelector:sel]) {
        [NSException raise:@"SelectorNotImplementedException" format:@"Given object does not implement given selector"];
    }

    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], 0);

    // Async call.
    dispatch_async(queue, ^{
        // Start operation in this thread. Connection is kicked-off.
        // Prepares data & starts async NSURLConnection.
        [operation start];

        // Runloop has to be run here otherwise callbacks are not delivered to a delegate.
        // Required because of the NSURLConnection running asynchronously.
        NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
        while ([loopUntil timeIntervalSinceNow] > 0) {
            BOOL finished = ((BOOL (*)(id, SEL))objc_msgSend)(obj, sel);
            if (finished){
                break;
            }

            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        DDLogVerbose(@"Queue[%@] Exiting background thread.", queueName);
    });
}

+ (void)executeAsync:(NSOperation *)operation queueName:(NSString *)queueName
             timeout:(NSTimeInterval)timeout semaphore:(dispatch_semaphore_t)sem semWaitTime: (dispatch_time_t) semTime;
{
    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], 0);

    // Async call.
    dispatch_async(queue, ^{
        // Start operation in this thread. Connection is kicked-off.
        // Prepares data & starts async NSURLConnection.
        [operation start];

        // Runloop has to be run here otherwise callbacks are not delivered to a delegate.
        // Required because of the NSURLConnection running asynchronously.
        NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
        while ([loopUntil timeIntervalSinceNow] > 0) {
            int64_t semResult = dispatch_semaphore_wait(sem, semTime);
            if (semResult==0){
                break;
            }

            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        DDLogVerbose(@"Queue[%@] Exiting background thread.", queueName);
    });
}
+ (int)waitWithCancellation:(NSOperation *)operation doneSemaphore:(dispatch_semaphore_t)sem
                semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout cancelBlock:(BOOL (^)())cancelBlock
{
    return [self waitWithCancellation:operation doneSemaphore:sem semWaitTime:semTime timeout:timeout doRunLoop:YES cancelBlock:cancelBlock];
}

+ (int)waitWithCancellation:(NSOperation *)operation doneSemaphore:(dispatch_semaphore_t)sem
                semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout doRunLoop:(BOOL)doRunLoop
                cancelBlock:(BOOL (^)())cancelBlock
{
    NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
    for(;[loopUntil timeIntervalSinceNow] > 0;){
        int64_t semResult = dispatch_semaphore_wait(sem, semTime);
        if (semResult==0){
            // Semaphore acquired - return 0, wait is over.
            return kWAIT_RESULT_FINISHED;
        }

        if (doRunLoop){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        // If cancelled - cancel the whole queue.
        // Still has to wait on semaphore signaling.
        if (cancelBlock != nil && cancelBlock()){
            // Cancel background SOAP task, if non-nil.
            if (operation!=nil) {
                [operation cancel];
            }

            // Cancellation = 1;
            return kWAIT_RESULT_CANCELLED;
        }
    }

    // Loop apparently timeouted.
    return kWAIT_RESULT_TIMEOUTED;
}

+ (int)waitThreadWithCancellation:(NSThread *)operation doneSemaphore:(dispatch_semaphore_t)sem
                      semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout
                      cancelBlock:(BOOL (^)())cancelBlock
{
    return [self waitThreadWithCancellation:operation doneSemaphore:sem semWaitTime:semTime timeout:timeout
                                  doRunLoop:YES cancelBlock:cancelBlock];
}

+ (int)waitThreadWithCancellation:(NSThread *)operation doneSemaphore:(dispatch_semaphore_t)sem
                      semWaitTime:(dispatch_time_t)semTime timeout:(NSTimeInterval)timeout doRunLoop:(BOOL)doRunLoop
                      cancelBlock:(BOOL (^)())cancelBlock
{
    NSDate *loopUntil = timeout<0 ? [NSDate distantFuture] : [NSDate dateWithTimeIntervalSinceNow: timeout];
    for(;[loopUntil timeIntervalSinceNow] > 0;){
        int64_t semResult = dispatch_semaphore_wait(sem, semTime);
        if (semResult==0){
            // Semaphore acquired - return 0, wait is over.
            return kWAIT_RESULT_FINISHED;
        }

        if (doRunLoop){
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        }

        // If cancelled - cancel the whole queue.
        // Still has to wait on semaphore signaling.
        if (cancelBlock != nil && cancelBlock()){
            // Cancel background SOAP task, if non-nil.
            if (operation!=nil) {
                [operation cancel];
            }

            // Cancellation = 1;
            return kWAIT_RESULT_CANCELLED;
        }
    }

    // Loop apparently timeouted.
    return kWAIT_RESULT_TIMEOUTED;
}

@end