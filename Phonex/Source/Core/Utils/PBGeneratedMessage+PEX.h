//
// Created by Dusan Klinec on 11.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeneratedMessage.h"

@class PBCodedOutputStream;

@interface PBGeneratedMessage (PEX)
-(NSData *)writeToCodedNSData;

/**
* Determines serialized size of the message and writes it to the given stream as varint32
* so reader can determine message boundary and parse it properly, separate from next data.
*/
-(void) writeDelimitedSizeToStream: (PBCodedOutputStream *) os;

/**
* Writes RawSInt32 (serialized message size) at first, then the message.
*/
-(NSData *)writeDelimitedToCodedNSData;
@end