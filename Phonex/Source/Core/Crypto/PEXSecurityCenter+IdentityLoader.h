//
// Created by Dusan Klinec on 19.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSecurityCenter.h"
#import "PEXUserPrivate.h"

typedef enum tIdentityLoadResult {
    kIDENTITY_EXISTS = 1,
    kIDENTITY_DOES_NOT_EXIST,
    kIDENTITY_NO_FILE,
    kIDENTITY_BAD_KEY,
    kIDENTITY_EMPTY,
    kIDENTITY_BAD_CN,
    kIDENTITY_INVALID,
    kIDENTITY_NONE,
} tIdentityLoadResult;

typedef enum tLoginDataCheckResult{
    kLOGIN_DATA_OK = 1,
    kLOGIN_DATA_NO_SALT_PKCS12 = -1,
    kLOGIN_DATA_NO_SALT_PEM = -2,
    kLOGIN_DATA_NO_PKCS12 = -3
} tLoginDataCheckResult;

@interface PEXSecurityCenter (IdentityLoader)

/**
 * Verifies presence of password salts stored in preferences and PKCS12 file.
 * Returns 1 when user can be logged in using stored credentials (salt + PKCS12 file).
 * Otherwise stored PKCS12 cannot be used and a new private key has to be generated.
 */
+(int) checkStoredUserLoginData: (NSString *) username;

/**
 * Loads default identity data to the private data structure.
 * PKCS12 password has to be computed at the time of calling this.
 */
+(int) loadIdentity: (PEXUserPrivate *) privData;

/**
Exports default key store from the loaded identity in privData.
Passwords have to be generated before calling this.
 */
+(int) exportKeyStore: (PEXUserPrivate *) privData;

/**
* Exports default PEM files from the loaded identity in privData.
* Passwords have to be generated calling this.
*/
+(int) exportPEMFiles: (PEXUserPrivate *) privData;

@end