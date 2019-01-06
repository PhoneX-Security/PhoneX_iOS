//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPbDhkeySig;


@interface PEXDHKeySignatureGenerator : NSObject

/**
* Generates digital signature for the DhKey.
* @param tosign
* @param privKey
* @param rand
* @return
* @throws SignatureException
*/
+(NSData *) generateDhKeySignature: (PEXPbDhkeySig *) tosign privKey:(PEXEVPPKey *) privKey;

/**
* Signature verification for the DhKey.
* @param toverify
* @param signature
* @param pubKey
* @return
* @throws SignatureException
*/
+(BOOL) verifyDhKeySignature: (PEXPbDhkeySig *) toverify signature: (NSData *) signature pubKey: (PEXEVPPKey *) pubKey;
+(BOOL) verifyDhKeySignature: (PEXPbDhkeySig *) toverify signature: (NSData *) signature cert: (PEXX509 *) cert;
@end