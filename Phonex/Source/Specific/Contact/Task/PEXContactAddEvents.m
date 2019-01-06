//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactAddEvents.h"


@implementation PEXContactAddTaskEventProgress
- (instancetype)init {
    self = [super init];
    if (self) {
        _stage = PEX_CONTACT_ADD_STAGE_1;
        self.progress = nil;
        self.ignoreStage = YES;
    }

    return self;
}


- (id) initWithStage: (const PEXContactAddStage) stage {
    self = [self init];
    _stage = stage;
    self.progress = nil;
    self.ignoreStage = NO;
    return self;
}

- (PEXContactAddStage) stage { return _stage; };

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"_stage=%ld", (long)_stage];
    [description appendFormat:@", self.progress=%@", self.progress];
    [description appendFormat:@", self.ignoreStage=%d", self.ignoreStage];
    [description appendString:@">"];
    return description;
}

@end

@implementation PEXContactAddResult
- (instancetype)initWithResultDescription:(PEXContactAddResultDescription)desc {
    self = [super init];
    if (self) {
        self.resultDescription = desc;
    }

    return self;
}

+ (instancetype)resultWithDesc:(PEXContactAddResultDescription)desc {
    return [[self alloc] initWithResultDescription:desc];
}

@end

@interface PEXContactAddTaskEventEnd ()
@property (nonatomic) PEXContactAddResult * result;
@end

@implementation PEXContactAddTaskEventEnd

- (id) initWithResult:(PEXContactAddResult * const )result
{
    self = [super init];
    self.result = result;
    return self;
}

- (PEXContactAddResult *) getResult { return self.result; }

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.result=%@", self.result];
    [description appendString:@">"];
    return description;
}

@end

