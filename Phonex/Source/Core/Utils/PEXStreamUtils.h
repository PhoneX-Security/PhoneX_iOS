//
// Created by Dusan Klinec on 26.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PEX_STREAM_COPY_OK,
    PEX_STREAM_READ_ERROR,
    PEX_STREAM_WRITE_ERROR,
    PEX_STREAM_CANCELLED,
} PEXStreamCopyResult;

FOUNDATION_EXPORT NSString * const PEXStreamCopyException;

@interface PEXStreamUtils : NSObject
+(PEXStreamCopyResult) copyStreamWithBuffer: (NSUInteger) buffSize is: (NSInputStream *) is os: (NSOutputStream *) os
                                    readCnt: (uint64_t *) read
                                cancelBlock: (cancel_block) cancelBlock
                             bytesReadBlock: (bytes_processed_block) readBlock
                          bytesWrittenBlock: (bytes_processed_block) writtenBlock;
@end