//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXCanceller;
@class PEXDhKeyGenManager;

FOUNDATION_EXPORT const NSInteger PEX_NUM_OF_UPLOAD_RETRIES;
FOUNDATION_EXPORT const NSInteger PEX_NUM_OF_USERS_IN_BULK;
FOUNDATION_EXPORT const NSInteger PEX_NUM_OF_KEYS_PER_USER_IN_BULK;
FOUNDATION_EXPORT const NSInteger PEXFtErrorKeyUploadFailed;
FOUNDATION_EXPORT const NSInteger PEXFtErrorKeyUploadFailedNotConnected;
FOUNDATION_EXPORT const NSInteger PEXFtErrorKeyUploadFailedException;

@interface PEXDHKeyGenOperation : NSOperation
/**
* Key gen manager to be used for check.
* This task operates on queue owned by this manager.
*/
@property(nonatomic, weak) PEXDhKeyGenManager * mgr;

/**
* User credentials for certificate check. Certificate check is user dependent.
*/
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, readonly) NSError * opError;
@property(nonatomic, readonly) BOOL interruptedDueToConnectionError;

/**
* Stores user names for which there was at least one new key generated.
*/
@property(nonatomic, readonly) NSArray * usersWithKeysGenerated;

@property(nonatomic) NSInteger numOfUsersInBulk;
@property(nonatomic) NSInteger numOfKeysPerUserInBulk;
@property(nonatomic) NSInteger numOfUploadRetries;

- (instancetype)initWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData;
+ (instancetype)operationWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData;

- (void) doCancel;
-(BOOL) wasCancelled;

@end