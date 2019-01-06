//
//  PEXDbProviderTest.m
//  Phonex
//
//  Created by Matej Oravec on 27/10/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "PEXDbTestEntity.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDatabase.h"
#import "PEXUser.h"
#import "PEXDbTestProvider.h"

#import <limits.h>

static NSString * const s_dbKey = @"testovaciehesielko";

@interface PEXDbProviderTest : XCTestCase

@property (nonatomic) NSString *blobText1;
@property (nonatomic) PEXDbTestEntity * entity1;
@property (nonatomic) NSString *blobText2;
@property (nonatomic) PEXDbTestEntity * entity2;

@end

@implementation PEXDbProviderTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [PEXDatabase initInstance];
    PEXUser * user = [[PEXUser alloc] init];
    user.email = @"testingTester";
    [PEXDatabase openOrCreateDatabase:user encryptionKey:s_dbKey];
    [PEXDatabase executeSimple:[[PEXDbTestEntity getCreateTable] UTF8String]];

    self.blobText1 = @"blobText1";
    self.entity1 =
            [self createEntity:LLONG_MAX double:1.23456789123456789123456789 text:@"myEntity1"
                          blob:[self.blobText1 dataUsingEncoding:NSUTF8StringEncoding]];

    self.blobText2 = @"blobText2";
    self.entity2 =
            [self createEntity:LLONG_MIN double:0.0 text:@"myEntity2"
                          blob:[self.blobText2 dataUsingEncoding:NSUTF8StringEncoding]];

    PEXDbAppContentProvider * const cp = [[PEXDbTestProvider alloc] init];
    [cp insert:[PEXDbTestEntity getURI] contentValues:[self.entity1 getDbContentValues]];
    [cp insert:[PEXDbTestEntity getURI] contentValues:[self.entity2 getDbContentValues]];
}

- (void)tearDown {
    [PEXDatabase unloadDatabase];
    [PEXDatabase removeAllDatabases];
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testContentProviderGeneral
{
    PEXDbAppContentProvider * const cp = [[PEXDbTestProvider alloc] init];

    PEXDbCursor * const cursor =
            [cp query:[PEXDbTestEntity getURI]
           projection:[PEXDbTestEntity getFullProjection]
            selection:nil
        selectionArgs:nil
            sortOrder:nil];

    // test cursor
    [self assertMoveFreshNotEmptyAndNilCursor:cursor numberOfEntities:2];

    // test entities
    [cursor moveToFirst];
    PEXDbTestEntity * const te1 = [[PEXDbTestEntity alloc] init];
    [te1 createFromCursor:cursor];
    [self assertEntity:self.entity1 with:te1];
    NSString * const dataString1 = [[NSString alloc] initWithData:te1.blobField encoding:NSUTF8StringEncoding];
    XCTAssert([self.blobText1 isEqualToString:dataString1], @"Malformed string from BLOB");

    [cursor moveToNext];
    PEXDbTestEntity * const te2 = [[PEXDbTestEntity alloc] init];
    [te2 createFromCursor:cursor];
    [self assertEntity:self.entity2 with:te2];
    NSString * const dataString2 = [[NSString alloc] initWithData:te2.blobField encoding:NSUTF8StringEncoding];
    XCTAssert([self.blobText2 isEqualToString:dataString2], @"Malformed string from BLOB");
}

- (void) testContentProviderSelect
{
    PEXDbAppContentProvider * const cp = [[PEXDbTestProvider alloc] init];

    PEXDbCursor * const cursor =
            [cp query:[PEXDbTestEntity getURI]
           projection:[PEXDbTestEntity getFullProjection]
            selection:@"WHERE " TESTENTITY_TFIELD_TEXT "=?"
        selectionArgs:@[self.entity1.textField]
            sortOrder:nil];

    // test cursor
    [self assertMoveFreshNotEmptyAndNilCursor:cursor numberOfEntities:1];

    // test entities
    [cursor moveToFirst];
    PEXDbTestEntity * const te1 = [[PEXDbTestEntity alloc] init];
    [te1 createFromCursor:cursor];
    [self assertEntity:self.entity1 with:te1];
}

- (void) testContentProviderDelete
{
    PEXDbAppContentProvider * const cp = [[PEXDbTestProvider alloc] init];

    XCTAssertTrue([cp delete:[PEXDbTestEntity getURI]
     selection:@"WHERE " TESTENTITY_TFIELD_TEXT "=?"
 selectionArgs:@[self.entity1.textField]]);

    PEXDbCursor * const cursor =
            [cp query:[PEXDbTestEntity getURI]
           projection:[PEXDbTestEntity getFullProjection]
            selection:@"WHERE " TESTENTITY_TFIELD_TEXT "=?"
        selectionArgs:@[self.entity1.textField]
            sortOrder:nil];

    XCTAssertEqual([cursor getCount], 0);
}

- (void) assertEntity: (PEXDbTestEntity * const)before
                 with: (PEXDbTestEntity * const)after
{
    XCTAssert([before.textField isEqualToString: after.textField],
            @"Malformed textField: %@ VS %@",
    before.textField, after.textField);
    XCTAssertTrue(before.doubleField.doubleValue == after.doubleField.doubleValue,
            @"Malformed doubleField: %@ VS %@",
            before.doubleField, after.doubleField);
    XCTAssert(before.fieldInt64.longLongValue == after.fieldInt64.longLongValue,
            @"Malformed fieldInt64: %@ VS %@",
            before.fieldInt64, after.fieldInt64);
    XCTAssert([before.blobField isEqualToData: after.blobField],
            @"Malformed blobField: %@ VS %@",
            before.blobField, after.blobField);
}

- (PEXDbTestEntity *) createEntity: (int64_t) fieldInt64
                            double: (double) fieldDouble
                              text: (NSString * const) fieldText
                              blob: (NSData * const) fieldBlob
{
    PEXDbTestEntity *entity = [[PEXDbTestEntity alloc] init];
    entity.fieldInt64 = [[NSNumber alloc] initWithLongLong:fieldInt64];
    entity.doubleField = [[NSNumber alloc] initWithDouble:fieldDouble];
    entity.textField = fieldText;
    entity.blobField = fieldBlob;
    return entity;
}

- (void) assertMoveFreshNotEmptyAndNilCursor: (PEXDbCursor *) cursor
                        numberOfEntities:(const int) num
{

    XCTAssertNotNil(cursor, @"There should a Cursor instance returned from query");

    XCTAssertEqual([cursor getPosition], 0, @"Fresh cursor should be before first");
    XCTAssertTrue([cursor isBeforeFirst], @"Fresh cursor should be before first");
    XCTAssertTrue([cursor moveToNext], @"Cursor has not other element at: %@", [cursor getPosition]);
    XCTAssertEqual([cursor getPosition], 1, @"Fresh cursor should be at the first");
    XCTAssertTrue([cursor isFirst], @"Fresh cursor should be at the first");
    XCTAssertTrue([cursor isFirst], @"Fresh cursor should be at the first");

    XCTAssertEqual([cursor move:200], false);
    XCTAssertEqual([cursor getPosition], 1, @"Cursor should not move after false move");

    XCTAssertTrue([cursor moveToFirst], @"moving to first should be possible");
    XCTAssertEqual([cursor getPosition], 1, @"Cursor should be at the first");
    XCTAssertEqual([cursor move:-1], true, @"we should not be able to move beyond and after");

    XCTAssertTrue( [cursor moveToLast]);
    XCTAssertTrue( [cursor moveToPrevious]);
    XCTAssertEqual([cursor getPosition], num - 1, @"Cursor should be at the num - 1 position");

    XCTAssertEqual([cursor moveToPosition:num + 1], false, @"Cursor should not be able to move to num + 1");
    XCTAssertEqual([cursor moveToPosition:num], true, @"Cursor should not be able to move to num");
}




@end
