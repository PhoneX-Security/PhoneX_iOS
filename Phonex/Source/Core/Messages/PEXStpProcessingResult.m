//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXStpProcessingResult.h"


@implementation PEXStpProcessingResult {

}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.ampVersion=%i", self.ampVersion];
    [description appendFormat:@", self.ampType=%i", self.ampType];
    [description appendFormat:@", self.sequenceNumber=%@", self.sequenceNumber];
    [description appendFormat:@", self.nonce=%@", self.nonce];
    [description appendFormat:@", self.sendDate=%llu", self.sendDate];
    [description appendFormat:@", self.sender=%@", self.sender];
    [description appendFormat:@", self.destination=%@", self.destination];
    [description appendFormat:@", self.signatureValid=%d", self.signatureValid];
    [description appendFormat:@", self.hmacValid=%d", self.hmacValid];
    [description appendFormat:@", self.payload=%@", self.payload];
    [description appendString:@">"];
    return description;
}

@end