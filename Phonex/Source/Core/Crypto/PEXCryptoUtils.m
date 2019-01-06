//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCryptoUtils.h"
#import "openssl/evp.h"
#import "openssl/sha.h"
#import "openssl/buffer.h"
#import "openssl/rand.h"
#import "openssl/err.h"
#import "openssl/aes.h"
#import "openssl/x509.h"
#import "openssl/pem.h"
#import "openssl/buffer.h"
#import "openssl/hmac.h"
#import "openssl/rsa.h"
#import "PEXPEMParser.h"
#import "PEXMemBIO.h"
#import "PEXEVPPKey.h"
#import "PEXSTKeychain.h"
#import "PEXSecurityCenter.h"
#import "PEXUser.h"
#import "PEXUserPrivate.h"
#import "PEXUtils.h"
#import "PEXAESCipher.h"
#import "PEXMessageDigest.h"
#import "PEXDH.h"
#import "PEXPKCS7.h"


@implementation PEXCryptoUtils {

}

NSString * const PEXCryptoErrorDomain = @"PEXCryptoErrorDomain";
NSInteger const PEXCryptoSignatureError = 1;
NSInteger const PEXCryptoVerificationError = 2;
NSInteger const PEXCryptoRSASetupError = 3;
NSString * const PEXRandomException = @"PEXRandomException";
NSString * const PEXCryptoException = @"PEXCryptoException";

NSString * const PEXDateConversionError = @"PEXDateConversionError";
NSInteger const PEXDateConversionErrorGeneric = 1;

+ (void)initOpenSSL {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Weird stuff - has to add all algorithms to internal table.
        OpenSSL_add_all_algorithms();
    });
}

+ (unsigned char *)secureRandom:(unsigned char *)buffer len:(NSUInteger)len amplifyWithArc: (BOOL) amplifyWithARC {
    // Allocate a new buffer if input one is NULL.
    unsigned char * resultBuf = buffer;
    if (resultBuf==NULL){
        resultBuf = (unsigned char *) malloc(sizeof(unsigned char) * len);
    }

    if (resultBuf==NULL){
        DDLogError(@"secureRandom: Allocation failed");
        return NULL;
    }

    int rc = RAND_pseudo_bytes(resultBuf, len);
    unsigned long err = ERR_get_error();
    if(rc != 0 && rc != 1) {
        DDLogError(@"Randomness error = %lu", err);
        return NULL;
    }

    // Amplify with secure random - iOS recommended way.
    NSMutableData * amplify1 = [NSMutableData dataWithLength:len];
    uint8_t * amplify1Bytes = (uint8_t*)[amplify1 mutableBytes];
    int secRes = SecRandomCopyBytes(kSecRandomDefault, len, amplify1Bytes);
    if (secRes != 0){
        DDLogError(@"Error in generating random data SecRandom");
    } else {
        for(int i=0; i<len; i++){
            resultBuf[i] ^= amplify1Bytes[i];
        }
    }

    // If ARC amplification was selected, allocate extra memory with the same size,
    // generate another random data from ARC and XOR it byte-wise.
    if (amplifyWithARC){
        arc4random_buf(amplify1Bytes, (size_t)len);
        for(int i=0; i<len; i++){
            resultBuf[i] ^= amplify1Bytes[i];
        }
    }

    return resultBuf;
}

+ (NSMutableData *)secureRandomData:(NSMutableData *)buffer len:(NSUInteger)len amplifyWithArc: (BOOL) amplifyWithARC {
    NSMutableData * toReturn = buffer;
    if (toReturn!=nil){
        if ([toReturn length] < len){
            DDLogError(@"Buffer is too small");
            return nil;
        }
    } else {
        toReturn = [NSMutableData dataWithLength:len];
    }

    unsigned char * bytes = (unsigned char *) [toReturn mutableBytes];
    int rc = RAND_pseudo_bytes(bytes, len);
    unsigned long err = ERR_get_error();
    if(rc != 0 && rc != 1) {
        DDLogError(@"Randomness error = %lu", err);
        return nil;
    }

    // Amplify with secure random - iOS recommended way.
    NSMutableData * amplify1 = [NSMutableData dataWithLength:len];
    uint8_t * amplify1Bytes = (uint8_t*)[amplify1 mutableBytes];
    int secRes = SecRandomCopyBytes(kSecRandomDefault, len, amplify1Bytes);
    if (secRes != 0){
        DDLogError(@"Error in generating random data SecRandom");
    } else {
        for(int i=0; i<len; i++){
            bytes[i] ^= amplify1Bytes[i];
        }
    }

    // If ARC amplification was selected, allocate extra memory with the same size,
    // generate another random data from ARC and XOR it byte-wise.
    if (amplifyWithARC){
        arc4random_buf(amplify1Bytes, len);
        for(int i=0; i<len; i++){
            bytes[i] ^= amplify1Bytes[i];
        }
    }

    return toReturn;
}

+ (uint32_t)secureRandomUInt32:(BOOL)amplifyWithARC {
    uint32_t out = 0;

    int rc = RAND_pseudo_bytes((unsigned char *) &out, sizeof(out));
    unsigned long err = ERR_get_error();
    if(rc != 0 && rc != 1) {
        [NSException raise:PEXRandomException format:@"Cannot generate random number, rc=%d, err=%lu", rc, err];
    }

    // Amplify with secure random - iOS recommended way.
    uint32_t out2 = 0;
    int secRes = SecRandomCopyBytes(kSecRandomDefault, sizeof(uint32_t), (uint8_t*) &out2);
    if (secRes != 0){
        DDLogError(@"Error in generating random data SecRandom");
    } else {
        out ^= out2;
    }

    // If ARC amplification was selected, allocate extra memory with the same size,
    // generate another random data from ARC and XOR it byte-wise.
    if (amplifyWithARC){
        uint32_t tmp = 0;
        arc4random_buf(&tmp, sizeof(tmp));
        out ^= tmp;
    }

    return out;
}

+ (uint64_t)secureRandomUInt64:(BOOL)amplifyWithARC {
    uint64_t out = 0;

    int rc = RAND_pseudo_bytes((unsigned char *) &out, sizeof(out));
    unsigned long err = ERR_get_error();
    if(rc != 0 && rc != 1) {
        [NSException raise:PEXRandomException format:@"Cannot generate random number, rc=%d, err=%lu", rc, err];
    }

    // Amplify with secure random - iOS recommended way.
    uint64_t out2 = 0;
    int secRes = SecRandomCopyBytes(kSecRandomDefault, sizeof(uint64_t), (uint8_t*) &out2);
    if (secRes != 0){
        DDLogError(@"Error in generating random data SecRandom");
    } else {
        out ^= out2;
    }

    // If ARC amplification was selected, allocate extra memory with the same size,
    // generate another random data from ARC and XOR it byte-wise.
    if (amplifyWithARC){
        uint64_t tmp = 0;
        arc4random_buf(&tmp, sizeof(tmp));
        out ^= tmp;
    }

    return out;
}

+ (int)pbkdf2:(unsigned char *)out seedUchar:(unsigned char *)seed seedLen:(int)seedLen withPass:(NSString *)pass
        withIterations:(uint)iter withOutLen:(uint)outLen hash:(EVP_MD const *)hash
{
    const char * passBuf = [pass cStringUsingEncoding:NSUTF8StringEncoding];
    return PKCS5_PBKDF2_HMAC(passBuf, (int)[pass length], seed, seedLen, iter, hash, outLen, out);
}

+ (int)pbkdf2:(unsigned char *)out seed:(NSData *)seed withPass:(NSString *)pass withIterations:(uint)iter
   withOutLen:(uint)outLen hash:(EVP_MD const *)hash
{
    const char * passBuf = [pass cStringUsingEncoding:NSUTF8StringEncoding];
    const unsigned char * saltBuf = [seed bytes];
    return PKCS5_PBKDF2_HMAC(passBuf, (int)[pass length], saltBuf, (int)[seed length], iter, hash, outLen, out);
}

+ (NSData *)pbkdf2:(NSData *)seed withPass:(NSString *)pass withIterations:(uint)iter withOutLen:(uint)outLen
              hash:(EVP_MD const *)hash
{
    unsigned char digest[outLen];
    const char * passBuf = [pass cStringUsingEncoding:NSUTF8StringEncoding];
    const unsigned char * saltBuf = [seed bytes];

    if (!PKCS5_PBKDF2_HMAC(passBuf, (int)[pass length], saltBuf, (int)[seed length], iter, hash, outLen, digest)){
        return nil;
    }

    return [NSData dataWithBytes:digest length:outLen];
}

+ (NSData *)pbkdf2:(NSData *)seed withPass:(NSString *)pass withIterations:(uint)iter withOutLen:(uint)outLen
{
    return [self pbkdf2:seed withPass:pass withIterations:iter withOutLen:outLen hash:EVP_sha1()];
}

/**
* Determines if given cipher works in authenticated mode.
* This determination is not complete, only several ciphers are known.
*/
+ (BOOL) isAEADCipher: (EVP_CIPHER const *)cipher {
    return cipher == EVP_aes_256_gcm()
            || cipher == EVP_aes_192_gcm()
            || cipher == EVP_aes_128_gcm()
            || cipher == EVP_aes_128_ccm()
            || cipher == EVP_aes_192_ccm()
            || cipher == EVP_aes_256_ccm();
}

+ (BOOL) isGCMCipher: (EVP_CIPHER const *)cipher {
    return cipher == EVP_aes_256_gcm()
            || cipher == EVP_aes_192_gcm()
            || cipher == EVP_aes_128_gcm();
}

+ (int)encryptRaw:(unsigned char const *)plaintext plen:(int)plaintext_len key:(unsigned char *)key
               iv:(unsigned char const *)iv ciphertext:(unsigned char *)ciphertext cipher:(EVP_CIPHER const *)cipher {
    EVP_CIPHER_CTX *ctx;

    int len=0;
    int ciphertext_len=0;
    BOOL gcm = [self isGCMCipher:cipher];

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new())) {
        return -1;
    }

    /* Initialise the encryption operation. */
    if(1 != EVP_EncryptInit_ex(ctx, cipher, NULL, NULL, NULL)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if(gcm && 1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 16, NULL)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Initialise the encryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits */
    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    ciphertext_len = len;

    /* Finalise the encryption. Further ciphertext bytes may be written at
     * this stage.
     */
    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    ciphertext_len += len;

    // Get TAG from authenticated encryption.
    if (gcm){
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, ciphertext + ciphertext_len)){
            EVP_CIPHER_CTX_free(ctx);
            return -1;
        }

        ciphertext_len += 16;
    }

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

+ (int)decryptRaw:(unsigned char const *)ciphertext clen:(int)ciphertext_len key:(unsigned char *)key
               iv:(unsigned char const *)iv plaintext:(unsigned char *)plaintext cipher:(EVP_CIPHER const *)cipher {
    EVP_CIPHER_CTX *ctx;

    int len=0;
    int plaintext_len=0;
    BOOL gcm = [self isGCMCipher:cipher];
    int real_ciphertext_len = gcm ? ciphertext_len - 16 : ciphertext_len;
    if (real_ciphertext_len < 0){
        DDLogError(@"Real ciphertext seems too small.");
        return -1;
    }

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new())){
        return -1;
    }

    /* Initialise the encryption operation. */
    if(1 != EVP_DecryptInit_ex(ctx, cipher, NULL, NULL, NULL)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if(gcm && 1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 16, NULL)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Initialise the decryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits */
    if(1 != EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if(1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, real_ciphertext_len)){
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    plaintext_len = len;

    if (gcm){
        /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
        if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, ciphertext + real_ciphertext_len)){
            DDLogError(@"GCM TAG set failure");
            EVP_CIPHER_CTX_free(ctx);
            return -1;
        }
    }

    /* Finalise the decryption. Further plaintext bytes may be written at
     * this stage.
     */
    if(1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len)) {
        DDLogError(@"Decryption failure");
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    plaintext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return plaintext_len;
}

+ (NSData *)encryptData:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv cipher:(EVP_CIPHER const *)cipher error:(NSError **)pError {
    // Compute output size.
    NSUInteger const outLen = (([plaintext length] / AES_BLOCK_SIZE) + 5ul) * AES_BLOCK_SIZE;
    NSMutableData * outBuffData = [NSMutableData dataWithLength:outLen];

    // AES
    int encRes = [PEXCryptoUtils encryptRaw:[plaintext bytes] plen:(int)[plaintext length]
                                        key:[key bytes] iv:[iv bytes] ciphertext:[outBuffData mutableBytes] cipher:cipher];
    if (encRes <= 0) {
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain];
        return nil;
    }

    // Ciphertext size.
    [outBuffData setLength:(NSUInteger) encRes];
    return outBuffData;
}

+ (NSData *)decryptData:(NSData *)ciphertext key:(NSData *)key iv:(NSData *)iv cipher:(EVP_CIPHER const *)cipher error:(NSError **)pError {
    // Compute output size.
    NSUInteger const outLen = (([ciphertext length] / AES_BLOCK_SIZE) + 3ul) * AES_BLOCK_SIZE;
    NSMutableData * outBuffData = [NSMutableData dataWithLength:outLen];

    // AES
    int encRes = [PEXCryptoUtils decryptRaw:[ciphertext bytes] clen:[ciphertext length]
                                        key:[key bytes] iv:[iv bytes] plaintext:[outBuffData mutableBytes] cipher:cipher];
    if (encRes <= 0) {
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain];
        return nil;
    }

    // Real plaintext may be shorter due to padding.
    [outBuffData setLength:(NSUInteger) encRes];
    return outBuffData;
}

+ (NSArray *)getDERCertsFromPEM:(NSData *)certsPem {
    if (certsPem==nil){
        return nil;
    }

    // Create & init a new PEM parsing object.
    PEXPEMParser * parser = [[PEXPEMParser alloc] init];
    [parser setProduceDER:YES];

    // Init input parameters.
    const char * src = [certsPem bytes];
    int len = (int)[certsPem length];
    const char * lastChar = src + len - 1;
    uint numCerts = 0;

    NSMutableArray * toReturn = [[NSMutableArray alloc] init];
    for(numCerts=0; src <= lastChar; numCerts++){
        PEXPemChunk * chunk = [parser parsePEM:&src len:&len];
        if (chunk==nil || [chunk success]==NO){
            break;
        }

        // We want only certificate records.
        if ([@"CERTIFICATE" isEqualToString:[[chunk objType] uppercaseString]]==NO){
            continue;
        }

        // Add DER data to the array.
        NSData * der = [chunk der];
        if (der==nil || [der length]==0){
            DDLogWarn(@"getDERCertsFromPEM: Certificate has empty DER.");
            continue;
        }

        [toReturn addObject:der];

        // If there is no more certificate to read, end the parsing.
        if (len<=0){
            break;
        }
    }

    return toReturn;
}

+ (NSArray *)getAnchorsFromDERCerts:(NSArray *)certsDer {
    NSMutableArray * toReturn = [[NSMutableArray alloc] init];
    for (NSData *certDer in certsDer) {
        SecCertificateRef caRef = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef) certDer);
        if (caRef==nil){
            continue;
        }

        [toReturn addObject: (__bridge_transfer id) caRef];
    }

    return toReturn;
}

+ (NSArray *)getAnchorsFromPEMCerts:(NSData *)certsPem {
    NSArray * der = [self getDERCertsFromPEM:certsPem];
    if (der==nil || [der count]==0){
        return nil;
    }

    return [self getAnchorsFromDERCerts:der];
}

+ (NSData *) getDERFromPEM:(NSData *) pem oType: (NSString **) oType {
    if (pem==nil){
        return nil;
    }

    // Create & init a new PEM parsing object.
    PEXPEMParser * parser = [[PEXPEMParser alloc] init];
    [parser setProduceDER:YES];

    // Init input parameters.
    const char * src = [pem bytes];
    int len = (int)[pem length];
    const char * lastChar = src + len - 1;
    uint numCerts = 0;

    for(numCerts=0; src <= lastChar; numCerts++){
        PEXPemChunk * chunk = [parser parsePEM:&src len:&len];
        if (chunk==nil || ![chunk success]){
            break;
        }

        // Add DER data to the array.
        NSData * der = [chunk der];
        if (der==nil || [der length]==0){
            DDLogWarn(@"getDERFromPEM: Invalid DER.");
            continue;
        }

        // If oType is not null, fill it with object type.
        if (oType != NULL){
            *oType = [NSString stringWithString:[chunk objType]];
        }

        return der;
    }

    return nil;
}

+ (NSString *) getPEMFromDER:(NSData *) der oType: (NSString *) oType {
    // Create PEM from DER here.
    NSString * b64 = [der base64EncodedStringWithOptions:0];
    NSUInteger len = [b64 length];
    NSUInteger cRead = 0;

    NSMutableString *pemString = [NSMutableString stringWithFormat:@"-----BEGIN %@-----\n", [oType uppercaseString]];
    for(; cRead < len; ){
        NSUInteger ln = MIN(64, len - cRead);
        [pemString appendFormat:@"%@\n", [b64 substringWithRange:NSMakeRange(cRead, ln)]];
        cRead += ln;
    }

    [pemString appendFormat:@"-----END %@-----\n", [oType uppercaseString]];
    return [NSString stringWithString:pemString];
}

+ (PEXEVPPKey *)getEVPPkeyFromRSA:(RSA *)rsa {
    EVP_PKEY *pk = NULL;
    if ((pk=EVP_PKEY_new()) == NULL) {
        DDLogError(@"exportPrivKeyToPEM: Cannot allocate new PKEY");
        return nil;
    }

    if (!EVP_PKEY_set1_RSA(pk, rsa)) {
        DDLogError(@"exportPrivKeyToPEM: Cannot copy RSA key");
        EVP_PKEY_free(pk);
        return nil;
    }

    return [[PEXEVPPKey alloc] initWith:pk];
}

+ (NSString *)exportEvpKeyToPEM:(EVP_PKEY *)key password:(NSString *)password {
    NSString * pem = nil;
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    if (membio==nil){
        DDLogError(@"exportPrivKeyToPEM: Cannot allocate new BIO memory");
        return nil;
    }

    // Do the export. Warning! initOpenSSL has to be called before this.
    BOOL usePassword = password!=nil;
    if (!usePassword) {
        DDLogWarn(@"Warning: not using a password for private key export");
    }

    char const * const passwd = usePassword ? [password cStringUsingEncoding:NSASCIIStringEncoding] : (char const *) NULL;
    const int passwdLen = usePassword ? (int)[password length] : 0;
    int pemWriteRes = PEM_write_bio_PKCS8PrivateKey([membio getRaw], key, usePassword ? EVP_aes_256_cbc() : (EVP_CIPHER const *) NULL,
            passwd, passwdLen, NULL, NULL);

    // Read PEM from the BIO stream.
    pem = [membio exportAsString];

    if (pemWriteRes!=1){
        DDLogError(@"exportPrivKeyToPEM: Cannot write PEM to the memory, err=%d", pemWriteRes);
        pem = nil;
    }

    membio=nil;
    return pem;
}

+ (NSString *)exportPrivKeyToPEM:(RSA *)key password:(NSString *)password {
    NSString * pem = nil;
    EVP_PKEY *pk = NULL;
    if ((pk=EVP_PKEY_new()) == NULL) {
        DDLogError(@"exportPrivKeyToPEM: Cannot allocate new PKEY");
        return nil;
    }

    if (!EVP_PKEY_set1_RSA(pk, key)) {
        DDLogError(@"exportPrivKeyToPEM: Cannot copy RSA key");
        EVP_PKEY_free(pk);
        return nil;
    }

    pem = [self exportEvpKeyToPEM:pk password:password];

    // Free memory for pkey.
    EVP_PKEY_free(pk);

    return pem;
}

+ (NSString *)exportPubKeyToPEM:(RSA *)key {
    // Write CSR to the PEM to memory BIO.
    NSString *pem=nil;
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    if (membio==nil){
        DDLogError(@"exportPubKeyToPEM: Cannot allocate new BIO memory");
        return nil;
    }

    int pemWriteRes = PEM_write_bio_RSAPublicKey([membio getRaw], key);
    if (pemWriteRes!=1){
        DDLogError(@"Cannot write PEM to the memory");
    }

    // Read PEM from the BIO stream.

    pem = [membio exportAsString];
    membio=nil;
    return pem;
}

+ (NSString *)exportCertificateToPEM:(X509 *)cert {
    // Write CSR to the PEM to memory BIO.
    NSString *pem=nil;
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    if (membio==nil){
        DDLogError(@"exportCertificateToPEM: Cannot allocate new BIO memory");
        return nil;
    }

    int pemWriteRes = PEM_write_bio_X509([membio getRaw], cert);
    if (pemWriteRes!=1){
        DDLogError(@"Cannot write PEM to the memory");
    }

    // Read PEM from the BIO stream.

    pem = [membio exportAsString];
    membio=nil;
    return pem;
}

+ (NSData *)exportCertificateToDER:(X509 *)cert {
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    if (membio==nil){
        DDLogError(@"exportCertificateToDER: Cannot allocate new BIO memory");
        return nil;
    }

    int success = i2d_X509_bio(membio.getRaw, cert);
    if (!success){
        DDLogError(@"exportCertificateToDER: Cannot export a certificate");
        return nil;
    }

    NSData * toReturn = membio.export;
    return toReturn;
}

+ (NSString *)exportCSRToPEM:(X509_REQ *)csr {
    NSString *pem=nil;
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    if (membio==nil){
        DDLogError(@"exportCertificateToPEM: Cannot allocate new BIO memory");
        return nil;
    }

    int pemWriteRes = PEM_write_bio_X509_REQ([membio getRaw], csr);
    if (pemWriteRes!=1){
        DDLogError(@"Cannot write PEM to the memory");
    }

    // Read PEM from the BIO stream.

    pem = [membio exportAsString];
    membio=nil;
    return pem;
}

+(RSA *) importPrivKeyFromPEM: (RSA **) key pem: (NSData *) pem password: (NSString *) password {
    if (pem==nil){
        DDLogError(@"NSData is nil");
        return nil;
    }

    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:pem];
    EVP_PKEY *pk = PEM_read_bio_PrivateKey([membio getRaw], NULL, NULL,
            password==nil ? NULL: (void *) [password cStringUsingEncoding:NSASCIIStringEncoding]);
    membio = nil;

    // Try to import to RSA.
    RSA * toReturn = NULL;
    if (pk!=NULL){
        toReturn = [self pkey_get_rsa:pk rsa:key];
    }

    return toReturn;
}

+ (RSA *)importPubKeyFromPEM:(RSA **)key pem:(NSData *)pem {
    if (pem==nil){
        DDLogError(@"NSData is nil");
        return nil;
    }

    // If key is non-null, use provided structure. Initialize a new one otherwise.
    RSA * keyToUse=NULL;
    RSA ** ppKeyToUse = &keyToUse;
    if (key!=NULL){
        keyToUse = *key;
        ppKeyToUse = key;
    } else {
        keyToUse = RSA_new();
    }

    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:pem];
    RSA * toReturn = PEM_read_bio_RSAPublicKey([membio getRaw], ppKeyToUse, NULL, NULL);
    membio = nil;

    return toReturn;
}

+ (X509 *)importCertificateFromPEM:(X509 **)cert pem:(NSData *)pem {
    if (pem==nil){
        DDLogError(@"NSData is nil");
        return nil;
    }

    // If key is non-null, use provided structure. Initialize a new one otherwise.
    X509 * certToUse=NULL;
    X509 ** ppCertToUse = &certToUse;
    if (cert!=NULL){
        certToUse = *cert;
        ppCertToUse = cert;
    } else {
        certToUse = X509_new();
    }

    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:pem];
    X509 * toReturn = PEM_read_bio_X509([membio getRaw], ppCertToUse, NULL, NULL);
    membio = nil;

    return toReturn;
}

+ (X509 *)importCertificateFromDER:(NSData *)der {
    unsigned char const * derPtr = [der bytes];
    return d2i_X509(NULL, &derPtr, (long)[der length]);
}

+ (PKCS12 *)importPKCS12FromFile:(NSData *)der {
    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:der];
    PKCS12 * toReturn = d2i_PKCS12_bio([membio getRaw], NULL);
    membio = NULL;

    return toReturn;
}

+ (PKCS7 *)importPKCS7FromFile:(NSData *)der {
    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:der];
    PKCS7 * toReturn = d2i_PKCS7_bio([membio getRaw], NULL);
    membio = NULL;

    return toReturn;
}

+ (RSA *) pkey_get_rsa: (EVP_PKEY *) key rsa: (RSA **) rsa
{
    RSA *rtmp;
    if(!key) return NULL;
    rtmp = EVP_PKEY_get1_RSA(key);
    EVP_PKEY_free(key);
    if(!rtmp) return NULL;
    if(rsa) {
        RSA_free(*rsa);
        *rsa = rtmp;
    }
    return rtmp;
}

+ (NSString *)exportPrivKeyToPEMWrap:(PEXRSA *)key password:(NSString *)password {
    return [self exportPrivKeyToPEM: key == nil ? nil : key.getRaw password:password];
}

+ (NSString *)exportEvpKeyToPEMWrap:(PEXEVPPKey *)key password:(NSString *)password {
    return [self exportEvpKeyToPEM: key == nil ? nil : key.getRaw password:password];
}

+ (NSString *)exportPubKeyToPEMWrap:(PEXRSA *)key {
    return [self exportPubKeyToPEM: key == nil ? nil : key.getRaw];
}

+ (NSString *)exportCertificateToPEMWrap:(PEXX509 *)cert {
    return [self exportCertificateToPEM: cert == nil ? nil : cert.getRaw];
}

+ (NSData *)exportCertificateToDERWrap:(PEXX509 *)cert {
    return [self exportCertificateToDER: cert == nil ? nil : cert.getRaw];
}

+ (NSString *)exportCSRToPEMWrap:(PEXX509Req *)csr {
    return [self exportCSRToPEM: csr == nil ? nil : csr.getRaw];
}

+ (PEXRSA *)importPrivKeyFromPEMWrap:(NSData *)pem password:(NSString *)password {
    return [[PEXRSA alloc] initWith:[self importPrivKeyFromPEM:NULL pem:pem password:password]];
}

+ (PEXRSA *)importPubKeyFromPEMWrap:(NSData *)pem {
    return [[PEXRSA alloc] initWith:[self importPubKeyFromPEM:NULL pem:pem]];
}

+ (PEXX509 *)importCertificateFromDERWrap:(NSData *)der {
    return [[PEXX509 alloc] initWith:[self importCertificateFromDER:der]];
}

+ (PEXX509 *)importCertificateFromPEMWrap:(NSData *)pem {
    return [[PEXX509 alloc] initWith:[self importCertificateFromPEM:NULL pem:pem]];
}

+ (PEXPKCS12 *)importPKCS12FromFileWrap:(NSData *)der {
    return [[PEXPKCS12 alloc] initWith:[self importPKCS12FromFile:der]];
}

+ (PEXPKCS7 *)importPKCS7FromFileWrap:(NSData *)der {
    return [[PEXPKCS7 alloc] initWith:[self importPKCS7FromFile:der]];
}

+ (BOOL)isPubKeyEqual:(X509 *)cert csr:(X509_REQ *)req {
    if (cert==NULL || req==NULL) {
        DDLogWarn(@"isPubKeyEqual: null");
        return NO;
    }

    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey(cert)];
    if (cKey==NULL || ![cKey isAllocated]){
        DDLogWarn(@"isPubKeyEqual: x509 missing");
        return NO;
    }

    PEXEVPPKey * rKey = [[PEXEVPPKey alloc] initWith: X509_REQ_get_pubkey(req)];
    if (rKey==NULL || ![rKey isAllocated]){
        DDLogWarn(@"isPubKeyEqual: csr missing");
        return NO;
    }

    // Compare keys.
    EVP_PKEY * c = [cKey getRaw];
    EVP_PKEY * r = [rKey getRaw];
    int cmpRes = EVP_PKEY_cmp(c, r);
    c=NULL;
    r=NULL;
    cKey=nil;
    rKey=nil;

    return cmpRes == 1;
}

+ (BOOL)isCNameEqual:(X509 *)cert csr:(X509_REQ *)req {
    if (cert==NULL || req==NULL) {
        return NO;
    }

    int totalC=0;
    int totalR=0;

    NSString * c = [self getCNameCrt:cert totalCount:&totalC];
    NSString * r = [self getCNameReq:req  totalCount:&totalR];
    if (totalC!=totalR || totalC!=1 || totalR!=1){
        return NO;
    }

    if (c==nil || r==nil){
        return NO;
    }

    return [c isEqualToString:r];
}

+ (NSString *)getCName:(X509_NAME *)name totalCount: (int*) totalCount {
    int total=0;
    int lastpos=0;
    NSString * toUse = nil;
    for (;toUse==nil; total++)
    {
        lastpos = X509_NAME_get_index_by_NID(name, NID_commonName, lastpos);
        if (lastpos == -1) {
            break;
        }

        X509_NAME_ENTRY * e = X509_NAME_get_entry(name, lastpos);
        if (e==NULL){
            continue;
        }

        ASN1_STRING * st = X509_NAME_ENTRY_get_data(e);
        toUse = [[NSString alloc] initWithBytes:st->data length:st->length encoding:NSUTF8StringEncoding];
    }

    // Set total count if not null.
    if (totalCount!=NULL){
        *totalCount = total;
    }

    return toUse;
}

+ (NSString *)getCNameCrt:(X509 *)cert totalCount:(int *)totalCount {
    if (cert==NULL){
        return nil;
    }

    X509_NAME * name = X509_get_subject_name(cert);
    if (name==NULL){
        return nil;
    }

    return [self getCName:name totalCount:totalCount];
}

+ (NSString *)getCNameReq:(X509_REQ *)cert totalCount: (int*) totalCount {
    if (cert==NULL){
        return nil;
    }

    X509_NAME * name = X509_REQ_get_subject_name(cert);
    if (name==NULL){
        return nil;
    }

    return [self getCName:name totalCount:totalCount];
}

+(time_t) getTimeFromASN1:(const ASN1_TIME *) aTime error: (NSError **) pError {
    time_t lResult = 0;

    char lBuffer[24];
    char * pBuffer = lBuffer;

    size_t lTimeLength = aTime->length;
    char * pString = (char *)aTime->data;

    if (aTime->type == V_ASN1_UTCTIME)
    {
        if ((lTimeLength < 11) || (lTimeLength > 17))
        {
            [PEXUtils setError:pError domain:PEXDateConversionError code:PEXDateConversionErrorGeneric];
            return 0;
        }

        memcpy(pBuffer, pString, 10);
        pBuffer += 10;
        pString += 10;
    }
    else
    {
        if (lTimeLength < 13)
        {
            [PEXUtils setError:pError domain:PEXDateConversionError code:PEXDateConversionErrorGeneric];
            return 0;
        }

        memcpy(pBuffer, pString, 12);
        pBuffer += 12;
        pString += 12;
    }

    if ((*pString == 'Z') || (*pString == '-') || (*pString == '+'))
    {
        *(pBuffer++) = '0';
        *(pBuffer++) = '0';
    }
    else
    {
        *(pBuffer++) = *(pString++);
        *(pBuffer++) = *(pString++);
        // Skip any fractional seconds...
        if (*pString == '.')
        {
            pString++;
            while ((*pString >= '0') && (*pString <= '9'))
            {
                pString++;
            }
        }
    }

    *(pBuffer++) = 'Z';
    *(pBuffer++) = '\0';

    time_t lSecondsFromUCT;
    if (*pString == 'Z')
    {
        lSecondsFromUCT = 0;
    }
    else
    {
        if ((*pString != '+') && (pString[5] != '-'))
        {
            [PEXUtils setError:pError domain:PEXDateConversionError code:PEXDateConversionErrorGeneric];
            return 0;
        }

        lSecondsFromUCT = ((pString[1]-'0') * 10 + (pString[2]-'0')) * 60;
        lSecondsFromUCT += (pString[3]-'0') * 10 + (pString[4]-'0');
        if (*pString == '-')
        {
            lSecondsFromUCT = -lSecondsFromUCT;
        }
    }

    struct tm lTime;
    lTime.tm_sec  = ((lBuffer[10] - '0') * 10) + (lBuffer[11] - '0');
    lTime.tm_min  = ((lBuffer[8] - '0') * 10) + (lBuffer[9] - '0');
    lTime.tm_hour = ((lBuffer[6] - '0') * 10) + (lBuffer[7] - '0');
    lTime.tm_mday = ((lBuffer[4] - '0') * 10) + (lBuffer[5] - '0');
    lTime.tm_mon  = (((lBuffer[2] - '0') * 10) + (lBuffer[3] - '0')) - 1;
    lTime.tm_year = ((lBuffer[0] - '0') * 10) + (lBuffer[1] - '0');
    if (lTime.tm_year < 50)
    {
        lTime.tm_year += 100; // RFC 2459
    }
    lTime.tm_wday = 0;
    lTime.tm_yday = 0;
    lTime.tm_isdst = 0;  // No DST adjustment requested
    lTime.tm_gmtoff = 0l;

    lResult = mktime(&lTime);
    if ((time_t)-1 != lResult)
    {
        if (0 != lTime.tm_isdst)
        {
            lResult -= 3600;  // mktime may adjust for DST  (OS dependent)
        }

        if (lSecondsFromUCT != 0) {
            lResult += lSecondsFromUCT;
        } else if (lTime.tm_gmtoff != 0) {
            lResult += lTime.tm_gmtoff;
        }
    }
    else
    {
        DDLogError(@"mktime failed");
        [PEXUtils setError:pError domain:PEXDateConversionError code:PEXDateConversionErrorGeneric];
        lResult = 0;
    }

    return lResult;
}

+ (NSDate *)getNotBefore:(X509 *)cert {
    if (cert == nil){
        DDLogError(@"Certificate is nil");
        return nil;
    }

    ASN1_TIME * notBefore = X509_get_notBefore(cert);
    if (notBefore == NULL){
        DDLogError(@"Certificate has null notBefore date.");
        return nil;
    }

    NSError * error = nil;
    time_t res = [self getTimeFromASN1:notBefore error:&error];
    if (error != nil){
        DDLogError(@"Cannot extract notBefore from X509 certificate.");
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970: (double) res];
}

+ (NSDate *)getNotAfter:(X509 *)cert {
    if (cert == nil){
        DDLogError(@"Certificate is nil");
        return nil;
    }

    ASN1_TIME *notAfter = X509_get_notAfter(cert);
    if (notAfter == NULL){
        DDLogError(@"Certificate has null notAfter date.");
        return nil;
    }

    NSError * error = nil;
    time_t res = [self getTimeFromASN1:notAfter error:&error];
    if (error != nil){
        DDLogError(@"Cannot extract notAfter from X509 certificate.");
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970: (double) res];
}

+ (PKCS12 *)createDefaultKeystore:(NSString *)username pkcsPasswd:(NSString *)pkcsPasswd cert:(X509 *)cert
                        certChain:(NSPointerArray *)certChain evpPrivKey:(EVP_PKEY *)evpPrivKey {
    // Convert name using path keying.
    NSString * ukey = [PEXSecurityCenter getUsernamePathKey:username];
    const char * pass = [pkcsPasswd cStringUsingEncoding:NSUTF8StringEncoding];
    const char * name = [ukey cStringUsingEncoding:NSUTF8StringEncoding];

    // CA root certificates.
    STACK_OF(X509) *cacertstack = NULL;
    if (certChain!=nil && [certChain count]>0) {
        if ((cacertstack = sk_X509_new_null()) == NULL) {
            DDLogError(@"Error creating STACK_OF(X509) structure.");
        }

        // Iterate over cert chain and add each to the stack.
        NSUInteger count = [certChain count];
        for(NSUInteger i=0; i<count; i++) {
            const X509 * const cur = (X509 *) [certChain pointerAtIndex:i];
            sk_X509_push(cacertstack, cur);
        }
    }

    // Main call - create PKCS12 container.
    PKCS12 * p12 = PKCS12_create(
            pass,        // certbundle access password
            name,        // friendly certname
            evpPrivKey,  // the certificate private key
            cert,        // the main certificate
            cacertstack, // stack of CA cert chain
            0,           // int nid_key (default 3DES)
            0,           // int nid_cert (40bitRC2)
            2048,        // int iter (default 2048)
            64,          // int mac_iter (default 1)
            0            // int keytype (default no flag)
    );

    // Free CA roots.
    if (cacertstack!=NULL){
        sk_X509_free(cacertstack);
        cacertstack=NULL;
    }

    return p12;
}

+ (PKCS12 *)createDefaultKeystore:(NSString *)username pkcsPasswd:(NSString *)pkcsPasswd cert:(X509 *)cert
                        certChain:(NSPointerArray *)certChain privKey:(RSA *)privKey {

    // Create EVP_KEY.
    EVP_PKEY * pkey = EVP_PKEY_new();
    EVP_PKEY_set1_RSA(pkey, privKey);

    PKCS12 * p12 = [self createDefaultKeystore:username pkcsPasswd:pkcsPasswd cert:cert certChain:certChain evpPrivKey:pkey];

    // Free EVP.
    if (pkey!=NULL){
        EVP_PKEY_free(pkey);
        pkey=NULL;
    }

    return p12;
}

+ (PKCS12 *) createDefaultKeystore: (PEXUserPrivate *) privData {
    NSPointerArray * pArr = nil;
    if (privData.cacerts!=nil && privData.cacerts.count > 0){
        pArr = [[NSPointerArray alloc] init];
        for(PEXX509 * curCrt in privData.cacerts){
            X509 * curX509 = curCrt.getRaw;
            if (curX509==NULL){
                continue;
            }

            [pArr addPointer:curX509];
        }

        if (pArr.count==0){
            pArr = nil;
        }
    }

    return [self createDefaultKeystore:privData.username
                            pkcsPasswd:privData.pkcsPass
                                  cert:privData.cert.getRaw
                             certChain:pArr
                            evpPrivKey:privData.privKey.getRaw];
}

+ (NSData *)exportPKCS12:(PKCS12 *)pkcs12 {
    PEXMemBIO * membio = [[PEXMemBIO alloc] init];
    int res = i2d_PKCS12_bio([membio getRaw], pkcs12);
    if (res <= 0){
        DDLogWarn(@"PKCS12 export failed, res=%d", res);
        return nil;
    }

    NSData * data = [membio export];
    membio = nil;
    return data;
}

+ (OSStatus)extractIdentity:(NSData *)inP12Data identity:(SecIdentityRef *)identity p12Passwd: (NSString *)p12Passwd {
    OSStatus securityError = errSecSuccess;

    CFStringRef password = (__bridge CFStringRef) p12Passwd;
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };

    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import((__bridge CFDataRef) inP12Data, options, &items);

    if (securityError == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
        DDLogVerbose(@"Identity successfully extracted = %p", tempIdentity);
    }

    if (options) {
        CFRelease(options);
    }

    return securityError;
}

+ (void)clearCertIdentity:(PEXUserPrivate *)privateData {
    privateData.identity = nil;
    privateData.privKey = nil;
    privateData.cert = nil;
}

+ (int)extractIdentity:(NSData *)inP12Data privData:(PEXUserPrivate *)privateData p12Passwd:(NSString *)p12Passwd {
    if (privateData==NULL){
        [NSException raise:@"IllegalArgumentException" format:@"Private data is null"];
    }

    // PKCS12 load.
    SecIdentityRef identity;
    OSStatus status = [self extractIdentity:inP12Data identity:&identity p12Passwd:p12Passwd];
    if (status != errSecSuccess){
        DDLogError(@"PKCS12 file malfomed, cannot import. Status=%d", (int) status);
        return -3;
    }

    [privateData setIdentity:identity];

    // RSA & X509 load.
    PKCS12 * p12 = [self importPKCS12FromFile:inP12Data];
    if (p12==NULL) {
        DDLogError(@"Could not parse PKCS12 file");
        return -1;
    }

    // Verify PKCS12 MAC.
    int macVerif = PKCS12_verify_mac(p12, [p12Passwd cStringUsingEncoding:NSUTF8StringEncoding], (int)[p12Passwd length]);
    if (!macVerif){
        DDLogError(@"PKCS12 - Mac verification failed");
        return -2;
    }

    EVP_PKEY * pkey = NULL;
    X509 * cert = NULL;
    STACK_OF(X509) * cacertstack = NULL;

    int parseRes = PKCS12_parse(p12, [p12Passwd cStringUsingEncoding:NSUTF8StringEncoding],
            &pkey, &cert, &cacertstack);

    if (!parseRes){
        DDLogError(@"PKCS12 parsing error");
        return -4;
    }

    // Read parsed data to identity record.
    PEXEVPPKey * evpKey = [[PEXEVPPKey alloc] initWith:pkey];
    [privateData setPrivKey: evpKey];

    PEXX509 * x509 = [[PEXX509 alloc] initWith:cert];
    [privateData setCert:x509];

    // Read cert chain stack, convert to
    NSArray * caArr = [self convertX509StackToArray:cacertstack error:nil];
    [privateData setCacerts:caArr];
    if (cacertstack!=NULL) {
        sk_X509_free(cacertstack);
    }

    return 1;
}

+ (NSArray *)convertX509StackToArray:(STACK_OF(X509) *)ca error:(NSError *)error {
    if (ca==NULL){
        return [[NSArray alloc] init];
    }

    int stackLen = sk_X509_num(ca);
    NSMutableArray * mArr = [[NSMutableArray alloc] initWithCapacity:stackLen];

    for(int i=0; i<stackLen; i++){
        X509 * curCert = sk_X509_value(ca, i);
        if (curCert==NULL){
            DDLogWarn(@"Warning, certificate is null in cert stack");
            continue;
        }

        PEXX509 * pCert = [[PEXX509 alloc] initWith:curCert];
        [mArr addObject:pCert];
    }

    return mArr;
}

+ (NSData *)sign:(NSData *)dataToSign key:(PEXPrivateKey *)key error:(NSError **)error {
    NSData * dataToSignHashed = [PEXMessageDigest sha256:dataToSign];
    return [self signHash:dataToSignHashed key:key error:error];
}

+ (NSData *)signHash:(NSData *)dataToSignHashed key:(PEXPrivateKey *)key error:(NSError **)error {
    EVP_PKEY_CTX * ctx;
    unsigned char * sig;
    unsigned char const * md = [dataToSignHashed bytes];
    size_t mdlen = [dataToSignHashed length];
    size_t siglen = 0;

    if (key == nil || key.key == nil || !key.key.isAllocated){
        DDLogWarn(@"Cannot generate signature, null key");
        return nil;
    }

    EVP_PKEY *signing_key = [key.key getRaw];

    /*
     * NB: assumes signing_key and md are set up before the next
     * step. signing_key must be an RSA private key and md must
     * point to the SHA-256 digest to be signed.
     */
    ctx = EVP_PKEY_CTX_new(signing_key, NULL /* no engine */);
    if (!ctx) {
        DDLogWarn(@"Cannot initialize signature context");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:1];
        return nil;
    }

    if (EVP_PKEY_sign_init(ctx) <= 0) {
        DDLogWarn(@"Cannot initialize signature engine");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:2];
        return nil;
    }

    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_PADDING) <= 0) {
        DDLogWarn(@"Cannot set signature padding");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:3];
        return nil;
    }

    if (EVP_PKEY_CTX_set_signature_md(ctx, EVP_sha256()) <= 0) {
        DDLogWarn(@"Cannot set signature digest function");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:4];
        return nil;
    }

    /* Determine buffer length */
    if (EVP_PKEY_sign(ctx, NULL, &siglen, md, mdlen) <= 0) {
        DDLogWarn(@"Cannot determine buffer length");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:5];
        return nil;
    }

    sig = OPENSSL_malloc(siglen);
    if (!sig) {
        DDLogWarn(@"Cannot allocate signature buffer");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:6];
        return nil;
    }

    if (EVP_PKEY_sign(ctx, sig, &siglen, md, mdlen) <= 0) {
        DDLogWarn(@"Cannot sign input buffer");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoSignatureError subCode:7];
        return nil;
    }

    /* Signature is siglen bytes written to buffer sig */
    NSData * sigOut = [NSData dataWithBytes:sig length:siglen];
    OPENSSL_free(sig);

    return sigOut;
}

+ (BOOL)verify:(NSData *)dataToVerify signature:(NSData *)signature pubKey:(PEXEVPPKey *)cKey error:(NSError **)error {
    NSData * dataToVerifyHashed = [PEXMessageDigest sha256:dataToVerify];
    return [self verifyHash:dataToVerifyHashed signature:signature pubKey:cKey error:error];
}

+ (BOOL)verifyHash:(NSData *)dataToVerifyHashed signature:(NSData *)signature pubKey:(PEXEVPPKey *)cKey error:(NSError **)error {
    EVP_PKEY_CTX * ctx;
    unsigned char const * md = (unsigned char const *) [dataToVerifyHashed bytes];
    unsigned char const * sig = (unsigned char const *) [signature bytes];
    size_t mdlen = [dataToVerifyHashed length];
    size_t siglen = [signature length];

    if (cKey == nil || ![cKey isAllocated]){
        DDLogWarn(@"cannot extract public key");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoVerificationError subCode:1];
        return NO;
    }

    EVP_PKEY * verify_key = cKey.getRaw;

    /* NB: assumes verify_key, sig, siglen md and mdlen are already set up
     * and that verify_key is an RSA public key
     */
    ctx = EVP_PKEY_CTX_new(verify_key, NULL);
    if (!ctx){
        DDLogWarn(@"Cannot initialize pkey context");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoVerificationError subCode:2];
        return NO;
    }

    if (EVP_PKEY_verify_init(ctx) <= 0){
        DDLogWarn(@"Cannot initialize pkey context");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoVerificationError subCode:3];
        return NO;
    }

    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_PADDING) <= 0){
        DDLogWarn(@"Cannot set padding");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoVerificationError subCode:4];
        return NO;
    }

    if (EVP_PKEY_CTX_set_signature_md(ctx, EVP_sha256()) <= 0){
        DDLogWarn(@"Cannot set digest function");
        [PEXUtils setError:error domain:PEXCryptoErrorDomain code:PEXCryptoVerificationError subCode:5];
        return NO;
    }

    int ret = EVP_PKEY_verify(ctx, sig, siglen, md, mdlen);
    return ret == 1;
}

+ (BOOL)verify:(NSData *)dataToVerify signature:(NSData *)signature certificate:(PEXCertificate *)certificate error:(NSError **)error {
    if (certificate == nil || certificate.cert == nil || !certificate.cert.isAllocated){
        DDLogWarn(@"Cannot verify signature, empty certificate.");
        return NO;
    }

    X509 * crt = certificate.cert.getRaw;
    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey(crt)];
    return [self verify:dataToVerify signature:signature pubKey:cKey error:error];
}

+ (NSData *)hmac:(NSData *)payload key:(NSData *)key {
    unsigned int mdlen = SHA256_DIGEST_LENGTH;
    NSMutableData * outBuf = [NSMutableData dataWithLength:mdlen];

    // Generate MAC.
    HMAC(EVP_sha256(), [key bytes], (int) [key length], [payload bytes], [payload length], [outBuf mutableBytes], &mdlen);
    return outBuf;
}

+ (NSData *)asymEncrypt:(NSData *)plaintext crt:(PEXX509 *)crt error:(NSError **)pError {
    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey([crt getRaw])];
    if (cKey==NULL || ![cKey isAllocated]){
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:10];
        return nil;
    }

    return [self asymEncrypt:plaintext key:cKey error:pError];
}

+ (NSData *)asymEncrypt:(NSData *)plaintext key:(PEXEVPPKey *)key error:(NSError **)pError {
    EVP_PKEY_CTX * ctx;
    unsigned char * in = [plaintext bytes];
    size_t outlen = 0;
    size_t inlen = [plaintext length];

    if ([plaintext length] > 256){
        DDLogError(@"Plaintext too long, can encrypt only one block");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:-1];
        return nil;
    }

    ctx = EVP_PKEY_CTX_new([key getRaw], NULL);
    if (!ctx) {
        DDLogWarn(@"Cannot initialize RSA context");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:1];
        return nil;
    }

    if (EVP_PKEY_encrypt_init(ctx) <= 0){
        DDLogWarn(@"Cannot initialize setup encryption");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:2];
        return nil;
    }

    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0){
        DDLogWarn(@"Cannot set padding, error=%ld", ERR_get_error());
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:3];
        return nil;
    }

    /* Determine buffer length */
    if (EVP_PKEY_encrypt(ctx, NULL, &outlen, in, inlen) <= 0){
        DDLogWarn(@"Cannot determine output length");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:4];
        return nil;
    }

    NSMutableData * outBuff = [NSMutableData dataWithLength:outlen];
    if (EVP_PKEY_encrypt(ctx, [outBuff mutableBytes], &outlen, in, inlen) <= 0) {
        DDLogWarn(@"Encryption error, code=%ld, len=%zu, inlen=%zu", ERR_get_error(), outlen, inlen);
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:5];
        return nil;
    }

    return outBuff;
}

+ (NSData *)asymDecrypt:(NSData *)ciphertext key:(PEXEVPPKey *)key error:(NSError **)pError {
    EVP_PKEY_CTX * ctx;
    unsigned char * in = [ciphertext bytes];
    size_t outlen = 0;
    size_t inlen = [ciphertext length];

    if ([ciphertext length] > 256){
        DDLogError(@"Ciphertext too long, can decrypt only one block");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:-1];
        return nil;
    }

    ctx = EVP_PKEY_CTX_new([key getRaw], NULL);
    if (!ctx) {
        DDLogWarn(@"Cannot initialize RSA context");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:1];
        return nil;
    }

    if (EVP_PKEY_decrypt_init(ctx) <= 0){
        DDLogWarn(@"Cannot initialize setup decryption");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:2];
        return nil;
    }

    if (EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_PKCS1_OAEP_PADDING) <= 0){
        DDLogWarn(@"Cannot set padding");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:3];
        return nil;
    }

    /* Determine buffer length */
    if (EVP_PKEY_decrypt(ctx, NULL, &outlen, in, inlen) <= 0){
        DDLogWarn(@"Cannot determine output length");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:4];
        return nil;
    }

    NSMutableData * outBuff = [NSMutableData dataWithLength:outlen];
    if (EVP_PKEY_decrypt(ctx, [outBuff mutableBytes], &outlen, in, inlen) <= 0) {
        DDLogWarn(@"Decryption error");
        [PEXUtils setError:pError domain:PEXCryptoErrorDomain code:PEXCryptoRSASetupError subCode:5];
        return nil;
    }

    NSRange range = {0, outlen};
    return [outBuff subdataWithRange: range];
}

+ (NSString *) getDeviceID {
    NSString *udidString;
    udidString = [self objectForKey:@"deviceID"];
    if(!udidString)
    {
        CFUUIDRef cfuuid = CFUUIDCreate(kCFAllocatorDefault);
        udidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, cfuuid));
        CFRelease(cfuuid);
        [self setObject:udidString forKey:@"deviceID"];
    }
    return udidString;
}

+(void) setObject:(NSString*) object forKey:(NSString*) key
{
    NSString *objectString = object;
    NSError *error = nil;
    [PEXSTKeychain storeUsername:key
                     andPassword:objectString
                  forServiceName:@"LIB"
                  updateExisting:YES
                           error:&error];

    if(error) {
        DDLogVerbose(@"%@", [error localizedDescription]);
    }
}

+(NSString*) objectForKey:(NSString*) key
{
    NSError *error = nil;
    NSString *object = [PEXSTKeychain getPasswordForUsername:key
                                              andServiceName:@"LIB"
                                                       error:&error];
    if(error) {
        DDLogVerbose(@"%@", [error localizedDescription]);
    }

    return object;
}

+ (DH *) pkey_get_dh: (EVP_PKEY *) key dh: (DH **) dh
{
    DH *rtmp;
    if(!key) return NULL;
    rtmp = EVP_PKEY_get1_DH(key);
    EVP_PKEY_free(key);
    if(!rtmp) return NULL;
    if(dh) {
        DH_free(*dh);
        *dh = rtmp;
    }
    return rtmp;
}

+ (DH *)importDHParamsFromPEM:(DH **)dh pem:(NSData *)pem {
    if (pem == nil){
        DDLogError(@"NSData is nil");
        return nil;
    }

    // If key is non-null, use provided structure. Initialize a new one otherwise.
    int rc, codes = 0;
    DH * dhToUse=NULL;
    DH ** ppDhToUse = &dhToUse;
    if (dh != NULL){
        dhToUse = *dh;
        ppDhToUse = dh;
    } else {
        dhToUse = DH_new();
    }

    PEXMemBIO * membio = [[PEXMemBIO alloc] initWithNSData:pem];
    DH * toReturn = PEM_read_bio_DHparams([membio getRaw], ppDhToUse, NULL, NULL);
    membio = nil;

    // DH check.
    rc = DH_check(toReturn, &codes);
    if (rc != 1)
        [NSException raise:PEXCryptoException format:@"DH check failed"];

    if(BN_is_word(toReturn->g, DH_GENERATOR_2)) {
        unsigned int residue = BN_mod_word(toReturn->p, 24);
        if(residue == 11 || residue == 23) {
            codes &= ~DH_NOT_SUITABLE_GENERATOR;
        }
    }

    if (codes & DH_UNABLE_TO_CHECK_GENERATOR)
        [NSException raise:PEXCryptoException format:@"Unable to check DH generator"];

    if (codes & DH_NOT_SUITABLE_GENERATOR)
        [NSException raise:PEXCryptoException format:@"Not suitable generator"];

    if (codes & DH_CHECK_P_NOT_PRIME)
        [NSException raise:PEXCryptoException format:@"P is not a prime"];

    if (codes & DH_CHECK_P_NOT_SAFE_PRIME)
        [NSException raise:PEXCryptoException format:@"P is not a safe prime"];

    return toReturn;
}

+ (PEXEVPPKey *)getEVPPkeyFromDH:(DH *)dh {
    EVP_PKEY *pk = NULL;
    if ((pk=EVP_PKEY_new()) == NULL) {
        DDLogError(@"getEVPPkeyFromDH: Cannot allocate new PKEY");
        return nil;
    }

    if (!EVP_PKEY_set1_DH(pk, dh)) {
        DDLogError(@"getEVPPkeyFromDH: Cannot copy RSA key");
        EVP_PKEY_free(pk);
        return nil;
    }

    return [[PEXEVPPKey alloc] initWith:pk];
}

+ (NSData *)exportDHPublicKeyToPEM:(DH *)dh {
    PEXEVPPKey *pkey = [self getEVPPkeyFromDH:dh];
    if (pkey == nil) {
        DDLogError(@"Cannot get pkey from dh");
        return nil;
    }

    PEXMemBIO *membio = [[PEXMemBIO alloc] init];
    if (membio == nil) {
        DDLogError(@"exportDHPublicKeyToDER: Cannot allocate new BIO memory");
        return nil;
    }

    int success = PEM_write_bio_PUBKEY(membio.getRaw, pkey.getRaw);
    if (!success) {
        DDLogError(@"exportDHPublicKeyToDER: Cannot export a DH public key");
        return nil;
    }

    NSData *toReturn = membio.export;
    return toReturn;
}

+ (NSData *)exportDHPublicKeyToDER:(DH *)dh {
    NSData * pem = [self exportDHPublicKeyToPEM:dh];
    return [self getDERFromPEM:pem oType:nil];
}

+ (NSData *)exportDHPrivateKeyToPEM:(DH *)dh {
    PEXEVPPKey * pkey = [self getEVPPkeyFromDH:dh];
    NSString * pem = [self exportEvpKeyToPEMWrap:pkey password:nil];
    return [pem dataUsingEncoding:NSASCIIStringEncoding];
}

+ (NSData *)exportDHPrivateKeyToDER:(DH *)dh {
    NSData * pemData = [self exportDHPrivateKeyToPEM:dh];
    return [self getDERFromPEM:pemData oType:nil];
}

+ (PEXDH *)importDHFromDER: (NSData *) data {
    if (data == nil) {
        DDLogError(@"NSData is nil");
        return nil;
    }

    // Create PEM from DER here.
    NSString *pemString = [self getPEMFromDER:data oType:@"PRIVATE KEY"];
    NSData *pem = [pemString dataUsingEncoding:NSASCIIStringEncoding];

    return [self importDHFromPEM:pem];
}

+ (PEXDH *)importDHFromPEM: (NSData *) pem {
    if (pem == nil) {
        DDLogError(@"NSData is nil");
        return nil;
    }

    PEXMemBIO *membio = [[PEXMemBIO alloc] initWithNSData:pem];
    EVP_PKEY *pk = PEM_read_bio_PrivateKey([membio getRaw], NULL, NULL, NULL);
    membio = nil;

    // Try to import to RSA.
    DH *toReturn = NULL;
    if (pk != NULL) {
        toReturn = [self pkey_get_dh:pk dh:nil];
    }

    return [[PEXDH alloc] initWith:toReturn];
}

+ (PEXDH *)importDHPubFromDER: (NSData *) der {
    if (der == nil) {
        DDLogError(@"NSData is nil");
        return nil;
    }

    // Create PEM from DER here.
    NSString *pemString = [self getPEMFromDER:der oType:@"PUBLIC KEY"];
    NSData *pem = [pemString dataUsingEncoding:NSASCIIStringEncoding];

    return [self importDHPubFromPEM:pem];
}

+ (PEXDH *)importDHPubFromPEM: (NSData *) pem {
    if (pem == nil) {
        DDLogError(@"NSData is nil");
        return nil;
    }

    PEXMemBIO *membio = [[PEXMemBIO alloc] initWithNSData:pem];
    EVP_PKEY *pk = PEM_read_bio_PUBKEY([membio getRaw], NULL, NULL, NULL);
    membio = nil;

    // Try to import to RSA.
    DH *toReturn = NULL;
    if (pk != NULL) {
        toReturn = [self pkey_get_dh:pk dh:nil];
    }

    return [[PEXDH alloc] initWith:toReturn];
}

+ (NSData *)computeDH:(DH *)dh pubKey:(BIGNUM *)pubKey {
    int keySize = DH_size(dh);
    NSMutableData * key = [NSMutableData dataWithLength:keySize];
    unsigned char * buff = [key mutableBytes];

    int success = DH_compute_key(buff, pubKey, dh);
    if (success == -1){
        DDLogError(@"DH key computation error");
        return nil;
    }

    return [NSMutableData dataWithData:key];
}


@end