//
//  PEXSOAPTest.m
//  Phonex
//
//  Created by Dusan Klinec on 06.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PhoenixPortServiceSvc.h"
#import "PEXSOAPSSLManager.h"
#import "PEXSOAPManager.h"

@interface PEXSOAPTest : XCTestCase <PhoenixPortSoap11BindingResponseDelegate>
@property (readwrite, atomic) BOOL isAsyncFinished;
- (void) operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response;
@end

@implementation PEXSOAPTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * SOAP integration test.
 * Calls simple SOAP service on production server in order to verify SOAP stack is working.
 *
 * Warning! Requires internet connection for passing the test.
 * This test is crippled at the moment. Should be refactored as an integration test
 * using testing environment.
 */
- (void)testSOAPIntegration {
    // Construct service binding.
    PhoenixPortSoap11Binding *binding = [PEXSOAPManager getDefaultSOAPBinding];
    binding.logXMLInOut = NO;  // Set to YES for debugging output.

    // Construct request.
    hr_getOneTimeTokenRequest *request = [hr_getOneTimeTokenRequest new];
    request.type = [NSNumber numberWithInt:1];
    request.user = @"test-internal@phone-x.net";
    request.userToken = @"alfa";
    DDLogVerbose(@"Request connstructed %@", request);

    PhoenixPortSoap11BindingResponse * response = [binding getOneTimeTokenUsingGetOneTimeTokenRequest:request];
    [self checkResponse:request response:response];
}

/**
* SOAP integration test.
* Calls simple SOAP service on production server in order to verify SOAP stack is working.
* Using asynchronous interface.
*
* Warning! Requires internet connection for passing the test.
* This test is crippled at the moment. Should be refactored as an integration test
* using testing environment.
*/
- (void) testAsyncSOAPIntegration {
    // Construct service binding.
    PhoenixPortSoap11Binding *binding = [PEXSOAPManager getDefaultSOAPBinding];
    binding.logXMLInOut = NO;  // Set to YES for debugging output.

    // Construct request.
    hr_getOneTimeTokenRequest *request = [hr_getOneTimeTokenRequest new];
    request.type = [NSNumber numberWithInt:1];
    request.user = @"test-internal@phone-x.net";
    request.userToken = @"alfa";
    DDLogVerbose(@"Request connstructed %@", request);

    [binding getOneTimeTokenAsyncUsingGetOneTimeTokenRequest:request delegate:self];
    DDLogVerbose(@"Async call started");
    [self setIsAsyncFinished:NO];

    // Repeatedly process events in the run loop until we see the callback run.
    // This code will wait for up to 10 seconds for something to come through
    // on the main queue before it times out. If your tests need longer than
    // that, bump up the time limit. Giving it a timeout like this means your
    // tests won't hang indefinitely.
    // -[NSRunLoop runMode:beforeDate:] always processes exactly one event or
    // returns after timing out.

    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:10];
    while ([self isAsyncFinished]==NO && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }

    XCTAssert([self isAsyncFinished]==YES, "Async test didn't make it");
    [NSThread sleepForTimeInterval:10];
}

- (void) operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response {
    DDLogVerbose(@"Async callback called, operation: op=%@, response=%@", operation, response);
    XCTAssert([operation isKindOfClass:[PhoenixPortSoap11Binding_getOneTimeToken class]], @"Invalid operation returned");

    PhoenixPortSoap11Binding_getOneTimeToken * op = (PhoenixPortSoap11Binding_getOneTimeToken*) operation;
    [self checkResponse:[op getOneTimeTokenRequest] response:response];

    // Signalize async has completed.
    [self setIsAsyncFinished:YES];
}

-(void) checkResponse: (hr_getOneTimeTokenRequest *)request response: (PhoenixPortSoap11BindingResponse *) response {
    NSError * error = [response error];

    // Check DNS host not found - Internet connection is off.
    if (error!=nil && [@"NSURLErrorDomain" isEqualToString:error.domain] && error.code == -1003){
        DDLogError(@"SOAP call failed, host was not found. Internet connection is required for this test. Message=%@", error.localizedDescription);
        return;
    }

    // Check server timeout.
    if (error!=nil && [@"NSURLErrorDomain" isEqualToString:error.domain] && error.code == -1001){
        DDLogError(@"SOAP call failed, host timeouted. Internet connection is required for this test. Message=%@", error.localizedDescription);
        return;
    }

    // Assertion on bad certificate.
    if (error!=nil && [@"NSURLErrorDomain" isEqualToString:error.domain] && error.code == -1012) {
        XCTAssert(NO, @"SOAP operation failed, request could not be completed. Please, check certificates and hostname match (no IP address in connection string)");
    }

    // Check SOAP response for validity.
    XCTAssert(response!=nil, @"SOAP response is null");
    NSArray *responseBodyParts = response.bodyParts;
    XCTAssert(responseBodyParts!=nil, @"SOAP response body parts are null");

    for(id bodyPart in responseBodyParts) {
        if ([bodyPart isKindOfClass:[SOAPFault class]]){
            SOAPFault *body = (SOAPFault*)bodyPart;
            DDLogError(@"FaultCode=%@, faultString=%@", [body faultcode], [body faultstring]);
            XCTAssert(NO, "SOAP Fault received: %@", bodyPart);
        }


        if([bodyPart isKindOfClass:[hr_getOneTimeTokenResponse class]]) {
            hr_getOneTimeTokenResponse *body = (hr_getOneTimeTokenResponse*)bodyPart;
            XCTAssert(body!=nil, @"SOAP Response is null");

            // Integration assertions.
            XCTAssertEqualObjects(body.userToken, request.userToken, @"User token does not match");
            XCTAssertEqualObjects(body.user, request.user, @"Request user does not match");
            DDLogVerbose(@"Response received user=%@, serverToken=%@", body.user, body.serverToken);
        }
    }
}

@end
