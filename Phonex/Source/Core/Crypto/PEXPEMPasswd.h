//
// Created by Dusan Klinec on 15.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * Class for generating PEM passwords.
 */
@interface PEXPEMPasswd : NSObject
+(NSString *) saltPrefsKey;

/**
* Returns preference key for salt for the given user.
* @param user
* @return
*/
+(NSString *) getSaltPrefsKeyForUser: (NSString *) user;

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
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key;

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
+(NSString *) getStoragePass: (NSString *) user key: (NSString *) key full:(BOOL) full;

@end