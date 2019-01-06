//
// Created by Dusan Klinec on 10.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjZrtpInfo.h"


@implementation PEXPjZrtpInfo {

}
- (instancetype)initWithCall_id:(pjsua_call_id)call_id {
    self = [super init];
    if (self) {
        self.call_id = call_id;
    }

    return self;
}

- (instancetype)initWithCall_id:(pjsua_call_id)call_id zrtp_tp:(pjmedia_transport *)zrtp_tp {
    self = [super init];
    if (self) {
        self.call_id = call_id;
        self.zrtp_tp = zrtp_tp;
    }

    return self;
}

+ (instancetype)infoWithCall_id:(pjsua_call_id)call_id zrtp_tp:(pjmedia_transport *)zrtp_tp {
    return [[self alloc] initWithCall_id:call_id zrtp_tp:zrtp_tp];
}


+ (instancetype)infoWithCall_id:(pjsua_call_id)call_id {
    return [[self alloc] initWithCall_id:call_id];
}

@end