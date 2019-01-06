//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCertificateUpdateManagerProtocol.h"
#import "PEXRegisterable.h"

FOUNDATION_EXPORT NSString *PEX_ACTION_CERT_UPDATE_PROGRESS_DB;
FOUNDATION_EXPORT NSString *PEX_ACTION_CERT_UPDATED;
FOUNDATION_EXPORT NSString *PEX_EXTRA_UPDATE_PROGRESS;
FOUNDATION_EXPORT NSString *PEX_EXTRA_UPDATED_USERS;

@protocol PEXCanceller;
@class PEXCertificateUpdateTask;

@interface PEXCertificateUpdateManager : NSObject <PEXCertificateUpdateManagerProtocol, PEXRegisterable>
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;

+ (PEXCertificateUpdateManager *)instance;

/**
* Main entry point for adding a new certificate refresh requests.
* Array of PEXCertRefreshParams objects.
*/
-(void) triggerCertUpdate: (NSArray *) paramsList;
-(void) triggerCertUpdateForAll: (BOOL) forceAll;

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

/**
* Call to retry all requests in the request queue.
* Should be called on keep-alive event if certificate manager is in backoff phase (too many fails to refresh
* certificates in a row), this should re-start backoff/retry counter for the whole manager (not for individual entries)
* and retry the entries.
*/
-(void) retryQueuedRequests;

/**
* Keep alive logic.
* Resets fail count and if there is some request for cert update, starts a new task.
*/
-(void) keepAlive: (BOOL) async;

@end