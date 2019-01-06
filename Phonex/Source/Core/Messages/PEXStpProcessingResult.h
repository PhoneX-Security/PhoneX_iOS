//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXStpProcessingResult : NSObject

@property(nonatomic) int ampVersion;
@property(nonatomic) int ampType;
@property(nonatomic) NSNumber * sequenceNumber; // Integer
@property(nonatomic) NSNumber * nonce; // Integer
@property(nonatomic) uint64_t sendDate;
@property(nonatomic) NSString * sender;
@property(nonatomic) NSString * destination;

@property(nonatomic) BOOL signatureValid;
@property(nonatomic) BOOL hmacValid;

@property(nonatomic) NSData * payload;


@end