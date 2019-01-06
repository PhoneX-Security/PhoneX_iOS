//
// Created by Dusan Klinec on 31.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"

@protocol PEXCanceller;
@protocol PEXStreamFunction;

@interface PEXInputFunctionStream : PEXRunLoopInputStream<NSStreamDelegate>
@property(nonatomic, readonly) id<PEXStreamFunction> function;
@property(nonatomic, readonly) NSInputStream * subStream;
@property(nonatomic, readonly) NSUInteger buffSize;
@property(nonatomic) BOOL multipleSubReadsAllowed;
@property(nonatomic) BOOL closeSubStream;

- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream;
- (instancetype)initWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize;
- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream;
- (instancetype)initWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize;

+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize;
+ (instancetype)streamWithCanceller:(id <PEXCanceller>)canceller function:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream;
+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream buffSize:(NSUInteger)buffSize;
+ (instancetype)streamWithFunction:(id <PEXStreamFunction>)function subStream:(NSInputStream *)subStream;

@end