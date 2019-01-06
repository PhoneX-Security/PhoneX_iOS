//
//  PEXPasswdGeneratorTest.m
//  Phonex
//
//  Created by Dusan Klinec on 09.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXPasswdGenerator.h"

@interface PEXPasswdGeneratorTest : XCTestCase

@end

@implementation PEXPasswdGeneratorTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAuthHash {
    XCTAssertEqualObjects(
            @"f0e9ba91d7ab498c0f5c96bdd1feac2c",
            [PEXPasswdGenerator getHA1:@"alice@phone-x.net" password:@"bob"],
            "alice@phone-x.net:bob auth hash failed");

    XCTAssertEqualObjects(
            @"18a88c13431377bca5df887d476e742d",
            [PEXPasswdGenerator getHA1:@"alice@phone-x.net" domain:@"phone-x.net" password:@"bob"],
            "alice@phone-x.net:bob auth hash 1b failed");
}

- (void)testUserToken {
    NSString * authToken = [PEXPasswdGenerator generateUserAuthToken:@"test-internal@phone-x.net"
                                                                 ha1:@"test"
                                                            usrToken:@"alpha"
                                                         serverToken:@"beta"
                                                         milliWindow:1000
                                                              offset:0
                                                             curTime:1000];

    XCTAssert(authToken!=nil, "Auth token is nil");
    XCTAssert([authToken length]>10, "Auth token is too short");
    XCTAssertEqualObjects(@"YkbbMIzLPiaNwllycZgNk3QrsSH5p0chlF6mkegMci16WpiujFfe/gkwVOY8My+/ngwsIo/iGTjZD8gyCdrkvQ==",
            authToken, "AuthToken does not match");

    // Auth token used in SOAP calls, current time. Cannot be null.
    authToken = [PEXPasswdGenerator generateUserAuthToken:@"phonex-internal@phone-x.net"
                                                      ha1:@"ha-ha-ha" usrToken:@"" serverToken:@"" milliWindow:1000 * 60 offset:0];

    XCTAssert(authToken!=nil, "Auth token is nil");
    XCTAssert([authToken length]>10, "Auth token is too short");
}

@end
