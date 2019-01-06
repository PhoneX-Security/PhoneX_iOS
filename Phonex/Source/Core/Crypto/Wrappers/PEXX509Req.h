//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/x509.h"

@interface PEXX509Req : NSObject {

}

- (id) initWith: (X509_REQ *) aCrt;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (X509_REQ*) getRaw;
- (X509_REQ *) setRaw: (X509_REQ *) aCrt;
@end