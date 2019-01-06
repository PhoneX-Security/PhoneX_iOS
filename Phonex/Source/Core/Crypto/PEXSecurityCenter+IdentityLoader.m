//
// Created by Dusan Klinec on 19.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSecurityCenter+IdentityLoader.h"
#import "PEXPKCS12Passwd.h"
#import "PEXPEMPasswd.h"
#import "PEXUserPrivate.h"
#import "PEXCryptoUtils.h"


@implementation PEXSecurityCenter (IdentityLoader)
+ (int)checkStoredUserLoginData:(NSString *)username {
    // Check auth salt presence.
    if (![PEXPKCS12Passwd saltExists:username]){
        return kLOGIN_DATA_NO_SALT_PKCS12;
    }

    if (![PEXPEMPasswd saltExists:username]){
        return kLOGIN_DATA_NO_SALT_PEM;
    }

    // Try to load PKCS12 file.
    NSString * p12Path = [PEXSecurityCenter getPKCS12File:username];

    // Existence check. If the do not exist, auth cannot be made.
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if (![fmgr fileExistsAtPath:p12Path]){
        return kLOGIN_DATA_NO_PKCS12;
    }

    return kLOGIN_DATA_OK;
}

+ (int)loadIdentity:(PEXUserPrivate *)privData {
    // Check persistent identity data
    int checkRes = [self checkStoredUserLoginData:[privData username]];

    // Default - no key.
    if (checkRes!=kLOGIN_DATA_OK){
        DDLogError(@"Could not load identity, stored data missing, code: %d", checkRes);
        return kIDENTITY_NO_FILE;
    }

    // Load PKCS12 file to NSData.
    NSString * p12Path = [PEXSecurityCenter getPKCS12File:[privData username]];
    NSData * p12Bin = [PEXSecurityCenter readP12File:p12Path];
    if (p12Bin==nil || [p12Bin length] < 50){
        DDLogError(@"Cannot load PEM cert. p12bin null: %d, size: %lu", p12Bin == nil, (unsigned long)(p12Bin == nil ? 0 : [p12Bin length]));
        return kIDENTITY_NO_FILE;
    }

    // Read identity to priv data structure.
    int identityRes = [PEXCryptoUtils extractIdentity:p12Bin privData:privData p12Passwd:[privData pkcsPass]];
    if (identityRes != 1){
        DDLogError(@"Cannot load identity file, res=%d", identityRes);
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_NO_FILE;
    }

    // Check if empty
    if ([privData privKey] == NULL || [[privData privKey] getRaw] == NULL
            || [privData cert] == NULL || [[privData cert] getRaw] == NULL){
        DDLogError(@"Identity file seems empty - cannot load private key or certificate");
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_EMPTY;
    }

    // Check CName of the certificate
    int cnameCnt = 0;
    NSString * crtCname = [PEXCryptoUtils getCNameCrt:[[privData cert] getRaw] totalCount:&cnameCnt];

    // Compare path keys instead of user names. There is a specific normalization during path key gen.
    NSString * uKeyUsr = [self getUsernamePathKey:[privData username]];
    NSString * uKeyCrt = [self getUsernamePathKey:crtCname];
    if (cnameCnt!=1 || ![uKeyUsr isEqualToString:uKeyCrt]) {
        DDLogError(@"Identity load fail: bad CN: %@", uKeyCrt);
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_BAD_CN;
    }

    // Check expiration.
    NSDate * notAfter = [PEXCryptoUtils getNotAfter:[[privData cert] getRaw]];
    if (notAfter == nil){
        DDLogError(@"NotAfter cannot be extracted");
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_INVALID;
    }

    if ([PEXDateUtils date:notAfter isOlderThan:[NSDate date]]){
        DDLogError(@"NotAfter is already past, certificate expired: %@", notAfter);
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_INVALID;
    }

    // Check for validity
    BOOL certValid = [PEXSecurityCenter tryOsslCertValidate:[privData cert]];
    if (!certValid){
        DDLogError(@"Identity cannot be verified");
        [PEXCryptoUtils clearCertIdentity:privData];
        return kIDENTITY_INVALID;
    }

    // Generate PEM files.
    [self exportPEMFiles:privData];

    // Data loaded successfully, exit.
    return kIDENTITY_EXISTS;
}

+ (int)exportKeyStore:(PEXUserPrivate *)privData {
    // Obtain file manager instance for file manipulation.
    NSFileManager * fmgr = [NSFileManager defaultManager];

    // Create a private directory if it does not exist.
    [PEXSecurityCenter getDefaultPrivateDirectory:YES];

    // Obtain paths for certificate and private key.
    NSString * pkcs12Path = [PEXSecurityCenter getPKCS12File:privData.username];

    // Export PKCS12 file - main identity file for SOAP & XMPP calls.
    PKCS12 * p12 = [PEXCryptoUtils createDefaultKeystore:privData];
    NSData * p12Bin = [PEXCryptoUtils exportPKCS12:p12];
    PKCS12_free(p12);

    [fmgr createFileAtPath:pkcs12Path contents:p12Bin
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    [PEXSecurityCenter trySetBackupFlagFile:pkcs12Path backupFlag:[[PEXUserAppPreferences instance] getDefaultBackupFlagForIdentity]];
    DDLogVerbose(@"PKCS12File: %@, user=%@", pkcs12Path, privData.username);
    return 1;
}

+ (int)exportPEMFiles:(PEXUserPrivate *)privData {
    // Obtain file manager instance for file manipulation.
    NSFileManager * fmgr = [NSFileManager defaultManager];

    // Create a private directory if it does not exist.
    [PEXSecurityCenter getDefaultPrivateDirectory:YES];

    // Obtain paths for certificate and private key.
    NSString * certPath = [PEXSecurityCenter getCertificateFile:privData.username];
    NSString * privKeyPath = [PEXSecurityCenter getPrivkeyFile:privData.username];
    const BOOL identityBackupFlag = [[PEXUserAppPreferences instance] getDefaultBackupFlagForIdentity];

    // Export received certificate to PEM and write it to a file.
    // Default encryption mode - until first auth.
    NSString * certPem = [PEXCryptoUtils exportCertificateToPEMWrap: privData.cert];
    [fmgr createFileAtPath:certPath contents:[certPem dataUsingEncoding:NSUTF8StringEncoding]
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    privData.pemCrtPath = certPath;
    [PEXSecurityCenter trySetBackupFlagFile:certPath backupFlag:identityBackupFlag];
    DDLogVerbose(@"CertificateFile: %@", certPath);

    // Export private key to a file, ahs to generate encryption password at first.
    NSString * privPem = [PEXCryptoUtils exportEvpKeyToPEMWrap: privData.privKey password: privData.pemPass];
    [fmgr createFileAtPath:privKeyPath contents:[privPem dataUsingEncoding:NSUTF8StringEncoding]
                attributes:@{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication}];
    privData.pemKeyPath = privKeyPath;
    [PEXSecurityCenter trySetBackupFlagFile:certPath backupFlag:identityBackupFlag];
    DDLogVerbose(@"PrivkeyFile: %@", privKeyPath);

    return 1;
}


@end