//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXStpProcessingResult.h"
#import "PEXProtocols.h"

@protocol PEXStp <NSObject>

+(PEXProtocolType) getProtocolType;
+(PEXProtocolVersion) getProtocolVersion;
-(NSData*) buildMessage: (NSData*) payload destination: (NSString*) destination ampType: (PEXProtocolType) ampType ampVersion: (PEXProtocolVersion) ampVersion error: (NSError **) pError;
-(PEXStpProcessingResult*) readMessage: (NSData *) serializedStpMessage stpType: (int) stpType stpVersion: (int) stpVersion;
-(void) setVersion: (PEXProtocolVersion) transportProtocolVersion;

@end