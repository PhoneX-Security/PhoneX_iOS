//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Password scheme for PKCS v2.
 *   input = username + | + userpasswd + | + MAGIC_KEY + | + ANDROID_UNIQUE_ID
 *   salt = random 32byte salt stored for given user in shared preferences
 *   step1 = scrypt(input, salt, N=2^15, r=1, p=1, dkeylen=32)
 *   step2 = pbkdf2(step1, salt, iterations=8192, mac=MACWithSHA1)
 *   step1_64 = base64.encode(step1)
 *   step2_64 = base64.encode(step2)
 *   step3 = base64.encode(SHA512(step1_64 + | + step2_64))
 *   return step3
 *
 * @author ph4r05
 *
 */
@interface PEXPKCS12Passwd : NSObject
+(NSString *) saltPrefsKey;

/**
* Returns true if there is stored a salt value in a shared preferences.
* @param ctxt
* @return
*/
+(BOOL) saltExists: (NSString *) user;

/**
* Generates new salt to the shared preferences.
* @param ctxt
* @param rand
*/
+(NSData *) generateNewSalt: (NSString *) user;

/**
* Loads salt from preferences
* @param ctxt
* @return
* @throws IOException
*/
+(NSData *) getSalt: (NSString *) user;

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
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key progress: (NSProgress *) parentProgress;
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key;

@end