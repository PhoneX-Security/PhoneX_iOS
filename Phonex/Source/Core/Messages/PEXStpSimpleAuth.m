//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "PEXStpSimpleAuth.h"
#import "PEXPbMessage.pb.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXCryptoUtils.h"
#import "PEXUtils.h"

@implementation PEXStpSimpleAuth {

}

+(PEXProtocolType) getProtocolType{
    return PEX_STP_SIMPLE_AUTH;
}

+(PEXProtocolVersion) getProtocolVersion{
    return PEX_STP_SIMPLE_AUTH_VERSION_2;
}

+(int32_t) getSequenceNumber{
    static volatile int32_t counter = 0;
    OSAtomicIncrement32(&counter);
    return counter;
}

// construct when sending messages
- (instancetype)initWithSender:(NSString *)sender pk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    self = [super initWithSender:sender pk:pk remoteCert:remoteCert];
    if (self) {

    }

    return self;
}

// construct when receiving messages
- (instancetype)initWithPk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    self = [super initWithPk:pk remoteCert:remoteCert];
    if (self) {

    }

    return self;
}

/**
* Use when sending message from upper layer
* @param payload Amp serialized message
* @return serialized StpSimpleAuth protobuf message
* @throws CryptoHelper.CipherException
*/
-(NSData *) buildMessage: (NSData *) payload destination: (NSString *) destination ampType: (PEXProtocolType) ampType
    ampVersion: (PEXProtocolVersion) ampVersion error: (NSError **) pError
{
    PEXPbSTPSimpleBuilder * builder = [[PEXPbSTPSimpleBuilder alloc] init];
    [builder setAmpType:ampType];
    [builder setAmpVersion:ampVersion];
    [builder setDestination:destination];
    [builder setSender:self.sender];

    uint32_t nonce = [PEXCryptoUtils secureRandomUInt32:YES];
    [builder setRandomNonce:nonce];

    uint64_t timestamp = [PEXUtils currentTimeMillis];
    [builder setMessageSentMiliUtc:timestamp];

    uint32_t sequenceNumber = (uint32_t) [PEXStpSimpleAuth getSequenceNumber];
    [builder setSequenceNumber:sequenceNumber];

    // Store payload
    [builder setPayload:payload];

    // Sign plaintext  + user identity        ;
    NSData * signature = [self createSignature: [self getDataForSigning:destination sender:self.sender
                                                         sequenceNumber:sequenceNumber timestamp:timestamp nonce:nonce
                                                         messagePayload:payload
                                                                ampType:ampType ampVersion:ampVersion
                                                                stpType:[PEXStpSimpleAuth getProtocolType]
                                                             stpVersion:[PEXStpSimpleAuth getProtocolVersion]] error:nil];
    [builder setSignature:signature];

    PEXPbSTPSimple * msg = [builder build];
    return [msg writeToCodedNSData];
}

/**
* Use when receiving message from lower layer
* @param serializedStpMessage
* @return
*/
-(PEXStpProcessingResult *) readMessage: (NSData *) serializedStpMessage stpType: (int) stpType stpVersion: (int) stpVersion {
    PEXPbSTPSimple * msg = nil;
    @try {
        msg = [PEXPbSTPSimple parseFromData:serializedStpMessage];
    } @catch (NSException * e) {
        [NSException raise:PEXCryptoException format:@"Cannot parse proto buff, exception=%@", e];
    }

    PEXStpProcessingResult * result = [[PEXStpProcessingResult alloc] init];
    result.ampType = msg.ampType;
    result.ampType = msg.ampType;
    result.ampVersion = msg.ampVersion;
    result.sendDate = msg.messageSentMiliUtc;
    result.nonce = @(msg.randomNonce);
    result.sequenceNumber = @(msg.sequenceNumber);
    result.sender = msg.sender;
    result.destination = msg.destination;
    result.hmacValid = YES;

    // decrypt symBlock
    NSData * payload = msg.payload;

    // verify signature
    NSData * dataForVerification = [self getDataForSigning:msg.destination sender:msg.sender
                                            sequenceNumber:msg.sequenceNumber timestamp:msg.messageSentMiliUtc nonce:msg.randomNonce
                                            messagePayload:payload
                                                   ampType:msg.ampType ampVersion:msg.ampVersion
                                                   stpType:stpType stpVersion:stpVersion];

    BOOL signatureValid = [self verifySignature:dataForVerification signature:msg.signature error:nil];
    result.signatureValid = signatureValid;
    if (!signatureValid) {
        DDLogError(@"ALERT: Signature of received message is not valid [ %@ ]", msg);
        return result;
    }

    result.payload = payload;

    DDLogVerbose(@"ReadMessage() ProcessingResult [ %@ ]", result);
    return result;
}

-(NSData*) getDataForSigning: (NSString *) destination sender: (NSString *) sender
              sequenceNumber: (uint32_t) sequenceNumber timestamp: (uint64_t) timestamp
                       nonce: (uint32_t) nonce
              messagePayload: (NSData *) messagePayload
                     ampType: (int) ampType ampVersion: (int) ampVersion
                     stpType: (int) stpType stpVersion: (int) stpVersion
{
    PEXPbSTPSimpleBuilder * builder = [[PEXPbSTPSimpleBuilder alloc] init];
    [builder setProtocolType:stpType];
    [builder setProtocolVersion:stpVersion];
    [builder setAmpType:ampType];
    [builder setAmpVersion:ampVersion];
    [builder setMessageSentMiliUtc:timestamp];

    [builder setSequenceNumber:sequenceNumber];
    [builder setRandomNonce:nonce];
    [builder setDestination:destination];
    [builder setSender:sender];

    [builder setPayload:messagePayload];

    PEXPbSTPSimple * toSign = [builder build];
    return [toSign writeToCodedNSData];
}

@end