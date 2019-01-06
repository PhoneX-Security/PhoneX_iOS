//
// Created by Dusan Klinec on 06.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSecurityCenter.h"
#import "PEXResCrypto.h"
#import "PEXCryptoUtils.h"
#import "PEXSystemUtils.h"
#import "PEXMessageDigest.h"
#import "PEXStringUtils.h"
#import "X509LookupBuffer.h"
#import "PEXX509Store.h"
#import "PEXX509Stack.h"
#import "PEXUtils.h"

@implementation PEXCertVerifyOptions { }

- (instancetype)init {
    self = [super init];
    if (self) {
        self.allowOldCaExpired = NO;
    }

    return self;
}

- (instancetype)initWithAllowOldCaExpired:(BOOL)allowOldCaExpired {
    self = [super init];
    if (self) {
        self.allowOldCaExpired = allowOldCaExpired;
    }

    return self;
}

+ (instancetype)optionsWithAllowOldCaExpired:(BOOL)allowOldCaExpired {
    return [[self alloc] initWithAllowOldCaExpired:allowOldCaExpired];
}

@end

// OpenSSL certificate verification callback.
static int verifyCbAllowExpiredInterm(int ok,X509_STORE_CTX *ctx);

@implementation PEXSecurityCenter {

}

/**
* Static array of DER CA root certificates.
*/
static NSArray * serverTrustDER = nil;

/**
* Static array of DER Web CA root certificates.
*/
static NSArray * serverWebTrustDER = nil;

/**
 * Static array of SecCertificateRef.
 */
static NSArray * serverTrustAnchors = nil;

/**
 * Static array of SecCertificateRef.
 */
static NSArray * expiredPems = nil;

+ (NSArray *)getRootCAsInDer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (serverTrustDER==nil){
            NSData * caRoots = [PEXResCrypto loadCARoots];
            if (caRoots==nil){
                DDLogError(@"CA roots file cannot be loaded from resources");
                return;
            }

            // Parse PEM encoded certificates to array of Sec certificates.
            serverTrustDER = [PEXCryptoUtils getDERCertsFromPEM:caRoots];
            DDLogVerbose(@"Root CA DER loaded [%p], cn=%lu", serverTrustDER, (unsigned long)serverTrustDER.count);
        }
    });

    return serverTrustDER;
}

+ (NSArray *)getRootCAWebInDer {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (serverWebTrustDER==nil){
            NSData * caRoots = [PEXResCrypto loadCAWebRoots];
            if (caRoots==nil){
                DDLogError(@"Web CA roots file cannot be loaded from resources");
                return;
            }

            // Parse PEM encoded certificates to array of Sec certificates.
            serverWebTrustDER = [PEXCryptoUtils getDERCertsFromPEM:caRoots];
            DDLogVerbose(@"Root Web CA DER loaded [%p], cn=%lu", serverWebTrustDER, (unsigned long)serverWebTrustDER.count);
        }
    });

    return serverWebTrustDER;
}

+ (NSArray<PEXX509*> *)getRootCAExpired {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (expiredPems==nil){
            NSData * caRoots = [PEXResCrypto loadExpiredCARoots];
            if (caRoots==nil || caRoots.length == 0){
                DDLogError(@"CA expired roots file cannot be loaded from resources");
                return;
            }

            // Parse PEM encoded certificate file to DER and then to PEXX509.
            NSMutableArray<PEXX509*> * toRet = [[NSMutableArray alloc] init];
            NSArray<NSData *> * expiredDer = [PEXCryptoUtils getDERCertsFromPEM:caRoots];
            for(NSData * der in expiredDer){
                PEXX509 * x509 = [PEXCryptoUtils importCertificateFromDERWrap:der];
                if (x509 == nil || !x509.isAllocated){
                    continue;
                }

                [toRet addObject:x509];
            }

            expiredPems = [NSArray arrayWithArray:toRet];
            DDLogVerbose(@"Root CA Expired loaded [%p], cn=%lu", expiredPems, (unsigned long)expiredPems.count);
        }
    });

    return expiredPems;
}

+ (NSArray *)getServerTrustAnchors {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       if (serverTrustAnchors==nil){
           NSArray * der = [self getRootCAsInDer];
           NSArray * der2 = [self getRootCAWebInDer];
           NSArray * finalDers = [der arrayByAddingObjectsFromArray:der2];

           serverTrustAnchors = [PEXCryptoUtils getAnchorsFromDERCerts:finalDers];
           DDLogVerbose(@"ServerTrustAnchors loaded [%p] cnt=%d", serverTrustAnchors, serverTrustAnchors.count);
       }
    });

    return serverTrustAnchors;
}

+ (PEXX509Store *) getDefaultCAStore {
    static dispatch_once_t onceToken;
    static PEXX509Store * defaultStore = nil;
    dispatch_once(&onceToken, ^{
        if (defaultStore==nil){
            defaultStore = [self getX509Store:nil];
            DDLogVerbose(@"Default X509 CA store loaded [%@]", defaultStore);
        }
    });

    return defaultStore;
}

+ (BOOL) validateCertificate: (const NSData * const) crt {
    SecTrustRef trust = nil;
    SecCertificateRef caRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef) crt);
    if (caRef == nil){
        DDLogError(@"Cannot create certificate");
        return NO;
    }

    OSStatus trustOk =SecTrustCreateWithCertificates(caRef, nil, &trust);
    CFRelease(caRef); // CaRef is not needed anymore, has retain count +1, needs to be released.
    
    if (trustOk != noErr){
        DDLogError(@"Error in creating trust obj from certiicates");
        return NO;
    }

    const bool result = [self validateServerTrust:trust];
    CFRelease(trust);

    return result;
}

+ (BOOL) validateTrustForChallenge: (NSURLAuthenticationChallenge *)challenge
                        credential: (NSURLCredential **) credential
{
    NSURLProtectionSpace * const protectionSpace = [challenge protectionSpace];
    const SecTrustRef trust = [protectionSpace serverTrust];

    const BOOL trustIsValid = [self validateServerTrust:trust];

    if (trustIsValid)
    {
        NSURLCredential * const newCredential = [NSURLCredential credentialForTrust:trust];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];

        if (credential != NULL)
            *credential = newCredential;
    }
    else
    {
        DDLogWarn(@"authenticateForChallenge: Certificate not valid!");
    }

    return trustIsValid;
}

+ (BOOL) validateServerTrust: (const SecTrustRef) trust
{
    // Obtain trust root CA anchors.
    NSArray * anchors = [PEXSecurityCenter getServerTrustAnchors];
    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) anchors);
    SecTrustSetAnchorCertificatesOnly(trust, YES);

    // Validate certificate & trust zone against given trust anchors.
    SecTrustResultType res = kSecTrustResultInvalid;
    OSStatus sanityCheck = SecTrustEvaluate(trust, &res);

    return sanityCheck == noErr && [self validateResult:res];
}

+ (BOOL) validateResult:(SecTrustResultType)res
{
    return ((res == kSecTrustResultProceed)                 // trusted certificate
            || (res == kSecTrustResultUnspecified)      // valid but user have not specified whether to trust
            || (res == kSecTrustResultDeny));             // valid but user does not trusts this certificate
}

+ (BOOL) provideClientCertificateForChallenge: (NSURLAuthenticationChallenge *)challenge
                                   credential: (NSURLCredential **) credential
                                  privateData: (const PEXUserPrivate * const) privData
{
    NSURLProtectionSpace * const protectionSpace = [challenge protectionSpace];

    NSArray *acceptedIssuers = [protectionSpace distinguishedNames];
    //[securityCenter setIssuerDistinguishedNames:acceptedIssuers];

    // If we have some CA certificates, it has to be set now.

    if (privData.cacerts!=nil && privData.cacerts.count > 0){
        // TODO: implement adding CA certificates to the certChain to be sent to the server.
        DDLogWarn(@"CA certificates are not supported yet");
    }

    const bool certificatePrerequisitesFulfilled = (privData != nil) && (privData.identity != nil);

    if (certificatePrerequisitesFulfilled)
    {
        CFArrayRef certArray = nil;
        NSURLCredential * const newCredential = [NSURLCredential credentialWithIdentity:privData.identity
                                                   certificates:(__bridge NSArray*) certArray
                                                    persistence:NSURLCredentialPersistenceNone];

        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];

        if (credential != NULL)
            *credential = newCredential;

        DDLogVerbose(@"ClientCert provided for user=%@", privData.username);
    }
    else
    {
        DDLogWarn(@"authenticateForChallenge: Client certificate problem!");
    }

    return certificatePrerequisitesFulfilled;
}

/**
* Generates X509 store object for X509 certificate validation initialized with root CA and additional trust roots in
* DER format.
*/
+ (PEXX509Store *) getX509Store: (NSArray *) trustRoots {
    int ret=0;
    X509_STORE *cert_ctx=NULL;
    X509_LOOKUP *lookup=NULL;

    cert_ctx = X509_STORE_new();
    if (cert_ctx == NULL) {
        return nil;
    }

    lookup = X509_STORE_add_lookup(cert_ctx, X509_LOOKUP_buffer());
    if (lookup == NULL){
        return nil;
    }

    // Load CA
    NSArray * certsToAdd = nil;
    if (trustRoots == nil || trustRoots.count == 0){
        certsToAdd = [self getRootCAsInDer];
    } else {
        NSMutableArray *caCerts = [[NSMutableArray alloc] init];
        [caCerts addObjectsFromArray:[self getRootCAsInDer]];
        [caCerts addObjectsFromArray:trustRoots];
        certsToAdd = caCerts;
    }

    // Add each cert individually.
    PEXMemBIO * mbio = nil;
    for (NSData * cCrt in certsToAdd){
        mbio = [[PEXMemBIO alloc] initWithNSData:cCrt];

        if(!X509_LOOKUP_load_buf(lookup, (char const *)mbio.getRaw, X509_FILETYPE_ASN1)){
            DDLogError(@"Error in loading current certificate");
            continue;
        }

        [mbio freeBuffer];
    }

    lookup=X509_STORE_add_lookup(cert_ctx, X509_LOOKUP_hash_dir());
    if (lookup == NULL){
        goto end;
    }

    X509_LOOKUP_add_dir(lookup,NULL, X509_FILETYPE_DEFAULT);
    return [[PEXX509Store alloc] initWith:cert_ctx];
end:
    return nil;
}

+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt {
    return [self tryOsslCertValidate:crt chainOfDer:nil store:[self getDefaultCAStore] settings:nil];
}

+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt settings: (PEXCertVerifyOptions *) settings {
    return [self tryOsslCertValidate:crt chainOfDer:nil store:[self getDefaultCAStore] settings:settings];
}

+ (BOOL) tryOsslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store settings: (PEXCertVerifyOptions *) settings{
    BOOL crtOk = NO;
    @try {
        crtOk = [PEXSecurityCenter osslCertValidate:crt chainOfDer:chain store:store settings:settings];
    } @catch(NSException * e){
        DDLogInfo(@"Certificate was not verified, exception=%@", e);
    }

    return crtOk;
}

+ (BOOL) osslCertValidate: (PEXX509 *) crt {
    return [self osslCertValidate:crt chainOfDer: nil store:[self getDefaultCAStore] settings:nil];
}

+ (BOOL) osslCertValidate: (PEXX509 *) crt settings: (PEXCertVerifyOptions *) settings{
    return [self osslCertValidate:crt chainOfDer: nil store:[self getDefaultCAStore] settings:nil];
}

+ (BOOL) osslCertValidate: (PEXX509 *) crt additionalTrustAnchors: (NSArray *) additionalTrustAnchors {
    return [self osslCertValidate:crt chainOfDer: nil store:[self getX509Store:additionalTrustAnchors] settings:nil];
}

+ (BOOL) osslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store {
    return [self osslCertValidate:crt chainOfDer:chain store:store settings:nil];
}

+ (BOOL) osslCertValidate: (PEXX509 *) crt chainOfDer: (NSArray *) chain store: (PEXX509Store *) store
                 settings: (PEXCertVerifyOptions *) settings
{
    if (crt == nil || !crt.isAllocated){
        return NO;
    }

    int i = 0;
    BOOL ret = NO;
    X509_STORE * ctx = store.getRaw;
    X509 *x = crt.getRaw;
    X509_STORE_CTX * csc = NULL;
    X509_VERIFY_PARAM * vparam = NULL;
    STACK_OF(X509) * chainStack = NULL;
    PEXX509Stack * pexChainStack = nil;

    csc = X509_STORE_CTX_new();
    if (csc == NULL) {
        goto end;
    }

    vparam = X509_VERIFY_PARAM_new();
    if (vparam == NULL){
        goto end;
    }

    X509_VERIFY_PARAM_set_depth(vparam, 16);

    // Can set custom time of verification if needed.
    //X509_VERIFY_PARAM_set_time(vparam, NULL);
    X509_STORE_set1_param(ctx, vparam);
    X509_STORE_set_flags(ctx, 0);

    // Create cert chain for validation.
    // CA root certificates.
    if (chain != nil && chain.count > 0){
        pexChainStack = [[PEXX509Stack alloc] initWithDERArray:chain];
        chainStack = pexChainStack.getRaw;
    }

    if(!X509_STORE_CTX_init(csc,ctx,x,chainStack)){
        goto end;
    }

    // Verification callback, on each error the callback is triggered
    // so we can disable checking of some particular features, e.g., expiration
    // time of intermediate authority.
    if (settings != nil && settings.allowOldCaExpired) {
        X509_STORE_CTX_set_verify_cb(csc, verifyCbAllowExpiredInterm);
    }

    ////// See crypto/asn1/t_x509.c for ideas on how to access and print the values
    i = X509_verify_cert(csc);
    if (i != 1){
        int errCode = X509_STORE_CTX_get_error(csc);
        int depth = X509_STORE_CTX_get_error_depth(csc);
        char const * errString = X509_verify_cert_error_string(errCode);
        DDLogInfo(@"Certificate validation failed, i=%d, code=%d, depth=%d, errString=%s", i, errCode, depth, errString);
    }

end:
    if (csc != NULL){
        X509_STORE_CTX_free(csc);
        csc = NULL;
    }

    if (vparam != NULL){
        X509_VERIFY_PARAM_free(vparam);
        vparam = NULL;
    }

    pexChainStack = nil;
    ret = i == 1;
    return ret;
}

+(int) verifyCallbackAllowExpiredIntermediate: (int) ok ctx: (X509_STORE_CTX *) ctx{
    int err = X509_STORE_CTX_get_error(ctx);
    int depth = X509_STORE_CTX_get_error_depth(ctx);
    X509 * errCrt = X509_STORE_CTX_get_current_cert(ctx);

    if (err == X509_V_ERR_CERT_HAS_EXPIRED){
        NSString * cname = [PEXCryptoUtils getCNameCrt:errCrt totalCount:NULL];
        NSArray<PEXX509*> * expiredExceptions = [PEXSecurityCenter getRootCAExpired];
        DDLogVerbose(@"Certificate has expired: %@, depth: %d, roots allowed: %d", cname, depth, (int)expiredExceptions.count);

        if (expiredExceptions == nil || expiredExceptions.count == 0){
            return ok;
        }

        for(PEXX509 * exc in expiredExceptions){
            if ([exc isAllocated] && X509_cmp(errCrt, [exc getRaw]) == 0){
                DDLogVerbose(@"Expired certificate is an exception");
                return 1;
            }
        }

        return ok;
    }

    return ok;
}

+(NSString *) getDefaultPrivateDirectory: (BOOL) createIfNonexistent {
    NSString * supDir = [PEXSystemUtils getDefaultSupportDirectory];
    NSString * privDir = [supDir stringByAppendingPathComponent:@"private"];

    if (createIfNonexistent){
        NSFileManager *filemgr = [NSFileManager defaultManager];
        if (![filemgr fileExistsAtPath:privDir]){

            // Create the private directory.
            NSError * err;
            NSDictionary * attributes = @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
            if (![filemgr createDirectoryAtPath:privDir withIntermediateDirectories:YES attributes:attributes error: &err]){
                // Failed to create directory
                DDLogError(@"Cannot create a private directory %@, error=%@", privDir, err);
                return nil;
            } else {
                DDLogDebug(@"Private directory created at: %@", privDir);
            }
        } else {
            [self setDefaultProtectionMode:privDir pError:nil];
        }

        // Backup
        PEXUserAppPreferences * prefs = [PEXUserAppPreferences instance];
        const BOOL privDirBackupFlag = [prefs getDefaultBackupFlagForIdentity] || [prefs getDefaultBackupFlagForDatabase];
        [PEXSecurityCenter trySetBackupFlagFile:privDir backupFlag:privDirBackupFlag];
    }

    return privDir;
}

+(NSString *) getDefaultDocsDirectory: (NSString *) subDir createIfNonexistent: (BOOL)createIfNonexistent{
    if (subDir != nil && ([PEXStringUtils contains:subDir needle:@"/"] || [PEXStringUtils contains:subDir needle:@".."])){
        [NSException raise:@"SecurityException" format:@"subdir not allowed: %@", subDir];
    }

    NSString * docsDir = [PEXSystemUtils getDefaultDocsDirectory];
    NSString * dsubDir = subDir != nil ? [docsDir stringByAppendingPathComponent:subDir] : docsDir;

    if (createIfNonexistent){
        NSFileManager *filemgr = [NSFileManager defaultManager];
        if (![filemgr fileExistsAtPath:dsubDir]){

            // Create the private directory.
            NSError * err;
            NSDictionary * attributes = @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
            if (![filemgr createDirectoryAtPath:dsubDir withIntermediateDirectories:YES attributes:attributes error:&err]){
                // Failed to create directory
                DDLogError(@"Cannot create a docs directory %@, error=%@", dsubDir, err);
                return nil;
            } else {
                DDLogDebug(@"Docs directory created at %@", dsubDir);
            }

            // Backup flag.
            [self trySetBackupFlagFile:dsubDir fileClass:PEX_SECURITY_FILE_CLASS_FILES];
        }
    }

    return dsubDir;
}

+(NSString *) getDefaultCachesDirectory: (NSString *) subDir createIfNonexistent: (BOOL)createIfNonexistent{
    if (subDir != nil && ([PEXStringUtils contains:subDir needle:@"/"] || [PEXStringUtils contains:subDir needle:@".."])){
        [NSException raise:@"SecurityException" format:@"subdir not allowed: %@", subDir];
    }

    NSString *cacheDir = [PEXSystemUtils getDefaultCacheDirectory];
    NSString *csubDir = subDir != nil ? [cacheDir stringByAppendingPathComponent:subDir] : cacheDir;
    csubDir = [PEXUtils ensureDirectoryPath:csubDir];

    if (createIfNonexistent){
        NSFileManager *filemgr = [NSFileManager defaultManager];
        if (![filemgr fileExistsAtPath:csubDir]){

            // Create the private directory.
            NSError * err = nil;
            NSDictionary * attributes = @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
            if (![filemgr createDirectoryAtPath:csubDir withIntermediateDirectories:YES attributes:attributes error:&err]){
                // Failed to create directory
                DDLogError(@"Cannot create a cache directory %@, error=%@", csubDir, err);
                return nil;
            }

            if (err != nil){
                DDLogError(@"Cannot create directory %@, error=%@", csubDir, err);
                return nil;
            }

            // Existence check
            if (![PEXUtils directoryExists:csubDir fmgr:filemgr]){
                DDLogError(@"Directory does not exist after create call, %@", csubDir);
                return nil;
            } else {
                DDLogDebug(@"Cache directory created at %@", csubDir);
            }

            // Backup flag.
            [self trySetBackupFlagFile:csubDir fileClass:PEX_SECURITY_FILE_CLASS_CACHES];
        }
    }

    return csubDir;
}

+ (NSString *)getUsernamePathKey:(NSString *)username {
    // Normalization / Trim
    NSString * trimmedUname = [username stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];

    // Detect domain part, add default if missing.
    NSArray * arr = [trimmedUname componentsSeparatedByString:@"@"];
    NSString * effectiveUname = trimmedUname;
    if (arr==nil || [arr count]!=2){
        // Domain not present, suffix it.
        effectiveUname = [[NSString alloc] initWithFormat:@"%@@phone-x.net", trimmedUname];
    }

    // Hash the username to convert it to a path-friendly format.
    NSString * ukeyBase = [PEXMessageDigest bytes2hex: [PEXMessageDigest sha256Message:effectiveUname]];
    NSString * ukeyPrefix = [ukeyBase substringToIndex:24];

    // Return first 24 characters of the hash.
    return [[NSString alloc] initWithFormat:@"uk_%@", ukeyPrefix];
}

+ (NSUInteger) setDefaultProtectionModeOnAll: (NSString *) rootPath {
    return [self setDefaultProtectionModeOnAll:rootPath
                                matchingPrefix:nil
                                   fileManager:[NSFileManager defaultManager]];
}

+ (NSUInteger) setDefaultProtectionModeOnAll: (NSString *) rootPath matchingPrefix: (NSString *) prefix {
    return [self setDefaultProtectionModeOnAll:rootPath
                                matchingPrefix:prefix
                                   fileManager:[NSFileManager defaultManager]];
}

+ (NSUInteger) setDefaultProtectionModeOnAll: (NSString *) rootPath
                              matchingPrefix: (NSString *) prefix
                                 fileManager: (NSFileManager *) filemgr
{
    if (rootPath == nil || filemgr == nil){
        return 0;
    }

    if (![filemgr fileExistsAtPath:rootPath]){
        return 0;
    }

    // Check the directory itself.
    NSUInteger ctr = 0;
    if ([self setDefaultProtectionMode:rootPath fileManager:filemgr pError:nil]){
        ctr += 1;
    }

    // Enumerate directory contents.
    NSArray* elements = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:NULL];
    if (elements == nil || [elements count] == 0){
        return ctr;
    }

    for(NSString * fname in elements){
        NSString * curPath = [rootPath stringByAppendingPathComponent:fname];
        if (prefix != nil && ![curPath hasPrefix:prefix]){
            continue;
        }

        BOOL isADirectory = NO;
        const BOOL exists = [filemgr fileExistsAtPath:curPath isDirectory:&isADirectory];
        if (!exists){
            DDLogError(@"File should have existed: %@", curPath);
            continue;
        }

        // Recursive call to a directory.
        if (isADirectory) {
            ctr += [self setDefaultProtectionModeOnAll:fname matchingPrefix:prefix fileManager:filemgr];
            continue;
        }

        if ([self setDefaultProtectionMode:curPath fileManager:filemgr pError:nil]){
            ctr += 1;
        }
    }

    return ctr;
}

+ (NSUInteger)setBackupFlagOnAll:(NSString *)rootPath flagBlock: (PEXFileBackupFlagBlock) flagBlock {
    return [self setBackupFlagOnAll:rootPath
                     matchingPrefix:nil
                          flagBlock:flagBlock
                        fileManager:[NSFileManager defaultManager]];
}


+ (NSUInteger)setBackupFlagOnAll:(NSString *)rootPath
                  matchingPrefix:(NSString *)prefix
                       flagBlock:(PEXFileBackupFlagBlock)flagBlock
                     fileManager: (NSFileManager *) filemgr
{
    if (rootPath == nil || filemgr == nil){
        return 0;
    }

    if (![filemgr fileExistsAtPath:rootPath]){
        return 0;
    }

    // Check the directory itself.
    NSUInteger ctr = 0;
    if ([self trySetBackupFlagFile:rootPath backupFlag:flagBlock(rootPath)]){
        ctr += 1;
    }

    // Enumerate directory contents.
    NSArray* elements = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootPath error:NULL];
    if (elements == nil || [elements count] == 0){
        return ctr;
    }

    for(NSString * fname in elements){
        NSString * curPath = [rootPath stringByAppendingPathComponent:fname];
        if (prefix != nil && ![curPath hasPrefix:prefix]){
            continue;
        }

        BOOL isADirectory = NO;
        const BOOL exists = [filemgr fileExistsAtPath:curPath isDirectory:&isADirectory];
        if (!exists){
            DDLogError(@"File should have existed: %@", curPath);
            continue;
        }

        // Recursive call to a directory.
        if (isADirectory) {
            ctr += [self setBackupFlagOnAll:fname matchingPrefix:prefix flagBlock:flagBlock fileManager:filemgr];
            continue;
        }

        if ([self trySetBackupFlagFile:curPath backupFlag:flagBlock(curPath)]){
            ctr += 1;
        }
    }

    return ctr;
}

+ (BOOL) getDefaultBackupFlagForFileClass: (pex_security_file_class) fileClass{
    BOOL backupFlag = NO;
    if (fileClass == PEX_SECURITY_FILE_CLASS_IDENTITY){
        backupFlag = [[PEXUserAppPreferences instance] getDefaultBackupFlagForIdentity];
    } else if (fileClass == PEX_SECURITY_FILE_CLASS_DB){
        backupFlag = [[PEXUserAppPreferences instance] getDefaultBackupFlagForDatabase];
    } else if (fileClass == PEX_SECURITY_FILE_CLASS_FILES) {
        backupFlag = [[PEXUserAppPreferences instance] getDefaultBackupFlagForFiles];
    } else if (fileClass == PEX_SECURITY_FILE_CLASS_CACHES) {
        backupFlag = NO; // caches are pure local thing.
    } else {
        DDLogError(@"File protection class unknown: %d", (int)fileClass);
    }
    return backupFlag;
}

+ (BOOL) setDefaultProtectionMode: (NSString *) file fileClass: (pex_security_file_class) fileClass pError: (NSError **) pError{
    const BOOL protectionOK = [self setDefaultProtectionMode:file fileManager:[NSFileManager defaultManager] pError:pError];

    // Backup flag.
    const BOOL backupFlagOK = [self trySetBackupFlagFile:file fileClass:fileClass];
    return protectionOK && backupFlagOK;
}

+ (BOOL) setDefaultProtectionMode: (NSString *) file pError: (NSError **) pError {
    return [self setDefaultProtectionMode:file fileManager:[NSFileManager defaultManager] pError:pError];
}

+ (BOOL) setDefaultProtectionMode: (NSString *) file fileManager:(NSFileManager *) filemgr pError: (NSError **) pError {
    if (filemgr == nil){
        filemgr = [NSFileManager defaultManager];
    }

    if (![filemgr fileExistsAtPath:file]){
        return YES;
    }

    NSError * attrError = nil;
    NSDictionary * curAttrs = [filemgr attributesOfItemAtPath:file error:&attrError];
    if (attrError != nil || curAttrs == nil){
        DDLogError(@"Could not fetch current file attributes, error: %@", attrError);
        if (pError != NULL){
            *pError = attrError;
        }

        return NO;
    }

    // Current protection level.
    if ([curAttrs[NSFileProtectionKey] isEqual:NSFileProtectionCompleteUntilFirstUserAuthentication]) {
        return YES;
    }

    DDLogInfo(@"Previous protection mode differs: %@ for file %@", curAttrs[NSFileProtectionKey], file);
    NSDictionary * attrs = @{NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication};
    NSError * error = nil;
    const BOOL success = [filemgr setAttributes:attrs ofItemAtPath:file error:&error];
    if (pError != NULL){
        *pError = error;
    }

    if (!success){
        DDLogError(@"Could not set attributes to a file [%@], error: %@", file, error);
    }

    return success;
};

+ (int) isBackupFlagSetFile: (NSString *) filePath {
    return [PEXSecurityCenter isBackupFlagSet:[NSURL fileURLWithPath:filePath]];
}

+ (int) isBackupFlagSet: (NSURL *) fileUrl {
    NSNumber * num = nil;
    NSError * error = nil;

    if  (![fileUrl getResourceValue:&num forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        DDLogError(@"Obtaining backup flag for %@ failed with error: %@", fileUrl, error);
        return -1;
    }

    return ![num boolValue];
}

+ (BOOL) setBackupFlagFile: (NSString *) filePath backupFlag:(BOOL) backupFlag {
    return [PEXSecurityCenter setBackupFlag:[NSURL fileURLWithPath:filePath] backupFlag:backupFlag];
}

+ (BOOL) setBackupFlag: (NSURL *) fileUrl backupFlag:(BOOL) backupFlag {
    NSError *error = nil;
    [fileUrl setResourceValue:@(!backupFlag)
                     forKey: NSURLIsExcludedFromBackupKey
                      error: &error];
    if (error != nil){
        DDLogError(@"BackupFlag error: %@ for file %@", error, fileUrl);
    }

    return error == nil;
}

+ (BOOL) trySetBackupFlagFile: (NSString *) filePath fileClass: (pex_security_file_class) fileClass {
    return [self trySetBackupFlagFile:filePath backupFlag:[self getDefaultBackupFlagForFileClass: fileClass]];
}

+ (BOOL) trySetBackupFlagFile: (NSString *) filePath backupFlag:(BOOL) backupFlag {
    return [self trySetBackupFlag:[NSURL fileURLWithPath:filePath] backupFlag:backupFlag];
}

+ (BOOL) trySetBackupFlag: (NSURL *) fileUrl backupFlag:(BOOL) backupFlag {
    @try {
        int curBackup = [self isBackupFlagSet:fileUrl];
        BOOL success = [self setBackupFlag:fileUrl backupFlag:backupFlag];

        if (success && curBackup != backupFlag){
            DDLogVerbose(@"Backup flag changed[%d] for file %@", backupFlag, fileUrl);
        }

        return success;

    } @catch (NSException * exc){
        DDLogError(@"Exception when setting backup flag to a file: %@, exc: %@", fileUrl, exc);
        return NO;
    }
}

+ (NSData *) readP12File:(NSString *)p12Path {
    // Set default protection mode.
    [PEXSecurityCenter setDefaultProtectionMode:p12Path fileClass:PEX_SECURITY_FILE_CLASS_IDENTITY pError:nil];

    // Read the given file.
    return [NSData dataWithContentsOfFile:p12Path];
}

+ (NSString *)getCAFile:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:NO];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@_CA.pem", ukey]];
}

+ (NSString *)getCertificateFile:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:NO];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@_cert.pem", ukey]];
}

+ (NSString *)getPrivkeyFile:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:NO];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@_priv.pem", ukey]];
}

+ (NSString *)getPKCS12File:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:NO];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@_ks.p12", ukey]];
}

+ (NSString *)getDatabaseFile:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:YES];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@.db", ukey]];
}

+ (NSString *)getZrtpFile:(NSString *)username {
    NSString * privDir = [self getDefaultPrivateDirectory:YES];
    NSString * ukey = [self getUsernamePathKey:username];

    return [privDir stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@_zrtp.bin", ukey]];
}

+ (NSString *)getLogDirGeneral
{
    return [self getLogDir:nil];
}

+ (NSString *)getLogDir:(NSString *)username {
    NSString * ukey = [self getUsernamePathKey:username];
    NSString * subDir = username == nil ? @"logs" : [NSString stringWithFormat: @"logs_%@", ukey];
    return [self getDefaultDocsDirectory:subDir createIfNonexistent: YES];
}

+ (NSString *)getFileTransferCacheDir:(NSString *)username {
    NSString * ukey = [self getUsernamePathKey:username];
    NSString * subDir = username == nil ? @"ftransfer" : [NSString stringWithFormat: @"ftransfer_%@", ukey];
    return [self getDefaultCachesDirectory:subDir createIfNonexistent: YES];
}

+ (NSString *)getFileTransferDocDir {
    return [self getDefaultDocsDirectory:@"transfer" createIfNonexistent: YES];
}

+ (pex_security_file_class) getFileProtectionClass: (NSString *) path {
    if (![path containsString:@"/private/"]){
        return PEX_SECURITY_FILE_CLASS_FILES;
    }

    return [self isFilePathDatabaseRelated:path] ? PEX_SECURITY_FILE_CLASS_DB : PEX_SECURITY_FILE_CLASS_IDENTITY;
}

+ (BOOL) isFilePathDatabaseRelated: (NSString *) path {
    NSString * privDir = [self getDefaultPrivateDirectory:YES];
    NSString * fileName = [path lastPathComponent];
    NSString * extension = [fileName pathExtension];

    // Is the file located in the private directory?
    if (![path hasPrefix:privDir]){
        return NO;
    }

    return [@"db" isEqualToString:extension]
            || [@"db-journal" isEqualToString:extension]
            || [@"db-wal" isEqualToString:extension]
            || [@"db-shm" isEqualToString:extension]
            || [@"-journal" isEqualToString:extension]
            || [@"-wal" isEqualToString:extension]
            || [@"-shm" isEqualToString:extension];
}

@end

static int verifyCbAllowExpiredInterm(int ok, X509_STORE_CTX *ctx){
    return [PEXSecurityCenter verifyCallbackAllowExpiredIntermediate:ok ctx:ctx];
}
