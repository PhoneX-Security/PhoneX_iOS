//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtDownloadEntry.h"
#import "PEXFtDownloadFileParams.h"


@implementation PEXFtDownloadEntry {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cancelled = NO;
        self.processingStarted = NO;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.params = [coder decodeObjectForKey:@"self.params"];
        self.storeResult = [coder decodeBoolForKey:@"self.storeResult"];
        self.deleteOnly = [coder decodeBoolForKey:@"self.deleteOnly"];
        self.cancelled = [coder decodeBoolForKey:@"self.cancelled"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.params forKey:@"self.params"];
    [coder encodeBool:self.storeResult forKey:@"self.storeResult"];
    [coder encodeBool:self.deleteOnly forKey:@"self.deleteOnly"];
    [coder encodeBool:self.cancelled forKey:@"self.cancelled"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtDownloadEntry *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.params = self.params;
        copy.storeResult = self.storeResult;
        copy.deleteOnly = self.deleteOnly;
        copy.cancelled = self.cancelled;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToEntry:other];
}

- (BOOL)isEqualToEntry:(PEXFtDownloadEntry *)entry {
    if (self == entry)
        return YES;
    if (entry == nil)
        return NO;
    if (self.params != entry.params && ![self.params isEqualToParams:entry.params])
        return NO;
    if (self.storeResult != entry.storeResult)
        return NO;
    if (self.deleteOnly != entry.deleteOnly)
        return NO;
    if (self.cancelled != entry.cancelled)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.params hash];
    hash = hash * 31u + self.storeResult;
    hash = hash * 31u + self.deleteOnly;
    hash = hash * 31u + self.cancelled;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.params=%@", self.params];
    [description appendFormat:@", self.storeResult=%d", self.storeResult];
    [description appendFormat:@", self.deleteOnly=%d", self.deleteOnly];
    [description appendFormat:@", self.cancelled=%d", self.cancelled];
    [description appendString:@">"];
    return description;
}

@end