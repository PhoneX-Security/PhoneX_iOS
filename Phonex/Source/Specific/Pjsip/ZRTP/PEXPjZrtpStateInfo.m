//
// Created by Dusan Klinec on 12.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjZrtpStateInfo.h"


@implementation PEXPjZrtpStateInfo {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.call_id = PJSUA_INVALID_ID;
        self.sas = nil;
        self.sas_verified = NO;
        self.cipher = nil;
        self.secure = NO;
        self.zrtp_hash_match = 0;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.call_id=%i", self.call_id];
    [description appendFormat:@", self.secure=%d", self.secure];
    [description appendFormat:@", self.sas=%@", self.sas];
    [description appendFormat:@", self.cipher=%@", self.cipher];
    [description appendFormat:@", self.sas_verified=%d", self.sas_verified];
    [description appendFormat:@", self.zrtp_hash_match=%i", self.zrtp_hash_match];
    [description appendString:@">"];
    return description;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.call_id = [coder decodeIntForKey:@"self.call_id"];
        self.secure = [coder decodeBoolForKey:@"self.secure"];
        self.sas = [coder decodeObjectForKey:@"self.sas"];
        self.cipher = [coder decodeObjectForKey:@"self.cipher"];
        self.sas_verified = [coder decodeBoolForKey:@"self.sas_verified"];
        self.zrtp_hash_match = [coder decodeIntForKey:@"self.zrtp_hash_match"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt:self.call_id forKey:@"self.call_id"];
    [coder encodeBool:self.secure forKey:@"self.secure"];
    [coder encodeObject:self.sas forKey:@"self.sas"];
    [coder encodeObject:self.cipher forKey:@"self.cipher"];
    [coder encodeBool:self.sas_verified forKey:@"self.sas_verified"];
    [coder encodeInt:self.zrtp_hash_match forKey:@"self.zrtp_hash_match"];
}


@end