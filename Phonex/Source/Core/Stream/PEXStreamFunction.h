//
// Created by Dusan Klinec on 30.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXStreamFunction <NSObject>
/**
* Returns minimal amount of memory that is this function able to process to produce some output.
* E.g., for crypto functions this may be size of the cipher block.
*/
- (int) minimalReadChunkSize;

/**
* Required size of the output buffer required to store result after processing given input data.
* E.g., for ciphers the padding block may be appended to reader has to count with this.
* Returned length has to be safe boundary. i.e., after allocating such buffer and calling update function
* there must not occur an overflow.
*
* If 0 is passed then there must be enough space for result of finalize() method.
*/
- (size_t) getNeededOutputBufferSize: (size_t) inputLength;

/**
* Basic function for processing input data to output data.
*/
- (int) update: (unsigned char const *) input len: (NSUInteger) inputLen
        output: (unsigned char *) output outputLen: (int *) outputLen;

/**
* Tell the function to finalize processing, i.e. all data was already processed.
* E.g., for ciphers this may cause writing additional padding data
*/
- (int) finalize: (unsigned char *) outBuff outLen: (int *) outLen;

@optional
/**
* Data processing function returning result as NSData.
*/
- (NSData *) updateToData: (unsigned char const *) input len: (NSUInteger) inputLen;

/**
* Data processing function, result is appended to the outData buffer and idxOfFreeByte is set appropriately.
*/
- (int) updateAppendData: (unsigned char const *) input len: (NSUInteger) inputLen
                 outData: (NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte;

/**
* Final block is returned as NSData.
*/
- (NSData *) finalizeToData;

/**
* Final block is appended to the outData buffer.
*/
- (int) finalizeAppendData:(NSMutableData *) outData idxOfFreeByte: (NSUInteger *) idxOfFreeByte;

@end