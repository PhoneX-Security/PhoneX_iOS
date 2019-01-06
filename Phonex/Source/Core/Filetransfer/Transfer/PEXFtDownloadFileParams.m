//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtDownloadFileParams.h"


@implementation PEXFtDownloadFileParams {}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.destinationDirectory = nil;
        self.msgId = nil;
        self.nonce2 = nil;
        self.createDestinationDirIfNeeded = YES;
        self.deleteOnly = NO;
        self.conflictAction = PEX_FILECOPY_RENAME_NEW;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.nonce2 = [coder decodeObjectForKey:@"self.nonce2"];
        self.msgId = [coder decodeObjectForKey:@"self.msgId"];
        self.queueMsgId = [coder decodeObjectForKey:@"self.queueMsgId"];
        self.destinationDirectory = [coder decodeObjectForKey:@"self.destinationDirectory"];
        self.createDestinationDirIfNeeded = [coder decodeBoolForKey:@"self.createDestinationDirIfNeeded"];
        self.conflictAction = (PEXFtFilenameConflictCopyAction) [coder decodeIntForKey:@"self.conflictAction"];
        self.deleteOnly = [coder decodeBoolForKey:@"self.deleteOnly"];
        self.deleteOnSuccess = [coder decodeBoolForKey:@"self.deleteOnSuccess"];
        self.downloadFullArchiveNow = [coder decodeBoolForKey:@"self.downloadFullArchiveNow"];
        self.downloadFullIfOnWifiAndUnderThreshold = [coder decodeBoolForKey:@"self.downloadFullIfOnWifiAndUnderThreshold"];
        self.fileTypeIdx = [coder decodeInt64ForKey:@"self.fileTypeIdx"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.nonce2 forKey:@"self.nonce2"];
    [coder encodeObject:self.msgId forKey:@"self.msgId"];
    [coder encodeObject:self.queueMsgId forKey:@"self.queueMsgId"];
    [coder encodeObject:self.destinationDirectory forKey:@"self.destinationDirectory"];
    [coder encodeBool:self.createDestinationDirIfNeeded forKey:@"self.createDestinationDirIfNeeded"];
    [coder encodeInt:self.conflictAction forKey:@"self.conflictAction"];
    [coder encodeBool:self.deleteOnly forKey:@"self.deleteOnly"];
    [coder encodeBool:self.deleteOnSuccess forKey:@"self.deleteOnSuccess"];
    [coder encodeBool:self.downloadFullArchiveNow forKey:@"self.downloadFullArchiveNow"];
    [coder encodeBool:self.downloadFullIfOnWifiAndUnderThreshold forKey:@"self.downloadFullIfOnWifiAndUnderThreshold"];
    [coder encodeInt64:self.fileTypeIdx forKey:@"self.fileTypeIdx"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtDownloadFileParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.nonce2 = self.nonce2;
        copy.msgId = self.msgId;
        copy.queueMsgId = self.queueMsgId;
        copy.destinationDirectory = self.destinationDirectory;
        copy.createDestinationDirIfNeeded = self.createDestinationDirIfNeeded;
        copy.conflictAction = self.conflictAction;
        copy.deleteOnly = self.deleteOnly;
        copy.deleteOnSuccess = self.deleteOnSuccess;
        copy.downloadFullArchiveNow = self.downloadFullArchiveNow;
        copy.downloadFullIfOnWifiAndUnderThreshold = self.downloadFullIfOnWifiAndUnderThreshold;
        copy.fileTypeIdx = self.fileTypeIdx;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToParams:other];
}

- (BOOL)isEqualToParams:(PEXFtDownloadFileParams *)params {
    if (self == params)
        return YES;
    if (params == nil)
        return NO;
    if (self.nonce2 != params.nonce2 && ![self.nonce2 isEqualToString:params.nonce2])
        return NO;
    if (self.msgId != params.msgId && ![self.msgId isEqualToNumber:params.msgId])
        return NO;
    if (self.queueMsgId != params.queueMsgId && ![self.queueMsgId isEqualToNumber:params.queueMsgId])
        return NO;
    if (self.destinationDirectory != params.destinationDirectory && ![self.destinationDirectory isEqualToString:params.destinationDirectory])
        return NO;
    if (self.createDestinationDirIfNeeded != params.createDestinationDirIfNeeded)
        return NO;
    if (self.conflictAction != params.conflictAction)
        return NO;
    if (self.deleteOnly != params.deleteOnly)
        return NO;
    if (self.deleteOnSuccess != params.deleteOnSuccess)
        return NO;
    if (self.downloadFullArchiveNow != params.downloadFullArchiveNow)
        return NO;
    if (self.downloadFullIfOnWifiAndUnderThreshold != params.downloadFullIfOnWifiAndUnderThreshold)
        return NO;
    if (self.fileTypeIdx != params.fileTypeIdx)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.nonce2 hash];
    hash = hash * 31u + [self.msgId hash];
    hash = hash * 31u + [self.queueMsgId hash];
    hash = hash * 31u + [self.destinationDirectory hash];
    hash = hash * 31u + self.createDestinationDirIfNeeded;
    hash = hash * 31u + (NSUInteger) self.conflictAction;
    hash = hash * 31u + self.deleteOnly;
    hash = hash * 31u + self.deleteOnSuccess;
    hash = hash * 31u + self.downloadFullArchiveNow;
    hash = hash * 31u + self.downloadFullIfOnWifiAndUnderThreshold;
    hash = hash * 31u + self.fileTypeIdx;
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.nonce2=%@", self.nonce2];
    [description appendFormat:@", self.msgId=%@", self.msgId];
    [description appendFormat:@", self.queueMsgId=%@", self.queueMsgId];
    [description appendFormat:@", self.destinationDirectory=%@", self.destinationDirectory];
    [description appendFormat:@", self.createDestinationDirIfNeeded=%d", self.createDestinationDirIfNeeded];
    [description appendFormat:@", self.conflictAction=%d", self.conflictAction];
    [description appendFormat:@", self.deleteOnly=%d", self.deleteOnly];
    [description appendFormat:@", self.deleteOnSuccess=%d", self.deleteOnSuccess];
    [description appendFormat:@", self.downloadFullArchiveNow=%d", self.downloadFullArchiveNow];
    [description appendFormat:@", self.downloadFullIfOnWifiAndUnderThreshold=%d", self.downloadFullIfOnWifiAndUnderThreshold];
    [description appendFormat:@", self.fileTypeIdx=%lu", (unsigned long)self.fileTypeIdx];
    [description appendString:@">"];
    return description;
}


@end