//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAESCipher.h"
#import "openssl/rand.h"
#import "openssl/err.h"
#import "openssl/evp.h"
#import "PEXCryptoUtils.h"

uint const AES_PBKDF2_ITERATIONS =1024;
uint const AES_PBKDF2_SALT_SIZE =12;
uint const AES_KEY_SIZE=32;
@implementation PEXAESCipher {
}

+ (NSData *)encrypt:(NSData *)plaintext password:(NSData *)password {
    return [self encrypt:plaintext password:password doKeyDerivation:YES];
}

+ (NSData *)encrypt:(NSData *)plaintext password:(NSData *)password doKeyDerivation: (BOOL) doKeyDerivation {
    // Compute output size.
    uint64_t const outLen = (([plaintext length] / AES_BLOCK_SIZE) + 1ul) * AES_BLOCK_SIZE;
    uint64_t const outTotalLen = AES_PBKDF2_SALT_SIZE + AES_BLOCK_SIZE + outLen;

    unsigned char salt[AES_PBKDF2_SALT_SIZE];
    unsigned char iv[AES_BLOCK_SIZE];
    unsigned char encKey[AES_KEY_SIZE];

    uint64_t err;
    int rc;

    // Generate random salt.
    if (doKeyDerivation) {
        rc = RAND_pseudo_bytes(salt, AES_PBKDF2_SALT_SIZE);
        err = ERR_get_error();
        if (rc != 0 && rc != 1) {
            return nil;
        }
    } else {
        memset(salt, 0, AES_PBKDF2_SALT_SIZE);
    }

    // Generate random IV.
    rc = RAND_pseudo_bytes(iv, AES_BLOCK_SIZE);
    err = ERR_get_error();
    if(rc != 0 && rc != 1) {
        return nil;
    }

    // Derive AES Key.
    if (doKeyDerivation) {
        if (1 != PKCS5_PBKDF2_HMAC([password bytes], (int) [password length], salt, AES_PBKDF2_SALT_SIZE, AES_PBKDF2_ITERATIONS, EVP_sha1(), AES_KEY_SIZE, encKey)) {
            DDLogVerbose(@"PBKDF2 error");
            return nil;
        }
    } else {
        if (AES_KEY_SIZE != [password length]){
            DDLogError(@"Provided key is not of the correct size %d vs. %lu", AES_KEY_SIZE, (unsigned long)[password length]);
            return nil;
        }

        memcpy(encKey, [password bytes], AES_KEY_SIZE);
    }

    // Output buffer allocation.
    unsigned char * outBuff = (unsigned char *) calloc(outTotalLen, 1);
    unsigned char * outBuff4Ciphertext = outBuff + AES_PBKDF2_SALT_SIZE + AES_BLOCK_SIZE;
    memcpy(outBuff,                       salt, AES_PBKDF2_SALT_SIZE);
    memcpy(outBuff+ AES_PBKDF2_SALT_SIZE, iv,   AES_BLOCK_SIZE);

    // AES
    int encRes = [PEXCryptoUtils encryptRaw:[plaintext bytes] plen:(int)[plaintext length] key:encKey iv:iv ciphertext:outBuff4Ciphertext cipher:EVP_aes_256_cbc()];
    if (encRes <= 0) {
        free(outBuff);
        return nil;
    }

    NSData * toRet = [NSData dataWithBytes:outBuff length:(NSUInteger) (encRes + AES_PBKDF2_SALT_SIZE + AES_BLOCK_SIZE)];
    free(outBuff);

    return toRet;
}

+ (NSData *)decrypt:(NSData *)cipherblock password:(NSData *)password {
    return [self decrypt:cipherblock password:password doKeyDerivation:YES];
}

+ (NSData *)decrypt:(NSData *)cipherblock password:(NSData *)password doKeyDerivation: (BOOL) doKeyDerivation {
    uint64_t totalLen = [cipherblock length];
    if (totalLen <= (AES_PBKDF2_SALT_SIZE + AES_BLOCK_SIZE) ||
            ((totalLen - AES_PBKDF2_SALT_SIZE) % AES_BLOCK_SIZE) != 0){

        // Invalid format, too short, no ciphertext/illegal length.
        DDLogError(@"Invalid format, too short, no ciphertext/illegal length");
        return nil;
    }

    const unsigned char * const salt = [cipherblock bytes];
    const unsigned char * const iv = salt + AES_PBKDF2_SALT_SIZE;
    const unsigned char * const ciphertext = iv + AES_BLOCK_SIZE;
    const uint64_t clen = totalLen - AES_PBKDF2_SALT_SIZE - AES_BLOCK_SIZE;
    unsigned char encKey[AES_KEY_SIZE];

    // Derive AES Key.
    if (doKeyDerivation) {
        if (1 != PKCS5_PBKDF2_HMAC([password bytes], (int) [password length], salt, AES_PBKDF2_SALT_SIZE, AES_PBKDF2_ITERATIONS, EVP_sha1(), AES_KEY_SIZE, encKey)) {
            return nil;
        }
    } else {
        if (AES_KEY_SIZE != [password length]){
            DDLogError(@"Provided key is not of the correct size %d vs. %lu", AES_KEY_SIZE, (unsigned long)[password length]);
            return nil;
        }

        memcpy(encKey, [password bytes], AES_KEY_SIZE);
    }

    // AES
    unsigned char * outBuff = (unsigned char *) calloc(clen, 1);
    int plen = [PEXCryptoUtils decryptRaw:ciphertext clen:(int)clen key:encKey iv:iv plaintext:outBuff cipher:EVP_aes_256_cbc()];
    if (plen <= 0){
        free(outBuff);
        return nil;
    }

    NSData * toRet = [NSData dataWithBytes:outBuff length:(NSUInteger) plen];
    free(outBuff);

    return toRet;
}

+ (NSData *)generateKey {
    return [PEXCryptoUtils secureRandomData:nil len:32 amplifyWithArc:YES];
}

+ (NSData *)generateIV {
    return [PEXCryptoUtils secureRandomData:nil len:16 amplifyWithArc:YES];
}

@end