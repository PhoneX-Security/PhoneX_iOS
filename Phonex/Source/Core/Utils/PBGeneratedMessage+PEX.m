//
// Created by Dusan Klinec on 11.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PBGeneratedMessage+PEX.h"
#import "CodedOutputStream.h"
#import "PEXUtils.h"


@implementation PBGeneratedMessage (PEX)

- (NSData *)writeToCodedNSData {
    // Output stream
    NSOutputStream * sout = [NSOutputStream outputStreamToMemory];
    [sout open];
    PBCodedOutputStream * out = [PBCodedOutputStream streamWithOutputStream: sout];

    // This workaround is needed if message contains array of objects.
    // It computes serialized size of property that is cached in message
    // object and used during writeToCodedOutputStream. Without this
    // object is incorrectly serialized.
    [self serializedSize];

    // Write to output stream
    [self writeToCodedOutputStream:out];
    [out flush];
    NSData * dat = [PEXUtils getDataFromStream:sout];
    [sout close];
    return dat;
}

- (void)writeDelimitedSizeToStream:(PBCodedOutputStream *)os {
    // Determine serialized size.
    SInt32 size = [self serializedSize];
    // Write message size to the stream.
    [os writeRawVarint32:size];
}

- (NSData *)writeDelimitedToCodedNSData {
    // Output stream
    NSOutputStream * sout = [NSOutputStream outputStreamToMemory];
    [sout open];
    PBCodedOutputStream * out = [PBCodedOutputStream streamWithOutputStream: sout];

    // This workaround is needed if message contains array of objects.
    // It computes serialized size of property that is cached in message
    // object and used during writeToCodedOutputStream. Without this
    // object is incorrectly serialized.
    // Moreover we need here to compute size so it can be prepended to the message
    // so read parser can determine where message ends and stars another / data.
    SInt32 size = [self serializedSize];

    // Write message size to the stream.
    [out writeRawVarint32:size];

    // Write to output stream
    [self writeToCodedOutputStream:out];
    [out flush];
    NSData * dat = [PEXUtils getDataFromStream:sout];
    [sout close];
    return dat;
}


@end