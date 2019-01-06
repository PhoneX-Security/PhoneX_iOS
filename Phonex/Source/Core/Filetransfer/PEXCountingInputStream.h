//
// Created by Dusan Klinec on 21.04.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRunLoopInputStream.h"

/**
* Simple input stream with counting number of read characters.
*/
@interface PEXCountingInputStream : PEXRunLoopInputStream
@property (nonatomic, readonly) NSUInteger bytesRead;

- (id)initWithStream:(NSInputStream *)stream;
@end