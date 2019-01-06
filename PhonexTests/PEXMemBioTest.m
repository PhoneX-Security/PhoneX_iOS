//
//  PEXMemBioTest.m
//  Phonex
//
//  Created by Dusan Klinec on 09.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "openssl/bio.h"
#import "PEXCryptoUtils.h"
#import "PEXMemBIO.h"

@interface PEXMemBioTest : XCTestCase

@end

@implementation PEXMemBioTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBioConversion {
    const char testBuff[] = {0x01, 0x02, 0x03, 0x5f, 0xf3, 0xb3, 0x12, 0x76, 0x98};
    NSData * d1 = [NSData dataWithBytes:testBuff length:(sizeof(testBuff)/sizeof(testBuff[0]))];

    BIO * mem = [PEXMemBIO NSData2Bio:d1];
    XCTAssert(mem!=nil, "Allocated BIO is null");

    // Convert back to NSData
    NSData * d2 = [PEXMemBIO Bio2NSData:mem];
    XCTAssert(d2!=nil, "Allocated NSData is null");
    XCTAssert([d1 length] == [d2 length], "Copied data size differs");
    XCTAssert([d1 isEqualToData:d2], "Copied data does not match");
}

- (void)testImportExport {
    const char testBuff[] = {0x01, 0x02, 0x03, 0x5f, 0xf3, 0xb3, 0x12, 0x76, 0x98};
    NSData * d1 = [NSData dataWithBytes:testBuff length:(sizeof(testBuff)/sizeof(testBuff[0]))];

    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:d1];
    NSData * d2 = [membio export];
    XCTAssert(d2!=nil, "BIO export is nil");
    XCTAssert([d1 isEqualToData:d2], "Export(Import(x)) != x");
}

@end
