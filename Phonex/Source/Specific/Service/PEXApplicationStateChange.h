//
// Created by Dusan Klinec on 30.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum PEX_APPSTATE_CHANGE_ENUM {
    PEX_APPSTATE_NA = 0,
    PEX_APPSTATE_WILL_RESIGN_ACTIVE,
    PEX_APPSTATE_DID_ENTER_BACKGROUND,
    PEX_APPSTATE_WILL_ENTER_FOREGROUND,
    PEX_APPSTATE_DID_BECOME_ACTIVE,
    PEX_APPSTATE_WILL_TERMINATE
} PEX_APPSTATE_CHANGE_ENUM;

@interface PEXApplicationStateChange : NSObject
@property(nonatomic) PEX_APPSTATE_CHANGE_ENUM stateChange;
@property(nonatomic) NSDictionary * extras;

- (instancetype)initWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange;
+ (instancetype)changeWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange;

- (instancetype)initWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange extras:(NSDictionary *)extras;
+ (instancetype)changeWithStateChange:(PEX_APPSTATE_CHANGE_ENUM)stateChange extras:(NSDictionary *)extras;

-(BOOL) isBackground;

- (NSString *)description;
@end