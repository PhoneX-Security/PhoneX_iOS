//
// Created by Dusan Klinec on 14.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPKCS7 : NSObject

- (id) initWith: (PKCS7 *) pkcs7;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (PKCS7*) getRaw;
- (PKCS7 *) setRaw: (PKCS7 *) pkcs7;
@end