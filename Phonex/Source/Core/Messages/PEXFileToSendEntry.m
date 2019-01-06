//
// Created by Dusan Klinec on 27.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFileToSendEntry.h"


@implementation PEXFileToSendEntry {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.doGenerateThumbIfPossible = YES;
        self.file = nil;
        self.title = nil;
        self.desc = nil;
        self.fileDate = nil;
        self.isAsset = NO;
    }

    return self;
}

- (instancetype)initWithFile:(NSString *)file {
    self = [self init];
    if (self) {
        self.file = [NSURL fileURLWithPath:file];
    }

    return self;
}

+ (instancetype)entryWithFile:(NSString *)file {
    return [[self alloc] initWithFile:file];
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [self init];
    if (self) {
        self.file = url;
    }

    return self;
}

- (instancetype)initWithFile:(NSURL *)file isAsset:(BOOL)isAsset {
    self = [self init];
    if (self) {
        self.file = file;
        self.isAsset = isAsset;
    }

    return self;
}

+ (instancetype)entryWithFile:(NSURL *)file isAsset:(BOOL)isAsset {
    return [[self alloc] initWithFile:file isAsset:isAsset];
}


- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        self.file = [coder decodeObjectForKey:@"self.file"];
        self.isAsset = [coder decodeBoolForKey:@"self.isAsset"];
        self.prefFileName = [coder decodeObjectForKey:@"self.prefFileName"];
        self.mimeType = [coder decodeObjectForKey:@"self.mimeType"];
        self.doGenerateThumbIfPossible = [coder decodeBoolForKey:@"self.doGenerateThumbIfPossible"];
        self.fileDate = [coder decodeObjectForKey:@"self.fileDate"];
        self.title = [coder decodeObjectForKey:@"self.title"];
        self.desc = [coder decodeObjectForKey:@"self.desc"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.file forKey:@"self.file"];
    [coder encodeBool:self.isAsset forKey:@"self.isAsset"];
    [coder encodeObject:self.prefFileName forKey:@"self.prefFileName"];
    [coder encodeObject:self.mimeType forKey:@"self.mimeType"];
    [coder encodeBool:self.doGenerateThumbIfPossible forKey:@"self.doGenerateThumbIfPossible"];
    [coder encodeObject:self.fileDate forKey:@"self.fileDate"];
    [coder encodeObject:self.title forKey:@"self.title"];
    [coder encodeObject:self.desc forKey:@"self.desc"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFileToSendEntry *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.file = self.file;
        copy.isAsset = self.isAsset;
        copy.prefFileName = self.prefFileName;
        copy.mimeType = self.mimeType;
        copy.doGenerateThumbIfPossible = self.doGenerateThumbIfPossible;
        copy.fileDate = self.fileDate;
        copy.title = self.title;
        copy.desc = self.desc;
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

- (BOOL)isEqualToEntry:(PEXFileToSendEntry *)entry {
    if (self == entry)
        return YES;
    if (entry == nil)
        return NO;
    if (self.file != entry.file && ![self.file isEqual:entry.file])
        return NO;
    if (self.isAsset != entry.isAsset)
        return NO;
    if (self.prefFileName != entry.prefFileName && ![self.prefFileName isEqualToString:entry.prefFileName])
        return NO;
    if (self.mimeType != entry.mimeType && ![self.mimeType isEqualToString:entry.mimeType])
        return NO;
    if (self.doGenerateThumbIfPossible != entry.doGenerateThumbIfPossible)
        return NO;
    if (self.fileDate != entry.fileDate && ![self.fileDate isEqualToDate:entry.fileDate])
        return NO;
    if (self.title != entry.title && ![self.title isEqualToString:entry.title])
        return NO;
    if (self.desc != entry.desc && ![self.desc isEqualToString:entry.desc])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.file hash];
    hash = hash * 31u + self.isAsset;
    hash = hash * 31u + [self.prefFileName hash];
    hash = hash * 31u + [self.mimeType hash];
    hash = hash * 31u + self.doGenerateThumbIfPossible;
    hash = hash * 31u + [self.fileDate hash];
    hash = hash * 31u + [self.title hash];
    hash = hash * 31u + [self.desc hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.file=%@", self.file];
    [description appendFormat:@", self.isAsset=%d", self.isAsset];
    [description appendFormat:@", self.prefFileName=%@", self.prefFileName];
    [description appendFormat:@", self.mimeType=%@", self.mimeType];
    [description appendFormat:@", self.doGenerateThumbIfPossible=%d", self.doGenerateThumbIfPossible];
    [description appendFormat:@", self.fileDate=%@", self.fileDate];
    [description appendFormat:@", self.title=%@", self.title];
    [description appendFormat:@", self.desc=%@", self.desc];
    [description appendString:@">"];
    return description;
}


+ (instancetype)entryWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}



@end