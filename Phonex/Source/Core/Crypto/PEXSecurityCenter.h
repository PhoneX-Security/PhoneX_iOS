//
// Created by Dusan Klinec on 06.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXX509Store;

typedef enum pex_security_file_class {
    PEX_SECURITY_FILE_CLASS_IDENTITY=1,
    PEX_SECURITY_FILE_CLASS_DB=2,
    PEX_SECURITY_FILE_CLASS_FILES=4,
    PEX_SECURITY_FILE_CLASS_CACHES=8
} pex_security_file_class;

/**
 * Block to determine backup flag for given path.
 */
typedef BOOL (^PEXFileBackupFlagBlock)(NSString *path);

/**
 * Object passed for certificate verification.
 * Defines policy for acceptable errors - e.g., certificate
 * expiration on intermediate certificates.
 */
@interface PEXCertVerifyOptions : NSObject
@property (nonatomic) BOOL allowOldCaExpired;
- (instancetype)initWithAllowOldCaExpired:(BOOL)allowOldCaExpired;
+ (instancetype)optionsWithAllowOldCaExpired:(BOOL)allowOldCaExpired;
@end

/**
 * Main Security center - handles certificates, trust, verifications, ...
 */
@interface PEXSecurityCenter : NSObject

/**
* Returns array of NSData - Root CA certificates in DER format.
* Lazy initializes shared variable.
*/
+(NSArray *) getRootCAsInDer;
+(NSArray *) getRootCAWebInDer;

/**
 * Temporary certificate expiration recovery.
 */
+ (NSArray<PEXX509*> *)getRootCAExpired;

/**
 * Returns array of SecCertificateRef.
 * Lazy initializes shared variable.
 */
+(NSArray *) getServerTrustAnchors;

/**
* Returns store of CA certificates used for X509 certificate verification.
*/
+ (PEXX509Store *) getDefaultCAStore;

+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt;
+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt settings: (PEXCertVerifyOptions *) settings;
+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store settings: (PEXCertVerifyOptions *) settings;
+ (BOOL) osslCertValidate: (PEXX509 *) crt;
+ (BOOL) osslCertValidate: (PEXX509 *) crt settings: (PEXCertVerifyOptions *) settings;
+ (BOOL) osslCertValidate: (PEXX509 *) crt additionalTrustAnchors: (NSArray *) additionalTrustAnchors;
+ (BOOL) osslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store;
+ (BOOL) osslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store
                 settings: (PEXCertVerifyOptions *) settings;

/**
 * Returns default directory for storing private data - certificates, private keys, ...
 * Directory is created if it does not exist.
 */
+(NSString *) getDefaultPrivateDirectory: (BOOL) createIfNonexistent;
+(NSString *) getDefaultDocsDirectory: (NSString *) subDir createIfNonexistent: (BOOL)createIfNonexistent;
+(NSString *) getDefaultCachesDirectory: (NSString *) subDir createIfNonexistent: (BOOL)createIfNonexistent;

/**
 * Returns username search key for the given user name.
 * May or may not contain domain part. If domain part is missing, default
 * one is added, suffixing it with @phone-x.net.
 *
 * Userkey is path friendly, can be used as a part of a file name.
 * Used as a level of protection against malicious user names.
 */
+(NSString *) getUsernamePathKey: (NSString *) username;

/**
* Sets default file protection (encryption) mode by the application on the existing file.
*/
+ (BOOL) setDefaultProtectionMode: (NSString *) file pError: (NSError **) pError;

/**
 * Sets protection mode + backup flag according to given file class.
 */
+ (BOOL) setDefaultProtectionMode: (NSString *) file fileClass: (pex_security_file_class) fileClass pError: (NSError **) pError;

/**
 * Sets default file protection (encryption) mode on the given folder and all elements it contains (recursively).
 * Returns number of checked elements (files+folders).
 */
+ (NSUInteger) setDefaultProtectionModeOnAll: (NSString *) rootPath;

/**
 * Same as setDefaultProtectionModeOnAll but checks only file names with matching given prefix, not descending to a folders.
 */
+ (NSUInteger) setDefaultProtectionModeOnAll: (NSString *) rootPath matchingPrefix: (NSString *) prefix;

/**
 * Recursively sets backup flag on the files+folders from rootPath down (inclusive).
 * Backup flag is determined by the block.
 */
+ (NSUInteger)setBackupFlagOnAll:(NSString *)rootPath flagBlock: (PEXFileBackupFlagBlock) flagBlock;
+ (NSUInteger)setBackupFlagOnAll:(NSString *)rootPath
                  matchingPrefix:(NSString *)prefix
                       flagBlock:(PEXFileBackupFlagBlock)flagBlock
                     fileManager: (NSFileManager *) filemgr;

/**
 * Tries to obtain backupability flag of the given file.
 */
+ (int) isBackupFlagSet: (NSURL *) fileUrl;
+ (int) isBackupFlagSetFile: (NSString *) filePath;

/**
 * Set backupability for the given file. If true, file can be backed up to iTunes or iCloud.
 * If false, file will be excluded from backups.
 */
+ (BOOL) setBackupFlag: (NSURL *) fileUrl backupFlag:(BOOL) backupFlag;
+ (BOOL) setBackupFlagFile: (NSString *) filePath backupFlag:(BOOL) backupFlag;

/**
 * Like setBackupFlag, but encapsulated in try-catch. Logs verbose message if
 * flag actually changed by this operation.
 */
+ (BOOL) trySetBackupFlagFile: (NSString *) filePath backupFlag:(BOOL) backupFlag;
+ (BOOL) trySetBackupFlag: (NSURL *) fileUrl backupFlag:(BOOL) backupFlag;
+ (BOOL) trySetBackupFlagFile: (NSString *) filePath fileClass: (pex_security_file_class) fileClass;

+(NSData *) readP12File:(NSString *)p12Path;

+(NSString *) getCAFile: (NSString *) username;

+(NSString *) getCertificateFile: (NSString *) username;

+(NSString *) getPrivkeyFile: (NSString *) username;

+(NSString *) getPKCS12File: (NSString *) username;

+(NSString *) getDatabaseFile: (NSString *) username;

+(NSString *) getZrtpFile: (NSString *) username;

+(NSString *) getLogDir: (NSString *)username;
+ (NSString *)getLogDirGeneral;

+(NSString *) getFileTransferCacheDir: (NSString *) username;

+(NSString *) getFileTransferDocDir;

/**
 * Determines backup flag for the file class from user using preferences.
 */
+ (BOOL) getDefaultBackupFlagForFileClass: (pex_security_file_class) fileClass;

/**
 * Guesses file protection class from its path. Has to be an absolute path!
 * Mainly for differentiation of identity vs. database file.
 */
+ (pex_security_file_class) getFileProtectionClass: (NSString *) path;

+ (BOOL) validateCertificate: (const NSData * const) crt;
+ (BOOL) validateTrustForChallenge: (NSURLAuthenticationChallenge *)challenge
                        credential: (NSURLCredential **) credential;

+ (BOOL) provideClientCertificateForChallenge: (NSURLAuthenticationChallenge *)challenge
                                   credential: (NSURLCredential **) credential
                                  privateData: (const PEXUserPrivate * const) privData;

@end