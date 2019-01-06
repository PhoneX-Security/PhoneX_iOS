//
// Created by Dusan Klinec on 19.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXMessageDigest.h"
#import "PEXX509.h"
#import "PEXCryptoUtils.h"
#import "openssl/md5.h"
#import "PEXUtils.h"
#import "PEXCanceller.h"

@interface PEXMessageDigest () {
    BOOL _initialized;
    int _hashFunction;
    EVP_MD_CTX _ctx;
}

@end

@implementation PEXMessageDigest {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialized = YES;
        _hashFunction = -1;
        EVP_MD_CTX_init(&_ctx);
    }

    return self;
}

- (instancetype)initWithHashFunction:(int)hashFunction {
    self = [self init];
    if (self) {
        [self setHashFunction:hashFunction];
    }

    return self;
}

+ (instancetype)digestWithHashFunction:(int)hashFunction {
    return [[self alloc] initWithHashFunction:hashFunction];
}

- (void) setHashFunction: (int) hashFunction {
    if (hashFunction != HASH_MD5
            && hashFunction != HASH_SHA256
            && hashFunction != HASH_SHA512
            && hashFunction != HASH_SHA1){
        [NSException raise:PEXRuntimeSecurityException format:@"Unknown hash function: %d", hashFunction];
    }

    if (!_initialized){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    _hashFunction = hashFunction;
    EVP_DigestInit_ex(&_ctx, [PEXMessageDigest getDigestFunction:hashFunction], NULL);
}

- (int) update: (NSData *) chunk {
    if (!_initialized || _hashFunction == -1){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    if (chunk == nil){
        return 0;
    }

    return EVP_DigestUpdate(&_ctx, (unsigned char const *) [chunk bytes], [chunk length]);
}

- (int) update: (unsigned char const *) data len: (size_t) len {
    if (!_initialized || _hashFunction == -1){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    if (len <= 0){
        return 0;
    }

    return EVP_DigestUpdate(&_ctx, data, len);
}

- (NSData *) final {
    if (!_initialized || _hashFunction == -1){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    unsigned int mdlen = (unsigned int) [PEXMessageDigest getDigestSize:_hashFunction];
    NSMutableData * outBuf = [NSMutableData dataWithLength:mdlen];

    int success = EVP_DigestFinal_ex(&_ctx, [outBuf mutableBytes], &mdlen);
    if (success != 1){
        DDLogError(@"EVP_DigestFinal_ex was not successfull");
        return nil;
    }

    return [NSData dataWithBytes:[outBuf mutableBytes] length:mdlen];
}

- (void) destroy {
    if (_initialized){
        EVP_MD_CTX_cleanup(&_ctx);
        _initialized = NO;
        _hashFunction = -1;
    }
}

- (void)dealloc {
    [self destroy];
}

+ (NSData *)md5Message:(NSString *)message {
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    return [PEXMessageDigest md5:data];
}

+ (NSData *)sha512Message:(NSString *)message {
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    return [PEXMessageDigest sha512:data];
}

+ (NSData *)sha256Message:(NSString *)message {
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    return [PEXMessageDigest sha256:data];
}

+ (NSData *)md5:(NSData *)message {
    unsigned char md[MD5_DIGEST_LENGTH];
    MD5([message bytes], [message length], md);

    return [NSData dataWithBytes:md length:MD5_DIGEST_LENGTH];
}

+ (NSData *)sha512:(NSData *)message {
    unsigned char md[SHA512_DIGEST_LENGTH];
    SHA512([message bytes], [message length], md);

    return [NSData dataWithBytes:md length:SHA512_DIGEST_LENGTH];
}

+ (NSData *)sha1:(NSData *)message {
    unsigned char md[SHA_DIGEST_LENGTH];
    SHA1([message bytes], [message length], md);

    return [NSData dataWithBytes:md length:SHA_DIGEST_LENGTH];
}

+ (NSData *)sha256:(NSData *)message {
    unsigned char md[SHA256_DIGEST_LENGTH];
    SHA256([message bytes], [message length], md);

    return [NSData dataWithBytes:md length:SHA256_DIGEST_LENGTH];
}

+ (NSString *)bytes2hex:(NSData *)input {
    NSMutableString * sb = [NSMutableString stringWithCapacity: [input length] * 2];
    const uint64_t len = [input length];
    const unsigned char * bytes = [input bytes];
    for(uint64_t i=0; i<len; i++){
        if (((int)bytes[i] & 0xff) < 0x10){
            [sb appendString:@"0"];
        }
        [sb appendFormat:@"%x", (bytes[i] & 0xff)];
    }

    return [NSString stringWithString: sb];
}

+ (NSString *)bytes2base64:(NSData *)input {
    return [input base64EncodedStringWithOptions:0];
}

+ (NSString *)base64ToHex:(NSString *)input {
    if (input == nil){
        return nil;
    }

    NSData * decodedData = [[NSData alloc] initWithBase64EncodedString:input options:0];
    if (decodedData == nil){
        return nil;
    }

    return [self bytes2hex:decodedData];
}


+ (int)getDigestSize:(int)digest {
    switch(digest){
        case HASH_MD5: return MD5_DIGEST_LENGTH;
        case HASH_SHA256: return SHA256_DIGEST_LENGTH;
        case HASH_SHA512: return SHA512_DIGEST_LENGTH;
        default: return -1;
    }
}

+ (const EVP_MD *) getDigestFunction: (int) functionIdx {
    switch(functionIdx){
        case HASH_MD5: return EVP_md5();
        case HASH_SHA256: return EVP_sha256();
        case HASH_SHA512: return EVP_sha512();
        case HASH_SHA1:   return EVP_sha1();
        default: return NULL;
    }
}

+ (NSData *)iterativeHash:(NSData *)message iterations:(unsigned int)iterations digest:(int)digest {
    if (iterations==0){
        return [NSData dataWithData:message];
    }

    const int digestSize = [self getDigestSize:digest];
    if (digestSize<=0){
        [NSException raise:NSInvalidArgumentException format:@"Invalid digest size"];
    }

    // Two buffers for message digest, [ MD1 | MD2 ]
    unsigned char md[2*digestSize];

    // First iteration - message will have only digest size.
    switch(digest){
        case HASH_MD5:
            MD5([message bytes], [message length], md);
            break;
        case HASH_SHA256:
            SHA256([message bytes], [message length], md);
            break;
        case HASH_SHA512:
            SHA512([message bytes], [message length], md);
            break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Unknown hash value"];
    }

    // Additional iterations, now input and output have the same size.
    unsigned long long j=0;
    unsigned int iterationsLeft = iterations-1;
    for(; iterationsLeft > 0; j++, iterationsLeft--){
        unsigned char * src = ((j&1) == 0)? md            : md+digestSize;
        unsigned char * dst = ((j&1) == 0)? md+digestSize : md;
        switch(digest){
            case HASH_MD5:
                MD5(src, digestSize, dst);
                break;
            case HASH_SHA256:
                SHA256(src, digestSize, dst);
                break;
            case HASH_SHA512:
                SHA512(src, digestSize, dst);
                break;
        }
    }

    // Return the digest buffer, depending on the parity of number of iterations,
    // return first or second part of the buffer.
    return [NSData dataWithBytes:(((j&1) == 0)? md : md+digestSize) length:digestSize];
}

+ (NSString *)getCertificateDigestDER:(NSData *)crt {
    return [self bytes2hex: [self sha512:crt]];
}

+ (NSString *)getCertificateDigestWrap:(PEXX509 *)crt {
    return [self getCertificateDigest: crt == nil ? nil : crt.getRaw];
}

+ (NSString *)getCertificateDigest:(X509 *)crt {
    // At first has to export to DER, then hash.
    NSData * der = [PEXCryptoUtils exportCertificateToDER:crt];
    if (der==nil){
        return nil;
    }

    return [self getCertificateDigestDER:der];
}

+ (NSData *)getFileDigestFile:(NSString *)filePath hashFunction: (int) hashFunction canceller: (id<PEXCanceller>) canceller len: (NSUInteger *) len {
    NSInputStream * is = [NSInputStream inputStreamWithFileAtPath:filePath];
    [is open];

    NSData * dat = [self getFileDigest:is hashFunction:hashFunction canceller:canceller len:len];
    [PEXUtils closeSilently:is];
    return dat;
}

+ (NSData *)getFileDigestURL:(NSURL *)fileURL hashFunction: (int) hashFunction canceller: (id<PEXCanceller>) canceller len: (NSUInteger *) len {
    NSInputStream * is = [NSInputStream inputStreamWithURL:fileURL];
    [is open];

    NSData * dat = [self getFileDigest:is hashFunction:hashFunction canceller:canceller len:len];
    [PEXUtils closeSilently:is];
    return dat;
}

+ (NSData *)getFileDigest:(NSInputStream *)is hashFunction:(int)hashFunction canceller:(id <PEXCanceller>)canceller len: (NSUInteger *) len {
    PEXMessageDigest * dig = [PEXMessageDigest digestWithHashFunction:hashFunction];

    NSData * dat = nil;
    NSMutableData * buffBytes = [NSMutableData dataWithLength:2048];
    uint8_t * bytes = [buffBytes mutableBytes];
    NSInteger read = 0;
    NSUInteger length = 0;
    while((read = [is read:bytes maxLength:[buffBytes length]]) > 0){
        [dig update:bytes len:(NSUInteger) read];
        length += read;
    }

    if (read < 0){
        DDLogError(@"Error occurred during stream read.");
        return nil;
    } else {
        dat = [dig final];
    }

    if (len != NULL){
        *len = length;
    }

    [dig destroy];
    return dat;
}

+ (NSData *)getFileDigest:(ALAssetRepresentation *)repr hashFunction:(int)hashFunction canceller:(id <PEXCanceller>)canceller len: (int64_t *) len pErr: (NSError **) pErr {
    PEXMessageDigest * dig = [PEXMessageDigest digestWithHashFunction:hashFunction];

    NSData * dat = nil;
    NSMutableData * buffBytes = [NSMutableData dataWithLength:8192];
    uint8_t * bytes = [buffBytes mutableBytes];
    NSInteger read = 0;
    int64_t length = [repr size];
    if (length < 0){
        DDLogError(@"Size is smaller than 0, repr: %@", repr);
        return nil;
    }

    NSError * err = nil;
    for(; read < length ;){
        NSUInteger curRead = [repr getBytes:bytes fromOffset:read length:[buffBytes length] error:&err];
        if (err != nil || curRead == 0){
            DDLogError(@"Error in reading file for hash, err=%@", err);
            if (pErr != NULL){
                *pErr = err;
            }
        }

        [dig update:bytes len:(NSUInteger) curRead];
        read += curRead;
    }

    if (len != NULL){
        *len = length;
    }

    dat = [dig final];
    [dig destroy];
    return dat;
}


@end