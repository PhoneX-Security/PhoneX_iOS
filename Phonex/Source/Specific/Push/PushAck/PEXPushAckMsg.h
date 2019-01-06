//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushAckPart;

/**
 * Ack request to be sent to the push server.
 * Contains individual push messages to be ACKed.
 *
 * Sent to push server to let him know we received
 * and processed given push messages so it does not push them again.
 */
@interface PEXPushAckMsg : NSObject <NSCoding, NSCopying>

/**
* Array of PEXPushAckPart.
*/
@property(nonatomic) NSMutableArray * acks;
@property(nonatomic) long tstamp;

-(void) addPart: (PEXPushAckPart *) part;
-(void) clear;
- (NSMutableDictionary *)getSerializationBase;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end