//
// Created by Dusan Klinec on 19.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXMessageModel.h"
#import "PEXDBMessage.h"
#import "PEXDbReceivedFile.h"
#import "PEXInTextData.h"


@implementation PEXMessageModel {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.numDataDetectedInBody = 0;
        self.dataDetectionFinished = NO;
        self.dataDetectionStarted = NO;
        self.cellSizeForItem = CGSizeZero;
        self.cellSizeOk = NO;
    }

    return self;
}

- (instancetype)initWithMessage:(PEXDbMessage *)message {
    self = [self init];
    if (self) {
        self.message = message;
        [self fillAttributedText];
    }

    return self;
}

- (void) fillAttributedText {
    self.attributedString = [[NSMutableAttributedString alloc] initWithString:self.message.body];
    const NSRange fullRange = NSMakeRange(0, [self.attributedString length]);
    [self.attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:PEXVal(@"dim_size_medium")] range:fullRange];
}

- (void)dirty {
    self.cellSizeOk = NO;
    self.cellSizeForItem = CGSizeZero;
    self.dataDetectionStarted = NO;
    self.dataDetectionFinished = NO;
    DDLogVerbose(@"Dirty dirty message %@", self.id);
}

- (NSString *)body {
    return self.message.body;
}

- (NSDate *)date {
    return self.message.date;
}

- (void)setDate:(NSDate *)date {
    self.message.date = date;
}

- (void)setBody:(NSString *)body {
    self.message.body = body;
}

- (BOOL)isFile {
    return [self.message isFile];
}

- (BOOL)outgoing {
    return self.message.isOutgoing.integerValue > 0;
}

- (NSNumber *)isOutgoing {
    return self.message.isOutgoing;
}

- (NSNumber *)id {
    return self.message.id;
}

+ (instancetype)modelWithMessage:(PEXDbMessage *)message {
    return [[self alloc] initWithMessage:message];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXMessageModel *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.attributedString = self.attributedString;
        copy.message = self.message;
        copy.numDataDetectedInBody = self.numDataDetectedInBody;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToModel:other];
}

- (BOOL)isEqualToModel:(PEXMessageModel *)model {
    if (self == model)
        return YES;
    if (model == nil)
        return NO;
    if (self.message != model.message && ![self.message isEqualToMessage:model.message])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    return [self.message hash];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.attributedString = [coder decodeObjectForKey:@"self.attributedString"];
        self.message = [coder decodeObjectForKey:@"self.message"];
        self.numDataDetectedInBody = [coder decodeInt64ForKey:@"self.numDataDetectedInBody"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.attributedString forKey:@"self.attributedString"];
    [coder encodeObject:self.message forKey:@"self.message"];
    [coder encodeInt64:self.numDataDetectedInBody forKey:@"self.numDataDetectedInBody"];
}


@end