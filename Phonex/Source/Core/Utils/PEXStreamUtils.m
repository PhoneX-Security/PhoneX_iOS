//
// Created by Dusan Klinec on 26.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXStreamUtils.h"
#import "PEXRingBuffer.h"

NSString * const PEXStreamCopyException = @"PEXStreamCopyException";

@implementation PEXStreamUtils {}

+ (PEXStreamCopyResult)copyStreamWithBuffer: (NSUInteger) buffSize is: (NSInputStream *) is os: (NSOutputStream *) os
                                    readCnt: (uint64_t *) read
                                cancelBlock: (cancel_block) cancelBlock
                             bytesReadBlock: (bytes_processed_block) readBlock
                          bytesWrittenBlock: (bytes_processed_block) writtenBlock
{
    BOOL cancelled = NO;

    NSMutableData * bytesBuffer = [NSMutableData dataWithLength: buffSize];
    PEXRingBuffer * ring        = [PEXRingBuffer bufferWithBuffSize: [bytesBuffer length]];
    uint8_t * bytes             = [bytesBuffer mutableBytes];

    BOOL failReading     = NO;
    BOOL streamFinished  = NO;
    NSInteger totalRead  = 0;
    NSInteger totalWrite = 0;
    for( ; ![ring isEmpty] || !streamFinished ; ) {
        if ([ring isEmpty]) {
            [ring resetBufferIfEmpty];
            NSInteger bytesRead = [is read:bytes maxLength:[bytesBuffer length]];
            if (bytesRead < 0) {
                DDLogError(@"Error while unziping a file.");
                failReading = YES;
                break;
            } else if (bytesRead == 0) {
                streamFinished = YES;
            }

            //  Add data to ring buffer.
            NSInteger ringWritten = [ring write:bytes maxLength:(NSUInteger) bytesRead];
            if (ringWritten != bytesRead){
                DDLogError(@"RingWritten != data.length.");
                [NSException raise:PEXStreamCopyException format:@"Ring buffer works wrong."];
            }

            totalRead += bytesRead;
            if (read != NULL){
                *read = (uint64_t) totalRead;
            }

            if (readBlock != nil){
                readBlock((NSInteger) totalRead);
            }
        }

        // If ring is not empty, dump it to the stream.
        if (![ring isEmpty]){
            uint8_t * readBytes = [ring getContiguousReadBuffer];
            NSInteger buffLen = [ring getContiguousReadBufferLen];
            NSInteger streamWritten = [os write:readBytes maxLength:(NSUInteger) buffLen];
            if (streamWritten < 0){
                DDLogError(@"Cannot write data into the file");
                [NSException raise:PEXStreamCopyException format:@"Cannot write data into file."];
                failReading = YES;

            } else if (streamWritten == 0){
                DDLogDebug(@"Writen 0 bytes to the file stream");
            }

            [ring setBytesRead:(NSUInteger)streamWritten];
            totalWrite += streamWritten;

            if (writtenBlock != nil){
                writtenBlock((NSInteger) totalWrite);
            }
        }

        // Was operation cancelled?
        if (cancelBlock != nil && cancelBlock()){
            cancelled = YES;
            break;
        }
    }

    if (cancelled){
        return PEX_STREAM_CANCELLED;
    } else if (failReading){
        return PEX_STREAM_READ_ERROR;
    }

    return PEX_STREAM_COPY_OK;
}

@end