//
// Created by Dusan Klinec on 11.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/ossl_typ.h"

@interface PEXEVPPKey : NSObject {

}

- (id) initWith: (EVP_PKEY *) aKey;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (EVP_PKEY*) getRaw;
- (EVP_PKEY *) setRaw: (EVP_PKEY *) aKey;
@end