//
//  PEXPriotityTestObject.h
//  PEXPriorityQueueUnitTests
//
//  Created by Jesse Collis on 26/02/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPriorityQueue.h"

@interface PEXPriotityTestObject : NSObject <PEXPriorityQueueObject>

@property (nonatomic) double cost;

+ (id)objectWithValue:(double)value;

- (id)initWithValue:(double)value;

@end
