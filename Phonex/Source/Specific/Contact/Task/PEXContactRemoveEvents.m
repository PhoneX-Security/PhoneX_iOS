//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactRemoveEvents.h"

@implementation PEXContactRemoveResult
- (instancetype)initWithResultDescription:(PEXContactRemoveResultDescription)desc {
    self = [super init];
    if (self) {
        self.resultDescription = desc;
    }

    return self;
}

+ (instancetype)resultWithDesc:(PEXContactRemoveResultDescription)desc {
    return [[self alloc] initWithResultDescription:desc];
}

@end

@interface PEXContactRemoveTaskEventEnd ()
@property (nonatomic) PEXContactRemoveResult * result;
@end

@implementation PEXContactRemoveTaskEventEnd

- (id) initWithResult:(PEXContactRemoveResult * const )result
{
    self = [super init];
    self.result = result;
    return self;
}

- (PEXContactRemoveResult *) getResult { return self.result; }

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.result=%@", self.result];
    [description appendString:@">"];
    return description;
}

@end
