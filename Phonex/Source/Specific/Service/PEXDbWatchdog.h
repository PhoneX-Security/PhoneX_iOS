//
// Created by Dusan Klinec on 20.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* Database accessibility watchdog.
* The watchdog has two running modes.
*
* If application is running in the background mode, there should be called doBackgroundCheck method
* in the keep alive handler to test DB sanity. If 3 consecutive DB read test fail, request for DB reload
* is broadcasted. Service should respond by reloading the database.
*
* If application is running in the foreground, DB accessibility is checked periodically, each X seconds.
* If several consecutive errors happen, request for DB reload is broadcasted.
*
* If number of DB reload requests is too high assertion is triggered so application is restarted by the iOS.
* Watchdog operates via DB app state events, it is started / stopped automatically.
*
* Watchdog uses private data structure to check DB sanity by loading user profile from the database by currently
* logged in user. DB accessibility test consists of two tests: 1. simple DB read query, 2. user profile fetch.
*
* Watchdog logs DB read fail event to Flurry as PEX_EVENT_DB_WATCHDOG_ERROR.
*/
@interface PEXDbWatchdog : NSObject
@property(nonatomic, readonly, weak) PEXUserPrivate * privData;

-(void) doRegister;
-(void) doUnregister;
-(void) udatePrivData: (PEXUserPrivate *) privData;

/**
* Call suitable for keep-alive DB check. Check is performed in calling thread without unnecessary sleeping.
* If 3 consecutive read attempts fails, DB reload request is broadcasted.
* Returns YES if everything is OK or user is not logged in.
* Returns NO if database was not working properly.
*/
- (BOOL) doBackgroundCheck;

/**
* General read check.
* Returns:
*   -1 if simple read fails.
*   -2 if account read fails.
*   0 if everything is OK.
*   1 if private data is not usable for account fetch.
*/
+ (int) dbReadCheck: (PEXUserPrivate *) privData;
@end