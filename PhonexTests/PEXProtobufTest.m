//
//  PEXProtobufTest.m
//  Phonex
//
//  Created by Dusan Klinec on 11.11.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "GeneratedMessageBuilder.h"
#import "PEXPbPush.pb.h"
#import "PEXUtils.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXPbFiletransfer.pb.h"

@interface PEXProtobufTest : XCTestCase

@end

@implementation PEXProtobufTest

- (void)testExportImportMessage {
    PEXPbPresencePushBuilder * b = [[PEXPbPresencePushBuilder alloc] init];
    [b setCapabilitiesSkip:YES];
    [b setCertHashFull:@"abcdfegh"];
    [b setCertHashShort:@"a"];
    [b setSipRegistered:YES];
    [b setVersion:2];
    PEXPbPresencePush * p = [b build];
    XCTAssert(p != nil, "Protobuf message is nil");

    NSData * dat = [p writeToCodedNSData];
    XCTAssert(dat.length > 0, "Empty output buffer.");

    // Try to decode it back from the stream.
    PBCodedInputStream * in = [PBCodedInputStream streamWithData:dat];
    PEXPbPresencePush * p2 = [PEXPbPresencePush parseFromCodedInputStream:in];
    XCTAssert(p2 != nil, "presence push decoded from input stream is nil");

    // Final comparison of final data.
    XCTAssertEqualObjects(p.certHashFull, p2.certHashFull);
    XCTAssertEqualObjects(p.certHashShort, p2.certHashShort);
    XCTAssertEqual(p2.version, 2);
}

-(void) testAckNotifMessage {
    uint64_t curMilli = [PEXUtils currentTimeMillis];
    PEXPbGeneralMsgNotificationBuilder * notificationBuilder = [[PEXPbGeneralMsgNotificationBuilder alloc] init];
    [notificationBuilder setNotifType:PEXPbGeneralMsgNotificationPEXPbNotificationTypeMessageReadAck];
    [notificationBuilder setTimestamp:curMilli];
    [notificationBuilder addAckNonces: (uint32_t) 0x01234567];
    [notificationBuilder addAckNonces: (uint32_t) 0xffffffff];
    PEXPbGeneralMsgNotification * notification = [notificationBuilder build];
    NSData * notificationData = [notification writeToCodedNSData];
    XCTAssert(notification != nil, "Protobuf message is nil");
    XCTAssert(notificationData.length > 0, "Empty output buffer.");

    // Try to decode it back from the stream.
    PEXPbGeneralMsgNotification * p2 = [PEXPbGeneralMsgNotification parseFromData:notificationData];
    XCTAssert(p2 != nil, "message decoded from input stream is nil");

    // Final comparison of final data.
    XCTAssertEqual(p2.timestamp, curMilli);
    XCTAssertEqual([p2 ackNoncesAtIndex:0], (uint32_t) 0x01234567);
    XCTAssertEqual([p2 ackNoncesAtIndex:1], (uint32_t) 0xffffffff);
}

@end
