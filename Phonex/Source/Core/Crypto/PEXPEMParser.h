//
// Created by Dusan Klinec on 04.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXPemChunk : NSObject
    @property(nonatomic) bool success;
    @property(nonatomic) bool hasMoreData;
    @property(nonatomic) NSString * objType;
    @property(nonatomic) NSData * der;
    @property(nonatomic) const char * dataStart;
    @property(nonatomic) const char * dataEnd;
    @property(nonatomic) uint bytesRead;
    @property(nonatomic) uint dataLen;
    @property(nonatomic) uint validDataLen;
@end

@interface PEXPEMParser : NSObject
    @property(nonatomic) int maximalDataSize;
    @property(nonatomic) bool produceDER;

/**
 * Main PEM parsing method.
 * Parses input string in PEM format, allowing plaintext certificate in the file.
 *
 * @param char** PEM source. Each successful invocation of the parser advances
 *  this parameter forward so it skips read entry.
 * @param int length of the input string. Length is shortened of the read entry on success.
 */
-(PEXPemChunk*) parsePEM: (char const **) src len: (int*) len;
-(PEXPemChunk*) parsePEM: (char **) src len: (int*) len doMoveSrc: (BOOL) doMoveSrc;

@end