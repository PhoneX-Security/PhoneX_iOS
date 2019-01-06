//
// Created by Dusan Klinec on 20.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXScrypt : NSObject

/**
 * Pure Java implementation of the <a href="http://www.tarsnap.com/scrypt/scrypt.pdf"/>scrypt KDF</a>.
 *
 * @param passwd    Password.
 * @param salt      Salt.
 * @param N         CPU cost parameter.
 * @param r         Memory cost parameter.
 * @param p         Parallelization parameter.
 * @param dkLen     Intended length of the derived key.
 *
 * @return The derived key.
 *
 * @throws GeneralSecurityException when HMAC_SHA256 is not available.
 */
+(NSData*) scrypt: (NSString *) passwd salt:(NSData *) salt N: (int64_t) N r: (uint) r p: (uint) p dkLen: (uint) dkLen progress: (NSProgress*) parentProgress;
+(NSData*) scrypt: (NSString *) passwd salt:(NSData *) salt N: (int64_t) N r: (uint) r p: (uint) p dkLen: (uint) dkLen;

+(void) smix:(unsigned char *)B Bi:(int)Bi r:(int)r N:(int64_t)N V:(unsigned char *)V XY:(unsigned char *)XY internalProgress: (NSProgress*) iProgress;
+(void) blockmix_salsa8: (unsigned char *) BY Bi: (int) Bi Yi: (int) Yi r: (int) r;
+(int) R: (int) a : (int) b;
+(void) salsa20_8: (unsigned char *) B;
+(void) blockxor: (unsigned char *) S Si: (int) Si D: (unsigned char *) D Di: (int) Di len: (int) len;
+(int) integerify: (unsigned char *) B Bi: (int) Bi r: (int) r;

@end