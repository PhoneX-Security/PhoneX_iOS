//
// Created by Dusan Klinec on 21.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXStreamFunction.h"


@interface PEXCipher : NSObject<PEXStreamFunction>
- (instancetype)initWithCipher:(struct evp_cipher_st const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv;
+ (instancetype)cipherWithCipher:(struct evp_cipher_st const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv;

- (int) setCipher:(EVP_CIPHER const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv;
- (size_t) getNeededOutputBufferSize: (size_t) inputLength;
- (int) update: (unsigned char const *) input len: (NSUInteger) inputLen
        output: (unsigned char *) output outputLen: (int *) outputLen;
- (NSData *) updateToData: (unsigned char const *) input len: (NSUInteger) inputLen;
- (int) updateAppendData: (unsigned char const *) input len: (NSUInteger) inputLen
                 outData: (NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte;

- (int) finalize: (unsigned char *) outBuff outLen: (int *) outLen;
- (NSData *) finalizeToData;
- (int) finalizeAppendData:(NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte;

- (void)destroy;
@end