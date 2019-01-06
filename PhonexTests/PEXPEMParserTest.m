//
//  PEXPEMParserTest.m
//  Phonex
//
//  Created by Dusan Klinec on 09.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXResCrypto.h"
#import "PEXPEMParser.h"

@interface PEXPEMParserTest : XCTestCase

@end

@implementation PEXPEMParserTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPEMParser {
    NSData * caRoots = [PEXResCrypto loadCARoots];

    // PEM parser test.
    char const * src = [caRoots bytes];
    int len = (int)[caRoots length];
    PEXPEMParser * parser = [[PEXPEMParser alloc] init];
    [parser setProduceDER:YES];
    PEXPemChunk * chunk = [parser parsePEM:&src len:&len];
    XCTAssert(chunk!=nil, "Chunk is nil");
    XCTAssert([chunk der]!=nil, "DER is nil");
    XCTAssert([[chunk der] length] > 0, "DER is empty");
    XCTAssert([chunk objType]!=nil, "PEM type is nil");
    XCTAssert([@"CERTIFICATE" isEqualToString:[[chunk objType] uppercaseString]], "Not CERTIFICATE type");
    NSLog(@"Parsing finished, DER length=%u, hasMore=%d, bytesRead=%d, success=%d, objType=%@",
            [[chunk der] length], [chunk hasMoreData], [chunk bytesRead], [chunk success], [chunk objType]);
}


@end
