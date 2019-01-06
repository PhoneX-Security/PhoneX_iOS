//
// Created by Dusan Klinec on 20.09.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXScrypt.h"
#import "PEXCryptoUtils.h"
#import "openssl/evp.h"
#import "NSProgress+PEXAsyncUpdate.h"

#define RR(a,b)  (((a) << (b)) | ((unsigned int)(a) >> (32 - (b))))
#define arraycopy(src, srcPos, dst, dstPos, len) memcpy((dst)+(dstPos), (src)+(srcPos), (len))
#define CUR_PROGRESS_ONE_SMIX_UNITS 1000
#define CUR_PROGRESS_ONE_SMIX_STEP 5   // (1000 / 2) / 100
#define CUR_PROGRESS_SMIX_PERCENT_STEP 5

@implementation PEXScrypt {

}
+ (NSData *)scrypt:(NSString *)passwd salt:(NSData *)salt N:(int64_t)N r:(uint)r p:(uint)p dkLen:(uint)dkLen {
    return [self scrypt:passwd salt:salt N:N r:r p:p dkLen:dkLen progress:nil];
}

+ (NSData *)scrypt:(NSString *)passwd salt:(NSData *)salt N:(int64_t)N r:(uint)r p:(uint)p dkLen:(uint)dkLen progress: (NSProgress*) parentProgress {
    if (N < 2 || (N & (N - 1)) != 0){
        [NSException raise:@"IllegalArgumentException" format:@"N must be a power of 2 greater than 1"];
    }

    if (N > NSIntegerMax / 128 / r) {
        [NSException raise:@"IllegalArgumentException" format:@"Parameter N is too large"];
    }

    if (r > NSIntegerMax / 128 / p) {
        [NSException raise:@"IllegalArgumentException" format:@"Parameter r is too large"];
    }

    NSProgress * progress = nil;
    if (parentProgress!=nil) {
        progress = [NSProgress alloc];
        [NSProgress doInitWithParentOnMainSync:progress parent:parentProgress userInfo:nil];
        [progress setProgressOnMain:1+5+5+p*CUR_PROGRESS_ONE_SMIX_UNITS completedCount:0];
    }

    unsigned char * DK = calloc(sizeof(unsigned char), (size_t) dkLen);
    unsigned char * B = calloc(sizeof(unsigned char), (size_t) (128ul * r * p));
    unsigned char * XY = calloc(sizeof(unsigned char), (size_t) (256ul * r));
    unsigned char * V  = calloc(sizeof(unsigned char), (size_t) (128ul * r * N));
    int i;

    if (progress!=nil){
        [progress incProgressOnMain:1];
    }

    [PEXCryptoUtils pbkdf2:B seed:salt withPass:passwd withIterations:1 withOutLen:(p * 128u * r) hash:EVP_sha256()];
    if (progress!=nil){
        [progress incProgressOnMain:5];
    }

    for (i = 0; i < p; i++) {
        [self smix:B Bi:(i * 128u * r) r:r N:N V:V XY:XY internalProgress:progress];
    }

    [PEXCryptoUtils pbkdf2:DK seedUchar:B seedLen:sizeof(B) withPass:passwd withIterations:1 withOutLen:dkLen hash:EVP_sha256()];
    if (progress!=nil){
        [progress incProgressOnMain:5];
    }

    free(B);
    free(XY);
    free(V);
    NSData * toReturn = [NSData dataWithBytes:DK length:dkLen];
    free(DK);

    return toReturn;
}

+ (void)smix:(unsigned char *)B Bi:(int)Bi r:(int)r N:(int64_t)N V:(unsigned char *)V XY:(unsigned char *)XY internalProgress: (NSProgress*) iProgress
{
    int Xi = 0;
    int Yi = 128 * r;
    int i;

    // Progress monitoring - derive 1% from N.
    int64_t percentUnit = iProgress == nil ? -1 : (int64_t) ceil(N / (100.0 / CUR_PROGRESS_SMIX_PERCENT_STEP));
    int64_t curUnits = 0;
    int totalIncrements = 0;

    arraycopy(B, Bi, XY, Xi, 128 * r);

    for (i = 0; i < N; i++) {
        arraycopy(XY, Xi, V, i * (128 * r), 128 * r);
        [self blockmix_salsa8:XY Bi:Xi Yi:Yi r:r];

        // Progress
        if (percentUnit >= 0) {
            curUnits += 1;
            if (curUnits > percentUnit) {
                [iProgress incProgressOnMain:CUR_PROGRESS_ONE_SMIX_STEP * CUR_PROGRESS_SMIX_PERCENT_STEP];
                totalIncrements += CUR_PROGRESS_SMIX_PERCENT_STEP;
                curUnits = 0;
            }
        }
    }

    curUnits = 0;
    for (i = 0; i < N; i++) {
        int j = [self integerify:XY Bi:Xi r:r] & (N - 1);
        [self blockxor:V Si:(j * (128 * r)) D:XY Di:Xi len:(128 * r)];
        [self blockmix_salsa8:XY Bi:Xi Yi:Yi r:r];

        // Progress
        if (percentUnit >= 0) {
            curUnits += 1;
            if (curUnits > percentUnit) {
                [iProgress incProgressOnMain:CUR_PROGRESS_ONE_SMIX_STEP * CUR_PROGRESS_SMIX_PERCENT_STEP];
                totalIncrements += CUR_PROGRESS_SMIX_PERCENT_STEP;
                curUnits = 0;
            }
        }
    }

    arraycopy(XY, Xi, B, Bi, 128 * r);

    // Finish progress.
    if (percentUnit >= 0 && totalIncrements < 200){
        [iProgress incProgressOnMain:(200 - totalIncrements) * CUR_PROGRESS_ONE_SMIX_STEP * CUR_PROGRESS_SMIX_PERCENT_STEP];
    }
}

+ (void)blockmix_salsa8:(unsigned char *)BY Bi:(int)Bi Yi:(int)Yi r:(int)r {
    unsigned char X[64];
    int i;

    arraycopy(BY, Bi + (2 * r - 1) * 64, X, 0, 64);

    for (i = 0; i < 2 * r; i++) {
        [self blockxor:BY Si:(i*64) D:X Di:0 len:64];
        [self salsa20_8:X];
        arraycopy(X, 0, BY, Yi + (i * 64), 64);
    }

    for (i = 0; i < r; i++) {
        arraycopy(BY, Yi + (i * 2) * 64, BY, Bi + (i * 64), 64);
    }

    for (i = 0; i < r; i++) {
        arraycopy(BY, Yi + (i * 2 + 1) * 64, BY, Bi + (i + r) * 64, 64);
    }
}

+ (int)R:(int)a :(int)b {
    return (a << b) | ((unsigned int)a >> (32 - b));
}

+ (void)salsa20_8:(unsigned char *)B {
    int B32[16];
    int x[16];
    int i;

    for (i = 0; i < 16; i++) {
        B32[i]  = (B[i * 4 + 0] & 0xff) << 0;
        B32[i] |= (B[i * 4 + 1] & 0xff) << 8;
        B32[i] |= (B[i * 4 + 2] & 0xff) << 16;
        B32[i] |= (B[i * 4 + 3] & 0xff) << 24;
    }

    memcpy(x, B32, 16 * sizeof(int));

    for (i = 8; i > 0; i -= 2) {
        x[ 4] ^= RR(x[ 0]+x[12], 7);  x[ 8] ^= RR(x[ 4]+x[ 0], 9);
        x[12] ^= RR(x[ 8]+x[ 4],13);  x[ 0] ^= RR(x[12]+x[ 8],18);
        x[ 9] ^= RR(x[ 5]+x[ 1], 7);  x[13] ^= RR(x[ 9]+x[ 5], 9);
        x[ 1] ^= RR(x[13]+x[ 9],13);  x[ 5] ^= RR(x[ 1]+x[13],18);
        x[14] ^= RR(x[10]+x[ 6], 7);  x[ 2] ^= RR(x[14]+x[10], 9);
        x[ 6] ^= RR(x[ 2]+x[14],13);  x[10] ^= RR(x[ 6]+x[ 2],18);
        x[ 3] ^= RR(x[15]+x[11], 7);  x[ 7] ^= RR(x[ 3]+x[15], 9);
        x[11] ^= RR(x[ 7]+x[ 3],13);  x[15] ^= RR(x[11]+x[ 7],18);
        x[ 1] ^= RR(x[ 0]+x[ 3], 7);  x[ 2] ^= RR(x[ 1]+x[ 0], 9);
        x[ 3] ^= RR(x[ 2]+x[ 1],13);  x[ 0] ^= RR(x[ 3]+x[ 2],18);
        x[ 6] ^= RR(x[ 5]+x[ 4], 7);  x[ 7] ^= RR(x[ 6]+x[ 5], 9);
        x[ 4] ^= RR(x[ 7]+x[ 6],13);  x[ 5] ^= RR(x[ 4]+x[ 7],18);
        x[11] ^= RR(x[10]+x[ 9], 7);  x[ 8] ^= RR(x[11]+x[10], 9);
        x[ 9] ^= RR(x[ 8]+x[11],13);  x[10] ^= RR(x[ 9]+x[ 8],18);
        x[12] ^= RR(x[15]+x[14], 7);  x[13] ^= RR(x[12]+x[15], 9);
        x[14] ^= RR(x[13]+x[12],13);  x[15] ^= RR(x[14]+x[13],18);
    }

    for (i = 0; i < 16; ++i) B32[i] = x[i] + B32[i];

    for (i = 0; i < 16; i++) {
        B[i * 4 + 0] = (unsigned char) (B32[i] >> 0  & 0xff);
        B[i * 4 + 1] = (unsigned char) (B32[i] >> 8  & 0xff);
        B[i * 4 + 2] = (unsigned char) (B32[i] >> 16 & 0xff);
        B[i * 4 + 3] = (unsigned char) (B32[i] >> 24 & 0xff);
    }
}

+ (void)blockxor:(unsigned char *)S Si:(int)Si D:(unsigned char *)D Di:(int)Di len:(int)len {
    for (int i = 0; i < len; i++) {
        D[Di + i] ^= S[Si + i];
    }
}

+ (int)integerify:(unsigned char *)B Bi:(int)Bi r:(int)r {
    int n;

    Bi += (2 * r - 1) * 64;

    n  = (B[Bi + 0] & 0xff) << 0;
    n |= (B[Bi + 1] & 0xff) << 8;
    n |= (B[Bi + 2] & 0xff) << 16;
    n |= (B[Bi + 3] & 0xff) << 24;

    return n;
}

@end