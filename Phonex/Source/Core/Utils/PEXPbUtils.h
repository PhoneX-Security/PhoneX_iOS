//
// Created by Dusan Klinec on 25.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPbUtils : NSObject
+ (SInt32) readMessageSize: (NSInputStream *) is;
+ (SInt32) readMessageSize: (NSInputStream *)is bytesRead: (NSInteger *) bytesRead;
+ (SInt32) readRawVarint32: (NSInputStream *) is bytesRead: (NSInteger *) bytesRead;
+ (int8_t) readRawByte: (NSInputStream *) is bytesRead: (NSInteger *) bytesRead;
@end