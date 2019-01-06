//
// Created by Dusan Klinec on 27.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPresenceUpdate.h"
#import "XMPPJID.h"


@implementation PEXPresenceUpdate {

}
- (instancetype)initWithUser:(NSString *)user isAvailable:(BOOL)isAvailable statusText:(NSString *)statusText {
    self = [super init];
    if (self) {
        self.user = user;
        self.isAvailable = isAvailable;
        self.statusText = statusText;
    }

    return self;
}

- (instancetype)initWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user {
    self = [super init];
    if (self) {
        self.isAvailable = isAvailable;
        self.statusText = statusText;
        self.timestamp = timestamp;
        self.user = user;
    }

    return self;
}

- (instancetype)initWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user xmppUser:(XMPPJID *)xmppUser {
    self = [super init];
    if (self) {
        self.isAvailable = isAvailable;
        self.statusText = statusText;
        self.timestamp = timestamp;
        self.user = user;
        self.xmppUser = xmppUser;
    }

    return self;
}

+ (instancetype)updateWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user xmppUser:(XMPPJID *)xmppUser {
    return [[self alloc] initWithIsAvailable:isAvailable statusText:statusText timestamp:timestamp user:user xmppUser:xmppUser];
}


+ (instancetype)updateWithIsAvailable:(BOOL)isAvailable statusText:(NSString *)statusText timestamp:(NSDate *)timestamp user:(NSString *)user {
    return [[self alloc] initWithIsAvailable:isAvailable statusText:statusText timestamp:timestamp user:user];
}


+ (instancetype)updateWithUser:(NSString *)user isAvailable:(BOOL)isAvailable statusText:(NSString *)statusText {
    return [[self alloc] initWithUser:user isAvailable:isAvailable statusText:statusText];
}

@end