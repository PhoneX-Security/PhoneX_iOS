//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/ossl_typ.h"
#import "openssl/bio.h"
#import "openssl/x509.h"
#import "openssl/pkcs12.h"
#import "PEXEVPPKey.h"
#import "PEXMemBIO.h"
#import "PEXRSA.h"
#import "PEXX509.h"
#import "PEXX509Req.h"
#import "PEXPKCS12.h"
#import "PEXUserPrivate.h"
#import "PEXPrivateKey.h"
#import "PEXCertificate.h"

@class PEXDH;
@class PEXPKCS7;

// HMAC key size - same as underlying hash function
#define PEX_HMAC_KEY_SIZE 32

FOUNDATION_EXPORT NSString * const PEXCryptoErrorDomain;
FOUNDATION_EXPORT NSInteger const PEXCryptoSignatureError;
FOUNDATION_EXPORT NSInteger const PEXCryptoVerificationError;
FOUNDATION_EXPORT NSInteger const PEXCryptoRSASetupError;
FOUNDATION_EXPORT NSString * const PEXRandomException;
FOUNDATION_EXPORT NSString * const PEXCryptoException;

@interface PEXCryptoUtils : NSObject

+(void) initOpenSSL;

+(unsigned char *) secureRandom: (unsigned char *) buffer len: (NSUInteger) len amplifyWithArc: (BOOL) amplifyWithARC;

+(NSMutableData *) secureRandomData: (NSMutableData *) buffer len: (NSUInteger) len amplifyWithArc: (BOOL) amplifyWithARC;

+(uint32_t) secureRandomUInt32: (BOOL) amplifyWithARC;
+(uint64_t) secureRandomUInt64: (BOOL) amplifyWithARC;

+(int) pbkdf2: (unsigned char *) out seedUchar: (unsigned char *) seed seedLen: (int) seedLen withPass: (NSString*) pass
        withIterations: (uint) iter withOutLen: (uint) outLen hash: (EVP_MD const *) hash;

+(int) pbkdf2: (unsigned char *) out seed: (NSData*) seed withPass: (NSString*) pass withIterations: (uint) iter withOutLen: (uint) outLen
              hash: (EVP_MD const *) hash;

+(NSData *) pbkdf2: (NSData*) seed withPass: (NSString*) pass withIterations: (uint) iter withOutLen: (uint) outLen
              hash: (EVP_MD const *) hash;

+(NSData *) pbkdf2: (NSData *) seed withPass: (NSString*) pass withIterations: (uint) iter withOutLen: (uint) outLen;

/**
 * Reads X509 encoded certificate in DER form, parses to X509 structure used by OpenSSL.
 */
+(NSString *) exportPrivKeyToPEM: (RSA *) key password: (NSString *) password;
+(NSString *) exportEvpKeyToPEM: (EVP_PKEY *) key password: (NSString *) password;
+(NSString *) exportPubKeyToPEM: (RSA *) key;
+(NSString *) exportCertificateToPEM: (X509 *) cert;
+(NSData *)   exportCertificateToDER: (X509 *) cert;
+(NSString *) exportCSRToPEM: (X509_REQ *) csr;

+(RSA *) importPrivKeyFromPEM: (RSA **) key pem: (NSData *) pem password: (NSString *) password;
+(RSA *) importPubKeyFromPEM: (RSA **) key pem: (NSData *) pem;
+(X509 *) importCertificateFromDER: (NSData *) der;
+(X509 *) importCertificateFromPEM: (X509 **) cert pem: (NSData *) pem;
+(PKCS12 *) importPKCS12FromFile: (NSData *) der;
+(PKCS7 *) importPKCS7FromFile: (NSData *) der;

/**
* Import/export using wrapper classes
*/
+(NSString *) exportPrivKeyToPEMWrap: (PEXRSA *) key password: (NSString *) password;
+(NSString *) exportEvpKeyToPEMWrap: (PEXEVPPKey *) key password: (NSString *) password;
+(NSString *) exportPubKeyToPEMWrap: (PEXRSA *) key;
+(NSString *) exportCertificateToPEMWrap: (PEXX509 *) cert;
+(NSData *)   exportCertificateToDERWrap: (PEXX509 *) cert;
+(NSString *) exportCSRToPEMWrap: (PEXX509Req *) csr;

+(PEXRSA *) importPrivKeyFromPEMWrap: (NSData *) pem password: (NSString *) password;
+(PEXRSA *) importPubKeyFromPEMWrap: (NSData *) pem;
+(PEXX509 *) importCertificateFromDERWrap: (NSData *) der;
+(PEXX509 *) importCertificateFromPEMWrap: (NSData *) pem;
+(PEXPKCS12 *) importPKCS12FromFileWrap: (NSData *) der;
+(PEXPKCS7 *) importPKCS7FromFileWrap: (NSData *) der;

/**
 * Converts certificates stored in PEM file do DER
 * representation. Returns array of NSData in DER.
 */
+(NSArray *) getDERCertsFromPEM: (NSData *) certsPem;
+(NSArray *) getAnchorsFromDERCerts: (NSArray *) certsDer;
+(NSArray *) getAnchorsFromPEMCerts: (NSData *) certsPem;
+(NSData *) getDERFromPEM: (NSData *) pem oType: (NSString **) oType;
+(NSString *) getPEMFromDER:(NSData *) der oType: (NSString *) oType;
+(PEXEVPPKey *) getEVPPkeyFromRSA: (RSA *) rsa;

+(BOOL) isPubKeyEqual: (X509 *) cert csr: (X509_REQ * ) req;
+(BOOL) isCNameEqual: (X509 *) cert csr: (X509_REQ * ) req;

+(NSString *) getCName: (X509_NAME *) name totalCount: (int*) totalCount;
+(NSString *) getCNameCrt: (X509 *) cert totalCount: (int*) totalCount;
+(NSString *) getCNameReq: (X509_REQ *) cert totalCount: (int*) totalCount;
+(NSDate *) getNotBefore: (X509 *) cert;
+(NSDate *) getNotAfter: (X509 *) cert;

/**
 * Creates PKCS12 key store for internal use. Returns PKCS12 pointer.
 * Accepts RSA private keys and X509 certificates.
 * certChain contains CA certificate pointers, X509 *.
 */
+(PKCS12 *) createDefaultKeystore: (NSString *) username pkcsPasswd: (NSString *) pkcsPasswd
                             cert: (X509 *) cert certChain: (NSPointerArray *) certChain evpPrivKey: (EVP_PKEY*) evpPrivKey;

/**
* Creates PKCS12 key store for internal use. Returns PKCS12 pointer.
* Accepts RSA private keys and X509 certificates.
* certChain contains CA certificate pointers, X509 *.
*/
+(PKCS12 *) createDefaultKeystore: (NSString *) username pkcsPasswd: (NSString *) pkcsPasswd
                             cert: (X509 *) cert certChain: (NSPointerArray *) certChain privKey: (RSA*) privKey;

/**
* Creates PKCS12 key store for internal use. Returns PKCS12 pointer.
*/
+(PKCS12 *) createDefaultKeystore: (PEXUserPrivate *) privData;

/**
 * Writes PKCS12 to a binary representation, suitable for storing to a file.
 */
+(NSData *) exportPKCS12: (PKCS12 *) pkcs12;

/**
 * Extracts identity from PKCS12 file.
 */
+ (OSStatus)extractIdentity:(NSData *)inP12Data identity:(SecIdentityRef *)identity p12Passwd: (NSString *)p12Passwd;

/**
 * Clears certificate identity.
 */
+ (void)clearCertIdentity:(PEXUserPrivate *)privateData;

/**
 * Extracts identity, private key and certificates.
 */
+ (int)extractIdentity:(NSData *)inP12Data privData:(PEXUserPrivate *)privateData p12Passwd: (NSString *)p12Passwd;

/**
 * Converts X509 array from openssl representation to NSArray of PEXX509 objects.
 */
+ (NSArray *) convertX509StackToArray: (STACK_OF(X509) *) ca error: (NSError *) error;

+(int) encryptRaw: (unsigned char const *) plaintext plen: (int) plaintext_len key: (unsigned char *) key
               iv: (unsigned char const *) iv ciphertext: (unsigned char *) ciphertext cipher: (EVP_CIPHER const *) cipher;
+(int) decryptRaw: (unsigned char const *) ciphertext clen: (int) ciphertext_len key: (unsigned char *) key
               iv: (unsigned char const *) iv plaintext: (unsigned char *) plaintext cipher: (EVP_CIPHER const *) cipher;
+(NSData *) encryptData: (NSData *) plaintext key: (NSData *) key
                iv: (NSData *) iv cipher: (EVP_CIPHER const *) cipher error: (NSError **) pError;
+(NSData *) decryptData: (NSData *) ciphertext key: (NSData *) key
                iv: (NSData *) iv cipher: (EVP_CIPHER const *) cipher error: (NSError **) pError;

+(NSData *) sign: (NSData *) dataToSign key: (PEXPrivateKey *) key error: (NSError **) error;
+(NSData *) signHash: (NSData *) dataToSignHashed key: (PEXPrivateKey *) key error: (NSError **) error;
+(BOOL) verify: (NSData *) dataToVerify signature: (NSData *) signature pubKey: (PEXEVPPKey *)cKey error: (NSError **)error;
+(BOOL) verify: (NSData *) dataToVerify signature: (NSData *) signature certificate: (PEXCertificate *) certificate error: (NSError **) error;
+(BOOL) verifyHash: (NSData *) dataToVerifyHashed signature: (NSData *) signature pubKey: (PEXEVPPKey *) cKey error: (NSError **) error;

+(NSData *) hmac: (NSData *) payload key: (NSData *) key;

+(NSData *) asymEncrypt: (NSData *) plaintext  crt:(PEXX509 *) crt error:(NSError **) pError;
+(NSData *) asymEncrypt: (NSData *) plaintext  key: (PEXEVPPKey *) key error: (NSError **) pError;
+(NSData *) asymDecrypt: (NSData *) ciphertext key: (PEXEVPPKey *) key error: (NSError **) pError;

+(NSString *) getDeviceID;
+(void) setObject:(NSString*) object forKey:(NSString*) key;
+(NSString*) objectForKey:(NSString*) key;

+ (DH *)importDHParamsFromPEM:(DH **)dh pem:(NSData *)pem;
+ (PEXEVPPKey *)getEVPPkeyFromDH:(DH *)dh;
+ (NSData *) exportDHPublicKeyToPEM: (DH *) dh;
+ (NSData *) exportDHPublicKeyToDER: (DH *) dh;
+ (NSData *) exportDHPrivateKeyToPEM: (DH *) dh;
+ (NSData *) exportDHPrivateKeyToDER: (DH *) dh;
+ (PEXDH *)importDHFromPEM: (NSData *) pem;
+ (PEXDH *)importDHFromDER: (NSData *) data;
+ (PEXDH *)importDHPubFromPEM: (NSData *) pem;
+ (PEXDH *)importDHPubFromDER: (NSData *) der;
+ (NSData *) computeDH: (DH *) dh pubKey: (BIGNUM *) pubKey;

@end

