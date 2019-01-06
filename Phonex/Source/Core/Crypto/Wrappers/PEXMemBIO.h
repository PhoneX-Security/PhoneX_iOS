//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/bio.h"


@interface PEXMemBIO : NSObject {

}

-(id) initWithNSData: (NSData *) data;
-(int) readDataToMem:(NSData *) src offset:(uint)offset len:(int)len;
-(int) readDataToMem: (NSData *) data;
-(NSData*) exportFromOffset: (uint)offset len:(int)len;
-(NSData*) export;
-(NSString *) exportAsStringFromOffset: (uint)offset len:(int)len;
-(NSString *) exportAsString;
-(BOOL) isAllocated;
-(void) freeBuffer;
-(BIO*) getRaw;

/**
* Attempts to write NSData to the newly created BIO.
* Copies data from NSData to BIO memory buffer.
*/
+(BIO *) NSData2Bio: (NSData*) src offset: (uint64_t) offset len: (int64_t) len;
+(BIO *) NSData2Bio: (NSData*) src;

/**
* Writes BIO data to NSData.
* Data is copied.
*/
+(NSData *) Bio2NSData: (BIO*) src offset: (uint64_t) offset len: (int64_t) len;
+(NSData *) Bio2NSData: (BIO*) src;

@end