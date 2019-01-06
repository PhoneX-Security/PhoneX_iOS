//
// Created by Dusan Klinec on 12.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pexpj.h"

@interface PEXPjZrtpStateInfo : NSObject <NSCoding>
@property(nonatomic) pjsua_call_id call_id;
@property(nonatomic) BOOL secure;
@property(nonatomic) NSString * sas;
@property(nonatomic) NSString * cipher;
@property(nonatomic) BOOL sas_verified;
@property(nonatomic) int zrtp_hash_match;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (NSString *)description;
@end