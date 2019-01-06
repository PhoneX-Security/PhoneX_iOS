//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDHKeySignatureGenerator.h"
#import "PEXPbFiletransfer.pb.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXCryptoUtils.h"
#import "PEXSignatureException.h"


@implementation PEXDHKeySignatureGenerator {

}

/**
* Generates digital signature for the DhKey.
* @param tosign
* @param privKey
* @param rand
* @return
* @throws SignatureException
*/
+(NSData *) generateDhKeySignature: (PEXPbDhkeySig *) tosign privKey:(PEXEVPPKey *) privKey {
    @try {
        // 1. Serialize given structure
        NSData * serialized = [tosign writeToCodedNSData];

        // 2. sign
        NSError * err = nil;
        NSData * signature = [PEXCryptoUtils sign:serialized key:[PEXPrivateKey keyWithKey:privKey] error:&err];
        if (err != nil){
            DDLogError(@"Cannot generate signature: %@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot generate signature"];
        }

        return signature;

    } @catch(NSException * ex){
        [PEXSignatureException raise:PEXRuntimeSecurityException format:@"Cannot generate signature"];
    }

    return nil;
}

/**
* Signature verification for the DhKey.
* @param toverify
* @param signature
* @param pubKey
* @return
* @throws SignatureException
*/
+(BOOL) verifyDhKeySignature: (PEXPbDhkeySig *) toverify signature: (NSData *) signature cert: (PEXX509 *) cert {
    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey(cert.getRaw)];
    return [self verifyDhKeySignature:toverify signature:signature pubKey:cKey];
}

+(BOOL) verifyDhKeySignature: (PEXPbDhkeySig *) toverify signature: (NSData *) signature pubKey: (PEXEVPPKey *) pubKey {
    @try {
        // 1. Serialize given structure
        NSData * serialized = [toverify writeToCodedNSData];

        // 2. verify
        NSError * err = nil;
        BOOL verified = [PEXCryptoUtils verify:serialized signature:signature pubKey:pubKey error:&err];
        if (err != nil){
            DDLogError(@"Cannot verify signature: %@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot verify signature"];
        }

        return verified;
    } @catch(NSException * ex){
        [PEXSignatureException raise:PEXRuntimeSecurityException format:@"Exception during signature verification"];
    }

    return NO;
}

@end