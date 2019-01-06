//
//  PEXPEMPasswdTest.m
//  Phonex
//
//  Created by Dusan Klinec on 15.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXPEMPasswd.h"

@interface PEXPEMPasswdTest : XCTestCase

@end

@implementation PEXPEMPasswdTest

- (void)testPemExample {
    // No salt test for unknown user.
    @try {
        [PEXPEMPasswd getStoragePass:@"blablabla-non-existent-user" key:@"key01"];
        XCTFail(@"PEM password generator should have thrown an exception due to non-existent salt");
    }
    @catch (NSException *exception) {

    }

    // Generate a new salt.
    [PEXPEMPasswd generateNewSalt:@"phonex-internal@phone-x.net"];

    NSString * pass01 = [PEXPEMPasswd getStoragePass:@"phonex-internal@phone-x.net" key:@"key01"];
    XCTAssert(pass01!=nil, "PEM password is nil");
    XCTAssert([pass01 length]>8, "PEM password is too short");

    // Consistency test.
    NSString * pass02 = [PEXPEMPasswd getStoragePass:@"phonex-internal@phone-x.net" key:@"key01"];
    XCTAssert(pass02!=nil, "PEM password is nil");
    XCTAssert([pass02 length]>8, "PEM password is too short");
    XCTAssert([pass02 isEqualToString:pass01], "PEM password is not consistent");

    // Difference test.
    NSString * pass03 = [PEXPEMPasswd getStoragePass:@"phonex-internal@phone-x.net" key:@"key02"];
    XCTAssert(pass03!=nil, "PEM password is nil");
    XCTAssert([pass03 length]>8, "PEM password is too short");
    XCTAssert(![pass03 isEqualToString:pass01], "PEM password must be different for different inputs.");
}


@end
