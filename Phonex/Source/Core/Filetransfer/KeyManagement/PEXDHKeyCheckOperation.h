//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDhKeyGenManager;
@protocol PEXCanceller;
@class PEXDHKeyGeneratorParams;

FOUNDATION_EXPORT const NSInteger PEXFtErrorGetKeyFailed;
FOUNDATION_EXPORT const NSInteger PEXFtErrorGetKeyNotConnected;
FOUNDATION_EXPORT const NSInteger PEXFtErrorGetKeyFailedException;
@interface PEXDHKeyCheckOperation : NSOperation
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
@property(nonatomic) NSInteger maxDhKeys;

@property(nonatomic) BOOL shouldPerformCleaning;
@property(nonatomic) BOOL shouldExpireKeys;
@property(nonatomic) BOOL triggerKeyUpdate;

@property(nonatomic, readonly) NSError * opError;
@property(nonatomic, readonly) NSInteger numOfUsersUpdated;
@property(nonatomic, readonly) BOOL interruptedDueToConnectionError;

- (instancetype)initWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData;
+ (instancetype)operationWithMgr:(PEXDhKeyGenManager *)mgr privData:(PEXUserPrivate *)privData;
- (void) doCancel;

@end