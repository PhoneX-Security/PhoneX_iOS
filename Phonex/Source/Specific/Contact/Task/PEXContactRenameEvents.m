//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXContactRenameEvents.h"

@implementation PEXContactRenameResult
- (instancetype)initWithResultDescription:(PEXContactRenameResultDescription)desc {
    self = [super init];
    if (self) {
        self.resultDescription = desc;
    }

    return self;
}

+ (instancetype)resultWithDesc:(PEXContactRenameResultDescription)desc {
    return [[self alloc] initWithResultDescription:desc];
}

@end

@interface PEXContactRenameTaskEventEnd ()
@property (nonatomic) PEXContactRenameResult * result;
@end

@implementation PEXContactRenameTaskEventEnd

- (id) initWithResult:(PEXContactRenameResult * const )result
{
    self = [super init];
    self.result = result;
    return self;
}

- (PEXContactRenameResult *) getResult { return self.result; }

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.result=%@", self.result];
    [description appendString:@">"];
    return description;
}

@end
