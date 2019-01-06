//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/aes.h"
#import "openssl/ossl_typ.h"

extern uint const AES_PBKDF2_ITERATIONS;
extern uint const AES_PBKDF2_SALT_SIZE;
extern uint const AES_KEY_SIZE;

/**
* Main AES cipher object for encryption / decryption.
*/
@interface PEXAESCipher : NSObject

+(NSData *) encrypt: (NSData * ) plaintext password: (NSData * ) password;
+(NSData *) encrypt: (NSData * ) plaintext password: (NSData * ) password doKeyDerivation: (BOOL) doKeyDerivation;
+(NSData *) decrypt: (NSData * ) cipherblock password: (NSData * ) password;
+(NSData *) decrypt: (NSData * ) cipherblock password: (NSData * ) password doKeyDerivation: (BOOL) doKeyDerivation;
+(NSData *) generateKey;
+(NSData *) generateIV;
@end