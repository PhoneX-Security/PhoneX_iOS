//
// Created by Dusan Klinec on 27.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/pkcs12.h"


@interface PEXPKCS12 : NSObject

- (id) initWith: (PKCS12 *) pkcs12;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (PKCS12*) getRaw;
- (PKCS12 *) setRaw: (PKCS12 *) pkcs12;
@end