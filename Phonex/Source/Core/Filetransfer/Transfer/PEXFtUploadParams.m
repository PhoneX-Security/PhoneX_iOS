//
// Created by Dusan Klinec on 26.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFtUploadParams.h"


@implementation PEXFtUploadParams {

}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.files = [coder decodeObjectForKey:@"self.files"];
        self.destinationSip = [coder decodeObjectForKey:@"self.destinationSip"];
        self.msgId = [coder decodeObjectForKey:@"self.msgId"];
        self.queueMsgId = [coder decodeObjectForKey:@"self.queueMsgId"];
        self.title = [coder decodeObjectForKey:@"self.title"];
        self.desc = [coder decodeObjectForKey:@"self.desc"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.files forKey:@"self.files"];
    [coder encodeObject:self.destinationSip forKey:@"self.destinationSip"];
    [coder encodeObject:self.msgId forKey:@"self.msgId"];
    [coder encodeObject:self.queueMsgId forKey:@"self.queueMsgId"];
    [coder encodeObject:self.title forKey:@"self.title"];
    [coder encodeObject:self.desc forKey:@"self.desc"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXFtUploadParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.files = self.files;
        copy.destinationSip = self.destinationSip;
        copy.msgId = self.msgId;
        copy.queueMsgId = self.queueMsgId;
        copy.title = self.title;
        copy.desc = self.desc;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.files=%@", self.files];
    [description appendFormat:@", self.destinationSip=%@", self.destinationSip];
    [description appendFormat:@", self.msgId=%@", self.msgId];
    [description appendFormat:@", self.queueMsgId=%@", self.queueMsgId];
    [description appendFormat:@", self.title=%@", self.title];
    [description appendFormat:@", self.desc=%@", self.desc];
    [description appendString:@">"];
    return description;
}


@end