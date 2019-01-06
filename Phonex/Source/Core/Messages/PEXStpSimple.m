//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <libkern/OSAtomic.h>
#import "PEXStpSimple.h"
#import "PEXPbMessage.pb.h"
#import "PEXUtils.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXCryptoUtils.h"
#import "PEXAESCipher.h"

// Check for privacy.
#if PEX_ENABLE_STP_DEBUG_LOG
#warning "Warning! STP Debug logging is enabled. This may leak private data, disable it in production."
#endif

@interface PEXSymmetricKeys : NSObject { }
@property (nonatomic) NSData * encKey;
@property (nonatomic) NSData * macKey;
@end

@implementation PEXSymmetricKeys
@end

@interface PEXStpSimple () { }
-(NSData *) generateIvForAes;
-(NSData *) generateAesEncKey;
-(NSData *) generateHmacKey;
-(NSData *) encryptAsymBlock: (PEXSymmetricKeys *) symmetricKeys;
-(PEXSymmetricKeys *) decryptAsymBlock: (NSData *) encryptedData;
-(NSData *) encryptSymBlock: (NSData *) encKey iv: (NSData *) iv payload: (NSData *) payload;
-(NSData *) decryptSymBlock: (NSData *) encKey iv: (NSData *) iv payload: (NSData *) encPayload;
-(NSData*) getDataForSigning: (NSString *) destination sender: (NSString *) sender
              sequenceNumber: (uint32_t) sequenceNumber timestamp: (uint64_t) timestamp
                       nonce: (uint32_t) nonce iv: (NSData *) iv symmetricKeys: (PEXSymmetricKeys *) symmetricKeys
              messagePayload: (NSData *) messagePayload
                     ampType: (int) ampType ampVersion: (int) ampVersion
                     stpType: (int) stpType stpVersion: (int) stpVersion;
-(NSData*) getDataForMac: (NSString *) destination sender: (NSString *) sender
          sequenceNumber: (uint32_t) sequenceNumber timestamp: (uint64_t) timestamp nonce: (uint32_t) nonce
                      iv: (NSData*) iv symmetricKeys: (PEXSymmetricKeys *) symmetricKeys
              eAsymBlock: (NSData *) eAsymBlock eSymBlock: (NSData *) eSymBlock
                 ampType: (int) ampType ampVersion: (int) ampVersion
                 stpType: (int) stpType stpVersion: (int) stpVersion;
-(NSData *) mac: (NSData *) data key: (NSData *) key;
-(BOOL) verifyMac: (NSData*) data mac: (NSData *) mac key: (NSData *) key;
@end

@implementation PEXStpSimple {

}

+(PEXProtocolType) getProtocolType{
    return PEX_STP_SIMPLE;
}

+(PEXProtocolVersion) getProtocolVersion{
    return PEX_STP_SIMPLE_VERSION_3;
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
* Setup which version we want to use (if not the default one)
* @param transportProtocolVersion
*/
- (void)setVersion:(PEXProtocolVersion)protocolVersion {
    _protocolVersion = protocolVersion;
}

+(int32_t) getSequenceNumber{
    static volatile int32_t counter = 0;
    OSAtomicIncrement32(&counter);
    return counter;
}

/**
* Use when sending message from upper layer
* @param payload Amp serialized message
* @return serialized StpSimple protobuf message
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

    uint32_t sequenceNumber = (uint32_t)[PEXStpSimple getSequenceNumber];
    [builder setSequenceNumber:sequenceNumber];

    // Generate random AES encryption key
    NSData * encKey = [self generateAesEncKey];

    // Generate random HMAC key
    NSData * macKey = [self generateHmacKey];
    PEXSymmetricKeys * symmetricKeys = [[PEXSymmetricKeys alloc] init];
    symmetricKeys.encKey = encKey;
    symmetricKeys.macKey = macKey;

    // Generate initialization vector of  size of one AES block
    // WATCH OUT FOR THE AES MODE - some like CTR are deadly vulnerable to IV reuse
    NSData * iv = [self generateIvForAes];
    [builder setIv:iv];

    // Encrypt payload
    NSData * eSymBlock = [self encryptSymBlock:encKey iv:iv payload:payload];
    [builder setESymBlock:eSymBlock];

    // Hybrid encrypt key
    NSData * eAsymBlock = [self encryptAsymBlock: symmetricKeys];
    [builder setEAsymBlock:eAsymBlock];

    // Sign plaintext  + user identity,
    NSData * dataForSign = [self getDataForSigning:destination sender:self.sender
                                    sequenceNumber:sequenceNumber timestamp:timestamp nonce:nonce
                                                iv:iv symmetricKeys:symmetricKeys
                                    messagePayload:payload
                                           ampType:ampType ampVersion:ampVersion
                                           stpType:[PEXStpSimple getProtocolType]
                                        stpVersion:self.protocolVersion];

    NSData * signature = [self createSignature:dataForSign error:nil];
    [builder setSignature:signature];

    NSData * dataForMac = [self getDataForMac:destination sender:self.sender
                               sequenceNumber:sequenceNumber timestamp:timestamp nonce:nonce
                                           iv:iv symmetricKeys:symmetricKeys
                                   eAsymBlock:eAsymBlock eSymBlock:eSymBlock
                                      ampType:ampType ampVersion:ampVersion
                                      stpType:[PEXStpSimple getProtocolType] stpVersion:self.protocolVersion];
    NSData * mac = [self mac:dataForMac key:macKey];
    [builder setHmac:mac];

    PEXPbSTPSimple * msg = [builder build];

    // For debugging.
#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP build: iv=[%@],\naesKey=[%@],\nmacKey=[%@],\ndataForMac=[%@],\nmac=[%@],\ndataForSign=%@,\nsign=%@,\npayload=[%@],\n"
            "symBlock=[%@],\nasymBlock=[%@],\nmsg=[%@]",
            [iv base64EncodedStringWithOptions:0],
            [symmetricKeys.encKey base64EncodedStringWithOptions:0],
            [symmetricKeys.macKey base64EncodedStringWithOptions:0],
            [dataForMac base64EncodedStringWithOptions:0],
            [msg.hmac base64EncodedStringWithOptions:0],
            [dataForSign base64EncodedStringWithOptions:0],
            [signature base64EncodedStringWithOptions:0],
            [payload base64EncodedStringWithOptions:0],
            [eSymBlock base64EncodedStringWithOptions:0],
            [eAsymBlock base64EncodedStringWithOptions:0],
            msg
    );
#endif

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

    // Decrypt asym block
    PEXSymmetricKeys * symmetricKeys = [self decryptAsymBlock:msg.eAsymBlock];
    NSData * iv = msg.iv;

    // verify hmac
    NSData * dataForMac = [self getDataForMac:msg.destination sender:msg.sender
                               sequenceNumber:msg.sequenceNumber timestamp:msg.messageSentMiliUtc nonce:msg.randomNonce
                                           iv:iv symmetricKeys:symmetricKeys
                                   eAsymBlock:msg.eAsymBlock eSymBlock:msg.eSymBlock
                                      ampType:msg.ampType ampVersion:msg.ampVersion
                                      stpType:stpType stpVersion:stpVersion];

    BOOL macValid = [self verifyMac:dataForMac mac:msg.hmac key:symmetricKeys.macKey];
    result.hmacValid = macValid;

#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP debug log, receive, iv=[%@],\naesKey=[%@],\nmacKey=[%@],\ndataForMac=[%@],\nmac=[%@],\nmsg=[%@]",
        [iv base64EncodedStringWithOptions:0],
        [symmetricKeys.encKey base64EncodedStringWithOptions:0],
        [symmetricKeys.macKey base64EncodedStringWithOptions:0],
        [dataForMac base64EncodedStringWithOptions:0],
        [msg.hmac base64EncodedStringWithOptions:0],
        msg
    );
#endif

    if (!macValid) {
        DDLogError(@"ALERT: HMAC of received message is not valid [ %@ ]", msg);
        return result;
    }


    // decrypt symBlock
    NSData * payload = [self decryptSymBlock:symmetricKeys.encKey iv:iv payload:msg.eSymBlock];

    // verify signature
    NSData * dataForVerification = [self getDataForSigning:msg.destination sender:msg.sender
                                            sequenceNumber:msg.sequenceNumber timestamp:msg.messageSentMiliUtc nonce:msg.randomNonce
                                                        iv:iv symmetricKeys:symmetricKeys
                                            messagePayload:payload
                                                   ampType:msg.ampType ampVersion:msg.ampVersion
                                                   stpType:stpType stpVersion:stpVersion];
#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP debug log, sigVerif:\npayload=[%@],\ndataForVerification=[%@]\nsignature=[%@]",
     [payload base64EncodedStringWithOptions:0],
     [dataForVerification base64EncodedStringWithOptions:0],
     [msg.signature base64EncodedStringWithOptions:0]);
#endif

    NSError * sigError = nil;
    BOOL signatureValid = [self verifySignature:dataForVerification signature:msg.signature error:&sigError];
    if (sigError != nil){
        result.signatureValid = NO;
        DDLogError(@"Signature error: %@", sigError);
        return result;
    }

    result.signatureValid = signatureValid;
    if (!signatureValid) {
        DDLogError(@"ALERT: Signature of received message is not valid [ %@ ]", msg);
        return result;
    }

    result.payload = payload;

    DDLogVerbose(@"ReadMessage() ProcessingResult [ %@ ]", result);
    return result;
}

-(NSData *) generateIvForAes{
    @try {
        return [PEXAESCipher generateIV];
    } @catch (NSException * e) {
        DDLogError(@"Exception during aesiv gen, %@", e);
        [NSException raise:PEXCryptoException format:@"Exception during aesiv gen, %@", e];
    }
}

// Generate random AES encryption key, 256b
-(NSData *) generateAesEncKey {
    @try {
        return [PEXAESCipher generateKey];
    } @catch (NSException * e) {
        DDLogError(@"Exception during aeskey gen, %@", e);
        [NSException raise:PEXCryptoException format:@"Exception during aeskey gen, %@", e];
    }
}

// Generate HmacWithSha256 key
-(NSData *) generateHmacKey {
    @try {
        return [PEXCryptoUtils secureRandomData:nil len:PEX_HMAC_KEY_SIZE amplifyWithArc:YES];
    } @catch (NSException * e) {
        DDLogError(@"Exception during hmac gen, %@", e);
        [NSException raise:PEXCryptoException format:@"Exception during hmac gen, %@", e];
    }
}

// Encrypt the AES and HMAC key with RSA
-(NSData *) encryptAsymBlock: (PEXSymmetricKeys *) symmetricKeys {
    @try {
        // initialize block
        PEXPbSTPSimpleBuilder * builder = [[PEXPbSTPSimpleBuilder alloc] init];
        [builder setMacKey: symmetricKeys.macKey];
        [builder setEncKey: symmetricKeys.encKey];
        PEXPbSTPSimple * keysWrapper = [builder build];

        // encrypt
        NSError * encError = nil;
        NSData * toEnc = [keysWrapper writeToCodedNSData];
        NSData * enc = [PEXCryptoUtils asymEncrypt:toEnc crt:self.remoteCert.cert error:&encError];
        if (enc == nil){
            DDLogError(@"Async block cannot be created, error: %@", encError);
            [NSException raise:PEXCryptoException format:@"Asyn block cannot be created"];
            return nil;
        }
        return enc;

    } @catch (NSException * e) {
        DDLogError(@"Exception during RSA encryption, %@", e);
        [NSException raise:PEXCryptoException format:@"Exception during RSA encryption, %@", e];
    }
}

-(PEXSymmetricKeys *) decryptAsymBlock: (NSData *) encryptedData {
    @try {
        // Decrypt encryption keys.
        NSData * dec = [PEXCryptoUtils asymDecrypt:encryptedData key:[self.pk key] error:nil];
        if (dec == nil){
            DDLogWarn(@"Cannot decrypt asym block");
            return nil;
        }

        PEXPbSTPSimple * keysWrapper = [PEXPbSTPSimple parseFromData:dec];
        PEXSymmetricKeys * symKeys = [[PEXSymmetricKeys alloc] init];
        symKeys.macKey = keysWrapper.macKey;
        symKeys.encKey = keysWrapper.encKey;

        return symKeys;

    } @catch (NSException * e) {
        DDLogError(@"Exception during RSA encryption, %@", e);
        return nil;
    }
}

-(NSData *) encryptSymBlock: (NSData *) encKey iv: (NSData *) iv payload: (NSData *) payload {
    @try {
        return [PEXCryptoUtils encryptData:payload key:encKey iv:iv cipher:EVP_aes_256_ctr() error:nil];
    } @catch (NSException * ex){
        DDLogError(@"Exception during sym block building, exception=%@", ex);
        return nil;
    }
}

-(NSData *) decryptSymBlock: (NSData *) encKey iv: (NSData *) iv payload: (NSData *) encPayload {
    @try {
        return [PEXCryptoUtils decryptData:encPayload key:encKey iv:iv cipher:EVP_aes_256_ctr() error:nil];
    } @catch(NSException * ex){
        DDLogError(@"Exception during sym block decryption, exception=%@", ex);
        return nil;
    }
}

-(NSData*) getDataForSigning: (NSString *) destination sender: (NSString *) sender
              sequenceNumber: (uint32_t) sequenceNumber timestamp: (uint64_t) timestamp
                       nonce: (uint32_t) nonce iv: (NSData *) iv symmetricKeys: (PEXSymmetricKeys *) symmetricKeys
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

    [builder setIv:iv];

    [builder setMacKey:symmetricKeys.macKey];
    [builder setEncKey:symmetricKeys.encKey];
    [builder setPayload:messagePayload];

    PEXPbSTPSimple * toSign = [builder build];

#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP debug log, getDataForSigning, dataForSign=[%@]\nampType=%d", toSign, ampType);
    DDLogInfo(@"STP debug log, getDataForSigning, nonce=[%ud]\niv=[%@]\nmacKey=[%@]\nencKey=[%@]\npayload=[%@]",
            nonce,
            [iv base64EncodedStringWithOptions:0],
            [symmetricKeys.macKey base64EncodedStringWithOptions:0],
            [symmetricKeys.encKey base64EncodedStringWithOptions:0],
            [messagePayload base64EncodedStringWithOptions:0]);
#endif
    return [toSign writeToCodedNSData];
}

-(NSData*) getDataForMac: (NSString *) destination sender: (NSString *) sender
          sequenceNumber: (uint32_t) sequenceNumber timestamp: (uint64_t) timestamp nonce: (uint32_t) nonce
                      iv: (NSData*) iv symmetricKeys: (PEXSymmetricKeys *) symmetricKeys
              eAsymBlock: (NSData *) eAsymBlock eSymBlock: (NSData *) eSymBlock
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

    [builder setIv:iv];
    [builder setMacKey:symmetricKeys.macKey];
    [builder setEncKey:symmetricKeys.encKey];

    [builder setESymBlock:eSymBlock];
    [builder setEAsymBlock:eAsymBlock];
    PEXPbSTPSimple * build = [builder build];
#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP debug log, getDataForMac, dataForMac=[%@]\nampType=%d", build, ampType);
    DDLogInfo(@"STP debug log, getDataForMac, nonce=[%ud]\niv=[%@]\nmacKey=[%@]\nencKey=[%@]\nasym=[%@]\nsym=[%@]",
            nonce,
            [iv base64EncodedStringWithOptions:0],
            [symmetricKeys.macKey base64EncodedStringWithOptions:0],
            [symmetricKeys.encKey base64EncodedStringWithOptions:0],
            [eAsymBlock base64EncodedStringWithOptions:0],
            [eSymBlock base64EncodedStringWithOptions:0]);
#endif
    return [build writeToCodedNSData];
}

-(NSData *) mac: (NSData *) data key: (NSData *) key {
    @try {
        return [PEXCryptoUtils hmac:data key:key];
    } @catch(NSException * e){
        DDLogError(@"Exception during generating MAC, exception=%@", e);
        return nil;
    }
}

-(BOOL) verifyMac: (NSData*) data mac: (NSData *) mac key: (NSData *) key {
    NSData * macExpected = [self mac:data key:key];
#if PEX_ENABLE_STP_DEBUG_LOG
    DDLogInfo(@"STP debug log: macExpected=[%@]", [macExpected base64EncodedStringWithOptions:0]);
#endif
    return [macExpected isEqualToData:mac];
}

@end
