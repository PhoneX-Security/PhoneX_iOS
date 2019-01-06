//
// Created by Dusan Klinec on 25.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPbUtils.h"


@implementation PEXPbUtils {

}

+ (SInt32)readMessageSize:(NSInputStream *)is {
    return [self readMessageSize:is bytesRead:NULL];
}

+ (SInt32) readMessageSize: (NSInputStream *)is bytesRead: (NSInteger *) bytesRead {
    if (is == nil){
        DDLogError(@"InputStream is nil");
        return -1;
    }

    NSInteger bytes = 0;
    if ([is streamStatus] == NSStreamStatusNotOpen){
        DDLogVerbose(@"Stream is not opened, trying to open");
        [is open];
    }

    SInt32 size =  [self readRawVarint32:is bytesRead:&bytes];
    if (bytesRead != NULL){
        *bytesRead = bytes;
    }

    return size;
}

+ (SInt32) readRawVarint32: (NSInputStream *) is bytesRead: (NSInteger *) bytesRead {
    int8_t tmp = [self readRawByte: is bytesRead:bytesRead];
    if (tmp >= 0) {
        return tmp;
    }
    SInt32 result = tmp & 0x7f;
    if ((tmp = [self readRawByte: is bytesRead:bytesRead]) >= 0) {
        result |= tmp << 7;
    } else {
        result |= (tmp & 0x7f) << 7;
        if ((tmp = [self readRawByte: is bytesRead:bytesRead]) >= 0) {
            result |= tmp << 14;
        } else {
            result |= (tmp & 0x7f) << 14;
            if ((tmp = [self readRawByte: is bytesRead:bytesRead]) >= 0) {
                result |= tmp << 21;
            } else {
                result |= (tmp & 0x7f) << 21;
                result |= (tmp = [self readRawByte: is bytesRead:bytesRead]) << 28;
                if (tmp < 0) {
                    // Discard upper 32 bits.
                    for (int i = 0; i < 5; i++) {
                        if ([self readRawByte: is bytesRead:bytesRead] >= 0) {
                            return result;
                        }
                    }
                    @throw [NSException exceptionWithName:@"InvalidProtocolBuffer" reason:@"malformedVarint" userInfo:nil];
                }
            }
        }
    }
    return result;
}

/**
* Read one byte from the input.
*
* @throws InvalidProtocolBufferException The end of the stream or the current
*                                        limit was reached.
*/
+ (int8_t) readRawByte: (NSInputStream *) is bytesRead: (NSInteger *) bytesRead {
    uint8_t toReturn = 0;
    NSInteger read = [is read:&toReturn maxLength:1];
    if (read < 0){
        DDLogWarn(@"Stream reading error");
        return -1;
    }

    if (read == 0){
        return -1;
    }

    if (bytesRead != NULL){
        *bytesRead += read;
    }

    return (int8_t) toReturn;
}



@end