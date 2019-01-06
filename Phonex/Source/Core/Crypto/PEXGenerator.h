//
//  PEXCSRGenerator.h
//  Phonex
//
//  Created by Dusan Klinec on 18.09.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXKeyPair.h"
#import "openssl/rsa.h"
#import "openssl/x509.h"

@interface PEXGenerator : NSObject

/**
 * Generates RSA public-private key-pair with given number of bits.
 */
+(int) generateRSAKeyPair: (int) bits andRSA: (RSA**) rsa;

/**
* Generate DH key pair.
*/
+ (int) generateDhKeyPair: (DH *) dh;

/**
 * Generates custom CSR with specified CN. Public key is taken from pubKey parameter.
 */
+(X509_REQ*) generateCSRWith: (NSString*) CN andPubKey: (RSA*) pubKey;


@end
