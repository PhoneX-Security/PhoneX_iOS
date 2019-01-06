//
// Created by Dusan Klinec on 02.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSBundle+PEXResCrypto.h"
#import "PEXResCrypto.h"
#import "PEXCryptoUtils.h"
#import "PEXPEMParser.h"

@interface PEXResTest : XCTestCase

@end

@implementation PEXResTest

- (void)testCryptoRes {
    XCTAssert([[NSBundle mainBundle] pathForCARoots] != nil, "CA roots path is nil");
    XCTAssert([[NSBundle mainBundle] pathForDHGroupId:1] != nil, "DH group 1 not found");
    XCTAssert([[NSBundle mainBundle] pathForDHGroupId:256] != nil, "DH group 256 not found");
    XCTAssert([[NSBundle mainBundle] pathForDHGroupId:100] != nil, "DH group 100 not found");
    NSLog(@"FILE: %@", [[NSBundle mainBundle] pathForDHGroupId:100]);
}

- (void) testRootCAFile {
    NSData * caRoots = [PEXResCrypto loadCARoots];
    XCTAssert(caRoots!=nil, "CA roots file is nil");
    XCTAssert([caRoots length] > 50, "CA roots file is too short: %lld", (uint64_t) [caRoots length]);

    // Convert NSData to NSString
    NSString* caString = [[NSString alloc] initWithData:caRoots encoding:NSASCIIStringEncoding];
    XCTAssert([caString hasPrefix:@"-----BEGIN CERTIFICATE-----"], "Illegal format of the CA roots file: %@", caString);
}

- (void) testDHGroupFile {
   NSData * dhGoup = [PEXResCrypto loadDHGroupId:100];
   XCTAssert(dhGoup!=nil, "DH Group file is nil");
   XCTAssert([dhGoup length] > 50, "DH Group file is too short: %lld", (uint64_t) [dhGoup length]);

    // Convert NSData to NSString
    NSString * dhString = [[NSString alloc] initWithData:dhGoup encoding:NSASCIIStringEncoding];
    XCTAssert([dhString hasPrefix:@"-----BEGIN DH PARAMETERS-----"], "Illegal format of the DH Group file: %@", dhString);
}

@end