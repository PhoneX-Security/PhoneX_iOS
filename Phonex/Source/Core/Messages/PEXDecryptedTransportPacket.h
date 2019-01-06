//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXStpProcessingResult.h"

@interface PEXDecryptedTransportPacket : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSData * payload;
@property(nonatomic) BOOL payloadIsString;
@property(nonatomic) int ampType;
@property(nonatomic) int ampVersion;

@property(nonatomic) BOOL isValid;

@property(nonatomic) NSNumber * nonce; //Integer
@property(nonatomic) NSNumber * sendDate; //Long
@property(nonatomic) NSString * from;
@property(nonatomic) NSString * to;
@property(nonatomic) NSNumber * isOffline;

@property(nonatomic) BOOL macValid;
@property(nonatomic) BOOL signatureValid;
@property(nonatomic) NSDictionary * properties;

// legacy properties
@property(nonatomic) NSString * transportPacketHash;

+(PEXDecryptedTransportPacket *) initFrom: (PEXStpProcessingResult *) output;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

@end