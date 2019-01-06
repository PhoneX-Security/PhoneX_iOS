//
//  PEXPKCS12PasswdTest.m
//  Phonex
//
//  Created by Dusan Klinec on 15.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXPKCS12Passwd.h"
#import "PEXMessageDigest.h"

@interface PEXPKCS12PasswdTest : XCTestCase

@end

@implementation PEXPKCS12PasswdTest

- (void)testPKCS12PasswordGenerator {
    // No salt test for unknown user.
    @try {
        [PEXPKCS12Passwd getStoragePass:@"blablabla-non-existent-user" key:@"key01"];
        XCTFail(@"PKCS password generator should have thrown an exception due to non-existent salt");
    }
    @catch (NSException *exception) {

    }

    // Generate a new salt.
    [PEXPKCS12Passwd generateNewSalt:@"phonex-internal@phone-x.net"];

    NSString * pass01 = [PEXPKCS12Passwd getStoragePass:@"phonex-internal@phone-x.net" key:@"key01"];
    XCTAssert(pass01!=nil, "PKCS password is nil");
    XCTAssert([pass01 length]>8, "PKCS password is too short");

    // Consistency test.
    NSString * pass02 = [PEXPKCS12Passwd getStoragePass:@"phonex-internal@phone-x.net" key:@"key01"];
    XCTAssert(pass02!=nil, "PKCS password is nil");
    XCTAssert([pass02 length]>8, "PKCS password is too short");
    XCTAssert([pass02 isEqualToString:pass01], "PKCS password is not consistent");

    // Difference test.
    NSString * pass03 = [PEXPKCS12Passwd getStoragePass:@"phonex-internal@phone-x.net" key:@"key02"];
    XCTAssert(pass03!=nil, "PKCS password is nil");
    XCTAssert([pass03 length]>8, "PKCS password is too short");
    XCTAssert(![pass03 isEqualToString:pass01], "PKCS password must be different for different inputs.");
}

- (void)testPKCS12PasswordPerformance {
    const int capacity = 1;

    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:capacity];
    for(int i=0; i < capacity; i++){
        NSString * password = [PEXMessageDigest bytes2hex: [PEXMessageDigest sha256Message:[NSString stringWithFormat:@"%d", i]]];
        [arr addObject:password];
    }

    DDLogVerbose(@"Performance test for password computation");
    NSString * resPass = nil;
    for(int i=0; i < capacity; i++){
        NSString * password = arr[i];
        NSString * pass = [PEXPKCS12Passwd getStoragePass:@"phonex-internal@phone-x.net" key:password];
        resPass = pass;
    }
    DDLogVerbose(@"Generation finished, cn=%d, pass=%@", capacity, resPass);

    [NSThread sleepForTimeInterval:1.0];
}
@end
