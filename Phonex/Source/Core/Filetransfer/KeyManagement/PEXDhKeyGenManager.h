//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDHKeyGeneratorProgress.h"

@protocol PEXCanceller;
@class PEXUserKeyRefreshQueue;
@class PEXUserKeyRefreshRecord;

FOUNDATION_EXPORT NSString * PEX_ACTION_DHKEYGEN_UPDATE_PROGRESS_DB;
FOUNDATION_EXPORT NSString * PEX_ACTION_DHKEYS_UPDATED;
FOUNDATION_EXPORT NSString * PEX_EXTRA_DHKEYS_UPDATED;
FOUNDATION_EXPORT NSString * PEX_ACTION_TRIGGER_DHKEYCHECK;

@interface PEXDhKeyGenManager : NSObject
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, readonly) PEXUserKeyRefreshQueue * userQueue;

+(PEXDhKeyGenManager *) instance;
-(void) onAccountLoggedIn;
-(void) doRegister;
-(void) doUnregister;
-(void) quit;

+(void) triggerUserCheck;
-(void) triggerUserCheck;
-(void) triggerUserCheck:(NSArray *)paramsList allUsers: (BOOL) allUsers;
-(void)triggerKeyGen;

/**
* Progress monitoring.
*/
-(void) bcastState;
-(void) resetState;
-(void) updateState: (NSString *) user state: (PEXKeyGenStateEnum) state;
-(void) updateStateBatch: (NSArray *) users state: (PEXKeyGenStateEnum) state;

/**
* Queue management
*/
-(PEXUserKeyRefreshRecord *) getUserRecord: (NSString *) user;
-(PEXUserKeyRefreshRecord *) peekUserRecord;
-(PEXUserKeyRefreshRecord *) pollUserRecord;

/**
* Updates record defined as parameter. If does not exist in the queue, new is inserted.
*/
-(void) updateUserRecord: (PEXUserKeyRefreshRecord *) record;
@end