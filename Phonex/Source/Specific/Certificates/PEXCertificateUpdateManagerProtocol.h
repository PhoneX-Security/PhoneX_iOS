//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCertUpdateProgress.h"

@protocol PEXCertificateUpdateManagerProtocol <NSObject>
/**
* Returns recent progress for certificate update.
* @return
*/
-(NSArray *) getCertUpdateProgress;

/**
* Update certificate update state for a single user.
*
* @param user
* @param state
*/
-(void) updateState: (NSString *) user state: (PEXCertUpdateStateEnum) state;

/**
* Update certificate update state for multiple users.
*
* @param users
* @param state
*/
-(void) updateStateBatch: (NSArray *) users state: (PEXCertUpdateStateEnum) state;

/**
* Reset state of all updates to done.
*/
-(void) resetState;

/**
* Broadcast certificate update state.
*/
-(void) bcastState;

/**
* Called when some certificates got updated.
*/
-(void) certificatesUpdated: (NSArray *) updatedUsers;

/**
* Increase number of consecutive fails to refresh certificates (whole batch failed).
*/
-(void) failCountInc;

/**
* Reset number of consecutive fails to refresh whole batch of certificates.
*/
-(void) failCountReset;

/**
* Get number of consecutive fails to refresh whole batch of certificates.
*/
-(NSUInteger) failCountGet;

/**
* Returns YES if failcount is under threshold and cert check should be triggered.
*/
-(BOOL) isFailCountOK;

@optional
/**
* Adds users to the check list.
*
* @param paramsList
*/
-(void) addToCheckList: (NSArray * ) paramsList async: (BOOL) async;

/**
* Adds array of PEXCertCheckListEntry directly to the cert check list.
* Warning: should be considered as protected.
*/
-(void) addToCertCheckList: (NSArray *) certCheckEntryList async: (BOOL) async;

@end