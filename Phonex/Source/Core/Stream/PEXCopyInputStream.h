//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXMultipartElement.h"
#import "PEXRunLoopInputStream.h"

/**
* Block to inform about reading progress of the multipart element.
*/
typedef void (^StreamProgressBlock)(NSStream * s, NSInteger read);

/**
* Simple NSInputStream subclass for copying read data to NSData.
*/
@interface PEXCopyInputStream : PEXRunLoopInputStream<NSStreamDelegate>

/**
* Set to YES if you want to copy stream data to buffer.
*/
@property(nonatomic) BOOL copyStream;

/**
* Block for reading progress monitoring.
*/
@property(nonatomic, copy) StreamProgressBlock progressBlock;

/**
* Init with sub-stream.
*/
- (id)initWithStream:(NSInputStream *)stream;

/**
* Returns so far copied stream data.
*/
- (NSData *) getData;
@end