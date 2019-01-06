//
//  PEXSecurityCenterTest.m
//  Phonex
//
//  Created by Dusan Klinec on 14.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXSecurityCenter.h"

@interface PEXSecurityCenterTest : XCTestCase

@end

@implementation PEXSecurityCenterTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testPrivateDirectory {
    NSString * privDir = [PEXSecurityCenter getDefaultPrivateDirectory:YES];
    XCTAssert(privDir != nil, "Private directory is nil");

    // Existence check.
    NSFileManager * fmgr = [NSFileManager defaultManager];
    XCTAssert([fmgr fileExistsAtPath:privDir], "Private directory does not exist or is not a directory.");

    DDLogVerbose(@"private directory: %@", privDir);
}

- (void)testUkey{
    NSString * ukey01 = [PEXSecurityCenter getUsernamePathKey:@"phonex-internal"];
    XCTAssert(ukey01 != nil, "User key is null");
    XCTAssert([ukey01 length] > 24, "User key is too short");

    // Test trimming appending
    NSString * ukey02 = [PEXSecurityCenter getUsernamePathKey:@"  phonex-internal  "];
    XCTAssert(ukey02 != nil, "User key is null");
    XCTAssert([ukey01 isEqualToString:ukey01], "Trimming does not work");

    // Test trimmed auto append.
    NSString * ukey03 = [PEXSecurityCenter getUsernamePathKey:@"  phonex-internal@phone-x.net  "];
    XCTAssert(ukey03 != nil, "User key is null");
    XCTAssert([ukey03 isEqualToString:ukey01], "Auto appending does not work");

    // Test different domain - has to differ.
    NSString * ukey04 = [PEXSecurityCenter getUsernamePathKey:@"  phonex-internal@phone-x.biz  "];
    XCTAssert(ukey04 != nil, "User key is null");
    XCTAssert(![ukey04 isEqualToString:ukey01], "Collision, domain level");

    NSString * ukey05 = [PEXSecurityCenter getUsernamePathKey:@"phonex-internal2"];
    XCTAssert(ukey05 != nil, "User key is null");
    XCTAssert(![ukey05 isEqualToString:ukey01], "Collision, uname level");

    DDLogVerbose(@"Example user key: [%@]", ukey01);
}

@end
