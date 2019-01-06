//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/x509.h"

@interface PEXX509 : NSObject<NSCopying, NSCoding> {

}
@property (nonatomic, readonly) X509 * cert;

- (id) initWith: (X509 *) aCrt;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (X509*) getRaw;
- (X509 *) setRaw: (X509 *) aCrt;
@end