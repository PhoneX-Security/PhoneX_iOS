//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXUserPrivate.h"
#import "PEXTimeUtils.h"

@class PEXChatsManager;
@class PEXCallsManager;
@class PEXLicenceManager;
@class PEXChatAccountingManager;
@class PEXReferenceTimeManager;
@class PEXContactNotificationManager;

static const int PEX_PIN_LOCK_MAX_ATTEMPTS_COUNT = 3;

@interface PEXAppState : NSObject

@property (atomic, assign) bool isAppActive;
@property (nonatomic, assign) bool logged;

// TODO move to persistent storage because of auto-login
// This is required because the current licence is downloaded on login,
// before the database for a user is open.
@property (nonatomic, assign) int pinLockAttempts;


@property (nonatomic) PEXChatsManager * chatsManager;
@property (nonatomic) PEXCallsManager * callsManager;
@property (nonatomic) PEXChatAccountingManager *chatAccountingManager;
@property (nonatomic) PEXContactNotificationManager * contactNotificationManager;
@property (nonatomic) PEXReferenceTimeManager * referenceTimeManager;

@property (nonatomic, assign) bool appLoggedGuiWasShown;

- (void) resetPinLockAttempts;

+ (void) initInstance;
+ (id) instance;

/**
* Set private data for the user.
* Intended to be called after successful login so the application
* has a central place for storing such sensitive data. Private data
* is required on a several places in the application, this is a central
* holder for currently logged in user.
*/
- (void) setPrivData: (PEXUserPrivate *) priv;

/**
* Returns private data object for currently logged in user.
* Returns nil if there is no logged in user.
*/
- (PEXUserPrivate *) getPrivateData;

- (void) clearManagers;

@end