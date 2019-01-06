//
// Created by Dusan Klinec on 21.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXHmac.h"
#import "openssl/hmac.h"
#import "PEXCanceller.h"
#import "PEXUtils.h"

@interface PEXHmac () {
    BOOL _initialized;
    BOOL _resetCalled;
    HMAC_CTX _ctx;
}

@end

@implementation PEXHmac {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        HMAC_CTX_init(&_ctx);
        _initialized = YES;
        _resetCalled = NO;
    }

    return self;
}

- (instancetype)initWithKey:(NSData *)key {
    self = [self init];
    if (self) {
        [self setKey:key];
    }

    return self;
}

+ (instancetype)initWithKey:(NSData *)key {
    return [[self alloc] initWithKey:key];
}

+ (NSData *)hmac:(NSData *)payload key:(NSData *)key {
    unsigned int mdlen = SHA256_DIGEST_LENGTH;
    NSMutableData * outBuf = [NSMutableData dataWithLength:mdlen];

    HMAC(EVP_sha256(), [key bytes], (int)[key length], [payload bytes], [payload length], [outBuf mutableBytes], &mdlen);
    return [NSData dataWithBytes:[outBuf mutableBytes] length:mdlen];
}

- (int) setKey: (NSData *) key {
    if (!_initialized){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    _resetCalled = YES;
    return HMAC_Init_ex(&_ctx, [key bytes], (int)[key length], EVP_sha256(), NULL);
}

- (int) update: (NSData *) chunk {
    if (!_initialized || !_resetCalled){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    if (chunk == nil){
        return 0;
    }

    return HMAC_Update(&_ctx, (unsigned char const *) [chunk bytes], [chunk length]);
}

- (int) update: (unsigned char const *) data len: (size_t) len {
    if (!_initialized || !_resetCalled){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    if (len <= 0){
        return 0;
    }

    return HMAC_Update(&_ctx, data, len);
}

- (NSData *) final {
    if (!_initialized || !_resetCalled){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    unsigned int mdlen = SHA256_DIGEST_LENGTH;
    NSMutableData * outBuf = [NSMutableData dataWithLength:mdlen];

    int success = HMAC_Final(&_ctx, [outBuf mutableBytes], &mdlen);
    if (success != 1){
        DDLogError(@"HMAC_Final was not successfull");
        return nil;
    }

    return [NSData dataWithBytes:[outBuf mutableBytes] length:mdlen];
}

- (void)destroy {
    if (_initialized){
        HMAC_CTX_cleanup(&_ctx);
        _initialized = NO;
        _resetCalled = NO;
    }
}

- (void)dealloc {
    [self destroy];
}

+ (NSData *)getFileHMACFile:(NSString *)filePath key:(NSData *)key canceller:(id <PEXCanceller>)canceller {
    NSInputStream * is = [NSInputStream inputStreamWithFileAtPath:filePath];
    [is open];

    NSData * dat = [self getFileHMAC:is key:key canceller:canceller];
    [PEXUtils closeSilently:is];
    return dat;
}

+ (NSData *)getFileHMAC:(NSInputStream *)is key:(NSData *)key canceller:(id <PEXCanceller>)canceller {
    PEXHmac * hmac = [PEXHmac initWithKey:key];

    NSData * dat = nil;
    NSMutableData * buffBytes = [NSMutableData dataWithLength:2048];
    uint8_t * bytes = [buffBytes mutableBytes];
    NSInteger read = 0;
    while((read = [is read:bytes maxLength:[buffBytes length]]) > 0){
        [hmac update:bytes len:(NSUInteger) read];
    }

    if (read < 0){
        DDLogError(@"Error occurred during stream read.");
    } else {
        dat = [hmac final];
    }

    [hmac destroy];
    return dat;
}


@end