//
//  PEXPriotityTestObject.m
//  PEXPriorityQueueUnitTests
//
//  Created by Jesse Collis on 26/02/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import "PEXPriotityTestObject.h"
#import "PEXPriorityQueue.h"

@implementation PEXPriotityTestObject

@synthesize cost = _cost;

+ (id)objectWithValue:(double)value
{
  return [[self alloc] initWithValue:value];
}

- (id)init
{
  return [self initWithValue:0.0];
}

- (id)initWithValue:(double)value
{
  if ((self = [super init]))
  {
    _cost = value;
  }
  return self;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%f", _cost];
}

@end
