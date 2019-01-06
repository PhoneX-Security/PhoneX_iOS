//
// Created by Dusan Klinec on 10.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pexpj.h"

@interface PEXPjZrtpInfo : NSObject
@property(nonatomic) pjsua_call_id call_id;
@property(nonatomic) pjmedia_transport * zrtp_tp;

- (instancetype)initWithCall_id:(pjsua_call_id)call_id;
+ (instancetype)infoWithCall_id:(pjsua_call_id)call_id;

- (instancetype)initWithCall_id:(pjsua_call_id)call_id zrtp_tp:(pjmedia_transport *)zrtp_tp;
+ (instancetype)infoWithCall_id:(pjsua_call_id)call_id zrtp_tp:(pjmedia_transport *)zrtp_tp;

@end