//
//  PEXGzipTest.m
//  Phonex
//
//  Created by Dusan Klinec on 18.11.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "NSData+PEXGzip.h"
#import <XCTest/XCTest.h>

@interface PEXGzipTest : XCTestCase

@end

@implementation PEXGzipTest

- (void)testOutputEqualsInput
{
    //set up data
    NSString *inputString = @"Hello World!";
    NSData *inputData = [inputString dataUsingEncoding:NSUTF8StringEncoding];

    //compress
    NSData *compressedData = [inputData gzippedData];

    //decode
    NSData *outputData = [compressedData gunzippedData];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(outputString, inputString, @"OutputEqualsInput test failed");
}

- (void)testZeroLengthInput {
    NSData *data = [[NSData data] gzippedData];
    XCTAssertNil(data, @"ZeroLengthInput test failed");

    data = [[NSData data] gunzippedData];
    XCTAssertNil(data, @"ZeroLengthInput test failed");
}

@end
