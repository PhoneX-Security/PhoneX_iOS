//
//  PEXDatabaseTest.m
//  Phonex
//
//  Created by Matej Oravec on 24/10/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PEXUser.h"
#import "PEXDatabase.h"

@interface PEXDatabaseTest : XCTestCase

@end

static NSString * const s_dbKey = @"testovaciehesielko";

@implementation PEXDatabaseTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [PEXDatabase initInstance];
}

- (void)tearDown {
    [PEXDatabase removeAllDatabases];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDatabaseInstance
{
    XCTAssertNotNil([PEXDatabase instance], @"PEXDatabase instance was not successfully created");
}

- (void)testDatabaseLoad
{
    const PEXUser * const user = [[PEXUser alloc] init];
    user.email = @"testing.user.local@phone-x.test.net";

    const PEXDbLoadResult resultFirstLoad =[PEXDatabase openOrCreateDatabase:user encryptionKey:s_dbKey];
    XCTAssert(resultFirstLoad == PEX_DB_LOAD_OK,
            @"Database file for user with email: %@ could not be loaded (created), returned: %d",
            user.email, resultFirstLoad);

    [self unloadDbTest];

    const PEXDbLoadResult resultSecondLoad =[PEXDatabase openOrCreateDatabase:user encryptionKey:s_dbKey];
    XCTAssert(resultFirstLoad == PEX_DB_LOAD_OK,
            @"Database file for user with email: %@ could not be loaded (reload), returned: %d",
            user.email, resultSecondLoad);

    [self unloadDbTest];
}

- (void) unloadDbTest
{
    const int dbCloseResult = [PEXDatabase unloadDatabase];
    XCTAssertEqual(dbCloseResult,SQLITE_OK,
            @"Closing the database failed with code (-1 means it is already closed): @d",
            dbCloseResult);
}

@end
