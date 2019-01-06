//
//  PEXGeneratorTest.m
//  Phonex
//
//  Created by Dusan Klinec on 09.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "openssl/ossl_typ.h"
#import "PEXGenerator.h"
#import "openssl/objects.h"
#import "PEXCryptoUtils.h"

@interface PEXGeneratorTest : XCTestCase

@end

@implementation PEXGeneratorTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testKeyGen {
    RSA * keypair=NULL;
    int result = [PEXGenerator generateRSAKeyPair:1024 andRSA:&keypair];

    XCTAssert(result==1, "Result is not 1, error occurred");
    XCTAssert(keypair!=NULL, "Keypair is null");
    XCTAssert(keypair->p!=NULL, "Private p is null");
    XCTAssert(keypair->q!=NULL, "Private q is null");

    RSA_free(keypair);
    keypair = NULL;
}

- (void)testCSRGenerator {
    // At first, generate key pair to be used for CSR.
    RSA * keypair=NULL;
    int result = [PEXGenerator generateRSAKeyPair:1024 andRSA:&keypair];
    XCTAssert(result==1, "Keygen result is not 1, error occurred");
    XCTAssert(keypair!=NULL, "Keypair is null");

    ASN1_OBJECT * o = NULL;

    // Test CN objects access.
    o = OBJ_txt2obj("CN", 0);
    XCTAssert(o!=NULL);
    ASN1_OBJECT_free(o);

    o = OBJ_txt2obj("emailAddress", 0);
    XCTAssert(o!=NULL);
    ASN1_OBJECT_free(o);

    // Generate CSR.
    X509_REQ * req = [PEXGenerator generateCSRWith:@"test-internal@phone-x.net" andPubKey:keypair];
    XCTAssert(req!=NULL, "CSR is nil");

    // Convert to PEM.
    NSString * csr = [PEXCryptoUtils exportCSRToPEM:req];
    XCTAssert(csr!=nil, "CSR is nil");
    XCTAssert([csr length] > 200, "CSR is too short");
    XCTAssert([csr hasPrefix:@"-----BEGIN CERTIFICATE REQUEST-----"], "Generated CSR seems invalid, no BEGIN part.");
    DDLogVerbose(@"CSR: len=%lld", (uint64_t)  [csr length]);

    X509_REQ_free(req);
    RSA_free(keypair);
    keypair = NULL;
}

@end
