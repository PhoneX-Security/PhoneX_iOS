//
//  Unit_Tests.m
//  Unit Tests
//
//  Created by Jesse Collis on 26/02/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import "PEXPriorityQueueTests.h"
#import "PEXPriorityQueue.h"
#import "PEXPriotityTestObject.h"

@interface PEXPriorityQueueTests (){
  PEXPriorityQueue *_queue;
  double _details[25];
}

@end

static const  double testData[25] = {
  10.0,20.0,40.0,90.0,100.0,
  320.0,900.0,657.0,225.0,854.0,
  1689.0,5465.0,5123.0,6548.0,0.0,
  63876.0,32656.0,12368.0,95641.0,5.0,
  -123.0,-12345.0,-123456.0,-987.0,-43.0};

@implementation PEXPriorityQueueTests

- (void)setUp
{
  [super setUp];
  _queue = [[PEXPriorityQueue alloc] init];

  memcpy(_details, testData, sizeof(testData));
}

- (void)tearDown
{
  [super tearDown];
  
  _queue = nil;
}

- (void)testPriorityQueueReturnsNilWithEmptyQueue
{
  id<PEXPriorityQueueObject> first = [_queue pop];
  XCTAssertNil(first,@"Empty Queue should return nil if empty");
}

- (void)testPriorityQueueRemovesAnItemWhenItSaysItDoes
{
  [_queue addObject:[PEXPriotityTestObject objectWithValue:10.0]];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:20.0]];
  
  [_queue pop];
  
  XCTAssertEqual([_queue count], 2.0, @"add two, pop one should leave a count of two (default is count of 1)");
}


- (void)testPriorityQueueReturnsCorrectObjectWhenZeroAddedAsSingleObject
{
  id first_object = [PEXPriotityTestObject objectWithValue:0.0];
  [_queue addObject:first_object];
  
  id first_returned = [_queue pop];
  
  XCTAssertEqualObjects(first_object, first_returned, @"Adding one object then popping that object should return the same objet");
}

- (void)testPriorityQueueHandlesANegativeValue
{
  id first_object = [PEXPriotityTestObject objectWithValue:-49876.0];
  [_queue addObject:first_object];
  
  id first_returned = [_queue pop];

  XCTAssertEqualObjects(first_object, first_returned, @"Adding one object then popping that object should return the same objet");
}

- (void)testPriorityQueueHandlesSinglePositiveObject
{
  id<PEXPriorityQueueObject> first_object = [PEXPriotityTestObject objectWithValue:10];
  [_queue addObject:first_object];
  
  id<PEXPriorityQueueObject> first_returned = [_queue pop];

   XCTAssertEqualObjects(first_object, first_returned, @"First element returned should be the same object originally added");
   XCTAssertEqual(first_object.cost, 10.0, @"First element should be equal to the element added. Value was %d", first_returned.cost);
}

- (void)testPriorityQueueHandlesAFewPredictableValues
{
  [_queue addObject:[PEXPriotityTestObject objectWithValue:20.0]];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:10.0]];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:30.0]];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:40.0]];
  
  id <PEXPriorityQueueObject> obj = [_queue pop];
  XCTAssert(obj.cost == 10.0);
  
  obj = [_queue pop];
  XCTAssertTrue(obj.cost == 20.0);

  obj = [_queue pop];
  XCTAssertTrue(obj.cost == 30.0);

  obj = [_queue pop];
  XCTAssertTrue(obj.cost == 40.0);
  
  obj = [_queue pop];
  XCTAssertTrue(obj == nil);
}

- (void)testPriorityQueueHandlesLotsOfRandomValues
{
  double lowest_value = DBL_MAX;
  size_t size_of_details = sizeof(_details) / sizeof(*_details);

  srand(time(NULL));

  for (int i = 0; i < 500; i++)
  {
    int index = rand() % size_of_details;
    double value = _details[index];

    if (value < lowest_value)
    {
      lowest_value = value;
    }

    [_queue addObject:[PEXPriotityTestObject objectWithValue:value]];
  }
  
  id<PEXPriorityQueueObject> first_out = [_queue pop];

  XCTAssertEqual(first_out.cost, lowest_value, @"Popping the first value should be equal to the lowest entered");
}

- (void)testPriorityQueueCanResortBasedOnAValueChange
{
  PEXPriotityTestObject *sample = [PEXPriotityTestObject objectWithValue:20.0];
  PEXPriotityTestObject *first_top = [PEXPriotityTestObject objectWithValue:10.0];

  [_queue addObject:sample];
  [_queue addObject:first_top];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:30.0]];
  [_queue addObject:[PEXPriotityTestObject objectWithValue:40.0]];

  XCTAssertEqualObjects([_queue first], first_top, @"first item should be the lowerst so far");

  sample.cost = 5.0;
  [_queue resort:sample];

  XCTAssertEqualObjects([_queue first], sample, @"first item should now be the one just modified");
}


@end
