//
//  PEXOpenUDIDTest.m
//  Phonex
//
//  Created by Dusan Klinec on 14.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXOpenUDID.h"

@interface PEXOpenUDIDTest : XCTestCase

@end

@implementation PEXOpenUDIDTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void) testDeviceUid {
    NSString * devId01 = [PEXOpenUDID value];
    XCTAssert(devId01 != nil, "Device ID is nil");
    XCTAssert([devId01 length]>8, "Device ID is too short");

    NSString * devId02 = [PEXOpenUDID value];
    XCTAssert(devId02 != nil, "Device ID is nil");
    XCTAssert([devId01 isEqualToString:devId02], "Device ID is not equal to the previous one");

    DDLogVerbose(@"Device ID = %@", devId01);
}

@end
