//
// Created by Dusan Klinec on 17.09.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXMovingAverage : NSObject
@property (nonatomic) double smoothingFactor;
@property (nonatomic) double current;

@property (nonatomic) NSNumber * valMax;
@property (nonatomic) NSNumber * valMin;

- (instancetype)initWithSmoothingFactor:(double)smoothingFactor;
+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor;
- (instancetype)initWithSmoothingFactor:(double)smoothingFactor current:(double)current;
+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor current:(double)current;

- (instancetype)initWithSmoothingFactor:(double)smoothingFactor current:(double)current valMax:(NSNumber *)valMax valMin:(NSNumber *)valMin;

+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor current:(double)current valMax:(NSNumber *)valMax valMin:(NSNumber *)valMin;


- (double) update: (double) newValue;

- (NSString *)description;

@end