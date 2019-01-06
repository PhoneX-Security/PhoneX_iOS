//
//  PEXLoginTaskEvents.m
//  Phonex
//
//  Created by Matej Oravec on 30/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXLoginTaskEvents.h"
#import "PEXLoginTaskResult.h"

@implementation PEXLoginTaskEventProgress

- (instancetype)init {
    self = [super init];
    if (self) {
        _stage = PEX_LOGIN_STAGE_1;
        self.progress = nil;
        self.ignoreStage = YES;
    }

    return self;
}


- (id) initWithStage: (const PEXLoginStage) stage {
    self = [self init];
    _stage = stage;
    self.progress = nil;
    self.ignoreStage = NO;
    return self;
}

- (PEXLoginStage) stage { return _stage; };

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_stage=%ld", (long)_stage];
    [description appendFormat:@", self.progress=%@", self.progress];
    [description appendFormat:@", self.ignoreStage=%d", self.ignoreStage];
    [description appendString:@">"];
    return description;
}

@end


@interface PEXLoginTaskEventEnd ()
@property (nonatomic) PEXLoginTaskResult * result;
@end

@implementation PEXLoginTaskEventEnd

- (id) initWithResult:(PEXLoginTaskResult * const )result
{
    self = [super init];
    self.result = result;
    return self;
}

- (PEXLoginTaskResult *) getResult { return self.result; }

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.result=%@", self.result];
    [description appendString:@">"];
    return description;
}


@end