//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//


#import "PEXUserPrivate.h"
#import "PEXAppVersionUtils.h"
#import "PEXChatsManager.h"
#import "PEXLicenceManager.h"
#import "PEXChatAccountingManager.h"
#import "PEXService.h"
#import "PEXReferenceTimeManager.h"

@interface PEXAppState ()

@property(atomic) PEXUserPrivate * intPrivData;

@end

@implementation PEXAppState {

}

- (id)init
{
    self = [super init];

    return self;
}

- (void) resetPinLockAttempts
{
    [self setPinLockAttempts:PEX_PIN_LOCK_MAX_ATTEMPTS_COUNT];
}

+ (void) initInstance
{
    [PEXAppState instance];
}

+ (PEXAppState *) instance
{
    static PEXAppState * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXAppState alloc] init];
    });

    return instance;
}

- (void)setPrivData:(PEXUserPrivate *)priv {
    self.intPrivData = priv;
}

- (PEXUserPrivate *)getPrivateData {
    return self.intPrivData;
}

/**
* Clears all app managers for logged user.
* Should be probably called on logout
*/
- (void) clearManagers
{
    self.chatsManager = nil;
    self.callsManager = nil;
    self.chatAccountingManager = nil;
    self.contactNotificationManager = nil;
    self.referenceTimeManager = nil;
}

@end