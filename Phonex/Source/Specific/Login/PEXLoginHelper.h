//
// Created by Dusan Klinec on 26.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbLoadResult.h"

@class PEXCredentials;
@protocol PEXCanceller;
@class PEXService;


@interface PEXLoginHelper : NSObject

+(BOOL) passwordStoreAllowed;

/**
* Stores login credentials to the KeyChain.
*/
+(void) storeCredentialsToKeychain: (PEXUserPrivate *) privData;
+(void) storeCredentialsToKeychain: (PEXUserPrivate *) privData forceStore:(const bool) forceStore;

+(void) storeCredentialsToKeychain: (NSString *) username password: (NSString *) password forceStore:(const bool) forceStore;
+(void) storeCredentialsToKeychain: (NSString *) username password: (NSString *) password keychainId: (NSString *) keychainId
        forceStore:(const bool) forceStore;

/**
* Resets all KeyChain stored data. Removes stored login credentials from the KeyChain.
*/
+(void) resetKeychain;

/**
* Tries to load stored credentials from the KeyChain. If load is not successfull or data is empty, nil is returned.
*/
+(PEXCredentials *) loadCredentialsFromKeyChain;
+(PEXCredentials *) loadCredentialsFromKeyChain: (NSString *) keychainId;

+ (void) setSavePasswordInKeyChain: (const bool) enabled;

/**
* Waits while service is prepared for a login.
*/
+ (int) waitForServiceIsOK: (PEXService *) svc canceller: (id<PEXCanceller>) canceller;

/**
* Derive all passwords needed for auto-login from initial credentials.
*/
+ (int) derivePrivData: (PEXUserPrivate *) privData creds: (PEXCredentials *) creds canceller: (id<PEXCanceller>) canceller tryCached: (BOOL) tryCached;

/**
* Tries to open user database with given private data.
* Only one try is performed.
*/
+ (BOOL) tryOpenDatabase: (PEXUserPrivate *) privData openResult: (PEXDbOpenStatus *) openResult;

/**
* Loads account ID from database.
*/
+ (BOOL) loadAccountId: (PEXUserPrivate *) privData;

@end