//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPbHybridEncryption;


@interface PEXHybridCipher : NSObject

/**
* Simple routine for hybrid encryption.
* Should be only used if the source is small in length. Otherwise streaming
* approach might be more suitable.
*
* Plaintext to encrypt is byte array. Returned structure is hybridEncryption, which contain
* IV, symmetrically encrypted input byte array with randomly generated AES encryption key K
* and asymmetrically encrypted K.
*
* "RSA/ECB/OAEPWithSHA1AndMGF1Padding";
* "AES/GCM/NoPadding"; 256
*
* @param src
* @param pubKey
* @param rand
* @return
* @throws CipherException
*/
+(PEXPbHybridEncryption *) encrypt: (NSData *) src pubKey: (PEXEVPPKey *) pubKey;
+(PEXPbHybridEncryption *) encrypt: (NSData *) src cert: (PEXX509 *) cert;

/**
* Simple routine for hybrid decryption.
*
* "RSA/ECB/OAEPWithSHA1AndMGF1Padding";
* "AES/GCM/NoPadding"; 256
*
* @param he
* @param privKey
* @param rand
* @return
* @throws CipherException
*/
+(NSData *) decrypt: (PEXPbHybridEncryption *) he privKey: (PEXEVPPKey *) privKey;

@end