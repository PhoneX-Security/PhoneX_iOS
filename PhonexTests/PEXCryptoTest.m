//
//  PEXCryptoTest.m
//  Phonex
//
//  Created by Dusan Klinec on 02.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PEXMessageDigest.h"
#import "PEXPasswdGenerator.h"
#import "PEXCryptoUtils.h"
#import "PEXGenerator.h"
#import "openssl/objects.h"
#import "PEXResCrypto.h"
#import "PEXOpenUDID.h"
#import "PEXDH.h"

@interface PEXCryptoTest : XCTestCase

@end

@implementation PEXCryptoTest

static const char *exampleCSRPEM = "-----BEGIN CERTIFICATE REQUEST-----\n"
        "MIIC6zCCAdMCAQEwgaUxKDAmBgkqhkiG9w0BCQEWGXRlc3QtaW50ZXJuYWxAcGhv\n"
        "bmUteC5uZXQxIjAgBgNVBAMMGXRlc3QtaW50ZXJuYWxAcGhvbmUteC5uZXQxDzAN\n"
        "BgNVBAsMBlBob25lWDEPMA0GA1UECgwGUGhvbmVYMRIwEAYDVQQHDAlHaWJyYWx0\n"
        "YXIxEjAQBgNVBAgMCUdpYnJhbHRhcjELMAkGA1UEBhMCR0kwggEiMA0GCSqGSIb3\n"
        "DQEBAQUAA4IBDwAwggEKAoIBAQDKUQ/aU2dKJJDv7fG3Zz3ZM5gdEujcdVB3fapn\n"
        "KFI6rClkvSJJkM+EUJjSV2PpKdqLuvpvH62KbdLkIe8HhEBbofeqoaLkFh/zDqC5\n"
        "IDz1zOxxCDeQKDbSpxQau3FHKvVVsMdLhmai8Cntw0R/hpkCtT2Zzy17eTOljBpx\n"
        "FwilBzrWj6x6nRMa7thVGQox7sHm+nhkDhOmFu6gtQ7QBeCpVjzi0nIWdNNjFM6K\n"
        "p7w3U+Vw+svjOwMX9lii/7fH3t6NXi/P7/u8KkCbuXTFAVk22PB2jNnwtYqM4Jf2\n"
        "v4VxuzJUpAgTziXJ8I/tvJJfGBRFPorNEPynPMlwKuKB67LRAgMBAAGgADANBgkq\n"
        "hkiG9w0BAQUFAAOCAQEAOvwYe3gyBgM8nQJMiTxYEzd+tFS42m9uYblQafNGlmJJ\n"
        "4ekn4KZoN3m9q1N2Njk0KIRefJoWACxp4eCeB428EzwxG7mh0JEJ+ghSjzcld4wk\n"
        "iH5mUt8iOMnYGRS7DdnZQFukT5LAC8hF7elQSBjtwJPFCpFS8MMRBoHwFH2p/w7m\n"
        "aFPQV6qwh74nU6VIzot+1As6JeArn4IVAdjmSaaxO/SEHjggrLE3euyg9OTzw9E+\n"
        "bRO4ZVKj55q3D/t5oznsDr9m8lclFdvDwZQu65Wyp/DjykiYMoslPQfQT+Ciyb3k\n"
        "PAwUvEtqDA5UOy9gMvqYgCd5OJZ2Y8XNwhBEW8hkJw==\n"
        "-----END CERTIFICATE REQUEST-----";

static const char * exampleCertPem = "-----BEGIN CERTIFICATE-----\n"
        "MIIE7TCCAtWgAwIBAgICA68wDQYJKoZIhvcNAQEFBQAwezELMAkGA1UEBhMCR0kx\n"
        "EjAQBgNVBAgMCUdpYnJhbHRhcjEPMA0GA1UECgwGUGhvbmVYMQ8wDQYDVQQLDAZT\n"
        "ZXJ2ZXIxFDASBgNVBAMMC3Bob25lLXgubmV0MSAwHgYJKoZIhvcNAQkBFhFhZG1p\n"
        "bkBwaG9uZS14Lm5ldDAeFw0xNDEwMTUxNTAyMzNaFw0xNjEwMTQxNTAyMzNaMIGl\n"
        "MSgwJgYJKoZIhvcNAQkBFhl0ZXN0LWludGVybmFsQHBob25lLXgubmV0MSIwIAYD\n"
        "VQQDDBl0ZXN0LWludGVybmFsQHBob25lLXgubmV0MQ8wDQYDVQQLDAZQaG9uZVgx\n"
        "DzANBgNVBAoMBlBob25lWDESMBAGA1UEBwwJR2licmFsdGFyMRIwEAYDVQQIDAlH\n"
        "aWJyYWx0YXIxCzAJBgNVBAYTAkdJMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB\n"
        "CgKCAQEAylEP2lNnSiSQ7+3xt2c92TOYHRLo3HVQd32qZyhSOqwpZL0iSZDPhFCY\n"
        "0ldj6Snai7r6bx+tim3S5CHvB4RAW6H3qqGi5BYf8w6guSA89czscQg3kCg20qcU\n"
        "GrtxRyr1VbDHS4ZmovAp7cNEf4aZArU9mc8te3kzpYwacRcIpQc61o+sep0TGu7Y\n"
        "VRkKMe7B5vp4ZA4TphbuoLUO0AXgqVY84tJyFnTTYxTOiqe8N1PlcPrL4zsDF/ZY\n"
        "ov+3x97ejV4vz+/7vCpAm7l0xQFZNtjwdozZ8LWKjOCX9r+FcbsyVKQIE84lyfCP\n"
        "7bySXxgURT6KzRD8pzzJcCrigeuy0QIDAQABo1AwTjAMBgNVHRMBAf8EAjAAMB0G\n"
        "A1UdDgQWBBTUBO/bHT3Gm2AysoLs10L4qLqBDDAfBgNVHSMEGDAWgBSU7NvnbIEk\n"
        "YrH6O5ZMhj+3lflGgTANBgkqhkiG9w0BAQUFAAOCAgEANGK/6Qc3TRiG9HuFP3fn\n"
        "RHYkc9NYq+XodRMqBGrndx0R/VUciRsUs4LWFko9oT24bjX1st4xj8UbdB0CNYPf\n"
        "wL48FJAR9pkGK875R5SmcqzzFcKXrFNiJFyuUxdS/rtDwIgStpHWAgF4qqhupYkq\n"
        "LRoYmbdnR7oGnGU4LIbmFXJyF026aDmhwNtRYR+JmXH8qyKIf6db+tVyNkp+++op\n"
        "xhZxcVkXavLILcy8DvjgnTiFQwg3AnxVlIYJ57xrmEiYCBy3TpGFuI8MrzqffceK\n"
        "YxUPEE0CXI9bYT52sHKr0QYCM6SQjfQBZTaU8iHr95Enxd/vtMqgYJWIhst/yhXB\n"
        "aPfjJLtfZ4dYeskryGDOgoqXFMoHOinuJtu/XPauZFq+e3phXaYgifhDpOO/tsm4\n"
        "KJtpNLg2f2Fr5JUussWnDrkkiyTgn/6XBDgg+sU7zeRCzv5h9LqNv6qOwCGe0B/D\n"
        "AlDSDM+GR3VGwzmdlUxW84hWv0aDivM3l1LkvOn0vQ87Wr7+CzGDU149HgohlZG6\n"
        "2zKEms449SQIglRkiXo84Yd0lf3MuwSONB+zlFRztnUX3rFxkgD4MBVb4upCDEnZ\n"
        "Lwgi0cSn5a7CXVzTMwJOYFWigIyFbZzUFjD9GI399ceTXlnBrk+n4UlmN68goRIf\n"
        "8CjhbxM4pYw4fD1wKPjzrMg=\n"
        "-----END CERTIFICATE-----";

static const char *examplePrivKeyPEM = "-----BEGIN PRIVATE KEY-----\n"
        "MIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDKUQ/aU2dKJJDv\n"
        "7fG3Zz3ZM5gdEujcdVB3fapnKFI6rClkvSJJkM+EUJjSV2PpKdqLuvpvH62KbdLk\n"
        "Ie8HhEBbofeqoaLkFh/zDqC5IDz1zOxxCDeQKDbSpxQau3FHKvVVsMdLhmai8Cnt\n"
        "w0R/hpkCtT2Zzy17eTOljBpxFwilBzrWj6x6nRMa7thVGQox7sHm+nhkDhOmFu6g\n"
        "tQ7QBeCpVjzi0nIWdNNjFM6Kp7w3U+Vw+svjOwMX9lii/7fH3t6NXi/P7/u8KkCb\n"
        "uXTFAVk22PB2jNnwtYqM4Jf2v4VxuzJUpAgTziXJ8I/tvJJfGBRFPorNEPynPMlw\n"
        "KuKB67LRAgMBAAECggEAWwmS6pkxF0nQ9kXJyM9qIzx2LE7//YPEi6A+d2DLb59c\n"
        "mPoKXbQNzOo/ehbc3GR69PlUC4DjpDC6/vDOEEHQe+sr+Nn25E+YXNSuOd9pzulB\n"
        "U7Nw3StbT/rirwy9clrAPqjnZPK7aIJNO7HsNr4oR/GqIHX7b14ggVPD6jOFLkx+\n"
        "lrh1FSp0vQF4ViOdTTmRpNOTlaQExT+KYyTgfKHL9nOdWaQNSuJIM/5+oSP8OEAS\n"
        "NyuPVtVfz8P/CzdrljS6Qykog7zBeWv0Gc8cj7xpYhPgOuD00FWOF7y+qfWwhPdB\n"
        "kZvc4TIAMdAeagL4LZs4n0Na44I8lXxmXj3/AdfQAQKBgQD86D8Nk9UJ0GWowi2b\n"
        "B0UyshsHDsgKp4AWHUiloufEC4J6YDw/AKmSoGVcGxlJrTXQBFNw7ElvbX3DcXPS\n"
        "OlmYRqUi8BinijzZvZNxSz5J06gHGdJ8ZkK8fM9DZZlXrmSopydyfGamJgPqkF6d\n"
        "bRCSa01DzommV3yO6K5O7osYgQKBgQDMym+zN9SShgzl9pOxRe4hi72iu/jgKnW4\n"
        "+nZlp/M0oDErCOK0eYGud6irpWhPHo77yaDSp1DwjyC5lzsJJdVGEaKseUqMewIZ\n"
        "7BjMStv28BI/eGR2N9Z1Q2HIEaz0Uw+lFaC1xWNauxCikX4XhnF/x/SyP4ERmIpb\n"
        "LmZlAz/yUQKBgQCKjLUWPBmmsbsvk4kmd/opxrbVy/w9EfwyoUJOM4uis+d8IUKA\n"
        "BV3gjOxaZCIbYb+sQOJxZ5DncWVHb9zSm9K/gFwxYrUu+6VQZ/HhTCZIjaJsmXHd\n"
        "YqxG1F07f+pcxZYxarlKl+ooNYVJuGOM/NXqUMxYTErOjPkY1VHAviAHgQKBgQCV\n"
        "+nuriOvJExtHHzoyzcAEGU8cawVtRitI+UTUVherJtZbafp9qa7rkv6YFl858mtM\n"
        "wvFg1OBWDLwury6xGGAFHM1B+uI516xGR74xf3Fwe4khqo4IdgQ9hMeLukYr+Niw\n"
        "UhKMjK6it/UK2fq6R9+/cTUnhZKEzG4nMOgUejjOwQKBgQCoTc/CJ7vXgc1/cN2m\n"
        "04dhACBoEV+SHem3uD6kAAxtO1jeXiT4JPoF8AHkq6ttiIc69wYVC9UtB4An/IxX\n"
        "rXF/ykzBNEb2bqKFwDHmt7KT2nUJFF2BUNSLr9gP3uAjQkR8gDoS8++bkyZeE4n3\n"
        "fNEv4xYnBxWuzvrqW+Y16HMLRQ==\n"
        "-----END PRIVATE KEY-----";

static const char *exampleDHPrivKeyPEM = "-----BEGIN PRIVATE KEY-----\n"
        "MIIBZwIBADCCARsGCSqGSIb3DQEDATCCAQwCgYEA/X9TgR11EilS30qcLuzk5/YR\n"
        "t1I870QAwx4/gLZRJmlFXUAiUftZPY1Y+r/F9bow9subVWzXgTuAHTRv8mZgt2uZ\n"
        "UKWkn5/oBHsQIsJPu6nX/rfGG/g7V+fGqKYVDwT7g/bTxR7DAjVUE1oWkTL2dfOu\n"
        "K2HXKu/yIgMZndFIAccCgYEA9+GghdabPd7LvKtcNrhXuXmUr7v6OuqC+VdMCz0H\n"
        "gmdRWVeOutRZT+ZxBxCBgLRJFnEj6EwoFhO3zwkyjMim4TwWeotUfI0o4KOuHiuz\n"
        "pnWRbqN/C/ohNWLx+2J6ASQ7zKTxvqhRkImog9/hWuWfBpKLZl6Ae1UlZAFMO/7P\n"
        "SSoCAgIABEMCQQDhvJrLWh1+rYOFVfRsSvELkx4EejGZG3rAXOYH9G1QHZVaN6Gf\n"
        "d2kkTrMNFuu7Jw8TtPU1mtc1oahOUofrv687\n"
        "-----END PRIVATE KEY-----";

static const char *exampleDHPublKeyPEM = "-----BEGIN PUBLIC KEY-----\n"
        "MIIBpjCCARsGCSqGSIb3DQEDATCCAQwCgYEA/X9TgR11EilS30qcLuzk5/YRt1I8\n"
        "70QAwx4/gLZRJmlFXUAiUftZPY1Y+r/F9bow9subVWzXgTuAHTRv8mZgt2uZUKWk\n"
        "n5/oBHsQIsJPu6nX/rfGG/g7V+fGqKYVDwT7g/bTxR7DAjVUE1oWkTL2dfOuK2HX\n"
        "Ku/yIgMZndFIAccCgYEA9+GghdabPd7LvKtcNrhXuXmUr7v6OuqC+VdMCz0HgmdR\n"
        "WVeOutRZT+ZxBxCBgLRJFnEj6EwoFhO3zwkyjMim4TwWeotUfI0o4KOuHiuzpnWR\n"
        "bqN/C/ohNWLx+2J6ASQ7zKTxvqhRkImog9/hWuWfBpKLZl6Ae1UlZAFMO/7PSSoC\n"
        "AgIAA4GEAAKBgCAj0Q9uN3PcFZP9aeMWOD3ejG/TxslgZeKbmyr6qA8gH1Qg4Xdu\n"
        "YDfH4XGYgPawEA3M4UoikAF9AdUgMXQtVhX6mL5tlo2vTzWWU5wY4JoPt1BHCizC\n"
        "3E1uOSt+ahptA3wSX486MvQICEXo6dFRB99wjhohtcLInkdI6rt847vI\n"
        "-----END PUBLIC KEY-----";

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPrivkeyImportExport {
    RSA * keypair=NULL;
    int result = [PEXGenerator generateRSAKeyPair:1024 andRSA:&keypair];
    NSString * password = @"secret_123";

    // Export part
    NSString * pemString = [PEXCryptoUtils exportPrivKeyToPEM:keypair password:password];
    XCTAssert(pemString!=nil, "PEM is nil");
    XCTAssert([pemString length] > 20, "PEM is too short");
    XCTAssert([pemString hasPrefix:@"-----BEGIN"], "Generated PEM seems invalid, no BEGIN part.");

    // Import part
    NSData * pemSrc = [NSData dataWithBytes:[pemString cStringUsingEncoding:NSASCIIStringEncoding] length:[pemString length]];
    RSA * newPrivKey = [PEXCryptoUtils importPrivKeyFromPEM:NULL pem:pemSrc password:password];
    XCTAssert(newPrivKey!=nil, "Imported public key is nil");
    XCTAssert(newPrivKey->p != NULL && newPrivKey->q != NULL, "Imported private key is invalid");

    // Compare public keys.
    XCTAssert(BN_cmp(keypair->p, newPrivKey->p)==0, "Private prime p does not match");
    XCTAssert(BN_cmp(keypair->q, newPrivKey->q)==0, "Private prime q does not match");

    RSA_free(newPrivKey);
    RSA_free(keypair);
    keypair = NULL;
    newPrivKey = NULL;
}

- (void)testPubKeyImportExport {
    RSA * keypair=NULL;
    int result = [PEXGenerator generateRSAKeyPair:1024 andRSA:&keypair];

    // Export part
    NSString * pemString = [PEXCryptoUtils exportPubKeyToPEM:keypair];
    XCTAssert(pemString!=nil, "PEM is nil");
    XCTAssert([pemString length] > 20, "PEM is too short");
    XCTAssert([pemString hasPrefix:@"-----BEGIN"], "Generated PEM seems invalid, no BEGIN part.");

    // Import part
    NSData * pemSrc = [NSData dataWithBytes:[pemString cStringUsingEncoding:NSASCIIStringEncoding] length:[pemString length]];
    RSA * newPubKey = [PEXCryptoUtils importPubKeyFromPEM:NULL pem:pemSrc];
    XCTAssert(newPubKey!=nil, "Imported public key is nil");
    XCTAssert(newPubKey->n != NULL && newPubKey->e != NULL, "Imported public key is invalid");

    // Compare public keys.
    XCTAssert(BN_cmp(keypair->n, newPubKey->n)==0, "Public modulus does not match");
    XCTAssert(BN_cmp(keypair->e, newPubKey->e)==0, "Public exponent does not match");

    RSA_free(newPubKey);
    RSA_free(keypair);
    keypair = NULL;
    newPubKey = NULL;
}

- (void)testPEMRead {
    NSData * caRoots = [PEXResCrypto loadCARoots];

    // Parse PEM encoded certificates to array of DER encoded certificates.
    NSArray * derArr = [PEXCryptoUtils getDERCertsFromPEM:caRoots];
    XCTAssert(derArr!=nil, "DER array is nil");
    XCTAssert([derArr count]>0, "DER array is empty");

    // Parse PEM encoded certificates to array of Sec certificates.
    NSArray * secArr = [PEXCryptoUtils getAnchorsFromPEMCerts:caRoots];
    XCTAssert(secArr!=nil, "Certificate array is nil");
    XCTAssert([secArr count]>0, "Certificate array is empty");
}

- (void)testSecureRandom {
    const int len = 64;
    unsigned char * buff = calloc(sizeof(unsigned char), len);

    // Test with provided buffer.
    unsigned char * buff2 = [PEXCryptoUtils secureRandom:buff len:len amplifyWithArc:NO];
    XCTAssert(buff2!=NULL, "buff2 is null - something went wrong");
    XCTAssert(buff2 == buff, "Buffer pointers does not match, they should");
    int zerosNum=0;
    for(int i=0; i<len; i++){
        zerosNum = buff[i]==0;
    }
    XCTAssert(zerosNum < (0.2 * len), "Buffer contains quite a lot of zeros");

    // Test with amplification.
    buff2 = [PEXCryptoUtils secureRandom:buff len:len amplifyWithArc:YES];
    XCTAssert(buff2!=NULL, "buff2 is null - something went wrong");
    XCTAssert(buff2 == buff, "Buffer pointers does not match, they should");
    zerosNum=0;
    for(int i=0; i<len; i++){
        zerosNum = buff[i]==0;
    }
    XCTAssert(zerosNum < (0.2 * len), "Buffer contains quite a lot of zeros");

    // Test with null buffer.
    buff2 = [PEXCryptoUtils secureRandom:NULL len:len amplifyWithArc:YES];
    XCTAssert(buff2!=NULL, "buff2 is null - something went wrong");
    zerosNum=0;
    for(int i=0; i<len; i++){
        zerosNum = buff2[i]==0;
    }
    XCTAssert(zerosNum < (0.2 * len), "Buffer contains quite a lot of zeros");
    free(buff2);
    free(buff);
}

-(void) testSecureRandomData {
    const int len = 64;
    NSMutableData * dat01 = [PEXCryptoUtils secureRandomData:nil len:len amplifyWithArc:YES];
    XCTAssert(dat01 != nil, "Random data is nil");
    XCTAssert([dat01 length]==len, "Data lenght does not match");
}

-(void) testPEMToDerConversion {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];
    NSString * objType = nil;

    NSData * derCert = [PEXCryptoUtils getDERFromPEM:certPem oType:&objType];
    XCTAssert(derCert!=nil, "DER certificate is nil");
    XCTAssert([derCert length] > 100, "DER certificate is too short");
    XCTAssert([@"CERTIFICATE" isEqualToString:objType], "OBJ type is not CERTIFICATE");

    // Try to load DER to certificate in order to verify DER conversion.
    X509 * cert = [PEXCryptoUtils importCertificateFromDER:derCert];
    XCTAssert(cert!=NULL, "X509 certificate is nil, DER conversion is probably wrong");
    X509_free(cert);
}

-(void) testPKCS12ExportImport {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];
    NSData * privKeyPem = [[NSData alloc] initWithBytes:examplePrivKeyPEM length:strlen(examplePrivKeyPEM)];

    // Import X509 and private key.
    RSA * rsa = [PEXCryptoUtils importPrivKeyFromPEM:NULL pem:privKeyPem password:nil];
    XCTAssert(rsa!=NULL, "RSA private key could not be imported from local PEM sample.");

    X509 * cert = [PEXCryptoUtils importCertificateFromPEM:NULL pem:certPem];
    XCTAssert(cert!=NULL, "X509 certificate could not be imported from local PEM sample.");

    // Create PKCS12 OpenSSL object with default setings. Contains user certificate and private key.
    PKCS12 * p12 = [PEXCryptoUtils createDefaultKeystore:@"phonex-internal"
                                              pkcsPasswd:@"passwd"
                                                    cert:cert
                                               certChain:NULL
                                                 privKey:rsa];

    XCTAssert(p12!=NULL, "PKCS12 export failed");

    NSData * p12Bin = [PEXCryptoUtils exportPKCS12:p12];
    XCTAssert(p12Bin!=nil, "Exported PKCS12 is nil");
    XCTAssert([p12Bin length]>100, "Exported PKCS12 is too short");

    // Try to import PKCS12 to identity.
    SecIdentityRef identity = nil;
    OSStatus status = [PEXCryptoUtils extractIdentity:p12Bin identity:&identity p12Passwd:@"passwd"];
    XCTAssertEqual(errSecSuccess, status, "Error occurred during PKCS12 import");
    XCTAssertNotEqual(nil, identity, "Imported identity is nil");

    // Try to extract certificate - should be possible if everything went OK.
    SecCertificateRef importedCert = nil;
    status = SecIdentityCopyCertificate(identity, &importedCert);
    XCTAssertEqual(errSecSuccess, status, "Error occurred during SecIdentityCopyCertificate");
    XCTAssertNotEqual(nil, importedCert, "Imported certificate from identity is nil");

    // Try to extract private key.
    SecKeyRef importedKey = nil;
    status = SecIdentityCopyPrivateKey(identity, &importedKey);
    XCTAssertEqual(errSecSuccess, status, "Error occurred during SecIdentityCopyPrivateKey");
    XCTAssertNotEqual(nil, importedKey, "Imported private key from identity is nil");

    RSA_free(rsa);
    X509_free(cert);
    PKCS12_free(p12);
}

-(void) testSignatures {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];
    NSData * privKeyPem = [[NSData alloc] initWithBytes:examplePrivKeyPEM length:strlen(examplePrivKeyPEM)];

    PEXX509 * crt = [[PEXX509 alloc] initWith: [PEXCryptoUtils importCertificateFromPEM:NULL pem:certPem]];
    RSA * rsa = [PEXCryptoUtils importPrivKeyFromPEM:NULL pem:privKeyPem password:nil];
    PEXEVPPKey * pkey = [PEXCryptoUtils getEVPPkeyFromRSA: rsa];

    PEXPrivateKey * pk = [[PEXPrivateKey alloc] init];
    pk.key = pkey;
    PEXCertificate * c = [[PEXCertificate alloc] init];
    c.cert = crt;

    // Sign data.
    NSError * err;
    NSData * signature = [PEXCryptoUtils sign:certPem key:pk error:&err];
    XCTAssert(signature != nil, "Signature is nil");
    XCTAssert(err == nil, "Error is non-nil: %@", err);
    XCTAssert([signature length] > 4, "Signature length is too small");

    // Verify signature.
    BOOL verif = [PEXCryptoUtils verify:certPem signature:signature certificate:c error:&err];
    XCTAssert(err == nil, "Error is non-nil: %@", err);
    XCTAssertEqual(verif, YES, "Signature verification failed");
}

-(void) testAsymEnc {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];
    NSData * privKeyPem = [[NSData alloc] initWithBytes:examplePrivKeyPEM length:strlen(examplePrivKeyPEM)];

    PEXX509 * crt = [[PEXX509 alloc] initWith: [PEXCryptoUtils importCertificateFromPEM:NULL pem:certPem]];
    RSA * rsa = [PEXCryptoUtils importPrivKeyFromPEM:NULL pem:privKeyPem password:nil];
    PEXEVPPKey * pkey = [PEXCryptoUtils getEVPPkeyFromRSA: rsa];
    PEXEVPPKey * cKey = [[PEXEVPPKey alloc] initWith: X509_get_pubkey([crt getRaw])];
    if (cKey==NULL || ![cKey isAllocated]){
        XCTFail(@"Cannot extract public key from certificate.");
        return;
    }

    NSRange range = {0, 128};
    NSData * inp = [certPem subdataWithRange:range];

    // Asym encrypt data.
    NSError * err;
    NSData * asym = [PEXCryptoUtils asymEncrypt:inp key:cKey error:&err];

    XCTAssert(asym != nil, "Asymetric ciphertext is nil");
    XCTAssert(err == nil, "Error is non-nil: %@", err);
    XCTAssert([asym length] > 4, "Asymetric ciphertext length is too small");

    // Decrypt.
    NSData * plain = [PEXCryptoUtils asymDecrypt:asym key:pkey error:&err];
    XCTAssert(err == nil, "Error is non-nil: %@", err);
    XCTAssert(plain != nil, "Plaintext is nil");
    XCTAssert([plain isEqualToData:inp]);
}

-(void) testHmac {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];

    // Generate a HMAC key.
    NSData * macKey = [PEXCryptoUtils secureRandomData:nil len:32 amplifyWithArc:YES];
    XCTAssert(macKey != nil, "MAC key is nil");

    // MAC input.
    NSData * mac01 = [PEXCryptoUtils hmac:certPem key:macKey];
    NSData * mac02 = [PEXCryptoUtils hmac:certPem key:certPem];
    NSData * mac03 = [PEXCryptoUtils hmac:certPem key:macKey];

    XCTAssert(mac01 != nil, "MAC01 is nil");
    XCTAssert(mac02 != nil, "MAC02 is nil");
    XCTAssert(mac03 != nil, "MAC03 is nil");

    XCTAssert([mac01 isEqualToData:mac03], "MAC does not match");
    XCTAssert(![mac01 isEqualToData:mac02], "MAC matches even if they must not");
}

-(void) testAesGmc {
    NSData * certPem = [[NSData alloc] initWithBytes:exampleCertPem length:strlen(exampleCertPem)];

    // Generate a HMAC key.
    NSData * iv  = [PEXCryptoUtils secureRandomData:nil len:16 amplifyWithArc:YES];
    NSData * key = [PEXCryptoUtils secureRandomData:nil len:32 amplifyWithArc:YES];
    XCTAssert(iv != nil, "IV is nil");
    XCTAssert(key != nil, "KEY is nil");

    // MAC input.
    NSData * cip = [PEXCryptoUtils encryptData:certPem key:key iv:iv cipher:EVP_aes_256_gcm() error:nil];
    NSData * pln = [PEXCryptoUtils decryptData:cip key:key iv:iv cipher:EVP_aes_256_gcm() error:nil];

    XCTAssert([certPem isEqualToData:pln], "Does not match");
}

-(void) testDhImportExport {
    // Load DH group.
    NSData * groupData = [PEXResCrypto loadDHGroupId: 1];
    DH * dh = [PEXCryptoUtils importDHParamsFromPEM:NULL pem:groupData];
    XCTAssert(dh!=nil, "DH group is nil");

    int result = [PEXGenerator generateDhKeyPair: dh];
    XCTAssert(result == 1, "Cannot generate DH key");

    // Export part - private key.
    NSData * privDer = [PEXCryptoUtils exportDHPrivateKeyToDER:dh];
    XCTAssert(privDer!=nil, "DER is nil");
    XCTAssert([privDer length] > 20, "DER is too short");

    // Import part - private key.
    PEXDH * dhRec = [PEXCryptoUtils importDHFromDER:privDer];
    XCTAssert(dhRec != nil, "Imported DH private key is nil");
    XCTAssert(dhRec.getRaw != NULL, "Imported DH private key DH is NULL");
    XCTAssert(dhRec.getRaw->priv_key != NULL, "Priv key is nil");
    XCTAssert(dhRec.getRaw->pub_key != NULL, "Pub key is nil");

    // Compare private & public keys, prime & generator.
    XCTAssert(BN_cmp(dh->pub_key, dhRec.getRaw->pub_key)==0, "Pubkey does not match");
    XCTAssert(BN_cmp(dh->priv_key, dhRec.getRaw->priv_key)==0, "Privkey does not match");
    XCTAssert(BN_cmp(dh->p, dhRec.getRaw->p)==0, "Prime modulus does not match");
    XCTAssert(BN_cmp(dh->g, dhRec.getRaw->g)==0, "Generator does not match");

    // Export part - public key.
    NSData * publDer = [PEXCryptoUtils exportDHPublicKeyToDER:dh];
    XCTAssert(publDer!=nil, "DER is nil");
    XCTAssert([publDer length] > 20, "DER is too short");

    // Import part - public key.
    PEXDH * dhRecPubl = [PEXCryptoUtils importDHPubFromDER:publDer];
    XCTAssert(dhRecPubl != nil, "Imported DH private key is nil");
    XCTAssert(dhRecPubl.getRaw->priv_key == NULL, "Priv key should be nil");
    XCTAssert(dhRecPubl.getRaw->pub_key != NULL, "Pub key is nil");

    // Compare private & public keys, prime & generator.
    XCTAssert(BN_cmp(dh->pub_key, dhRecPubl.getRaw->pub_key)==0, "Pubkey does not match");
    XCTAssert(BN_cmp(dh->p, dhRecPubl.getRaw->p)==0, "Prime modulus does not match");
    XCTAssert(BN_cmp(dh->g, dhRecPubl.getRaw->g)==0, "Generator does not match");

    DH_free(dh);
}

-(void) testDhImportFromJava {
    NSData * dhPrivKeyPem = [[NSData alloc] initWithBytes:exampleDHPrivKeyPEM length:strlen(exampleDHPrivKeyPEM)];
    PEXDH * dhRec = [PEXCryptoUtils importDHFromPEM:dhPrivKeyPem];
    XCTAssert(dhRec != nil, "Imported DH private key is nil");
    XCTAssert(dhRec.getRaw != NULL, "Imported DH private key DH is NULL");
    XCTAssert(dhRec.getRaw->priv_key != NULL, "Priv key is nil");
    XCTAssert(dhRec.getRaw->pub_key != NULL, "Pub key is nil");
    XCTAssert(dhRec.getRaw->p != NULL, "Prime modulus is nil");
    XCTAssert(dhRec.getRaw->g != NULL, "Generator is nil");

    NSData * dhPublKeyPem = [[NSData alloc] initWithBytes:exampleDHPublKeyPEM length:strlen(exampleDHPublKeyPEM)];
    PEXDH * dhRec2 = [PEXCryptoUtils importDHPubFromPEM:dhPublKeyPem];
    XCTAssert(dhRec2 != nil, "Imported DH private key is nil");
    XCTAssert(dhRec2.getRaw != NULL, "Imported DH private key DH is NULL");
    XCTAssert(dhRec2.getRaw->priv_key == NULL, "Priv key should be nil");
    XCTAssert(dhRec2.getRaw->pub_key != NULL, "Pub key is nil");
    XCTAssert(dhRec2.getRaw->p != NULL, "Prime modulus is nil");
    XCTAssert(dhRec2.getRaw->g != NULL, "Generator is nil");

    // Compare private & public keys, prime & generator.
    XCTAssert(BN_cmp(dhRec2.getRaw->pub_key, dhRec.getRaw->pub_key)==0, "Pubkey does not match");
    XCTAssert(BN_cmp(dhRec2.getRaw->p, dhRec.getRaw->p)==0, "Prime modulus does not match");
    XCTAssert(BN_cmp(dhRec2.getRaw->g, dhRec.getRaw->g)==0, "Generator does not match");
}

@end
