//
// Created by Dusan Klinec on 21.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushRequestPart.h"
#import "PEXMessageDigest.h"
#import "PEXUtils.h"

static NSString * PEX_PUSH_FIELD_ACTION = @"push";
static NSString * PEX_PUSH_FIELD_KEY = @"key";
static NSString * PEX_PUSH_FIELD_EXPIRE = @"expire";
static NSString * PEX_PUSH_FIELD_TARGET = @"target";
static NSString * PEX_PUSH_FIELD_CANCEL = @"cancel";

@implementation PEXPushRequestPart {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.cancel = NO;
        self.expiration = nil;
    }

    return self;
}

- (instancetype)initWithAction:(NSString *)action toUser:(NSString *)toUser {
    self = [self init];
    if (self) {
        self.action = action;
        self.toUser = toUser;
    }

    return self;
}

- (instancetype)initWithAction:(NSString *)action key:(NSString *)key toUser:(NSString *)toUser {
    self = [self init];
    if (self) {
        self.action = action;
        self.key = key;
        self.toUser = toUser;
    }

    return self;
}

+ (instancetype)partWithAction:(NSString *)action key:(NSString *)key toUser:(NSString *)toUser {
    return [[self alloc] initWithAction:action key:key toUser:toUser];
}


+ (instancetype)partWithAction:(NSString *)action toUser:(NSString *)toUser {
    return [[self alloc] initWithAction:action toUser:toUser];
}

+ (instancetype)activeCallWithKey:(NSString *)key toUser:(NSString *)toUser {
    return [self partWithAction:@"newCall" key:key toUser:toUser];
}

+ (instancetype)messageWithKey:(NSString *)key toUser:(NSString *)toUser {
    return [self partWithAction:@"newMessage" key:key toUser:toUser];
}

+ (instancetype)missedCallWithKey:(NSString *)key toUser:(NSString *)toUser {
    return [self partWithAction:@"newMissedCall" key:key toUser:toUser];
}

-(BOOL) canMergeWith: (PEXPushRequestPart *) part {
    if (part == nil || part.action == nil || part.toUser == nil){
        return NO;
    }

    if (self.action == nil || self.toUser == nil){
        return NO;
    }

    return NO; // no merging for now. Each is non-unique.
}

-(BOOL) willChangeAfterMergeWith: (PEXPushRequestPart *) part {
    return YES;
}

+ (NSString *)genKey {
    NSDate * dt =  [NSDate date];
    NSData * da = [PEXMessageDigest sha256Message:[NSString stringWithFormat:@"dt:%f", [dt timeIntervalSince1970]]];
    NSString * in = [PEXMessageDigest bytes2hex:da];
    return [in substringToIndex:8];
}

- (NSMutableDictionary *)getSerializationBase {
    NSMutableDictionary * ret = [NSMutableDictionary dictionaryWithDictionary:
    @{
            PEX_PUSH_FIELD_ACTION : [self action],
            PEX_PUSH_FIELD_TARGET : [self toUser]
    }];

    if ([self expiration] != nil) {
        ret[PEX_PUSH_FIELD_EXPIRE] = [self expiration];
    }

    if ([self cancel]) {
        ret[PEX_PUSH_FIELD_CANCEL] = @([self cancel]);
    }

    NSString * cKey = [self key];
    if (![PEXUtils isEmpty:cKey]) {
        ret[PEX_PUSH_FIELD_KEY] = cKey;
    }

    return ret;
}

@end