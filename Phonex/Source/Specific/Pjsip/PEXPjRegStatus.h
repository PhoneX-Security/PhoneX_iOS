//
// Created by Dusan Klinec on 15.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* PJ registration status
*/
@interface PEXPjRegStatus : NSObject <NSCoding, NSCopying>
@property (nonatomic) NSDate * created;
@property (nonatomic) BOOL registered;
@property (nonatomic) BOOL registeringInProgress;
@property (nonatomic) int expire;
@property (nonatomic) int lastStatusCode;
@property (nonatomic) NSString * lastStatusText;
@property (nonatomic) BOOL ipReregistrationInProgress;

- (NSString *)description;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end