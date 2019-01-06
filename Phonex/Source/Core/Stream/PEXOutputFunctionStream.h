//
// Created by Dusan Klinec on 02.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopOutputStream.h"

@protocol PEXCanceller;
@protocol PEXStreamFunction;

@interface PEXOutputFunctionStream : PEXRunLoopOutputStream<NSStreamDelegate>
@property(nonatomic, readonly) id<PEXStreamFunction> function;
@property(nonatomic, readonly) NSOutputStream * subStream;
@property(nonatomic, readonly) NSUInteger buffSize;
@property(nonatomic) BOOL multipleSubWritesAllowed;
@property(nonatomic) BOOL closeSubStream;

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream;
- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize;
- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream;
- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize;

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize;
+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream;
+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream buffSize:(NSUInteger)buffSize;
+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSOutputStream *)subStream;

/**
* Call when no more data will be written to the stream so it can be finalized.
*/
-(NSInteger) closeData;

/**
* Write all buffered data to the underlying stream.
*/
- (NSInteger) flush;
@end