//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/md5.h"
#import "openssl/sha.h"
#import "openssl/ossl_typ.h"
#import <AssetsLibrary/AssetsLibrary.h>

@class PEXX509;
@protocol PEXCanceller;
#define HASH_MD5 1
#define HASH_SHA256 2
#define HASH_SHA512 3
#define HASH_SHA1 4

@interface PEXMessageDigest : NSObject
- (instancetype)initWithHashFunction:(int)hashFunction;
+ (instancetype)digestWithHashFunction:(int)hashFunction;

- (void) setHashFunction: (int) hashFunction;
- (int) update: (NSData *) chunk;
- (int) update: (unsigned char const *) data len: (size_t) len;
- (NSData *) final;
- (void) destroy;

+ (NSData*) sha1:   (NSData *)message;
+ (NSData*) sha256: (NSData *) message;
+ (NSData*) sha512: (NSData *) message;
+ (NSData*) md5:    (NSData *) message;
+ (NSData*) iterativeHash:    (NSData *) message iterations: (unsigned int) iterations digest: (int) digest;

+ (NSData*) sha256Message: (NSString *) message;
+ (NSData*) sha512Message: (NSString *) message;
+ (NSData*) md5Message:    (NSString *) message;

+ (NSString*) bytes2hex: (NSData *) input;
+ (NSString*) bytes2base64: (NSData *) input;
+ (NSString*) base64ToHex: (NSString *) input;

+ (int) getDigestSize: (int) digest;
+ (const EVP_MD *) getDigestFunction: (int) functionIdx;

/*
* Produces a hash representing users certificate in DER form.
* This is the most effective method to produce certificate hash in this API.
*/
+ (NSString *) getCertificateDigestDER: (NSData *) crt;

/**
* Produces a hash representing users certificate.
* Method at first converts it to the DER form what is costly
* so if you have certificate in DER form, use more appropriate API method.
*/
+ (NSString *) getCertificateDigestWrap: (PEXX509 *) crt;

/**
* Produces a hash representing users certificate.
* Method at first converts it to the DER form what is costly
* so if you have certificate in DER form, use more appropriate API method.
*/
+ (NSString *) getCertificateDigest: (X509 *) crt;

/**
* Computes file digest from the file name using streaming read.
*/
+ (NSData *)getFileDigestFile:(NSString *)filePath hashFunction: (int) hashFunction canceller: (id<PEXCanceller>) canceller len: (NSUInteger *) len;
+ (NSData *)getFileDigestURL:(NSURL *)fileURL hashFunction: (int) hashFunction canceller: (id<PEXCanceller>) canceller len: (NSUInteger *) len;
+ (NSData *)getFileDigest:(NSInputStream *)is hashFunction:(int)hashFunction canceller:(id <PEXCanceller>)canceller len: (NSUInteger *) len;
+ (NSData *)getFileDigest:(ALAssetRepresentation *)repr hashFunction:(int)hashFunction canceller:(id <PEXCanceller>)canceller len: (int64_t *) len pErr: (NSError **) pErr;
@end