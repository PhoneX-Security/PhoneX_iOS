//
//  PEXScryptTest.m
//  Phonex
//
//  Created by Dusan Klinec on 15.10.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "PEXScrypt.h"

@interface PEXScryptTest : XCTestCase

@end

@implementation PEXScryptTest

- (void)testScrypt {
    unsigned char saltB[] = {0x00, 0xcf, 0x42, 0x56, 0x12, 0x13, 0x14, 0x15, 0x16, 0xab, 0x8f, 0x8a};
    NSData * salt = [NSData dataWithBytes:saltB length:12];
    NSData * scrypted01 = [PEXScrypt scrypt:@"passwd" salt:salt N:32768 r:1 p:1 dkLen:32];
    XCTAssert(scrypted01!=nil, "Scrypt hash is nil");
    XCTAssertEqual(32, [scrypted01 length], "Scrypt hash has invalid length");
    DDLogVerbose(@"Base64(scrypt(passwd)) = %@", [scrypted01 base64EncodedStringWithOptions:0]);

    // Consistency test - if there is some problem with pointers, result could be different.
    NSData * scrypted02 = [PEXScrypt scrypt:@"passwd" salt:salt N:32768 r:1 p:1 dkLen:32];
    XCTAssert(scrypted02!=nil, "Scrypt hash is nil");
    XCTAssertEqual(32, [scrypted02 length], "Scrypt hash has invalid length");
    XCTAssert([scrypted02 isEqualToData:scrypted01], "Scrypt hash is not consistent");

    // Change parameter of a computation - input password.
    // Result has do differ. If not - probably a constant value is returned.
    NSData * scrypted03 = [PEXScrypt scrypt:@"password" salt:salt N:32768 r:1 p:1 dkLen:32];
    XCTAssert(scrypted03!=nil, "Scrypt hash is nil");
    XCTAssertEqual(32, [scrypted03 length], "Scrypt hash has invalid length");
    XCTAssert(![scrypted03 isEqualToData:scrypted01], "Scrypt hash of different data must be different");

    // Change parameter of a computation - input password.
    // Result has do differ. If not - probably a constant value is returned.
    NSData * scrypted04 = [PEXScrypt scrypt:@"passwd" salt:salt N:16384 r:1 p:1 dkLen:32];
    XCTAssert(scrypted04!=nil, "Scrypt hash is nil");
    XCTAssertEqual(32, [scrypted04 length], "Scrypt hash has invalid length");
    XCTAssert(![scrypted04 isEqualToData:scrypted01], "Scrypt hash of different data must be different");
    XCTAssert(![scrypted04 isEqualToData:scrypted03], "Scrypt hash of different data must be different");
}

@end
