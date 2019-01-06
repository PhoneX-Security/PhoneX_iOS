//
//  PEXMessageDigestTest.m
//  Phonex
//
//  Created by Dusan Klinec on 09.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXMessageDigest.h"

@interface PEXMessageDigestTest : XCTestCase

@end

@implementation PEXMessageDigestTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBytes2hexFunction {
    const char ba0[] = {};
    const char ba1[] = {0x00};
    const char ba2[] = {0x01};
    const char ba3[] = {0xff};
    const char ba4[] = {0x01, 0x02, 0x03, 0x5f, 0xf3};

    XCTAssertEqualObjects(@"",
            [PEXMessageDigest bytes2hex: [NSData dataWithBytes:ba0 length:sizeof(ba0)]],
            @"Empty string failed");

    XCTAssertEqualObjects(@"00",
            [PEXMessageDigest bytes2hex: [NSData dataWithBytes:ba1 length:sizeof(ba1)]],
            @"Zeros failed");

    XCTAssertEqualObjects(@"01",
            [PEXMessageDigest bytes2hex: [NSData dataWithBytes:ba2 length:sizeof(ba2)]],
            @"Zero prefix failed");

    XCTAssertEqualObjects(@"ff",
            [PEXMessageDigest bytes2hex: [NSData dataWithBytes:ba3 length:sizeof(ba3)]],
            @"FF failed");

    XCTAssertEqualObjects(@"0102035ff3",
            [PEXMessageDigest bytes2hex: [NSData dataWithBytes:ba4 length:sizeof(ba4)]],
            @"Complex example failed");
}

- (void)testMessageDigestSimple {

    XCTAssertEqualObjects(@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            [PEXMessageDigest bytes2hex: [PEXMessageDigest sha256Message: @""]],
            @"Has for empty string mismatch");

    XCTAssertEqualObjects(@"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
            [PEXMessageDigest bytes2hex: [PEXMessageDigest sha256Message: @"hello"]],
            @"sha256(hello) failed");

    XCTAssertEqualObjects(
            @"9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043",
            [PEXMessageDigest bytes2hex: [PEXMessageDigest sha512Message: @"hello"]],
            @"sha512(hello) failed");

    XCTAssertEqualObjects(@"5d41402abc4b2a76b9719d911017c592",
            [PEXMessageDigest bytes2hex: [PEXMessageDigest md5Message: @"hello"]],
            @"md5(hello) failed");
}

@end
