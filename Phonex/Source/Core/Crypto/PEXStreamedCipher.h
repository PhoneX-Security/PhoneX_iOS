//
// Created by Dusan Klinec on 29.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXCipher;
@class PEXTransferProgress;
@protocol PEXCanceller;
@class PEXHmac;

/**
* Streamed application of given symmetric cipher.
* This is not a stream cipher!
*
* This helper serves for using PEXCipher object on NSStream objects.
*/
@interface PEXStreamedCipher : NSObject
@property(nonatomic, readonly) PEXCipher * cip;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, copy) cancel_block cancelBlock;
@property(nonatomic) PEXTransferProgress * progressMonitor;
@property(nonatomic, copy) bytes_processed_block progressBlock;
@property(nonatomic, readonly) NSUInteger buffSize;
@property(nonatomic) NSUInteger offset;

/**
* HMAC object to be used to authenticate ciphertext.
*/
@property(nonatomic) PEXHmac * hmac;

- (instancetype)initWithCip:(PEXCipher *)cip;
- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor;
- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor buffSize:(NSUInteger)buffSize;
- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock;
- (instancetype)initWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock buffSize:(NSUInteger)buffSize;
+ (instancetype)cipherWithCip:(PEXCipher *)cip;
+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor;
+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressMonitor:(PEXTransferProgress *)progressMonitor buffSize:(NSUInteger)buffSize;
+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock;
+ (instancetype)cipherWithCip:(PEXCipher *)cip canceller:(id <PEXCanceller>)canceller progressBlock:(bytes_processed_block)progressBlock buffSize:(NSUInteger)buffSize;

-(void) doCipherFileA: (NSString *) fileA os: (NSOutputStream *) os;
-(void) doCipherFileA: (NSString *) fileA fileB: (NSString *) fileB append: (BOOL) append;

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
-(void) doCipher: (NSInputStream *) is os: (NSOutputStream *) os;

/**
* Should be used only for small data pieces.
*/
-(NSData *) doCipher: (NSData *) data;

@end