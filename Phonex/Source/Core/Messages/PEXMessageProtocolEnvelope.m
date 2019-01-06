//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMessageProtocolEnvelope.h"
#import "PEXProtocols.h"
#import "USAdditions.h"
#import "PBGeneratedMessage+PEX.h"


@implementation PEXMessageProtocolEnvelope {

}
- (instancetype)initWithEnvelope:(PEXPbMessageProtocolEnvelope *)envelope {
    self = [super init];
    if (self) {
        self.envelope = envelope;
    }

    return self;
}

+ (instancetype)envelopeWithEnvelope:(PEXPbMessageProtocolEnvelope *)envelope {
    return [[self alloc] initWithEnvelope:envelope];
}

+(PEXPbMessageProtocolEnvelope *) buildEnvelope: (NSData *) payload protocolType: (PEXProtocolType) protocolType
                                 protocolVersion: (PEXProtocolVersion) protocolVersion
{
    PEXPbMessageProtocolEnvelopeBuilder * builder = [[PEXPbMessageProtocolEnvelopeBuilder alloc] init];
    [builder setPayload:payload];
    [builder setProtocolType:protocolType];
    [builder setProtocolVersion:protocolVersion];
    return [builder build];
}

+(PEXMessageProtocolEnvelope *) createEnvelope: (NSData *) payload protocolType: (PEXProtocolType) protocolType
                                 protocolVersion: (PEXProtocolVersion) protocolVersion
{
    PEXPbMessageProtocolEnvelope * env = [self buildEnvelope:payload protocolType:protocolType protocolVersion:protocolVersion];
    return [[PEXMessageProtocolEnvelope alloc] initWithEnvelope:env];
}

+(PEXMessageProtocolEnvelope *) createEnvelope: (NSString *) textPayload {
    return [self createEnvelopeData:[NSData dataWithBase64EncodedString:textPayload]];
}

+(PEXMessageProtocolEnvelope *) createEnvelopeData: (NSData *) serializedEnvelope {
    PEXPbMessageProtocolEnvelope * env = [PEXPbMessageProtocolEnvelope parseFromData:serializedEnvelope];
    return [PEXMessageProtocolEnvelope envelopeWithEnvelope:env];
}

-(PEXProtocolType) getProtocolType{
    return self.envelope.protocolType;
}

-(PEXProtocolVersion) getProtocolVersion{
    return self.envelope.protocolVersion;
}

-(NSData *) getPayload{
    return self.envelope.payload;
}

-(NSData *) getSerialized{
    return [self.envelope writeToCodedNSData];
}

-(NSString *) getBase64EncodedSerialized {
    return [[self getSerialized] base64EncodedStringWithOptions:0];
}

@end