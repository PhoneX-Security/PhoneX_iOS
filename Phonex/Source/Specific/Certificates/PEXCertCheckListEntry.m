//
// Created by Dusan Klinec on 04.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertCheckListEntry.h"
#import "PEXCertRefreshParams.h"


@implementation PEXCertCheckListEntry {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.byPushNotification = NO;
        self.cancelledFlag = NO;
        self.policyCheck = YES;
        self.urgent = NO;
        self.failCount = 0;
    }

    return self;
}


- (void)doCancel {
    self.cancelledFlag = YES;
}

- (BOOL)wasCancelled {
    return self.cancelledFlag;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.usr = [coder decodeObjectForKey:@"self.usr"];
        self.policyCheck = [coder decodeBoolForKey:@"self.policyCheck"];
        self.params = [coder decodeObjectForKey:@"self.params"];
        self.byPushNotification = [coder decodeBoolForKey:@"self.byPushNotification"];
        self.cancelledFlag = [coder decodeBoolForKey:@"self.cancelledFlag"];
        self.urgent = [coder decodeBoolForKey:@"self.urgent"];

    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.usr forKey:@"self.usr"];
    [coder encodeBool:self.policyCheck forKey:@"self.policyCheck"];
    [coder encodeObject:self.params forKey:@"self.params"];
    [coder encodeBool:self.byPushNotification forKey:@"self.byPushNotification"];
    [coder encodeBool:self.cancelledFlag forKey:@"self.cancelledFlag"];
    [coder encodeBool:self.urgent forKey:@"self.urgent"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXCertCheckListEntry *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.usr = self.usr;
        copy.policyCheck = self.policyCheck;
        copy.params = self.params;
        copy.byPushNotification = self.byPushNotification;
        copy.cancelledFlag = self.cancelledFlag;
        copy.urgent = self.urgent;
    }

    return copy;
}

- (double)cost {
    return 0.0;
}


@end