//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXAmpSimple.h"
#import "PBGeneratedMessage+PEX.h"
#import "PEXUtils.h"
#import "PEXPbMessage.pb.h"

@interface PEXAmpSimple () { }
@property(nonatomic, readwrite) NSNumber * nonce; //Integer
@property(nonatomic, readwrite) NSString * message;
@end

@implementation PEXAmpSimple {

}

- (instancetype)initWithNonce:(NSNumber *)nonce message:(NSString *)message {
    self = [super init];
    if (self) {
        self.nonce = nonce;
        self.message = message;
    }

    return self;
}

+ (instancetype)simpleWithNonce:(NSNumber *)nonce message:(NSString *)message {
    return [[self alloc] initWithNonce:nonce message:message];
}

+(NSData *) buildSerializedMessage: (NSString *) message nonce: (int) nonce {
    return [[self buildMessage:message nonce:nonce] writeToCodedNSData];
}

+(PEXPbAMPSimple *) buildMessage: (NSString *) message nonce: (int) nonce {
    PEXPbAMPSimpleBuilder * builder = [[PEXPbAMPSimpleBuilder alloc] init];

    NSData * compressed = [PEXUtils compressGzip: [message dataUsingEncoding:NSUTF8StringEncoding]];
    [builder setMessage:compressed];
    [builder setNonce:(uint32_t) nonce];

    return [builder build];
}

+(PEXAmpSimple *) loadMessage: (NSData *) serializedAmpSimple {
    PEXPbAMPSimple * ampSimple = [PEXPbAMPSimple parseFromData:serializedAmpSimple];
    NSData * decoded = [PEXUtils decompressGzip:ampSimple.message];

    NSString * msg = nil;
    if (decoded != nil){
        msg = [[NSString alloc] initWithData:decoded encoding:NSUTF8StringEncoding];
    }

    return [PEXAmpSimple simpleWithNonce: (ampSimple.hasNonce ? @(ampSimple.nonce) : nil) message:msg];
}

@end