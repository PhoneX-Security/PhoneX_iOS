//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtUploadEntry.h"
#import "PEXFtUploadParams.h"


@implementation PEXFtUploadEntry {}
- (instancetype)init {
    self = [super init];
    if (self) {
        _cancelled = NO;
        _processingStarted = NO;
        _params = nil;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.cancelled = [coder decodeBoolForKey:@"self.cancelled"];
        self.params = [coder decodeObjectForKey:@"self.params"];
        self.processingStarted = [coder decodeBoolForKey:@"self.processingStarted"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.cancelled forKey:@"self.cancelled"];
    [coder encodeObject:self.params forKey:@"self.params"];
    [coder encodeBool:self.processingStarted forKey:@"self.processingStarted"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtUploadEntry *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.cancelled = self.cancelled;
        copy.params = self.params;
        copy.processingStarted = self.processingStarted;
    }

    return copy;
}


@end