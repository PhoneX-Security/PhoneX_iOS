//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCertificate.h"
#import "PEXUserPrivate.h"
#import "PEXStpBase.h"
#import "PEXProtocols.h"

@interface PEXStpSimple : PEXStpBase
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) PEXProtocolVersion protocolVersion;

-(NSData *) buildMessage: (NSData *) payload destination: (NSString *) destination ampType: (PEXProtocolType) ampType
              ampVersion: (PEXProtocolVersion) ampVersion error: (NSError **) pError;

@end