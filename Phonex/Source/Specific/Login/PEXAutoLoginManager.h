//
// Created by Dusan Klinec on 01.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXAutoLoginManager;
@protocol PEXCanceller;

// Finished block.
typedef void (^PExLoginFinishedBlock)(PEXAutoLoginManager * mgr);

FOUNDATION_EXPORT int PEX_AUTOLOGIN_SUCC;
FOUNDATION_EXPORT int PEX_AUTOLOGIN_FAIL;
FOUNDATION_EXPORT int PEX_AUTOLOGIN_LATER;

@interface PEXAutoLoginManager : NSObject
@property (nonatomic) BOOL waitOnCompleteSvcInit;
@property (nonatomic, readonly) BOOL lastDbOpenWasOk;
@property (nonatomic, readonly) PEXCredentials * creds;
@property (nonatomic) PEXUserPrivate * privData;
@property (nonatomic, readonly) BOOL lastServiceStartWasOk;

/**
* if autologin fails and this property is set to YES, user should be notified the application start
* was not successful and requires his attention. Login in this case should use password stored in the key chain.
*/
@property (nonatomic, readonly) BOOL shouldTryNormalLogin;

/**
* Canceller for long-running key derivation tasks during login. Can be nil.
*/
@property (nonatomic) id<PEXCanceller> canceller;

/**
* Will be executed when login is finished. Can be nil.
* In order to determine result caller should ask given manager.
*/
@property (nonatomic, copy) PExLoginFinishedBlock onLoginFinishedBlock;

+ (PEXAutoLoginManager *) newInstanceNotThreadSafe;

/**
* Returns YES if auto-login was performed successfully.
*/
-(BOOL) wasLoggedIn;

/**
* Returns YES if autologin is possible - there are some credentials stored.
* Effectively calls tryLoadCredentials.
* This call should be quite fast. If it returns NO auto-login will definitely fail so there is no need to try it.
* Has to be called on the main thread.
*/
-(BOOL)fastInit;

/**
* Returns YES if stored credentials are usable for encrypted database.
* Effectively calls tryOpenDatabase.
* Prepares for auto-login, registers connectivity watcher.
* If credentials were not loaded with fastInit they are loaded by this call.
* Can be called out of the main thread.
*/
-(BOOL)prepareAutoLogin;

/**
* Tries to auto-login.
* If credentials weren't loaded or database wasn't tried to be opened, this call tries to do it.
* For now, this is synchronous call.
* Can be called out of the main thread.
*/
-(int) doAutoLogin;

/**
* Terminate login process. Has to be called when e.g. fastInit was called, but prepareAutoLogin was not.
* Performs unregistration and cleans up the state.
*/
-(void) quit;

@end