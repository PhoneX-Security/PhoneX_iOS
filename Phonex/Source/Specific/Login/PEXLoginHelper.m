//
// Created by Dusan Klinec on 26.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLoginHelper.h"
#import "PEXCredentials.h"
#import "KeychainItemWrapper.h"
#import "PEXUtils.h"
#import "DDLog.h"
#import "PEXUserAppPreferences.h"
#import "PEXService.h"
#import "PEXSecurityCenter.h"
#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXPKCS12Passwd.h"
#import "PEXPEMPasswd.h"
#import "PEXPasswdGenerator.h"
#import "PEXDbLoadResult.h"
#import "PEXDatabase.h"
#import "PEXLoginTaskResult.h"
#import "PEXCanceller.h"
#import "PEXDbContentProvider.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDBUserProfile.h"
#import "Flurry.h"
#import "PEXReport.h"

static NSString * const keychainIdPass = @"net.phonex.phonex.logincreds";
static NSString * const keychainIdPkcs = @"net.phonex.phonex.logincreds.pkcs";
static NSString * const keychainIdPem = @"net.phonex.phonex.logincreds.pem";
@implementation PEXLoginHelper {

}

+ (BOOL) passwordStoreAllowed {
#ifdef PEX_NOKEYCHAIN
    return NO;
#else
    const BOOL passStoreAllowed = true;

    // DEPRECATED See IPH-294
    // PEXUserAppPreferences *prefs = [PEXUserAppPreferences instance];
    // BOOL passStoreAllowed = [prefs getBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY defaultValue:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT];

    return passStoreAllowed;
#endif
}

+ (PEXCredentials *)loadCredentialsFromKeyChain{
    return [self loadCredentialsFromKeyChain: keychainIdPass];
}

+ (PEXCredentials *)loadCredentialsFromKeyChain: (NSString *) keychainId {
    @try {
        // Check if storing credentials to KeyStore is allowed.
        /*
        if (![self passwordStoreAllowed]){
            DDLogVerbose(@"Password store is disabled");
            return nil;
        }
        */

        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:keychainId accessGroup:nil];
        NSString * uname = [keychain objectForKey:(__bridge id) kSecAttrAccount];
        NSString * pass = [keychain objectForKey:(__bridge id) kSecValueData];
        if ([PEXUtils isEmpty:uname] || [PEXUtils isEmpty:pass]){
            return nil;
        }

        return [PEXCredentials credentialsWithPassword:pass username:uname];

    } @catch(NSException * e){
        DDLogError(@"Exception in loading from keychain %@", e);
        [[PEXReport reportWith:YES] logError:@"alogin.credsLoadException"
                                     message:[NSString stringWithFormat:@"Exception in loading from keychain %@", e]
                                       exception:e];
    }

    return nil;
}

+ (void)storeCredentialsToKeychain:(PEXUserPrivate *) privData
{
    [self storeCredentialsToKeychain:privData forceStore:false];
}

+ (void)storeCredentialsToKeychain:(PEXUserPrivate *) privData forceStore:(const bool) forceStore
{
    if (privData == nil || [PEXUtils isEmpty:privData.username] || [PEXUtils isEmpty:privData.pass]){
        DDLogError(@"Cannot store credentials to the keychain from private data. Nil data");
        return;
    }

    // Store main password.
    [self storeCredentialsToKeychain:privData.username password:privData.pass forceStore:forceStore];

#ifdef PEX_AUTOLOGIN_CACHE_DERIVATES
    // Is PKCS password non-empty?
    if (![PEXUtils isEmpty:privData.pkcsPass]){
        [self storeCredentialsToKeychain:privData.username password:privData.pkcsPass keychainId:keychainIdPkcs];
    } else {
        DDLogInfo(@"PKCS pass not stored to keychain");
        [self resetKeychain:keychainIdPkcs];
    }

    // Is PEM password non-empty?
    if (![PEXUtils isEmpty:privData.pemPass]){
        [self storeCredentialsToKeychain:privData.username password:privData.pemPass keychainId:keychainIdPem];
    } else {
        DDLogInfo(@"PEM pass not stored to keychain");
        [self resetKeychain:keychainIdPem];
    }
#endif
}

+ (void)storeCredentialsToKeychain:(NSString *)username password:(NSString *)password
                        forceStore:(const bool) forceStore
{
    [self storeCredentialsToKeychain:username password:password keychainId:keychainIdPass forceStore:forceStore];
}

+ (void)storeCredentialsToKeychain:(NSString *)username password:(NSString *)password keychainId: (NSString *) keychainId
                             forceStore:(const bool) forceStore
{
    @try {
        // Check if storing credentials to KeyStore is allowed.
        if (!forceStore && ![self passwordStoreAllowed]){
            DDLogVerbose(@"Password store is disabled");
            return;
        }

        KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:keychainId accessGroup:nil];
        [keychain setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
        [keychain setObject:username forKey:(__bridge id)kSecAttrAccount];
        [keychain setObject:password forKey:(__bridge id)kSecValueData];
        DDLogVerbose(@"Pass stored to keychain");

    } @catch(NSException * e){
        DDLogError(@"Exception in keychain save %@", e);
    }
}

+ (void)resetKeychain {
    [self resetKeychain:keychainIdPass];
#ifdef PEX_AUTOLOGIN_CACHE_DERIVATES
    [self resetKeychain:keychainIdPkcs];
    [self resetKeychain:keychainIdPem];
#endif
}

+ (void)resetKeychain: (NSString *) keychainId {
    @try {
        KeychainItemWrapper* keychain = [[KeychainItemWrapper alloc] initWithIdentifier:keychainId accessGroup:nil];
        [keychain resetKeychainItem];

    } @catch(NSException * e){
        DDLogError(@"Exception in keychain reset %@", e);
    }
}

+ (void) setSavePasswordInKeyChain: (const bool) enabled {

    // DEPRECATED See IPH-294
    //[[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY
    //                                              value:enabled];

    if (!enabled) {
        [self resetKeychain];
    } else {
        PEXUserPrivate * privateData = [[PEXAppState instance] getPrivateData];
        [self storeCredentialsToKeychain:privateData];
    }
}

+ (int)waitForServiceIsOK:(PEXService *)svc canceller:(id <PEXCanceller>)canceller {
    DDLogVerbose(@"Starting wait loop for service to become ready.");

    NSDate * date = [NSDate date];
    int returnVal = 0;
    while (YES) {
        if (svc.initState == PEX_SERVICE_FINISHED || svc.initState == PEX_SERVICE_INITIALIZED) {
            DDLogDebug(@"Service is ready for a new login process.");
            break;
        }

        if ([date timeIntervalSinceNow] < -10.0) {
            returnVal = -1;
            DDLogInfo(@"Waiting for service to become ready for login timed out.");
            break;
        }

        if (canceller != nil && [canceller isCancelled]){
            returnVal = -2;
            DDLogInfo(@"Waiting for serice to become ready was cancelled");
            break;
        }

        // adapt this value in microseconds.
        usleep(10000);
    }

    return returnVal;
}

+ (int) derivePrivData: (PEXUserPrivate *) privData creds: (PEXCredentials *) creds canceller: (id<PEXCanceller>) canceller tryCached: (BOOL) tryCached {
    int storedCredsCheck = [PEXSecurityCenter checkStoredUserLoginData:creds.username];

    // IPH-306: If device does not contain
    if (storedCredsCheck != kLOGIN_DATA_OK){
        NSString * err = nil;
        if (storedCredsCheck == kLOGIN_DATA_NO_SALT_PKCS12 || storedCredsCheck == kLOGIN_DATA_NO_SALT_PEM){
            err = [NSString stringWithFormat:@"Autologin misses password salts, cannot continue, res: %d", storedCredsCheck];
        } else if (storedCredsCheck == kLOGIN_DATA_NO_PKCS12){
            err = @"Autologin misses PKCS12 priv key file, cannot continue";
        } else {
            err = [NSString stringWithFormat:@"Autologin cannot continue, missing stored credentials parts, res: %d", storedCredsCheck];
        }

        DDLogError(@"Autologin fail: %@", err);
        [[PEXReport reportWith:YES uName:creds.username]
                    logError:[NSString stringWithFormat:@"alogin.missingCreds.%d", storedCredsCheck] message:err error:nil];
        return -2;
    }

    DDLogVerbose(@"Stored credentials found on the device");

    // Generate PKCS password part.
    // 1.1. Generate new storage password, using salt.
    if (canceller != nil && [canceller isCancelled]){
        return -1;
    }

    DDLogVerbose(@"pkcs gen");
    privData.pkcsPass = nil;

#ifdef PEX_AUTOLOGIN_CACHE_DERIVATES
    if (tryCached){
        PEXCredentials * credPkcs = [self loadCredentialsFromKeyChain:keychainIdPkcs];
        DDLogVerbose(@"credPKCS: %@", credPkcs);
        if (credPkcs != nil
                && ![PEXUtils isEmpty:credPkcs.username]
                && ![PEXUtils isEmpty:credPkcs.password]
                && [creds.username isEqualToString:credPkcs.username])
        {
            DDLogVerbose(@"PKCS pass loaded from cache");
            privData.pkcsPass = credPkcs.password;
        }
    }
#endif

    if ([PEXUtils isEmpty:privData.pkcsPass]) {
        privData.pkcsPass = [PEXPKCS12Passwd getStoragePass:creds.username key:creds.password progress:nil];
    }

    // Generate PEM password part.
    // 2.1. Generate new storage password, using salt.
    if (canceller != nil && [canceller isCancelled]){
        return -1;
    }

    DDLogVerbose(@"pem gen");
    privData.pemPass = nil;

#ifdef PEX_AUTOLOGIN_CACHE_DERIVATES
    if (tryCached){
        PEXCredentials * credPem = [self loadCredentialsFromKeyChain:keychainIdPem];
        if (credPem != nil
                && ![PEXUtils isEmpty:credPem.username]
                && ![PEXUtils isEmpty:credPem.password]
                && [creds.username isEqualToString:credPem.username])
        {
            DDLogVerbose(@"PEM pass loaded from cache");
            privData.pemPass = credPem.password;
        }
    }
#endif

    if ([PEXUtils isEmpty:privData.pemPass]) {
        privData.pemPass = [PEXPEMPasswd getStoragePass:creds.username key:creds.password];
    }

    // Load identity file, init privData.
    if (canceller != nil && [canceller isCancelled]){
        return -1;
    }

    DDLogVerbose(@"identity load");
    int identityLoadRes = [PEXSecurityCenter loadIdentity:privData];
    if (identityLoadRes != kIDENTITY_EXISTS){
        DDLogError(@"Autologin cannot continue: Identity load was not successful, code: %d", identityLoadRes);

        [[PEXReport reportWith:YES uName:creds.username]
                    logError:[NSString stringWithFormat:@"alogin.missingIdentity.%d", identityLoadRes]
                 message:[NSString stringWithFormat: @"Identity load was not successful, code: %d", identityLoadRes]
                   error:nil];

        return -3;
    }

    if (canceller != nil && [canceller isCancelled]){
        return -1;
    }

    // Generate XMPP password part.
    DDLogVerbose(@"XMPP gen");
    privData.xmppPass = [PEXPasswdGenerator generateXMPPPassword:creds.username passwd:creds.password];
    privData.sipPass = creds.password;
    privData.pass = creds.password;
    privData.username = creds.username;
    return 0;
}

+ (BOOL) tryOpenDatabase: (PEXUserPrivate *) privData openResult: (PEXDbOpenStatus *) openResult {
    @try {
        return [self openDatabase:privData openResult:openResult];

    } @catch(NSException * e){
        DDLogError(@"Exception in setting DB key and user save task, exception=%@", e);
        if (openResult != NULL) {
            *openResult = PEX_DB_OPEN_FAIL_GENERAL;
        }
    }

    return NO;
}

+ (BOOL) openDatabase: (PEXUserPrivate *) privData openResult: (PEXDbOpenStatus *) openResult {
    DDLogVerbose(@"Going to open a database");
    PEXUser * const user = [[PEXUser alloc] init];
    user.email = privData.username;

    const PEXDbOpenStatus dbLoadResult = [PEXDatabase tryOpenDatabase:user encryptionKey:privData.pkcsPass];
    BOOL success = NO;
    if (openResult != NULL){
        *openResult = dbLoadResult;
    }

    switch (dbLoadResult) {
        case PEX_DB_OPEN_FAIL_GENERAL:
        case PEX_DB_OPEN_FAIL_CLOSE_PREVIOUS:
        case PEX_DB_OPEN_FAIL_NO_FILE:
        case PEX_DB_OPEN_FAIL_OPEN_FAILED:
        case PEX_DB_OPEN_FAIL_INVALID_KEY:
        default:
        {
            DDLogError(@"Fatal error during database open call, code: %ld", (long) dbLoadResult);
            [PEXDatabase unloadDatabase];
            success = NO;
            break;
        }

        case PEX_DB_OPEN_OK:
            DDLogVerbose(@"Database opened successfully");
            success = YES;
            break;
    }

    if (!success) {
        [[PEXReport reportWith:YES uName:privData.username]
                    logError:[NSString stringWithFormat:@"alogin.dbOpenFail.%ld", (long) dbLoadResult]
                 message:[NSString stringWithFormat:@"Autologin: DB Open was not successful, code: %ld", (long) dbLoadResult]
                   error:nil];
    }

    return success;
}

+ (BOOL)loadAccountId:(PEXUserPrivate *)privData {
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    NSArray * profiles = [PEXDbUserProfile loadFromDatabase:cr selection:nil selectionArgs:nil
                                                 projection:@[PEX_DBUSR_FIELD_ID, PEX_DBUSR_FIELD_ACC_ID, PEX_DBUSR_FIELD_DISPLAY_NAME]
                                                  sortOrder:nil];

    // Load all profiles stored for distribution accountManager
    DDLogVerbose(@"Number of saved accounts=%ld", (unsigned long) profiles.count);
    if (profiles != nil && profiles.count > 0){
        privData.accountId = ((PEXDbUserProfile * )profiles[0]).id;
        return YES;
    }

    return NO;
}


@end