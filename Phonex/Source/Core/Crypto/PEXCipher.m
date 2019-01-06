//
// Created by Dusan Klinec on 21.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCipher.h"

@interface PEXCipher () {
    EVP_CIPHER_CTX _ctx;
    EVP_CIPHER const * _curCipher;
    int _blockSize;
    int _ivSize;
    int _keySize;
    BOOL _initialized;
    BOOL _encryptMode;
}
@end


@implementation PEXCipher {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialized = YES;
        _curCipher = NULL;
        _blockSize = 0;
        _ivSize = 0;
        _keySize = 0;

        /* Initialise the context */
        EVP_CIPHER_CTX_init(&_ctx);
    }

    return self;
}

- (instancetype)initWithCipher:(struct evp_cipher_st const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv {
    self = [self init];
    if (self) {
        [self setCipher:cipher encrypt:encrypt key:key iv:iv];
    }

    return self;
}

+ (instancetype)cipherWithCipher:(struct evp_cipher_st const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv {
    return [[self alloc] initWithCipher:cipher encrypt:encrypt key:key iv:iv];
}

- (int) setCipher:(EVP_CIPHER const *)cipher encrypt: (BOOL) encrypt key: (NSData *) key iv: (NSData *) iv {
    if (!_initialized){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    _curCipher = cipher;
    _encryptMode = encrypt;
    _blockSize = EVP_CIPHER_block_size(_curCipher);
    _ivSize = EVP_CIPHER_iv_length(_curCipher);
    _keySize = EVP_CIPHER_key_length(_curCipher);

    /* Initialise the encryption operation. IMPORTANT - ensure you use a key
     * and IV size appropriate for your cipher
     * In this example we are using 256 bit AES (i.e. a 256 bit key). The
     * IV size for *most* modes is the same as the block size. For AES this
     * is 128 bits */
    if (encrypt){
        return EVP_EncryptInit_ex(&_ctx, cipher, NULL, [key bytes], [iv bytes]);
    } else {
        return EVP_DecryptInit_ex(&_ctx, cipher, NULL, [key bytes], [iv bytes]);
    }
}

- (size_t) getNeededOutputBufferSize: (size_t) inputLength {
    if (!_initialized || _curCipher == NULL){
        [NSException raise:PEXRuntimeSecurityException format:@"Already destroyed"];
    }

    return ((inputLength / _blockSize) + 3ul) * _blockSize;
}

- (int) update: (unsigned char const *) input len: (NSUInteger) inputLen
        output: (unsigned char *) output outputLen: (int *) outputLen
{
    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    int success = 0;
    if (_encryptMode){
        success = EVP_EncryptUpdate(&_ctx, output, outputLen, input, inputLen);
    } else {
        success = EVP_DecryptUpdate(&_ctx, output, outputLen, input, inputLen);
    }

    return success;
}

- (NSData *) updateToData: (unsigned char const *) input len: (NSUInteger) inputLen {
    // Allocate mutable data large enough to process the input.
    size_t requiredLength = [self getNeededOutputBufferSize:inputLen];
    NSMutableData * mdata = [NSMutableData dataWithLength:requiredLength];
    int realOutLen = 0;

    int success = [self update:input len:inputLen output:[mdata mutableBytes] outputLen:&realOutLen];
    if (success != 1){
        DDLogError(@"Cipher operation failed");
        return nil;
    }

    return [NSData dataWithBytes:[mdata mutableBytes] length:(NSUInteger) realOutLen];
}

- (int) updateAppendData: (unsigned char const *) input len: (NSUInteger) inputLen
                 outData: (NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte
{
    // Calculate if we have enough room in the mutable data. If not, try to inflate it.
    size_t requiredLength = [self getNeededOutputBufferSize:inputLen];
    NSUInteger outDataLen = [outData length];
    NSUInteger valIdxOfFreeByte = *idxOfFreeByte;
    if ((requiredLength + valIdxOfFreeByte) > outDataLen){
        [outData increaseLengthBy:(requiredLength + valIdxOfFreeByte) - outDataLen];
    }

    // Get position of the byte where data can be written. Need to offset data.
    unsigned char * buff = ((unsigned char *) [outData mutableBytes]) + valIdxOfFreeByte;

    int dataWritten = 0;
    int success = [self update:input len:inputLen output:buff outputLen:&dataWritten];
    if (success != 1){
        DDLogError(@"Cipher operation failed");
        return 0;
    }

    *idxOfFreeByte += dataWritten;
    return success;
}

- (int) finalize: (unsigned char *) outBuff outLen: (int *) outLen {
    /* Finalise the encryption. Further ciphertext bytes may be written at
     * this stage.
     */
    int success = 0;
    if (_encryptMode){
        success = EVP_EncryptFinal_ex(&_ctx, outBuff, outLen);
    } else {
        success = EVP_DecryptFinal(&_ctx, outBuff, outLen);
    }

    return success;
}

- (NSData *) finalizeToData {
    // Allocate mutable data large enough to process the input.
    size_t requiredLength = [self getNeededOutputBufferSize:0];
    NSMutableData * mdata = [NSMutableData dataWithLength:requiredLength];
    int realOutLen = 0;

    int success = [self finalize:[mdata mutableBytes] outLen:&realOutLen];
    if (success != 1){
        DDLogError(@"Cipher operation failed");
        return nil;
    }

    return [NSData dataWithBytes:[mdata mutableBytes] length:(NSUInteger) realOutLen];
}

- (int) finalizeAppendData:(NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte
{
// Calculate if we have enough room in the mutable data. If not, try to inflate it.
    size_t requiredLength = [self getNeededOutputBufferSize:0];
    NSUInteger outDataLen = [outData length];
    NSUInteger valIdxOfFreeByte = *idxOfFreeByte;
    if ((requiredLength + valIdxOfFreeByte) > outDataLen){
        [outData increaseLengthBy:(requiredLength + valIdxOfFreeByte) - outDataLen];
    }

    // Get position of the byte where data can be written. Need to offset data.
    unsigned char * buff = ((unsigned char *) [outData mutableBytes]) + valIdxOfFreeByte;

    int dataWritten = 0;
    int success = [self finalize:buff outLen:&dataWritten];
    if (success != 1){
        DDLogError(@"Cipher operation failed");
        return 0;
    }

    *idxOfFreeByte += dataWritten;
    return success;
}

- (void)destroy {
    if (_initialized){
        EVP_CIPHER_CTX_cleanup(&_ctx);
        _initialized = NO;
        _curCipher = NULL;
    }
}

- (void)dealloc {
    [self destroy];
}

@end