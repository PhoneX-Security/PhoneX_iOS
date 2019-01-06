//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPKCS12Passwd.h"
#import "PEXSharedPrefsSalt.h"
#import "PEXOpenUDID.h"
#import "PEXSecurityCenter.h"
#import "PEXScrypt.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"
#import "NSProgress+PEXAsyncUpdate.h"

@implementation PEXPKCS12Passwd : NSObject

+ (NSString *)saltPrefsKey {
    return @"PKCSPasswdSaltV2";
}

/**
* PKCS container key salt size in bytes
*/
static const int SALT_SIZE = 32;

/**
* Magic string appended to the source key to make hashchain differ
* from other hash chains using the same source passphrase.
*/
static NSString * const MAGIC_KEY = @"PhoneX-PKCS12";

/**
* Scrypt recommended attributes.
*/
static const int SCRYPT_N = 32768; // 2^15
static const int SCRYPT_R = 1; //
static const int SCRYPT_P = 1; //
static const int SCRYPT_KEYLEN = 32; // 256-bit key derived

/**
* Number of iterations of PBKDF2 after scrypt() derivation.
*/
static const int PBKDF2_ITERATIONS = 8192;

/**
* PBKDF2 key length derived
*/
static const int PBKDF2_KEYLEN = 256;

/**
* Returns preference key for salt for the given user.
* @param user
* @return
*/
+(NSString *) getSaltPrefsKeyForUser: (NSString *) user{
    return [PEXSharedPrefsSalt getSaltPrefsKey:[self saltPrefsKey] user:user];
}

/**
* Returns true if there is stored a salt value in a shared preferences.
* @param ctxt
* @return
*/
+(BOOL) saltExists: (NSString *) user{
    BOOL exists = [PEXSharedPrefsSalt saltExists:[self saltPrefsKey] user:user];
    if (!exists){
        return NO;
    }

    // Verify its size - has to be non-empty.
    NSData * salt = [self getSalt:user];
    return (salt!=nil && salt.length == SALT_SIZE);
}

/**
* Generates new salt to the shared preferences.
* @param ctxt
* @param rand
*/
+(NSData *) generateNewSalt: (NSString *) user {
    return [PEXSharedPrefsSalt generateNewSalt:[self saltPrefsKey] user:user saltSize:SALT_SIZE];
}

/**
* Loads salt from preferences
* @param ctxt
* @return
* @throws IOException
*/
+(NSData *) getSalt: (NSString *) user {
    return [PEXSharedPrefsSalt getSalt:[self saltPrefsKey] user:user];
}

/**
* Generates a new storage password.
* Uses scrypt().
*
* Can take very long to evaluate (units of seconds).
*
* @param ctxt
* @param user
* @param key
* @return
* @throws IOException
* @throws GeneralSecurityException
*/
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key {
    return [self getStoragePass:user key:key progress:nil];
}

+ (NSString *)getStoragePass:(NSString *)user key:(NSString *)key progress:(NSProgress *)parentProgress {
    // 1. At first get salt.
    NSData * salt = [self getSalt:user];
    if (salt==nil || salt.length != SALT_SIZE){
        [NSException raise:@"IllegalArgumentException" format:@"Salt does not exist or is invalid, generate the new one"];
    }

    NSProgress * progress = nil;
    if (parentProgress!=nil) {
        progress = [NSProgress alloc];
        [NSProgress doInitWithParentOnMainSync:progress parent:parentProgress userInfo:nil];
        [progress setProgressOnMain:3 completedCount:0];
    }

    // 2. Prepare input
    NSString * pass = [NSString stringWithFormat:@"%@|%@|%@|%@",
                                                 [PEXSecurityCenter getUsernamePathKey:user],
                                                 key, MAGIC_KEY, [PEXOpenUDID value]
    ];
    if (parentProgress!=nil) {
        [progress incProgressOnMain:1];
        DDLogVerbose(@"init done");
    }

    // 3. Scrypt
    if (parentProgress!=nil) {
        [progress becomeCurrentWithPendingUnitCountOnMain:1 async:NO];
    }

    NSData const * scrypted = [PEXScrypt scrypt:pass salt:salt N:SCRYPT_N r:SCRYPT_R p:SCRYPT_P dkLen:SCRYPT_KEYLEN progress:progress];
    if (parentProgress!=nil) {
        [progress resignCurrentOnMainAsync: NO];
        DDLogVerbose(@"scrypt done");
    }

    // 4. Post-processing by few PBKDF2 iterations
    NSData const * der = [PEXCryptoUtils pbkdf2:salt withPass:[scrypted base64EncodedStringWithOptions:0]
                                 withIterations:PBKDF2_ITERATIONS withOutLen:PBKDF2_KEYLEN hash:EVP_sha256()];
    if (parentProgress!=nil) {
        [progress incProgressOnMain:1];
        DDLogVerbose(@"pbkdf2 done");
    }

    // 5. Build const block to hash
    return [[PEXMessageDigest sha512Message:[NSString stringWithFormat:@"%@|%@",
                    [scrypted base64EncodedStringWithOptions:0],
                    [der base64EncodedStringWithOptions:0]]]
            base64EncodedStringWithOptions:0];
}

@end