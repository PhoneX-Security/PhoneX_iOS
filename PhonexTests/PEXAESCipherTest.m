//
//  PEXAESCipherTest.m
//  Phonex
//
//  Created by Dusan Klinec on 06.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "USAdditions.h"
#import "PEXAESCipher.h"

@interface PEXAESCipherTest : XCTestCase

@end

@implementation PEXAESCipherTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEncryptionDecryptionIdentity {
    NSString * passwd = @"-+123secret123+-";
    NSData * passwdData = [passwd dataUsingEncoding:NSUTF8StringEncoding];

    NSString * toEncrypt = @"Lorem ipsum dolor sit amet";
    NSData * input = [[toEncrypt dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions: 0];

    // Encrypt ciphertext
    NSData * ciphertext = [PEXAESCipher encrypt:input password: passwdData];
    XCTAssert(ciphertext != nil, "Ciphertext is nil");

    //Decrypt ciphertext
    NSData * plaintext = [PEXAESCipher decrypt:ciphertext password:passwdData];
    XCTAssert(plaintext != nil, "Plaintext is nil");
    XCTAssert([plaintext isEqualToData: input],
            "Encryption consistency fail. Decrypt(Encrypt(x)) != x; x=[%@] vs. plain=[%@]",
            [input base64EncodedStringWithOptions:0],
            [plaintext base64EncodedStringWithOptions:0]);
}


@end
