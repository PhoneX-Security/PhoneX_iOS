//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXHybridCipher.h"
#import "PEXPbFiletransfer.pb.h"
#import "PEXCipherException.h"
#import "PEXCryptoUtils.h"
#import "PEXAESCipher.h"


@implementation PEXHybridCipher {

}

+(PEXPbHybridEncryption *) encrypt: (NSData *) src cert: (PEXX509 *) cert {
    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey(cert.getRaw)];
    return [self encrypt:src pubKey:cKey];
}

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
+(PEXPbHybridEncryption *) encrypt: (NSData *) src pubKey: (PEXEVPPKey *) pubKey {
    @try {
        // Generate random AES encryption key
        NSData * aesKey = [PEXAESCipher generateKey];
        NSData * iv = [PEXAESCipher generateIV];

        // Encrypt the AES key with RSA
        NSError * err = nil;
        NSData * rsaCipherText = [PEXCryptoUtils asymEncrypt:aesKey key:pubKey error:&err];
        if (err != nil){
            DDLogError(@"RSA encryption error=%@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot RSA encrypt"];
        }

        // Encrypt given data by AES-GCM
        NSData * aesCipherText = [PEXCryptoUtils encryptData:src key:aesKey iv:iv cipher:EVP_aes_256_gcm() error:&err];
        if (err != nil){
            DDLogError(@"AES encryption error=%@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot AES encrypt"];
        }

        PEXPbHybridEncryptionBuilder * he = [[PEXPbHybridEncryptionBuilder alloc] init];
        [he setIv:iv];
        [he setACiphertext:rsaCipherText];
        [he setSCiphertext:aesCipherText];
        return [he build];

    } @catch(NSException * e){
        [PEXCipherException raise:PEXRuntimeSecurityException format:@"Exception during encryption: %@", e];
    }

    return nil;
}

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
+(NSData *) decrypt: (PEXPbHybridEncryption *) he privKey: (PEXEVPPKey *) privKey {
    @try {
        NSData * aCiphertext = he.aCiphertext;
        NSData * sCiphertext = he.sCiphertext;
        NSData * iv = he.iv;

        // Decrypt symmetric encryption key.
        NSError * err = nil;
        NSData * aesKey = [PEXCryptoUtils asymDecrypt:aCiphertext key:privKey error:&err];
        if (err != nil || aesKey == nil){
            DDLogError(@"RSA decryption failed, error=%@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot decrypt"];
        }

        NSData * dec = [PEXCryptoUtils decryptData:sCiphertext key:aesKey iv:iv cipher:EVP_aes_256_gcm() error:&err];
        if (err != nil){
            DDLogError(@"AES decrypt failed, error=%@", err);
            [NSException raise:PEXRuntimeSecurityException format:@"Cannot decrypt"];
        }

        return dec;

    } @catch(NSException * e){
        [PEXCipherException raise:PEXRuntimeSecurityException format:@"Exception during decryption: %@", e];
    }

    return nil;
}

@end