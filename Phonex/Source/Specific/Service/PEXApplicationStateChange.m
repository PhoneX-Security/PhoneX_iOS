//
// Created by Dusan Klinec on 30.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXApplicationStateChange.h"


@implementation PEXApplicationStateChange {

}

- (instancetype)initWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange {
    self = [super init];
    if (self) {
        self.stateChange = stateChange;
    }

    return self;
}

- (instancetype)initWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange extras:(NSDictionary *)extras {
    self = [super init];
    if (self) {
        self.stateChange = stateChange;
        self.extras = extras;
    }

    return self;
}

+ (instancetype)changeWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange extras:(NSDictionary *)extras {
    return [[self alloc] initWithStateChange:stateChange extras:extras];
}


+ (instancetype)changeWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange {
    return [[self alloc] initWithStateChange:stateChange];
}

- (BOOL)isBackground {
    return self.stateChange != PEX_APPSTATE_DID_BECOME_ACTIVE;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.extras=%@", self.extras];
    [description appendFormat:@", self.stateChange=%d", self.stateChange];
    [description appendString:@">"];
    return description;
}


@end