//
// Created by Dusan Klinec on 29.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXStreamedCipher.h"
#import "PEXCancelledException.h"
#import "PEXCipher.h"
#import "PEXCanceller.h"
#import "PEXTransferProgress.h"
#import "PEXIOException.h"
#import "PEXUtils.h"
#import "PEXHmac.h"

@interface PEXStreamedCipher() {}
@property(nonatomic) PEXCipher * cip;
@property(nonatomic) NSUInteger buffSize;
@end

@implementation PEXStreamedCipher {}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cip = nil;
        self.canceller = nil;
        self.progressMonitor = nil;
        self.buffSize = 2048;
        self.hmac = nil;
    }

    return self;
}

- (instancetype)initWithCip:(PEXCipher *)cip {
    self = [self init];
    if (self) {
        self.cip = cip;
    }

    return self;
}

- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor {
    self = [self init];
    if (self) {
        self.cip = cip;
        self.canceller = canceller;
        self.progressMonitor = progressMonitor;
    }

    return self;
}

- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor buffSize:(NSUInteger)buffSize {
    self = [self init];
    if (self) {
        self.cip = cip;
        self.canceller = canceller;
        self.progressMonitor = progressMonitor;
        self.buffSize = buffSize;
    }

    return self;
}

- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock {
    self = [self init];
    if (self) {
        self.cip = cip;
        self.canceller = canceller;
        self.progressBlock = progressBlock;
    }

    return self;
}

- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock buffSize:(NSUInteger)buffSize {
    self = [super init];
    if (self) {
        self.cip = cip;
        self.canceller = canceller;
        self.progressBlock = progressBlock;
        self.buffSize = buffSize;
    }

    return self;
}

+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithCip:cip canceller:canceller progressBlock:progressBlock buffSize:buffSize];
}

+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock {
    return [[self alloc] initWithCip:cip canceller:canceller progressBlock:progressBlock];
}

+ (instancetype)cipherWithCip:(PEXCipher *)cip {
    return [[self alloc] initWithCip:cip];
}

+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor {
    return [[self alloc] initWithCip:cip canceller:canceller progressMonitor:progressMonitor];
}

+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor buffSize:(NSUInteger)buffSize {
    return [[self alloc] initWithCip:cip canceller:canceller progressMonitor:progressMonitor buffSize:buffSize];
}

-(void) doCipherFileA: (NSString *) fileA os: (NSOutputStream *) os{
    NSInputStream * fisA = [NSInputStream inputStreamWithFileAtPath:fileA];
    [fisA open];
    [self doCipher:fisA os:os];
    [PEXUtils closeSilently:fisA];
}

-(void) doCipherFileA: (NSString *) fileA fileB: (NSString *) fileB append: (BOOL) append {
    NSInputStream * fisA = [NSInputStream inputStreamWithFileAtPath:fileA];
    NSOutputStream * fosB = [NSOutputStream outputStreamToFileAtPath:fileB append:append];
    [fisA open];
    [fosB open];

    [self doCipher:fisA os:fosB];

    [PEXUtils closeSilently:fisA];
    [PEXUtils closeSilently:fosB];
}

/**
* Streamed application of the given cipher.
*
* @param is
* @param os
* @param cip
* @param close
* @throws IOException
* @throws PEXCancelledException
*/
-(void) doCipher: (NSInputStream *) is os: (NSOutputStream *) os {
    BOOL cancelled  = NO;
    BOOL finalizing = NO;
    long absBytes   = 0;
    NSInteger numBytes    = 0;

    NSMutableData * bytesBuffer = [[NSMutableData alloc] initWithLength:_buffSize];
    NSMutableData * bytesBufferEnc = [[NSMutableData alloc] initWithLength:[_cip getNeededOutputBufferSize:_buffSize]];
    uint8_t * bytes = [bytesBuffer mutableBytes];
    uint8_t * bytesEnc = [bytesBufferEnc mutableBytes];

    [PEXUtils dropFirstN:is n:_offset c:^BOOL {
        return [self isCancelled];
    }];

    while (!finalizing) {
        int outputLen = 0;

        // Cancelled ?
        if (_canceller != nil && [_canceller isCancelled]){
            cancelled = YES;
            break;
        }

        // Read some bytes to the buffer.
        numBytes = [is read:bytes maxLength:[bytesBuffer length]];
        if (numBytes < 0){
            @throw [PEXIOException exceptionWithName:PEXRuntimeException reason:@"Input stream read error" userInfo:nil];
        } else if (numBytes == 0){
            // No more data to write, finalize encryption by writing last block (padding).
            [_cip finalize:bytesEnc outLen:&outputLen];
            if (_hmac != nil && outputLen > 0){
                [_hmac update:bytesEnc len:(NSUInteger) outputLen];
            }
            finalizing = YES;
        } else {
            // Perform encryption step.
            [_cip update:bytes len:(NSUInteger) numBytes output:bytesEnc outputLen:&outputLen];
            if (_hmac != nil && outputLen > 0){
                [_hmac update:bytesEnc len:(NSUInteger) outputLen];
            }
        }
        absBytes += numBytes;

        // If this step did not produce any output data, continue.
        if (outputLen <= 0){
            continue;
        }

        // Write given buffer to the underlying stream.
        NSInteger numBytesWritten = 0;
        NSInteger numBytesWrittenTotal = 0;
        while (numBytesWrittenTotal < outputLen)
        {
            numBytesWritten = [os write:bytesEnc + numBytesWrittenTotal maxLength:(NSUInteger)(outputLen - numBytesWrittenTotal)];
            if (numBytesWritten < 0){
                @throw [PEXIOException exceptionWithName:PEXRuntimeException reason:@"Output stream read error" userInfo:nil];
            } else if (numBytesWritten == 0){
                // bytesEnc buffer was successfully written.
                break;
            }

            // Cancelled ?
            if ([self isCancelled]){
                cancelled = YES;
                break;
            }

            numBytesWrittenTotal += numBytesWritten;
        }

        if (cancelled){
            break;
        }

        // Progress ?
        if (_progressMonitor != nil){
            [_progressMonitor updateTxProgress:@(absBytes)];
        }

        if (_progressBlock != nil){
            _progressBlock(absBytes);
        }
    }

    // If cancelled, throw exception to inform caller about unusual situation.
    if (cancelled){
        @throw [PEXCancelledException exceptionWithName:PEXOperationCancelledExceptionString reason:@"stream encryption cancelled" userInfo:nil];
    }
}

/**
* Bulk given cipher.
*
* @param is
* @param os
* @param cip
* @param close
* @throws IOException
* @throws PEXCancelledException
*/
-(NSData *) doCipher: (NSData *) data {
          NSUInteger absBytes = 0;
    const NSUInteger dataLen  = [data length];
    uint8_t const * bytes = [data bytes];

    NSMutableData * bytesBufferEnc = [[NSMutableData alloc] initWithLength:[_cip getNeededOutputBufferSize:dataLen]];
    uint8_t * bytesEnc = [bytesBufferEnc mutableBytes];

    int outputLen = 0;

    // No more data to write, finalize encryption by writing last block (padding).
    [_cip update:bytes len:dataLen output:bytesEnc outputLen:&outputLen];
    absBytes += outputLen;
    [_cip finalize:bytesEnc + absBytes outLen:&outputLen];
    absBytes += outputLen;

    return [NSData dataWithBytes:bytesEnc length:(NSUInteger) absBytes];
}

-(BOOL) isCancelled {
    return (_canceller != nil && _canceller.isCancelled) || (_cancelBlock != nil && _cancelBlock());
}

-(void) checkIfCancelled {
    if ([self isCancelled]){
        [PEXCancelledException raise:PEXOperationCancelledExceptionString format:@"Cancelled"];
    }
}

// TODO: implement runlooped variant.
// It would have to store HasSpaceAvailable && HasBytesAvailable events into
// pending events mask in case
//  a) the reading buffer is full, there is no room to place new read data to, read is postponed until there is some
//     room in the reading buffer.
//  b) there is HasSpaceAvailable but there is empty write buffer. Need to be set to pending so when new data in write
//     buffer fills.

@end