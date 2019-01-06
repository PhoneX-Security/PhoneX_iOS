//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSOAPTask.h"
#import "PEXUserPrivate.h"
#import "PEXSOAPManager.h"
#import "PEXUtils.h"

NSString * PEX_EXTRA_SOAP_FAULT = @"net.phonex.error.soapfault";

@interface PEXSOAPTask () { }

/**
 * Semaphore for signaling end of SOAP operation.
 */
@property (nonatomic) dispatch_semaphore_t semFinished;

/**
 * Semaphore for signaling to finish async runloop waiting after SOAP finishes.
 */
@property (nonatomic) dispatch_semaphore_t asyncFinished;

/**
 * SOAP binding.
 */
@property (nonatomic) PhoenixPortSoap11Binding * binding;
@end

@implementation PEXSOAPTask {

}

- (id)init {
    if (self = [super init]){
        self.operation=nil;
        self.response=nil;
        self.srcOperation=nil;
        self.shouldCancelBlock = nil;
        self.semFinished = dispatch_semaphore_create(0);
        self.asyncFinished = dispatch_semaphore_create(0);

        self.semMilliWait = 25ull;
        self.timeoutSec = 45;
        self.logXML = NO;
        self.timeoutDetected = NO;
        self.cancelDetected = NO;
        self.taskError = PEX_SOAP_ERROR_NONE;

        self.desiredAnswers = 1;
        self.desiredBody = nil;
        self.responseBody = nil;

    }

    return self;
}

- (PhoenixPortSoap11Binding *)getBinding {
    return self.binding;
}

- (void)prepareSOAP:(PEXUserPrivate *)privData {
    // Construct service binding. If we have a privateData, use provided identity.
    if (privData!=nil) {
        self.binding = [PEXSOAPManager getDefaultSOAPBindingWithIdentity:privData andUsername:privData.username];
    } else {
        self.binding = [PEXSOAPManager getDefaultSOAPBinding];
    }

    self.binding.logXMLInOut = self.logXML;  // Set to YES for debugging output.
}

- (void)subMain {
    dispatch_time_t tdeadline = dispatch_time(DISPATCH_TIME_NOW, self.semMilliWait * 1000000ull);

    // Perform real async call with runloop-ing.
    [PEXSOAPManager executeAsync:self.srcOperation queueName:self.taskName
                         timeout:self.timeoutSec semaphore:self.asyncFinished semWaitTime: tdeadline];

    // Wait for cancellation - semaphore indication.
    int waitRes = [PEXSOAPManager waitWithCancellation:self.srcOperation doneSemaphore:self.semFinished
                                           semWaitTime:tdeadline timeout:self.timeoutSec
                                           cancelBlock:^BOOL() { return [self shouldCancel]; }];

    // Waiting finished here, release background runloop task.
    dispatch_semaphore_signal(self.asyncFinished);

    // Did operation timeouted?
    if (waitRes == kWAIT_RESULT_TIMEOUTED){
        DDLogError(@"SOAP call timeouted");
        self.timeoutDetected = YES;
        self.taskError = PEX_SOAP_ERROR_TIMEDOUT;
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil]];
        return;
    }

    // Cancel test.
    if ([self shouldCancel]){
        self.taskError = PEX_SOAP_ERROR_CANCELLED;
        [self subCancel];
        return;
    }

    // Parse answer
    if (![PEXSOAPManager isValidOperation:self.operation ofType:[self.srcOperation class]]){
        DDLogError(@"SOAP_AuthCheck error: Response is invalid");
        self.taskError = PEX_SOAP_ERROR_UNEXPECTED_RESPONSE;
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotParseResponse userInfo:nil]];
        return;
    }

    // Test for soap fault.
    SOAPFault * fault = [PEXSOAPManager getSOAPFault:self.response];
    if (fault != nil){
        DDLogError(@"FaultCode=%@, faultString=%@", [fault faultcode], [fault faultstring]);
        self.taskError = PEX_SOAP_ERROR_SOAP_FAULT;
        self.soapFault = fault;
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:@{PEX_EXTRA_SOAP_FAULT : fault}]];
        return;
    }

    // Transfer error.
    if (self.response != nil && self.response.error != nil){
        DDLogVerbose(@"SOAP error detected: %@", self.response.error);

        // Testing for timeout.
        self.timeoutDetected |= [PEXUtils isErrorWithConnectivity:self.response.error];

        // Signalize error from lower task.
        self.taskError = PEX_SOAP_ERROR_TASK_ERROR;
        [self subError: self.response.error];
        return;
    }

    // Extract answer.
    int totalAnswers=0;
    if (self.desiredBody != nil){
        self.responseBody = [PEXSOAPManager getResponsePart:self.response class:self.desiredBody numResponses:&totalAnswers];
    }

    // Last sanity check for the answer.
    if ((self.responseBody == nil && self.desiredBody != nil) || (self.desiredAnswers >= 0 && totalAnswers != self.desiredAnswers)){
        DDLogError(@"Illegal number of total answers %d, body=%p", totalAnswers, self.responseBody);
        self.taskError = PEX_SOAP_ERROR_INVALID_RESPONSE;
        [self subError: [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
        return;
    }
}

- (void)operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response {
    DDLogVerbose(@"Async callback called, operation: op=%@, response=%@", operation, response);
    self.response = response;
    self.operation = operation;

    // Signalize async has completed.
    dispatch_semaphore_signal(self.semFinished);
}

@end