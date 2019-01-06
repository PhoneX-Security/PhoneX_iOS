//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPEMPasswd.h"
#import "PEXSharedPrefsSalt.h"
#import "PEXSecurityCenter.h"
#import "PEXOpenUDID.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"

// Private methods extension.
@interface PEXPEMPasswd () { }

@end

@implementation PEXPEMPasswd {

}

static const int SALT_SIZE=32;

/**
* Number of iterations for generating password for private key file.
*/
static const int PKCS_ITERATIONS = 256;

/**
* Number of iterations for generating password for private key file.
*/
static const int ITERATIONS = 2048;

/**
* Magic string appended to the source key to make hashchain differ
* from other hash chains using the same source passphrase.
*/
static NSString const * MAGIC_KEY = @"PhoneX-PEM";

/**
* PBKDF2 key length
*/
static const int PBKDF2_KEYLEN = 256;

/**
 * Returns preferences salt value.
 */
+ (NSString *)saltPrefsKey {
    return @"PEMPasswdSaltV2";
}

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
* Uses PBKDF2.
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
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key{
    // 1. At first get salt.
    NSData * salt = [self getSalt:user];
    if (salt==nil || salt.length != SALT_SIZE){
        [NSException raise:@"IllegalArgumentException" format:@"Salt does not exist or is invalid, generate the new one"];
    }

    // 2. Prepare input
    NSString * pass = [NSString stringWithFormat:@"%@|%@|%@|%@",
            [PEXSecurityCenter getUsernamePathKey:user],
            key, MAGIC_KEY, [PEXOpenUDID value]
        ];


    // 4. Post-processing by PBKDF2 iterations.
    NSData * der = [PEXCryptoUtils pbkdf2:salt withPass:pass withIterations:ITERATIONS withOutLen:PBKDF2_KEYLEN hash:EVP_sha256()];

    // 5. Build final block to hash
    return [[PEXMessageDigest sha512:der] base64EncodedStringWithOptions:0];
}

/**
* Generates a new storage password.
* Uses PBKDF2.
*
* Can take very long to evaluate (units of seconds).
*
* @param ctxt
* @param user
* @param key
* @param full if true returns complete PEM key (2nd. stage). false returns only 1st stage (one more call is needed to get 2nd)
* @return
* @throws IOException
* @throws GeneralSecurityException
*/
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key full:(BOOL) full {
    if (!full){
        return [self getStoragePass:user key:key];
    } else {
        NSString * pemStoragePass1 = [self getStoragePass:user key:key];
        NSString * pemStoragePass2 = [self getStoragePass:user key:pemStoragePass1];
        return pemStoragePass2;
    }
}

@end