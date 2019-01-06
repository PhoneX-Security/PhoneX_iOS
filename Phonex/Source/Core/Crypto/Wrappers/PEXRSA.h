//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/rsa.h"

@interface PEXRSA : NSObject {

}

- (id) initWith: (RSA *) aRsa;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (RSA*) getRaw;
- (RSA *) setRaw: (RSA *) aRsa;
@end