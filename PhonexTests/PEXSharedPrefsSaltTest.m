//
//  PEXSharedPrefsSaltTest.m
//  Phonex
//
//  Created by Dusan Klinec on 15.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXSharedPrefsSalt.h"

@interface PEXSharedPrefsSaltTest : XCTestCase

@end

@implementation PEXSharedPrefsSaltTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSaltKey {
    NSString * key01 = [PEXSharedPrefsSalt getSaltPrefsKey:@"key01" user:@"user01"];
    XCTAssert(key01!=nil, "Prefs key is nil");
    XCTAssert([key01 length]>=8, "Prefs key is too short");

    NSString * key02 = [PEXSharedPrefsSalt getSaltPrefsKey:@"key01" user:@"user02"];
    XCTAssert(key02!=nil, "Prefs key is nil");
    XCTAssert(![key02 isEqualToString:key01], "Prefs key collision");

    NSString * key03 = [PEXSharedPrefsSalt getSaltPrefsKey:@"key02" user:@"user01"];
    XCTAssert(key03!=nil, "Prefs key is nil");
    XCTAssert(![key03 isEqualToString:key01], "Prefs key collision");
    XCTAssert(![key03 isEqualToString:key02], "Prefs key collision");
}

- (void)testSaltStorage {
    NSData * salt = [PEXSharedPrefsSalt generateNewSalt:@"tmpKey" user:@"test-internal@phone-x.net" saltSize:32];
    XCTAssert(salt!=nil, "Generated salt is nil");
    XCTAssert([salt length]==32, "Generated salt is of incorrect length");

    // Check existence.
    XCTAssert([PEXSharedPrefsSalt saltExists:@"tmpKey" user:@"test-internal@phone-x.net"], "Salt should exist");
    XCTAssert(![PEXSharedPrefsSalt saltExists:@"tmpKey" user:@"test-internal@phone-x.net-blablanonexistent"], "Salt should not exist");

    // Retrieve
    NSData * salt02 = [PEXSharedPrefsSalt getSalt:@"tmpKey" user:@"test-internal@phone-x.net"];
    XCTAssert(salt02!=nil, "Generated salt is nil");
    XCTAssert([salt02 isEqualToData:salt], "Retrieved salt is not consistent with generated one");
}


@end
