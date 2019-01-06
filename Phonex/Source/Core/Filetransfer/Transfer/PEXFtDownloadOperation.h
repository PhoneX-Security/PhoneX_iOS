//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXFtTransferManager;
@protocol PEXCanceller;
@class PEXService;

@interface PEXFtDownloadOperation : NSOperation
@property(nonatomic, weak) PEXFtTransferManager * mgr;
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;

/**
* Whether to show Android Notifications during download.
*/
@property(nonatomic) BOOL showNotifications;

/**
* Whether to write error codes to the SIP message
*/
@property(nonatomic) BOOL writeErrorToMessage;

/**
* Delete files from server (e.g., after successful download) ?
*/
@property(nonatomic) BOOL deleteFromServer;
@property(nonatomic, readonly) NSError * opError;
@property(nonatomic, readonly) PEXService * svc;
@property(nonatomic, readonly) BOOL interruptedDueToConnectionError;

- (instancetype)initWithMgr:(PEXFtTransferManager *)mgr privData:(PEXUserPrivate *)privData;
+ (instancetype)operationWithMgr:(PEXFtTransferManager *)mgr privData:(PEXUserPrivate *)privData;

-(void) doCancel;
@end