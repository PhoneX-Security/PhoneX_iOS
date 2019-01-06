//
// Created by Dusan Klinec on 14.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXReceipt.h"
#import "PEXMemBIO.h"
#import "PEXCryptoUtils.h"
#import "PEXX509Stack.h"
#import "PEXX509Store.h"
#import "PEXPKCS7.h"
#import "PEXAppVersionUtils.h"
#import "PEXMessageDigest.h"
#import "RMAppReceipt.h"
#import "RMStore.h"
#import "RMStoreTransactionReceiptVerifier.h"
#import "RMStoreAppReceiptVerifier.h"

// Inspired by: https://www.objc.io/issues/17-security/receipt-validation/
@implementation PEXReceipt {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.receiptValid = NO;
    }

    return self;
}

+ (instancetype)receiptWithUrl:(NSURL *)receiptURL {
    return [[self alloc] initWithUrl:receiptURL];
}

- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        self.receiptUrl = url;
    }

    return self;
}

-(BOOL) verify {
    // Load the receipt file
    NSData *receiptData = [NSData dataWithContentsOfURL:_receiptUrl];

    // Create a memory buffer to extract the PKCS #7 container
    _receiptPKCS7 = [PEXCryptoUtils importPKCS7FromFileWrap:receiptData];
    if (_receiptPKCS7 == nil || !_receiptPKCS7.isAllocated) {
        DDLogError(@"Receipt is not pkcs7");
        _validationResult = PEX_RECEIPT_NOT_PKCS7;
        return NO;
    }

    // Check that the container has a signature
    if (_receiptPKCS7.getRaw == NULL || !PKCS7_type_is_signed(_receiptPKCS7.getRaw)) {
        DDLogError(@"Receipt is not signed PKCS7");
        _validationResult = PEX_RECEIPT_NOT_SIGNED_PKCS7;
        return NO;
    }

    // Check that the signed container has actual data
    if (_receiptPKCS7.getRaw->d.sign == NULL || !PKCS7_type_is_data(_receiptPKCS7.getRaw->d.sign->contents)) {
        DDLogError(@"Receipt has no data");
        _validationResult = PEX_RECEIPT_NO_DATA;
        return NO;
    }

    // Load the Apple Root CA (downloaded from https://www.apple.com/certificateauthority/)
    NSURL *appleRootURL = [[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"];
    NSURL *appleCompRootURL = [[NSBundle mainBundle] URLForResource:@"AppleComputerRootCertificate" withExtension:@"cer"];

    PEXX509 * appleRootX509 = [PEXCryptoUtils importCertificateFromDERWrap:[NSData dataWithContentsOfURL:appleRootURL]];
    PEXX509 * appleCompX509 = [PEXCryptoUtils importCertificateFromDERWrap:[NSData dataWithContentsOfURL:appleCompRootURL]];

    // Create a certificate store
    X509_STORE *store = X509_STORE_new();
    X509_STORE_add_cert(store, appleRootX509.getRaw);
    X509_STORE_add_cert(store, appleCompX509.getRaw);
    PEXX509Store * x509Store = [[PEXX509Store alloc] initWith:store];

    // Check the signature
    int result = PKCS7_verify(_receiptPKCS7.getRaw, NULL, x509Store.getRaw, NULL, NULL, 0);
    if (result != 1) {
        _validationResult = PEX_RECEIPT_VERIFICATION_ERROR;
        DDLogError(@"Receipt veritifacation error");
        return NO;
    }

    DDLogVerbose(@"Receipt signature & format validation passed");
    return [self parseReceipt];
}

-(BOOL) parseReceipt {
    // Get a pointer to the ASN.1 payload
    ASN1_OCTET_STRING *octets = _receiptPKCS7.getRaw->d.sign->contents->d.data;
    const unsigned char *ptr = octets->data;
    const unsigned char *end = ptr + octets->length;
    const unsigned char *str_ptr;

    int type = 0, str_type = 0;
    int xclass = 0, str_xclass = 0;
    long length = 0, str_length = 0;

    // Date formatter to handle RFC 3339 dates in GMT time zone
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    // Decode payload (a SET is expected)
    ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
    if (type != V_ASN1_SET) {
        _validationResult = PEX_RECEIPT_UNEXPECTED_FORMAT;
        DDLogError(@"ASN1.SET expected.");
        return NO;
    }

    // Parsing ASN.1 attributes.
    while (ptr < end) {
        ASN1_INTEGER *integer;

        // Parse the attribute sequence (a SEQUENCE is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SEQUENCE) {
            DDLogError(@"ASN1.Sequence expected");
            return NO;
        }

        const unsigned char *seq_end = ptr + length;
        long attr_type = 0;
        long attr_version = 0;

        // Parse the attribute type (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            _validationResult = PEX_RECEIPT_UNEXPECTED_FORMAT;
            DDLogError(@"ASN1.Integer expected - attribute type");
            return NO;
        }

        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_type = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // Parse the attribute version (an INTEGER is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_INTEGER) {
            DDLogError(@"ASN1.Integer expected - attribute version");
            return NO;
        }

        integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
        attr_version = ASN1_INTEGER_get(integer);
        ASN1_INTEGER_free(integer);

        // Check the attribute value (an OCTET STRING is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_OCTET_STRING) {
            _validationResult = PEX_RECEIPT_UNEXPECTED_FORMAT;
            DDLogError(@"ASN1.Octet_string expected - attribute value");
            return NO;
        }

        switch (attr_type) {
            case 2:
                // Bundle identifier
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store both the decoded string and the raw data for later
                    // The raw is data will be used when computing the GUID hash
                    _bundleIdString = [[NSString alloc] initWithBytes:str_ptr length:(NSUInteger)str_length encoding:NSUTF8StringEncoding];
                    _bundleIdData = [[NSData alloc] initWithBytes:(const void *)ptr length:(NSUInteger)length];
                }
                break;

            case 3:
                // Bundle version
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_UTF8STRING) {
                    // We store the decoded string for later
                    _bundleVersionString = [[NSString alloc] initWithBytes:str_ptr length:(NSUInteger)str_length encoding:NSUTF8StringEncoding];
                }
                break;

            case 4:
                // Opaque value
                _opaqueData = [[NSData alloc] initWithBytes:(const void *)ptr length:(NSUInteger)length];
                break;

            case 5:
                // Computed GUID (SHA-1 Hash)
                _hashData = [[NSData alloc] initWithBytes:(const void *)ptr length:(NSUInteger)length];
                break;

            case 21:
                // Expiration date
                str_ptr = ptr;
                ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                if (str_type == V_ASN1_IA5STRING) {
                    // The date is stored as a string that needs to be parsed
                    NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:(NSUInteger)str_length encoding:NSASCIIStringEncoding];
                    _expirationDate = [formatter dateFromString:dateString];
                }
                break;

                // You can parse more attributes...

            default:
                break;
        }

        // Move past the value
        ptr += length;
    }

    // Be sure that all information is present
    if (_bundleIdString == nil ||
            _bundleVersionString == nil ||
            _opaqueData == nil ||
            _hashData == nil)
    {
        DDLogError(@"Receipt is missing some key components");
        _validationResult = PEX_RECEIPT_UNEXPECTED_FORMAT;
        return NO;
    }

    // Check the bundle identifier
    if (![_bundleIdString isEqualToString:[PEXAppVersionUtils bundleIdentifier]]) {
        _validationResult = PEX_RECEIPT_INVALID_TARGET;
        DDLogError(@"Bundle version string does not match: %@", _bundleVersionString);
        return NO;
    }

    // Check the bundle version
    if (![_bundleVersionString isEqualToString:[PEXAppVersionUtils buildString]]) {
        _validationResult = PEX_RECEIPT_INVALID_TARGET;
        DDLogError(@"Bundle version string does not match: %@", _bundleVersionString);
        return NO;
    }

    // Get GUUID.
    NSData *guidData = [PEXReceipt getUUIDData];

    // To hash
    NSMutableData * toHash = [[NSMutableData alloc] init];
    [toHash appendData: guidData];
    [toHash appendData: _opaqueData];
    [toHash appendData: _bundleIdData];
    NSData *computedHashData = [PEXMessageDigest sha1:toHash];
    if (![computedHashData isEqualToData:_hashData]){
        _validationResult = PEX_RECEIPT_INVALID_TARGET;
        DDLogError(@"Receipt hash validation failed");
        return NO;
    }

    return YES;
}

+ (NSData *)getUUIDData {
    UIDevice *device = [UIDevice currentDevice];
    NSUUID *identifier = [device identifierForVendor];
    uuid_t uuid;
    [identifier getUUIDBytes:uuid];
    NSData *guidData = [NSData dataWithBytes:(const void *)uuid length:16];
    return guidData;
}


@end