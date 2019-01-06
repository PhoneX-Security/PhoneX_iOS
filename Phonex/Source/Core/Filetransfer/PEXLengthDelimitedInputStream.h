//
// Created by Dusan Klinec on 25.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"

/**
* Input stream used to read exactly X bytes from underlying input stream and end then.
* Example use case: size delimited protocol buffer message, read exactly X bytes from the stream in message parser,
* no more since there is next message.
*/
@interface PEXLengthDelimitedInputStream : PEXRunLoopInputStream

/**
* Init with sub-stream.
*/
- (id)initWithStream:(NSInputStream *)stream length: (int32_t) length;
@end