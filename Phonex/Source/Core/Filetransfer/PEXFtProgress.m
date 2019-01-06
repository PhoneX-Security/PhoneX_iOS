//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtProgress.h"


@implementation PEXFtProgress {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.error = PEX_FT_ERROR_NONE;
        self.done = NO;
    }

    return self;
}


- (id)copyWithZone:(NSZone *)zone {
    PEXFtProgress *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.messageId = self.messageId;
        copy.when = self.when;
        copy.title = self.title;
        copy.progress = self.progress;
        copy.done = self.done;
        copy.error = self.error;
        copy.errorCode = self.errorCode;
        copy.errorString = self.errorString;
        copy.nsError = self.nsError;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToProgress:other];
}

- (BOOL)isEqualToProgress:(PEXFtProgress *)progress {
    if (self == progress)
        return YES;
    if (progress == nil)
        return NO;
    if (self.messageId != progress.messageId)
        return NO;
    if (self.when != progress.when && ![self.when isEqualToDate:progress.when])
        return NO;
    if (self.title != progress.title && ![self.title isEqualToString:progress.title])
        return NO;
    if (self.progress != progress.progress)
        return NO;
    if (self.done != progress.done)
        return NO;
    if (self.error != progress.error)
        return NO;
    if (self.errorCode != progress.errorCode && ![self.errorCode isEqualToNumber:progress.errorCode])
        return NO;
    if (self.errorString != progress.errorString && ![self.errorString isEqualToString:progress.errorString])
        return NO;
    if (self.nsError != progress.nsError && ![self.nsError isEqual:progress.nsError])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.messageId;
    hash = hash * 31u + [self.when hash];
    hash = hash * 31u + [self.title hash];
    hash = hash * 31u + self.progress;
    hash = hash * 31u + self.done;
    hash = hash * 31u + (NSUInteger) self.error;
    hash = hash * 31u + [self.errorCode hash];
    hash = hash * 31u + [self.errorString hash];
    hash = hash * 31u + [self.nsError hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.messageId=%qi", self.messageId];
    [description appendFormat:@", self.when=%@", self.when];
    [description appendFormat:@", self.progressCode=%d", self.progressCode];
    [description appendFormat:@", self.title=%@", self.title];
    [description appendFormat:@", self.progress=%i", self.progress];
    [description appendFormat:@", self.done=%d", self.done];
    [description appendFormat:@", self.error=%d", self.error];
    [description appendFormat:@", self.errorCode=%@", self.errorCode];
    [description appendFormat:@", self.errorString=%@", self.errorString];
    [description appendFormat:@", self.nsError=%@", self.nsError];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.messageId = [coder decodeInt64ForKey:@"self.messageId"];
        self.when = [coder decodeObjectForKey:@"self.when"];
        self.progressCode = (PEXFtProgressEnum) [coder decodeIntForKey:@"self.progressCode"];
        self.title = [coder decodeObjectForKey:@"self.title"];
        self.progress = [coder decodeIntForKey:@"self.progress"];
        self.done = [coder decodeBoolForKey:@"self.done"];
        self.error = (PEXFtError) [coder decodeIntForKey:@"self.error"];
        self.errorCode = [coder decodeObjectForKey:@"self.errorCode"];
        self.errorString = [coder decodeObjectForKey:@"self.errorString"];
        self.nsError = [coder decodeObjectForKey:@"self.nsError"];
    }

    return self;
}

- (instancetype)initWithMessageId:(int64_t)messageId progressCode:(PEXFtProgressEnum)progressCode progress:(int)progress {
    self = [super init];
    if (self) {
        self.messageId = messageId;
        self.progressCode = progressCode;
        self.progress = progress;
        self.when = [NSDate date];
    }

    return self;
}

+ (instancetype)progressWithMessageId:(int64_t)messageId progressCode:(PEXFtProgressEnum)progressCode progress:(int)progress {
    return [[self alloc] initWithMessageId:messageId progressCode:progressCode progress:progress];
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.messageId forKey:@"self.messageId"];
    [coder encodeObject:self.when forKey:@"self.when"];
    [coder encodeInt:self.progressCode forKey:@"self.progressCode"];
    [coder encodeObject:self.title forKey:@"self.title"];
    [coder encodeInt:self.progress forKey:@"self.progress"];
    [coder encodeBool:self.done forKey:@"self.done"];
    [coder encodeInt:self.error forKey:@"self.error"];
    [coder encodeObject:self.errorCode forKey:@"self.errorCode"];
    [coder encodeObject:self.errorString forKey:@"self.errorString"];
    [coder encodeObject:self.nsError forKey:@"self.nsError"];
}


+ (BOOL)isTryAgainError:(PEXFtError)errCode {
    return  errCode==PEX_FT_ERROR_NONE ||
            errCode==PEX_FT_ERROR_CERTIFICATE_MISSING ||
            errCode==PEX_FT_ERROR_GENERIC_ERROR ||
            errCode==PEX_FT_ERROR_UPD_QUOTA_EXCEEDED ||
            errCode==PEX_FT_ERROR_UPD_NO_AVAILABLE_DHKEYS ||
            errCode==PEX_FT_ERROR_UPD_UPLOAD_ERROR ||
            errCode==PEX_FT_ERROR_DOWN_DOWNLOAD_ERROR ||
            errCode==PEX_FT_ERROR_BAD_RESPONSE ||
            errCode==PEX_FT_ERROR_TIMEOUT;
}

@end