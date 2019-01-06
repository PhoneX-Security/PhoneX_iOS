//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDecryptedTransportPacket.h"
#import "PEXStpProcessingResult.h"


@implementation PEXDecryptedTransportPacket {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.payloadIsString = NO;
        self.isValid = NO;
        self.macValid = NO;
        self.signatureValid = NO;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.ampType = [coder decodeIntForKey:@"self.ampType"];
        self.payload = [coder decodeObjectForKey:@"self.payload"];
        self.payloadIsString = [coder decodeBoolForKey:@"self.payloadIsString"];
        self.ampVersion = [coder decodeIntForKey:@"self.ampVersion"];
        self.isValid = [coder decodeBoolForKey:@"self.isValid"];
        self.nonce = [coder decodeObjectForKey:@"self.nonce"];
        self.sendDate = [coder decodeObjectForKey:@"self.sendDate"];
        self.from = [coder decodeObjectForKey:@"self.from"];
        self.to = [coder decodeObjectForKey:@"self.to"];
        self.isOffline = [coder decodeObjectForKey:@"self.isOffline"];
        self.macValid = [coder decodeBoolForKey:@"self.macValid"];
        self.signatureValid = [coder decodeBoolForKey:@"self.signatureValid"];
        self.properties = [coder decodeObjectForKey:@"self.properties"];
        self.transportPacketHash = [coder decodeObjectForKey:@"self.transportPacketHash"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.ampType forKey:@"self.ampType"];
    [coder encodeObject:self.payload forKey:@"self.payload"];
    [coder encodeBool:self.payloadIsString forKey:@"self.payloadIsString"];
    [coder encodeInt:self.ampVersion forKey:@"self.ampVersion"];
    [coder encodeBool:self.isValid forKey:@"self.isValid"];
    [coder encodeObject:self.nonce forKey:@"self.nonce"];
    [coder encodeObject:self.sendDate forKey:@"self.sendDate"];
    [coder encodeObject:self.from forKey:@"self.from"];
    [coder encodeObject:self.to forKey:@"self.to"];
    [coder encodeObject:self.isOffline forKey:@"self.isOffline"];
    [coder encodeBool:self.macValid forKey:@"self.macValid"];
    [coder encodeBool:self.signatureValid forKey:@"self.signatureValid"];
    [coder encodeObject:self.properties forKey:@"self.properties"];
    [coder encodeObject:self.transportPacketHash forKey:@"self.transportPacketHash"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXDecryptedTransportPacket *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.ampType = self.ampType;
        copy.payload = self.payload;
        copy.payloadIsString = self.payloadIsString;
        copy.ampVersion = self.ampVersion;
        copy.isValid = self.isValid;
        copy.nonce = self.nonce;
        copy.sendDate = self.sendDate;
        copy.from = self.from;
        copy.to = self.to;
        copy.isOffline = self.isOffline;
        copy.macValid = self.macValid;
        copy.signatureValid = self.signatureValid;
        copy.properties = self.properties;
        copy.transportPacketHash = self.transportPacketHash;
    }

    return copy;
}


+(PEXDecryptedTransportPacket *) initFrom: (PEXStpProcessingResult *) output {
    PEXDecryptedTransportPacket * packet = [[PEXDecryptedTransportPacket alloc] init];
    packet.ampType = output.ampType;
    packet.ampVersion = output.ampVersion;
    packet.to = output.destination;
    packet.from = output.sender;
    packet.nonce = output.nonce;

    packet.sendDate = @(output.sendDate);
    packet.macValid = output.hmacValid;
    packet.signatureValid = output.signatureValid;

    packet.isValid = output.signatureValid && output.hmacValid;

    packet.properties = [[NSDictionary alloc] init];
    packet.payload = output.payload;
    return packet;
}

@end