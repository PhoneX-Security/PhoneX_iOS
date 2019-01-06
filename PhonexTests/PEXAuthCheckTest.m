//
//  PEXAuthCheckTest.m
//  Phonex
//
//  Created by Dusan Klinec on 22.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXSecurityCenter.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXSOAPTask.h"
#import "PEXPKCS12Passwd.h"
#import "PEXPasswdGenerator.h"

@interface PEXAuthCheckTest : XCTestCase

@end

@implementation PEXAuthCheckTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
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
    // Do we have to identity loaded?
    PEXUserPrivate * privData = [[PEXUserPrivate alloc] init];
    privData.username = @"test-internal@phone-x.net";
    privData.pass = @"alpha123456..";

    // Derive PKCS12 password for identity loader.
    if ([PEXPKCS12Passwd saltExists:privData.username]){
        privData.pkcsPass = [PEXPKCS12Passwd getStoragePass:privData.username key:privData.pass];
        int idLoadRes = [PEXSecurityCenter loadIdentity:privData];
    }

    // Generate auth hash - invariant on stored credentials.
    // Do as a last thing since auth token is time dependent.
    NSString * ha1 = [PEXPasswdGenerator getHA1:privData.username password:privData.pass];

    // Generate auth token.
    NSString * authHash = [PEXPasswdGenerator generateUserAuthToken:privData.username
                                                                ha1:ha1 usrToken:@"" serverToken:@"" milliWindow:1000 * 60 offset:0];

    PEXSOAPTask * soapTask = [[PEXSOAPTask alloc] initWith:nil andName:@"authcheck_test"];

    // Construct service binding.
    soapTask.logXML = YES;
    [soapTask prepareSOAP: privData];

    // Construct request.
    hr_authCheckV2Request *request = [[hr_authCheckV2Request alloc] init];
    request.targetUser = privData.username;
    request.authHash = authHash;
    request.unregisterIfOK = hr_trueFalse_true;
    DDLogVerbose(@"Request connstructed %@", request);

    // Prepare SOAP operation.
    soapTask.desiredBody = [hr_authCheckV2Response class];
    soapTask.srcOperation = [[PhoenixPortSoap11Binding_authCheckV2 alloc]
            initWithBinding:soapTask.getBinding delegate:soapTask authCheckV2Request:request];

    // Start task, sync blocking here, on purpose.
    [soapTask start];

    // Cancelled check block.
    if ([soapTask cancelDetected]){
        XCTFail(@"SOAP task was cancelled");
        return;
    }

    // Error check block.
    if ([soapTask finishedWithError]){
        XCTFail(@"SOAP task finished with error");
        return;
    }

    // Extract answer
    hr_authCheckV2Response * body = (hr_authCheckV2Response *) soapTask.responseBody;
    DDLogVerbose(@"AuthHashValid? %d", [body authHashValid]==hr_trueFalse_true);
}
@end
