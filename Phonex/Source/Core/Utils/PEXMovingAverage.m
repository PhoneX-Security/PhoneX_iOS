//
// Created by Dusan Klinec on 17.09.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMovingAverage.h"


@implementation PEXMovingAverage {

}
- (instancetype)initWithSmoothingFactor:(double)smoothingFactor current:(double)current {
    self = [super init];
    if (self) {
        self.smoothingFactor = smoothingFactor;
        self.current = current;
    }

    return self;
}

- (instancetype)initWithSmoothingFactor:(double)smoothingFactor {
    self = [super init];
    if (self) {
        self.smoothingFactor = smoothingFactor;
    }

    return self;
}

- (instancetype)initWithSmoothingFactor:(double)smoothingFactor current:(double)current valMax:(NSNumber *)valMax valMin:(NSNumber *)valMin {
    self = [super init];
    if (self) {
        self.smoothingFactor = smoothingFactor;
        self.current = current;
        self.valMax = valMax;
        self.valMin = valMin;
    }

    return self;
}

+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor current:(double)current valMax:(NSNumber *)valMax valMin:(NSNumber *)valMin {
    return [[self alloc] initWithSmoothingFactor:smoothingFactor current:current valMax:valMax valMin:valMin];
}


+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor {
    return [[self alloc] initWithSmoothingFactor:smoothingFactor];
}


+ (instancetype)averageWithSmoothingFactor:(double)smoothingFactor current:(double)current {
    return [[self alloc] initWithSmoothingFactor:smoothingFactor current:current];
}

- (double)update:(double)newValue {
    double newVal = _smoothingFactor * newValue + (1.0-_smoothingFactor) * _current;

    if (_valMax != nil && newVal > [_valMax doubleValue]){
        newVal = [_valMax doubleValue];
    }

    if (_valMin != nil && newVal < [_valMin doubleValue]){
        newVal = [_valMin doubleValue];
    }

    _current = newVal;
    return newVal;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%lf", self.current];
}

@end