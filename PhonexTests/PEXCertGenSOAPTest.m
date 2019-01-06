//
//  PEXCertGenSOAPTest.m
//  Phonex
//
//  Created by Dusan Klinec on 13.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXCertGenTask.h"
#import "PEXCertGenParams.h"
#import "PEXTaskEvent.h"
#import "PEXUserPrivate.h"

@interface PEXCertGenSOAPTest : XCTestCase <PEXTaskListener>

@end

@implementation PEXCertGenSOAPTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCertGen {
    PEXCertGenParams * params = [[PEXCertGenParams alloc] init];
    params.userName = @"test-internal@phone-x.net";
    params.password = @"alpha123456..";

    PEXUserPrivate * privData = [[PEXUserPrivate alloc] init];
    PEXCertGenTask * task = [[PEXCertGenTask alloc] init];
    [task setParams:params];
    [task setPrivData:privData];
    [task addListener:self];

    DDLogVerbose(@"Starting test");
    [task start];
    DDLogVerbose(@"Test finished");

}

- (void) taskStarted: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskStarted %@", event);
}

- (void) taskEnded: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskEnded %@", event);
}

- (void) taskProgressed: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskProgressed %@", event);
}

- (void) taskCancelStarted: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskCancelStarted %@", event);
}

- (void) taskCancelEnded: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskCancelEnded %@", event);
}

- (void) taskCancelProgressed: (const PEXTaskEvent * const) event {
    DDLogVerbose(@"taskCancelProgressed %@", event);
}


@end
