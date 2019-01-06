//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPbMessage.pb.h"
#import "PEXProtocols.h"

@interface PEXMessageProtocolEnvelope : NSObject
@property(nonatomic) PEXPbMessageProtocolEnvelope * envelope;

- (instancetype)initWithEnvelope:(PEXPbMessageProtocolEnvelope *)envelope;
+ (instancetype)envelopeWithEnvelope:(PEXPbMessageProtocolEnvelope *)envelope;

+(PEXPbMessageProtocolEnvelope *) buildEnvelope: (NSData *) payload protocolType: (PEXProtocolType) protocolType
                                 protocolVersion: (PEXProtocolVersion) protocolVersion;
+(PEXMessageProtocolEnvelope *) createEnvelope: (NSData *) payload protocolType: (PEXProtocolType) protocolType
                               protocolVersion: (PEXProtocolVersion) protocolVersion;
+(PEXMessageProtocolEnvelope *) createEnvelope: (NSString *) textPayload;
+(PEXMessageProtocolEnvelope *) createEnvelopeData: (NSData *) serializedEnvelope;
-(PEXProtocolType) getProtocolType;
-(PEXProtocolVersion) getProtocolVersion;
-(NSData *) getPayload;
-(NSData *) getSerialized;
-(NSString *) getBase64EncodedSerialized;
@end